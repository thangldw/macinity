import Foundation
import XCTest
import os

@testable import MacinityMonitoring

final class ProcessTests: XCTestCase {
  private let identity = ProcessIdentity(pid: 123, startSeconds: 1, startMicroseconds: 0)

  func testPIDReuseAndCounterResetNeverProduceCPUFromOldProcess() {
    var tracker = ProcessTracker()
    func reading(start: UInt64, ticks: UInt64, state: MetricAvailability = .available)
      -> ProcessReading
    {
      ProcessReading(
        observations: [
          ProcessObservation(
            pid: 123,
            metadata: ProcessMetadata(
              identity: ProcessIdentity(pid: 123, startSeconds: start, startMicroseconds: 0),
              name: "worker", parentPID: 1),
            counters: state == .available
              ? ProcessCounters(cpuTicks: ticks, residentBytes: 42, threadCount: 1) : nil,
            availability: state, reason: nil)
        ], availability: .available)
    }
    func time(_ value: Double) -> SampleTime {
      SampleTime(wall: Date(timeIntervalSince1970: value), monotonic: value)
    }
    XCTAssertNil(tracker.update(reading(start: 1, ticks: 10), at: time(1)).first?.cpu.value)
    XCTAssertEqual(
      tracker.update(reading(start: 1, ticks: 1_000_000_010), at: time(2)).first?.cpu.value, 100)
    XCTAssertNil(
      tracker.update(reading(start: 2, ticks: 2_000_000_010), at: time(3)).first?.cpu.value)
    XCTAssertNil(tracker.update(reading(start: 2, ticks: 1), at: time(4)).first?.cpu.value)
    XCTAssertNil(
      tracker.update(reading(start: 2, ticks: 1, state: .permissionRequired), at: time(5)).first?
        .memory.value)
    XCTAssertNil(
      tracker.update(reading(start: 2, ticks: 3_000_000_010), at: time(6)).first?.cpu.value)
  }

  func testInspectorRevalidatesIdentityAfterReadingAndPreservesPermissionState() {
    let metadata = ProcessMetadata(identity: identity, name: "worker", parentPID: 1)
    let changed = ProcessMetadata(
      identity: ProcessIdentity(pid: 123, startSeconds: 2, startMicroseconds: 0), name: "other",
      parentPID: 1)
    let reused = ProcessInspector(access: FixtureAccess(metadata: [metadata, changed]))
    let result = reused.inspect(pid: 123)
    XCTAssertEqual(result.availability, .temporarilyUnavailable)
    XCTAssertNil(result.counters)
    for error in [ProcessReadError.exited, .permissionRequired] {
      let failed = ProcessInspector(access: FixtureAccess(metadata: [metadata], failure: error))
        .inspect(pid: 123)
      XCTAssertEqual(failed.availability, error.availability)
      XCTAssertNil(failed.counters)
    }
    let wrong = ProcessInspector(access: FixtureAccess(metadata: [changed])).inspect(
      pid: 123, expected: identity)
    XCTAssertNil(wrong.counters)
    XCTAssertEqual(wrong.reason, "identityChanged")
  }

  func testLargeProcessSetHasBoundedTrendsAndStableFilteringSorting() {
    var tracker = ProcessTracker()
    let observations = (1...10_000).map { pid in
      ProcessObservation(
        pid: Int32(pid),
        metadata: ProcessMetadata(
          identity: ProcessIdentity(pid: Int32(pid), startSeconds: 1, startMicroseconds: 0),
          name: "worker-\(pid)", parentPID: 1),
        counters: ProcessCounters(cpuTicks: 10, residentBytes: UInt64(pid), threadCount: 1),
        availability: .available, reason: nil)
    }
    let samples = tracker.update(
      ProcessReading(observations: observations, availability: .available),
      at: SampleTime(wall: Date(), monotonic: 1))
    XCTAssertEqual(samples.count, 10_000)
    XCTAssertEqual(samples.filter { !$0.cpuHistory.isEmpty }.count, 100)
    XCTAssertEqual(ProcessOrdering.memory.sorted(samples).first?.pid, 10_000)
    XCTAssertEqual(ProcessOrdering.pid.sorted(samples, query: "worker-9999").map(\.pid), [9999])
    _ = tracker.update(
      ProcessReading(observations: [], availability: .available),
      at: SampleTime(wall: Date(), monotonic: 2))
    let restarted = tracker.update(
      ProcessReading(observations: [observations[0]], availability: .available),
      at: SampleTime(wall: Date(), monotonic: 3))
    XCTAssertEqual(restarted.first?.cpuHistory.count, 1)
  }
}

private final class FixtureAccess: ProcessAccess {
  private struct State {
    var metadata: [ProcessMetadata]
    var index = 0
  }
  private let state: OSAllocatedUnfairLock<State>
  private let failure: ProcessReadError?
  init(metadata: [ProcessMetadata], failure: ProcessReadError? = nil) {
    state = OSAllocatedUnfairLock(initialState: State(metadata: metadata))
    self.failure = failure
  }
  func metadata(pid: Int32) -> ProcessMetadata {
    state.withLock { state in
      let value = state.metadata[min(state.index, state.metadata.count - 1)]
      state.index += 1
      return value
    }
  }
  func counters(pid: Int32) throws -> ProcessCounters {
    if let failure { throw failure }
    return ProcessCounters(cpuTicks: 10, residentBytes: 100, threadCount: 1)
  }
}
