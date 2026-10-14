import Foundation
import XCTest

@testable import ToolboxMonitoring

final class NetworkChangesTests: XCTestCase {
  private func socket(
    id: String = "descriptor", start: UInt64 = 10, state: String = "ESTABLISHED",
    verified: Bool = true
  ) -> NetworkSocket {
    NetworkSocket(
      id: id, pid: 42, processName: "App", transport: "TCP", endpoint: "[::1]:8080->[::1]:4000",
      state: state,
      identity: verified ? ProcessIdentity(pid: 42, startSeconds: start, startMicroseconds: 0) : nil
    )
  }
  private func reading(_ seconds: Double, _ sockets: [NetworkSocket], omitted: Int = 0)
    -> NetworkInspection
  {
    NetworkInspection(
      observedAt: Date(timeIntervalSince1970: seconds), sockets: sockets, omitted: omitted)
  }
  func testDescriptorOrderDoesNotCreateChangesButStateAndPIDReuseDo() {
    var tracker = NetworkChangeTracker()
    tracker.update(reading(100, [socket()]))
    tracker.update(reading(101, [socket(id: "different"), socket(id: "duplicate")]))
    XCTAssertTrue(tracker.events.isEmpty)
    tracker.update(reading(102, [socket(state: "CLOSE_WAIT")]))
    XCTAssertEqual(tracker.events.map(\.kind), ["State changed"])
    XCTAssertEqual(tracker.events.first?.previousState, "ESTABLISHED")
    tracker.update(reading(103, [socket(start: 11)]))
    XCTAssertEqual(
      Set(tracker.events.prefix(2).map(\.kind)), ["Newly observed", "No longer observed"])
  }
  func testPartialFailureUnverifiedAndLongGapResetCoverage() {
    var tracker = NetworkChangeTracker()
    tracker.update(reading(100, [socket(verified: false)]))
    XCTAssertEqual(tracker.unverifiedSockets, 1)
    tracker.update(reading(101, [socket()], omitted: 2))
    XCTAssertFalse(tracker.baselineEstablished)
    tracker.update(reading(102, [socket()]))
    XCTAssertTrue(tracker.events.isEmpty)
    tracker.invalidate()
    tracker.update(reading(103, []))
    XCTAssertTrue(tracker.events.isEmpty)
    tracker.update(reading(1000, [socket()]))
    XCTAssertTrue(tracker.events.isEmpty)
    tracker.update(reading(1001, []))
    XCTAssertEqual(tracker.events.map(\.kind), ["No longer observed"])
    tracker.clear()
    XCTAssertTrue(tracker.events.isEmpty)
    XCTAssertFalse(tracker.baselineEstablished)
  }
  func testChangeRetentionIsBoundedAndReportsOmissions() {
    var tracker = NetworkChangeTracker()
    tracker.update(reading(100, []))
    for i in 1...205 {
      tracker.update(reading(100 + Double(i), i.isMultiple(of: 2) ? [] : [socket()]))
    }
    XCTAssertEqual(tracker.events.count, 200)
    XCTAssertEqual(tracker.omittedEvents, 5)
  }
}
