import Foundation
import XCTest

@testable import ToolboxMonitoring

final class PhysicalSensorTests: XCTestCase {
  func testSMCIndependentBinaryFixturesAndUnitAdmission() throws {
    let cases: [(String, [UInt8], Double)] = [
      ("flt ", [0, 0, 72, 66], 50),
      ("sp78", [42, 128], 42.5), ("sp78", [255, 128], -0.5),
      ("fpe2", [39, 16], 2500), ("ui8 ", [2], 2), ("ui16", [9, 196], 2500),
    ]
    for (type, bytes, expected) in cases {
      XCTAssertEqual(
        try XCTUnwrap(SMCScalar.decode(type: type, bytes: bytes)), expected, accuracy: 0.0001)
    }
    XCTAssertNil(SMCScalar.decode(type: "flt ", bytes: [0, 0]))
    XCTAssertNil(SMCScalar.decode(type: "????", bytes: [0, 0, 0, 0]))
    XCTAssertFalse(SMCScalar.supports(type: "ui8 ", unit: .celsius))
    XCTAssertFalse(SMCScalar.supports(type: "sp78", unit: .watts))
    XCTAssertNil(SMCScalar.validated(.nan, unit: .celsius))
    XCTAssertNil(SMCScalar.validated(0, unit: .celsius))
    XCTAssertNil(SMCScalar.validated(151, unit: .celsius))
    XCTAssertNil(SMCScalar.validated(-1, unit: .rpm))
    XCTAssertEqual(SMCScalar.validated(0, unit: .rpm), 0)
    XCTAssertEqual(SMCScalar.validated(0, unit: .watts), 0)
  }

  func testM3DoesNotClassifyKnownGPUFabricKeyAsCPU() {
    let mapping = PhysicalSensors.mapping(for: "Apple M3 Pro")
    XCTAssertFalse(mapping.keys.contains { $0.0 == "Tf04" && $0.1 == "CPU sensors" })
  }

  func testUnknownAppleGenerationDoesNotBorrowAnOlderMapping() {
    XCTAssertTrue(PhysicalSensors.mapping(for: "Apple M30 Pro").keys.isEmpty)
    XCTAssertTrue(PhysicalSensors.mapping(for: "Unknown CPU").keys.isEmpty)
    XCTAssertEqual(PhysicalSensors.mapping(for: "Apple M3 Pro").family, "Apple M3")
  }

  func testSensorWindowRejectsMissingReusedWrongUnitAndOldGenerationValues() {
    func reading(
      _ value: Double?, unit: PhysicalSensorUnit = .rpm, state: MetricAvailability = .available
    ) -> PhysicalSensorReading {
      PhysicalSensorReading(
        key: "F0Ac", group: "Fans", unit: unit, value: value, availability: state, dataType: "flt ")
    }
    func point(_ time: Double, generation: Int = 2, sensors: [PhysicalSensorReading]?) -> TrendPoint
    {
      TrendPoint(
        time: SampleTime(wall: Date(timeIntervalSince1970: time), monotonic: time),
        generation: generation,
        ioSampled: true, cpuPercent: nil, memoryPercent: nil, networkInput: nil, networkOutput: nil,
        diskInput: nil, diskOutput: nil, physicalSensors: sensors)
    }
    let points = [
      point(1, generation: 1, sensors: [reading(8000)]),
      point(2, sensors: [reading(2500)]), point(3, sensors: nil),
      point(4, sensors: [reading(99, unit: .celsius)]),
      point(5, sensors: [reading(nil, state: .temporarilyUnavailable)]),
      point(6, sensors: [reading(0)]),
    ]
    let range = SensorWindow.physicalExtrema(points, sensor: reading(0))
    XCTAssertEqual(range.minimum, 0)
    XCTAssertEqual(range.maximum, 2500)
    XCTAssertEqual(range.validSamples, 2)
    XCTAssertEqual(
      SensorWindow.physicalExtrema(points, sensor: reading(0), since: 6).validSamples, 0)
    XCTAssertEqual(
      SensorWindow.physicalExtrema(points + [point(100, sensors: nil)], sensor: reading(0))
        .validSamples, 0)
  }

  func testUnavailableSensorsSurviveHardwareExportWithoutBecomingZero() throws {
    let time = SampleTime(wall: Date(timeIntervalSince1970: 100), monotonic: 100)
    let missing = PhysicalSensorReading(
      key: "TC0D", group: "CPU sensors", unit: .celsius, value: nil,
      availability: .temporarilyUnavailable, dataType: nil)
    let hardware = HardwareReading(
      disks: .init(availability: .unsupported, unit: .bytes, time: time, source: "test"),
      interfaces: .init(availability: .unsupported, unit: .bytes, time: time, source: "test"),
      capacity: .init(availability: .unsupported, unit: .bytes, time: time, source: "test"),
      battery: .init(availability: .unsupported, unit: .percent, time: time, source: "test"),
      thermal: .init(availability: .unsupported, unit: .state, time: time, source: "test"),
      swap: .init(availability: .unsupported, unit: .bytes, time: time, source: "test"),
      pressure: .init(availability: .unsupported, unit: .state, time: time, source: "test"),
      physicalSensors: .init(
        value: PhysicalSensorSnapshot(
          readings: [missing], reportedFanCount: nil,
          mappingFamily: "Intel", coverageLimited: true), availability: .available,
        unit: .collection, time: time, source: "AppleSMC"))
    let snapshot = MonitoringSnapshot(
      time: time, cpu: .init(availability: .loading, unit: .percent, time: time, source: "test"),
      memory: .init(availability: .loading, unit: .bytes, time: time, source: "test"), history: [],
      processes: .init(availability: .loading, unit: .collection, time: time, source: "test"),
      hardware: HardwareSnapshot(
        disks: .init(availability: .unsupported, unit: .bytesPerSecond, time: time, source: "test"),
        interfaces: .init(
          availability: .unsupported, unit: .bytesPerSecond, time: time, source: "test"),
        reading: hardware))
    let data = try HardwareReport.encode(
      HardwareProfile(observedAt: time.wall, fields: []), snapshot: snapshot, active: false,
      since: nil)
    let report = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let readings = try XCTUnwrap(
      (report["physicalSensors"] as? [String: Any])?["readings"] as? [[String: Any]])
    XCTAssertNil(readings[0]["value"])
    XCTAssertEqual(readings[0]["availability"] as? String, "temporarilyUnavailable")
    XCTAssertEqual(report["samplingActive"] as? Bool, false)
  }
}
