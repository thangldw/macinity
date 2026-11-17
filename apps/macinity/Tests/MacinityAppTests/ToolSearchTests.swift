import XCTest

@testable import Macinity

final class ToolSearchTests: XCTestCase {
  func testEmptyQueryListsEverySectionOnceAndClipboardIsFindable() {
    XCTAssertEqual(MacinitySection.matching("").count, MacinitySection.allCases.count)
    XCTAssertTrue(MacinitySection.matching("clipboard").contains(.clipboard))
  }

  func testEverySectionBelongsToExactlyOneArea() {
    for section in MacinitySection.allCases {
      XCTAssertEqual(MacinityArea.allCases.filter { $0.sections.contains(section) }.count, 1)
    }
  }
}
