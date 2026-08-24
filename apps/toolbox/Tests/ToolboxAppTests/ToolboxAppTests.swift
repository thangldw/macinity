import XCTest

@testable import Toolbox

final class ToolboxAppTests: XCTestCase {
  func testToolboxNavigationHasExactlySixStableSections() {
    XCTAssertEqual(
      ToolboxSection.allCases.map(\.rawValue),
      ["home", "storage", "projects", "applications", "changes", "recovery"])
  }
}
