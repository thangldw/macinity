import Foundation
import IOKit.pwr_mgt
import XCTest

@testable import ToolboxMonitoring

final class SleepInspectionTests: XCTestCase {
  private struct Access: ProcessAccess {
    let process: ProcessMetadata
    func metadata(pid: Int32) throws -> ProcessMetadata {
      guard pid == process.identity.pid else { throw ProcessReadError.exited }
      return process
    }
    func counters(pid: Int32) throws -> ProcessCounters { throw ProcessReadError.unavailable }
  }

  private func metadata(start: UInt64) -> ProcessMetadata {
    ProcessMetadata(
      identity: ProcessIdentity(pid: 42, startSeconds: start, startMicroseconds: 0),
      name: "Example", parentPID: 1)
  }

  private var active: [String: Any] {
    [
      kIOPMAssertionLevelKey: NSNumber(value: kIOPMAssertionLevelOn),
      kIOPMAssertionTypeKey: "PreventUserIdleSystemSleep",
      kIOPMAssertionNameKey: "Work in progress",
    ]
  }

  func testOwnershipRequiresSameStartIdentityAroundAssertionRead() {
    let initial = metadata(start: 100)
    for (start, verified) in [(UInt64(100), true), (UInt64(200), false)] {
      let report = SleepAssertionParser.parse(
        [42: [active]], before: [42: initial], access: Access(process: metadata(start: start)))
      XCTAssertEqual(report.requests.count, 1)
      XCTAssertEqual(report.requests.first?.owner != nil, verified)
      XCTAssertEqual(report.requests.first?.type, "PreventUserIdleSystemSleep")
    }
    let unknown = SleepAssertionParser.parse(
      [42: [active]], before: [:], access: Access(process: initial))
    XCTAssertNil(unknown.requests.first?.owner)
  }

  func testInactiveMalformedAndBoundedReportsRemainDistinct() {
    var inactive = active
    inactive[kIOPMAssertionLevelKey] = NSNumber(value: kIOPMAssertionLevelOff)
    var malformed = active
    malformed[kIOPMAssertionLevelKey] = NSNumber(value: 1.5)
    let access = Access(process: metadata(start: 100))
    let report = SleepAssertionParser.parse(
      [42: [inactive, malformed, active], NSNumber(value: 42.5): [active]], before: [:],
      access: access)
    XCTAssertEqual(report.requests.count, 1)
    XCTAssertEqual(report.omittedCount, 2)
    let bounded = SleepAssertionParser.parse(
      [42: Array(repeating: active, count: 520)], before: [:], access: access)
    XCTAssertEqual(bounded.requests.count, 512)
    XCTAssertEqual(bounded.omittedCount, 8)
    XCTAssertEqual(Set(bounded.requests.map(\.id)).count, 512)
    let empty = SleepAssertionParser.parse([42: [inactive]], before: [:], access: access)
    XCTAssertTrue(empty.requests.isEmpty)
    XCTAssertEqual(empty.omittedCount, 0)
  }
}
