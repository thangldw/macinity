import Foundation
import XCTest

@testable import MacinityMonitoring

final class HardwareInspectorTests: XCTestCase {
  private func point(
    _ time: Double, generation: Int = 2, cpu: Double?, io: Bool = true, disk: Double? = nil
  ) -> TrendPoint {
    TrendPoint(
      time: SampleTime(wall: Date(timeIntervalSince1970: time), monotonic: time),
      generation: generation, ioSampled: io, cpuPercent: cpu, memoryPercent: nil,
      networkInput: nil, networkOutput: nil, diskInput: disk, diskOutput: nil)
  }

  func testRangeExcludesOldGenerationMissingInvalidAndRepeatedIO() {
    let points = [
      point(1, generation: 1, cpu: 99, disk: 999),
      point(2, cpu: nil), point(3, cpu: .nan), point(4, cpu: 101),
      point(5, cpu: 20, disk: 40), point(6, cpu: 0, io: false, disk: 40),
    ]
    let range = SensorWindow.extrema(points)
    XCTAssertEqual(range[0].minimum, 0)
    XCTAssertEqual(range[0].maximum, 20)
    XCTAssertEqual(range[0].validSamples, 2)
    XCTAssertEqual(range[2].validSamples, 1)
    XCTAssertEqual(range[2].minimum, 40)
    XCTAssertNil(range[1].minimum)
    XCTAssertEqual(SensorWindow.extrema(points, since: 6)[0].validSamples, 0)
  }

  func testRangeHonorsTimeWindowAndResetBoundary() {
    let points = [point(1, cpu: 99), point(90, cpu: 80), point(100, cpu: 10)]
    XCTAssertEqual(SensorWindow.extrema(points)[0].maximum, 80)
    XCTAssertEqual(SensorWindow.extrema(points, since: 90)[0].maximum, 10)
  }

  func testLiveProfileAndReportContainOnlyBoundedAllowlistedHardwareFields() throws {
    let profile = HardwareProfile.read()
    XCTAssertFalse(profile.fields.isEmpty)
    XCTAssertEqual(Set(profile.fields.map(\.id)).count, profile.fields.count)
    XCTAssertLessThanOrEqual(profile.fields.count, 93)
    let data = try HardwareReport.encode(profile, snapshot: nil, active: false, since: nil)
    let report = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(report["samplingActive"] as? Bool, false)
    let fields = try XCTUnwrap((report["profile"] as? [String: Any])?["fields"] as? [[String: Any]])
    for field in fields {
      let id = try XCTUnwrap(field["id"] as? String)
      XCTAssertFalse(id.localizedCaseInsensitiveContains("serial"))
      XCTAssertFalse(id.localizedCaseInsensitiveContains("hostname"))
      XCTAssertFalse(id.contains("path"))
    }
  }
}
