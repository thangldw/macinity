import AppKit
import XCTest

@testable import Macinity

@MainActor
final class WorkspaceUtilityTests: XCTestCase {
  func testRestoredGeometryStaysOnAvailableDisplay() {
    let saved = WorkspaceWindow(
      id: UUID(), bundleID: "test", title: "test", screenID: 1, x: 2, y: -1, width: 2, height: 0.01)
    let bounds = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
    let frame = WorkspacePresets.frame(saved, bounds: bounds)
    XCTAssertTrue(bounds.contains(frame))
    XCTAssertEqual(frame.width, 1920)
    XCTAssertEqual(frame.height, 150)
  }
  func testKeepAwakeInvalidPIDDoesNotCreateSession() {
    let controller = KeepAwakeController()
    controller.start(minutes: 15, pid: -1)
    XCTAssertEqual(controller.remaining, 0)
    XCTAssertNil(controller.process)
    controller.stop()
  }
}
