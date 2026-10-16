import Foundation
import XCTest

@testable import MacinityMonitoring

final class NetworkInspectionTests: XCTestCase {
  func testSocketBoundariesPreserveIPv6AndNeverInheritState() {
    let result = NetworkInspection.parse(
      """
      p42
      cApp With Spaces
      f8
      tIPv6
      PTCP
      n[::1]:8080->[::1]:49152
      TST=ESTABLISHED
      f9
      PUDP
      n*:5353
      pbad
      f1
      PTCP
      n*:22
      p43
      cOther
      f1
      PTCP
      n*:80
      TST=LISTEN
      """)
    XCTAssertEqual(result.sockets.map(\.pid), [42, 42, 43])
    XCTAssertEqual(result.sockets.map(\.state), ["ESTABLISHED", "Unknown", "LISTEN"])
    XCTAssertEqual(result.sockets.first?.endpoint, "[::1]:8080->[::1]:49152")
    XCTAssertEqual(result.sockets.first?.processName, "App With Spaces")
    XCTAssertTrue(result.sockets.allSatisfy { $0.identity == nil })
  }
  func testCapReportsOmissionsInsteadOfClaimingCompleteCoverage() {
    let body = (0..<1030).map { "f\($0)\nPTCP\nn*:8080\n" }.joined()
    let result = NetworkInspection.parse("p42\ncApp\n" + body)
    XCTAssertEqual(result.sockets.count, 1024)
    XCTAssertEqual(result.omitted, 6)
    XCTAssertEqual(Set(result.sockets.map(\.id)).count, 1024)
  }
  func testPriorityReductionOnOwnedChildRejectsMismatchedIdentity() throws {
    let child = Process()
    child.executableURL = URL(fileURLWithPath: "/bin/sleep")
    child.arguments = ["30"]
    try child.run()
    defer {
      if child.isRunning { child.terminate() }
      child.waitUntilExit()
    }
    let identity = try SystemProcessAccess().metadata(pid: child.processIdentifier).identity
    let wrong = ProcessIdentity(
      pid: identity.pid, startSeconds: identity.startSeconds + 1,
      startMicroseconds: identity.startMicroseconds)
    XCTAssertThrowsError(try ProcessPriority.lower(wrong))
    XCTAssertGreaterThanOrEqual(try ProcessPriority.lower(identity), 10)
    XCTAssertGreaterThanOrEqual(try ProcessPriority.lower(identity), 10)
    XCTAssertThrowsError(
      try ProcessPriority.lower(.init(pid: 1, startSeconds: 1, startMicroseconds: 0)))
  }
}
