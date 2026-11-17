import XCTest

@testable import MacinityMonitoring

final class WeeklyReportTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_000_000)
  private let segment = UUID()

  private func record(
    minutesAgo: Double, cpu: Double?, level: Double? = nil, onBattery: Bool = false,
    segment: UUID? = nil, thermal: String? = nil
  ) -> HealthRecord {
    let at = now.addingTimeInterval(-minutesAgo * 60)
    var values = [
      HealthValue(
        id: "cpu", title: "CPU", unit: "%", value: cpu,
        availability: cpu == nil ? .temporarilyUnavailable : .available, source: "t", observedAt: at)
    ]
    if let level {
      for (id, v) in [
        ("battery.level", level), ("battery.charging", 0), ("battery.onBattery", onBattery ? 1 : 0),
      ] {
        values.append(
          HealthValue(
            id: id, title: id, unit: "", value: v, availability: .available, source: "t",
            observedAt: at))
      }
    }
    return HealthRecord(
      observedAt: at, uptime: 0, segment: segment ?? self.segment, values: values, thermal: thermal)
  }

  func testEmptyWindowReturnsNil() {
    XCTAssertNil(WeeklyReport.build(records: [], now: now))
    XCTAssertNil(WeeklyReport.build(records: [record(minutesAgo: 60 * 24 * 8, cpu: 10)], now: now))
  }

  func testStatsIgnoreMissingAndGapsAreNotBridged() throws {
    let other = UUID()
    let records = [
      record(minutesAgo: 10, cpu: 10), record(minutesAgo: 9, cpu: 20),
      record(minutesAgo: 8, cpu: nil), record(minutesAgo: 7, cpu: 90, thermal: "serious"),
      record(minutesAgo: 3, cpu: 30, segment: other), record(minutesAgo: 2, cpu: 40, segment: other),
    ]
    let summary = try XCTUnwrap(WeeklyReport.build(records: records, now: now))
    XCTAssertEqual(summary.observations, 6)
    XCTAssertEqual(summary.cpu?.count, 5)
    XCTAssertEqual(summary.cpu?.peak, 90)
    XCTAssertEqual(summary.cpu?.median, 30)
    XCTAssertEqual(summary.elevatedThermalObservations, 1)
    // 3 contiguous minute gaps in the first segment + 1 in the second; the 4-minute jump is a gap.
    XCTAssertEqual(summary.continuousMinutes, 4)
  }

  func testBatteryDischargeAndLowestLevel() throws {
    let records = [
      record(minutesAgo: 3, cpu: 1, level: 80, onBattery: true),
      record(minutesAgo: 2, cpu: 1, level: 78, onBattery: true),
      record(minutesAgo: 1, cpu: 1, level: 75, onBattery: true),
    ]
    let summary = try XCTUnwrap(WeeklyReport.build(records: records, now: now))
    XCTAssertEqual(summary.dischargeDropPercent, 5)
    XCTAssertEqual(summary.dischargeMinutes, 2)
    XCTAssertEqual(summary.lowestBatteryPercent, 75)
  }
}
