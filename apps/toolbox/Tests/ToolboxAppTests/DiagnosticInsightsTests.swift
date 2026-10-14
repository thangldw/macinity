import Foundation
import XCTest

@testable import Toolbox
@testable import ToolboxMonitoring

final class DiagnosticInsightsTests: XCTestCase {
  private func snapshot(gap: Bool = false, generationChange: Bool = false) -> MonitoringSnapshot {
    let time = SampleTime(wall: Date(), monotonic: 100)
    let hardware = HardwareReading.unsupported(at: time)
    var history: [TrendPoint] = []
    for index in 0...30 {
      let shift: Double = gap && index == 4 ? 5 : 0
      let timestamp = SampleTime(wall: Date(), monotonic: Double(index + 70) - shift)
      let generation: Int = generationChange && index == 3 ? 1 : 2
      history.append(
        TrendPoint(
          time: timestamp, generation: generation, ioSampled: false,
          cpuPercent: 90, memoryPercent: 100, networkInput: nil, networkOutput: nil,
          diskInput: nil, diskOutput: nil))
    }
    return MonitoringSnapshot(
      time: time,
      cpu: .init(
        value: 90, availability: .available, unit: .percent, time: time, source: "fixture"),
      memory: .init(
        value: .init(totalBytes: 100, freeBytes: 0, wiredBytes: 0, compressedBytes: 0),
        availability: .available, unit: .bytes, time: time, source: "fixture"),
      history: history,
      processes: .init(
        value: [], availability: .available, unit: .collection, time: time, source: "fixture"),
      hardware: .init(
        disks: .init(
          availability: .unsupported, unit: .bytesPerSecond, time: time, source: "fixture"),
        interfaces: .init(
          availability: .unsupported, unit: .bytesPerSecond, time: time, source: "fixture"),
        reading: hardware))
  }
  func testSustainedCPURequiresContinuousFreshActiveGeneration() {
    XCTAssertEqual(
      DiagnosticInsights.evaluate(snapshot(), now: 100, active: true).map(\.id), ["cpu"])
    for value in [snapshot(gap: true), snapshot(generationChange: true)] {
      XCTAssertTrue(DiagnosticInsights.evaluate(value, now: 100, active: true).isEmpty)
    }
    XCTAssertTrue(DiagnosticInsights.evaluate(snapshot(), now: 107, active: true).isEmpty)
    XCTAssertTrue(DiagnosticInsights.evaluate(snapshot(), now: 100, active: false).isEmpty)
    XCTAssertTrue(DiagnosticInsights.evaluate(snapshot(), now: 99, active: true).isEmpty)
    // 100% occupied RAM must not manufacture pressure when pressure is unsupported.
    XCTAssertFalse(
      DiagnosticInsights.evaluate(snapshot(), now: 100, active: true).contains { $0.id == "memory" }
    )
  }
  func testExportExcludesProcessNamesByDefaultAndPreservesUnavailableState() throws {
    let time = SampleTime(wall: Date(), monotonic: ProcessInfo.processInfo.systemUptime)
    let original = snapshot()
    let privateName = "/Users/private-person/confidential-project"
    let process = ProcessSample(
      pid: 42, identity: nil, name: privateName, parentPID: nil,
      cpu: .init(availability: .permissionRequired, unit: .percent, time: time, source: "fixture"),
      memory: .init(availability: .permissionRequired, unit: .bytes, time: time, source: "fixture"),
      threads: nil, cpuHistory: [])
    let value = MonitoringSnapshot(
      time: time, cpu: original.cpu, memory: original.memory,
      history: original.history,
      processes: .init(
        value: [process], availability: .available,
        unit: .collection, time: time, source: "fixture"), hardware: original.hardware)
    let data = try LocalDiagnosticsReport.encode(value, active: false, includeProcessNames: false)
    XCTAssertFalse(String(decoding: data, as: UTF8.self).contains(privateName))
    let report = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let rows = try XCTUnwrap(report["processes"] as? [[String: Any]])
    XCTAssertEqual(rows.first?["cpuAvailability"] as? String, "permissionRequired")
    XCTAssertNil(rows.first?["cpuOneCorePercent"])
    XCTAssertEqual(report["processesAvailability"] as? String, "stale")
    XCTAssertTrue(
      String(
        decoding: try LocalDiagnosticsReport.encode(
          value, active: true,
          includeProcessNames: true), as: UTF8.self
      ).contains("confidential-project"))
  }
}
