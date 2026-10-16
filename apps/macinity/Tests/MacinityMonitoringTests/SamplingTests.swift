import Foundation
import XCTest

@testable import MacinityMonitoring

final class SamplingTests: XCTestCase {
  func testInvalidPhysicalMemoryCannotBecomeZeroUtilization() {
    XCTAssertEqual(
      MemoryInfo(totalBytes: 100, freeBytes: 25, wiredBytes: 10, compressedBytes: 5)
        .occupiedPercent, 75)
    XCTAssertNil(
      MemoryInfo(totalBytes: 0, freeBytes: 0, wiredBytes: 0, compressedBytes: 0).occupiedPercent)
    XCTAssertNil(
      MemoryInfo(totalBytes: 100, freeBytes: 101, wiredBytes: 0, compressedBytes: 0).occupiedPercent
    )
  }

  func testRatesRejectInvalidPairsAndKeepTrueZero() {
    for elapsed in [0, -1, .nan, .infinity] {
      XCTAssertNil(RateCalculator.rate(previous: 1, current: 2, elapsed: elapsed))
    }
    XCTAssertNil(RateCalculator.rate(previous: 100, current: 1, elapsed: 1))
    XCTAssertEqual(RateCalculator.rate(previous: 100, current: 100, elapsed: 2), 0)
    XCTAssertEqual(RateCalculator.rate(previous: 100, current: 400, elapsed: 2), 150)
    XCTAssertEqual(
      RateCalculator.processCPU(
        previous: 0, current: 24_000_000, elapsed: 1, numerator: 125, denominator: 3), 100)
    XCTAssertNil(
      RateCalculator.processCPU(previous: 1, current: 0, elapsed: 1, numerator: 1, denominator: 1))
  }
  func testSystemCPUNormalizationAndWrap() {
    let before = CPUTicks(user: 10, system: 20, nice: 30, idle: 40)
    XCTAssertEqual(
      RateCalculator.cpu(
        previous: before, current: CPUTicks(user: 20, system: 30, nice: 40, idle: 110)), 30)
    XCTAssertNil(RateCalculator.cpu(previous: before, current: before))
    XCTAssertNil(
      RateCalculator.cpu(
        previous: before, current: CPUTicks(user: 0, system: 30, nice: 40, idle: 110)))
  }
  func testRingOverwritesOldestWithoutReordering() {
    var ring = RingBuffer<Int>(capacity: 3)
    for value in 0..<100_000 { ring.append(value) }
    XCTAssertEqual(ring.count, 3)
    XCTAssertEqual(ring.elements, [99_997, 99_998, 99_999])
  }
  func testAvailabilityDoesNotInventZeroAndUsesMonotonicFreshness() {
    let time = SampleTime(wall: Date(timeIntervalSince1970: 0), monotonic: 10)
    let sample = MetricSample(
      value: 0.0, availability: .available, unit: .percent, time: time, source: "fixture")
    XCTAssertEqual(sample.freshness(at: 12, maximumAge: 3), .available)
    XCTAssertEqual(sample.freshness(at: 14, maximumAge: 3), .stale)
    XCTAssertEqual(sample.freshness(at: 9, maximumAge: 3), .stale)
    XCTAssertEqual(sample.value, 0)
    let missing = MetricSample<Double>(
      availability: .available, unit: .percent, time: time, source: "fixture")
    XCTAssertNil(missing.value)
    XCTAssertEqual(missing.availability, .temporarilyUnavailable)
    let failed = MetricSample(
      value: 5.0, availability: .error, unit: .percent, time: time, source: "fixture")
    XCTAssertNil(failed.value)
  }
}

@MainActor
final class MonitoringLifecycleTests: XCTestCase {
  func testWarmUpPauseResumeAndBoundedPublication() async {
    let clock = ManualMonitoringClock()
    let engine = MonitoringCoordinator(provider: FixtureAggregateProvider(), clock: clock)
    var iterator = await engine.snapshots().makeAsyncIterator()
    await engine.setMode(.active)
    let first = await iterator.next()
    XCTAssertEqual(first?.cpu.availability, .loading)
    await clock.advance(to: 1)
    let second = await iterator.next()
    XCTAssertEqual(second?.cpu.value, 50)
    for second in 2...65 {
      await clock.advance(to: Double(second))
      _ = await iterator.next()
    }
    await clock.advance(to: 66)
    let bounded = await iterator.next()
    XCTAssertEqual(bounded?.history.count, 60)
    XCTAssertEqual(bounded?.history.first?.time.monotonic, 7)
    await engine.setMode(.paused)
    await engine.setMode(.active)
    let resumed = await iterator.next()
    XCTAssertEqual(resumed?.cpu.availability, .loading)
    await engine.stop()
    let finished = await iterator.next()
    XCTAssertNil(finished)
  }
  func testCancellationDiscardsLateProviderCompletionBeforeResume() async {
    let clock = ManualMonitoringClock()
    let provider = GatedAggregateProvider()
    let engine = MonitoringCoordinator(provider: provider, clock: clock)
    var iterator = await engine.snapshots().makeAsyncIterator()
    await engine.setMode(.active)
    await provider.waitUntilEntered()
    let pause = Task { await engine.setMode(.paused) }
    await provider.waitUntilCancelled()
    await provider.release()
    await pause.value
    await engine.setMode(.active)
    let fresh = await iterator.next()
    XCTAssertEqual(fresh?.cpu.availability, .loading)
    XCTAssertEqual(fresh?.history.count, 1)
    await engine.stop()
  }

