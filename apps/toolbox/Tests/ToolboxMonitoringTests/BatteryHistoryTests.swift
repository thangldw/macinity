import Foundation
import XCTest

@testable import ToolboxMonitoring

final class BatteryHistoryTests: XCTestCase {
  func testSystemHealthIsSeparateFromRawCapacityAndRejectsInvalidValues() throws {
    func report(_ capacity: String) throws -> BatteryHealthReport {
      try BatteryHealthReport(
        data: Data(
          """
          {"SPPowerDataType":[{"_name":"spbattery_information","sppower_battery_health_info":{
          "sppower_battery_health":"Good","sppower_battery_health_maximum_capacity":\(capacity)}}]}
          """.utf8))
    }
    XCTAssertEqual(try report("\"86%\"").maximumCapacity, 86)
    XCTAssertEqual(try report("86").condition, "Good")
    XCTAssertNil(try report("true").maximumCapacity)
    XCTAssertNil(try report("101").maximumCapacity)
    XCTAssertNil(try report("\"unavailable\"").maximumCapacity)
    XCTAssertThrowsError(try BatteryHealthReport(data: Data("{}".utf8)))
  }
  func testHistoryPersistsFullSensorSetPlusBatteryFields() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("history.json")
    let now = Date()
    let definitions =
      (0..<36).map { "metric.\($0)" } + ["battery.level", "battery.charging", "battery.onBattery"]
    let values = definitions.map {
      HealthValue(
        id: $0, title: $0, unit: "%", value: 1, availability: .available,
        source: "test", observedAt: now)
    }
    let record = HealthRecord(observedAt: now, uptime: 100, segment: UUID(), values: values)
    _ = try await HealthHistoryStore(url: url).append(record, retentionHours: 24)
    let archive = try await HealthHistoryStore(url: url).read(now: now, retentionHours: 24)
    XCTAssertEqual(archive.records.first?.values, values)
  }
  func testIntervalsSeparateModesAndNeverBridgeMissingOrSleepSamples() {
    let segment = UUID()
    func record(_ second: Double, _ mode: Int?, segment: UUID = segment) -> HealthRecord {
      let time = Date(timeIntervalSince1970: second)
      let values =
        mode.map { mode in
          [
            ("battery.level", 70.0 + second / 60), ("battery.charging", mode == 1 ? 1.0 : 0.0),
            ("battery.onBattery", mode == 2 ? 1.0 : 0.0),
          ].map {
            HealthValue(
              id: $0.0, title: $0.0, unit: "", value: $0.1,
              availability: .available, source: "test", observedAt: time)
          }
        } ?? []
      return HealthRecord(observedAt: time, uptime: second, segment: segment, values: values)
    }
    let intervals = BatteryHistoryAnalysis.intervals([
      record(0, 1), record(60, 1), record(120, 2), record(180, nil), record(240, 2),
      record(360, 2), record(420, 2, segment: UUID()), record(480, 0),
    ])
    XCTAssertEqual(intervals.count, 6)
    XCTAssertEqual(intervals[0].state, "Charging")
    XCTAssertEqual(intervals[0].end.timeIntervalSince1970, 60)
    XCTAssertEqual(intervals[1].start, intervals[1].end)
    XCTAssertEqual(intervals.last?.state, "External power (not charging)")
    XCTAssertTrue(BatteryHistoryAnalysis.intervals([record(0, nil)]).isEmpty)
  }
}
