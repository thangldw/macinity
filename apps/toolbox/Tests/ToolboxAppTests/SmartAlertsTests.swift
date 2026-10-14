import Foundation
import XCTest

@testable import Toolbox
@testable import ToolboxMonitoring

final class SmartAlertsTests: XCTestCase {
  func testAlertRequiresObservedRecoveryHysteresisAndCooldown() {
    var gate = AlertGate()
    XCTAssertEqual(gate.evaluate(findings: ["cpu"], recoveries: [], now: 0), ["cpu"])
    XCTAssertTrue(gate.evaluate(findings: ["cpu"], recoveries: [], now: 1).isEmpty)
    for now in stride(from: 10.0, through: 40.0, by: 10) {
      _ = gate.evaluate(findings: [], recoveries: ["cpu"], now: now)
    }
    XCTAssertTrue(gate.evaluate(findings: ["cpu"], recoveries: [], now: 41).isEmpty)
    XCTAssertEqual(gate.evaluate(findings: ["cpu"], recoveries: [], now: 901), ["cpu"])
  }
  func testUnknownEvidenceAndPauseCannotEstablishContinuousRecoveryAndSnoozeSuppresses() {
    var gate = AlertGate()
    _ = gate.evaluate(findings: ["thermal"], recoveries: [], now: 0)
    _ = gate.evaluate(findings: [], recoveries: ["thermal"], now: 1)
    _ = gate.evaluate(findings: [], recoveries: ["thermal"], now: 1000)
    XCTAssertTrue(gate.evaluate(findings: ["thermal"], recoveries: [], now: 1001).isEmpty)
    gate.snoozedUntil = Date(timeIntervalSince1970: 2000)
    XCTAssertTrue(
      gate.evaluate(
        findings: ["memory"], recoveries: [], now: 1500, wall: Date(timeIntervalSince1970: 1500)
      ).isEmpty)
    XCTAssertEqual(
      gate.evaluate(
        findings: ["memory"], recoveries: [], now: 1501, wall: Date(timeIntervalSince1970: 2000)),
      ["memory"])
  }
  func testCSVPreservesMissingStatusAndEscapesQuotesWithoutLocalizedNumbers() {
    let date = Date(timeIntervalSince1970: 0)
    let record = HealthRecord(
      observedAt: date, uptime: 0, segment: UUID(),
      values: [
        HealthValue(
          id: "smc:Te05", title: "CPU", unit: "°C", value: nil, availability: .unsupported,
          source: "SMC,\"mapped\"", observedAt: date)
      ])
    let csv = HealthSessionExport.csv([record])
    XCTAssertTrue(csv.contains("\"°C\",\"\",\"unsupported\",\"SMC,\"\"mapped\"\"\""))
    XCTAssertTrue(csv.hasSuffix("\n"))
    XCTAssertTrue(csv.contains("1970-01-01T00:00:00Z"))
  }
}