  func testRepeatedDemandHasOneSampler() async {
    let clock = ManualMonitoringClock()
    let provider = FixtureAggregateProvider()
    let engine = MonitoringCoordinator(provider: provider, clock: clock)
    var iterator = await engine.snapshots().makeAsyncIterator()
    await engine.setMode(.active)
    _ = await iterator.next()
    for _ in 0..<50 { await engine.setMode(.active) }
    let count = await provider.reads
    XCTAssertEqual(count, 1)
    await clock.advance(to: 1)
    _ = await iterator.next()
    let nextCount = await provider.reads
    XCTAssertEqual(nextCount, 2)
    await engine.stop()
  }
}

private actor ManualMonitoringClock: MonitoringClock {
  private var time = 0.0
  private var sleeper: CheckedContinuation<Void, Error>?
  private var observers: [CheckedContinuation<Void, Never>] = []
  func now() -> SampleTime { SampleTime(wall: Date(timeIntervalSince1970: time), monotonic: time) }
  func sleep(seconds: Double) async throws {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        if Task.isCancelled {
          continuation.resume(throwing: CancellationError())
          return
        }
        sleeper = continuation
        for observer in observers { observer.resume() }
        observers.removeAll()
      }
    } onCancel: {
      Task { await self.cancelSleep() }
    }
  }
  func advance(to next: Double) async {
    if sleeper == nil { await withCheckedContinuation { observers.append($0) } }
    time = next
    sleeper?.resume()
    sleeper = nil
  }
  private func cancelSleep() {
    sleeper?.resume(throwing: CancellationError())
    sleeper = nil
  }
}
private actor FixtureAggregateProvider: MonitoringProvider {
  private(set) var reads = 0
  func readAggregate(at time: SampleTime) -> AggregateReading {
    reads += 1
    let tick = UInt64(time.monotonic * 10)
    return AggregateReading(
      cpu: MetricSample(
        value: CPUTicks(user: tick, system: 0, nice: 0, idle: tick), availability: .available,
        unit: .ticks, time: time, source: "fixture"),
      memory: MetricSample(
        value: MemoryInfo(totalBytes: 100, freeBytes: 25, wiredBytes: 10, compressedBytes: 5),
        availability: .available, unit: .bytes, time: time, source: "fixture"))
  }
}

private actor GatedAggregateProvider: MonitoringProvider {
  private var entered = false
  private var cancelled = false
  private var gate: CheckedContinuation<Void, Never>?
  private var entryWaiter: CheckedContinuation<Void, Never>?
  private var cancelWaiter: CheckedContinuation<Void, Never>?
  func readAggregate(at time: SampleTime) async -> AggregateReading {
    if !entered {
      await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
          gate = continuation
          entered = true
          entryWaiter?.resume()
          entryWaiter = nil
        }
      } onCancel: {
        Task { await self.markCancelled() }
      }
    }
    return AggregateReading(
      cpu: MetricSample(
        value: CPUTicks(user: 1, system: 1, nice: 0, idle: 2), availability: .available,
        unit: .ticks, time: time, source: "gated fixture"),
      memory: MetricSample(
        value: MemoryInfo(totalBytes: 100, freeBytes: 50, wiredBytes: 1, compressedBytes: 0),
        availability: .available, unit: .bytes, time: time, source: "gated fixture"))
  }
  func waitUntilEntered() async {
    if !entered { await withCheckedContinuation { entryWaiter = $0 } }
  }
  func waitUntilCancelled() async {
    if !cancelled { await withCheckedContinuation { cancelWaiter = $0 } }
  }
  func markCancelled() {
    cancelled = true
    cancelWaiter?.resume()
    cancelWaiter = nil
  }
  func release() {
    gate?.resume()
    gate = nil
  }
}
