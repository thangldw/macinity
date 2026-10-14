import Foundation
import XCTest

@testable import ToolboxMonitoring

final class HealthHistoryTests: XCTestCase {
  private func record(_ index: Int, value: Double = 20, segment: UUID) -> HealthRecord {
    let date = Date(timeIntervalSince1970: 1_800_000_000 + Double(index) * 60)
    return HealthRecord(
      observedAt: date, uptime: Double(index) * 60, segment: segment,
      values: [
        HealthValue(
          id: "cpu", title: "System CPU", unit: "%", value: value,
          availability: .available, source: "host_statistics", observedAt: date)
      ])
  }
  func testStoreRoundTripCadenceRetentionAndBaselineComparison() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("history.json")
    let store = HealthHistoryStore(url: url)
    let segment = UUID()
    for i in 0..<30 { _ = try await store.append(record(i, segment: segment), retentionHours: 24) }
    let baseDate = record(29, segment: segment).observedAt
    _ = try await store.captureBaseline(now: baseDate, retentionHours: 24)
    for i in 30..<40 {
      _ = try await store.append(record(i, value: 50, segment: segment), retentionHours: 24)
    }
    let reloaded = try await HealthHistoryStore(url: url).read(
      now: record(39, segment: segment).observedAt, retentionHours: 24)
    XCTAssertEqual(reloaded.records.count, 40)
    let comparison = try XCTUnwrap(HealthAnalysis.comparisons(reloaded).first)
    XCTAssertEqual(comparison.baselineMedian, 20)
    XCTAssertEqual(comparison.currentMedian, 50)
    XCTAssertEqual(comparison.baselineCount, 30)
    XCTAssertEqual(comparison.currentCount, 10)
    let duplicate = try await store.append(
      record(39, value: 99, segment: segment), retentionHours: 24)
    XCTAssertEqual(duplicate.records.count, 40)
    let fastRestart = HealthRecord(
      observedAt: record(39, segment: segment).observedAt.addingTimeInterval(1),
      uptime: 1, segment: UUID(), values: [])
    let unchanged = try await store.append(fastRestart, retentionHours: 24)
    XCTAssertEqual(
      unchanged.records.count, 40, "Restarting must not bypass the persisted one-minute cadence")
    let pruned = try await store.setRetention(now: baseDate.addingTimeInterval(90_000), hours: 24)
    XCTAssertTrue(pruned.records.isEmpty)
    XCTAssertNil(pruned.baseline)
  }
  func testCorruptAndUnknownSchemaPreservedWithoutOverwrite() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("history.json")
    for bytes in [
      Data("broken".utf8), Data("{\"schemaVersion\":99,\"records\":[]}".utf8),
      Data(repeating: 0, count: 24 * 1024 * 1024 + 1),
    ] {
      try bytes.write(to: url)
      let store = HealthHistoryStore(url: url)
      do {
        _ = try await store.append(record(1, segment: UUID()), retentionHours: 168)
        XCTFail("Corrupt data must block writes")
      } catch {}
      XCTAssertEqual(try Data(contentsOf: url), bytes)
    }
  }
  func testBaselineCannotCountCachedOrMissingObservationsAsIndependentSamples() {
    let segment = UUID()
    let date = Date(timeIntervalSince1970: 1_800_000_000)
    let cached = HealthValue(
      id: "smc:Te05", title: "CPU sensors", unit: "°C", value: 42,
      availability: .available, source: "AppleSMC", observedAt: date)
    var archive = HealthArchive()
    archive.baseline = HealthBaseline(
      capturedAt: date,
      records: (0..<30).map {
        HealthRecord(
          observedAt: date.addingTimeInterval(Double($0)), uptime: Double($0), segment: segment,
          values: [cached])
      })
    archive.records = (1...15).map {
      HealthRecord(
        observedAt: date.addingTimeInterval(Double($0) * 60), uptime: Double($0) * 60,
        segment: segment,
        values: [
          HealthValue(
            id: "smc:Te05", title: "CPU sensors", unit: "°C",
            value: nil, availability: .temporarilyUnavailable, source: "AppleSMC",
            observedAt: date.addingTimeInterval(Double($0) * 60))
        ])
    }
    XCTAssertTrue(HealthAnalysis.comparisons(archive).isEmpty)
  }
  func testSerializedByteBudgetEvictsOlderRecordsAndReportsTheLoss() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let url = root.appendingPathComponent("history.json")
    let segment = UUID()
    let date = Date(timeIntervalSince1970: 1_800_000_000)
    let fields = (0..<36).map {
      HealthValue(
        id: "metric-\($0)", title: String(repeating: "t", count: 90), unit: "%",
        value: 20, availability: .available, source: String(repeating: "s", count: 140),
        observedAt: date)
    }
    func point(_ i: Int) -> HealthRecord {
      HealthRecord(
        observedAt: date.addingTimeInterval(Double(i) * 60), uptime: 1,
        segment: segment, values: fields)
    }
    let encoder = JSONEncoder()
    let limit = 24 * 1024 * 1024
    let count = min(10_000, limit / (try encoder.encode(point(0))).count)
    var archive = HealthArchive()
    archive.records = (0..<count).map(point)
    var data = try encoder.encode(archive)
    while data.count > limit {
      archive.records.removeLast()
      data = try encoder.encode(archive)
    }
    try data.write(to: url)
    let last = try XCTUnwrap(archive.records.last)
    let store = HealthHistoryStore(url: url)
    let next = HealthRecord(
      observedAt: last.observedAt.addingTimeInterval(60), uptime: 1,
      segment: UUID(), values: fields)
    let saved = try await store.append(next, retentionHours: 168)
    XCTAssertGreaterThan(saved.omittedRecords, 0)
    XCTAssertLessThan(saved.records.count, archive.records.count + 1)
    XCTAssertEqual(saved.records.last?.id, next.id)
    XCTAssertLessThanOrEqual(try Data(contentsOf: url).count, limit)
  }

}
