import XCTest

@testable import Macinity

final class MacinityURLActionTests: XCTestCase {
  private func parse(_ string: String) -> MacinityURLAction? {
    URL(string: string).flatMap(MacinityURLAction.parse)
  }

  func testKeepAwakeAcceptsOnlyAllowedDurations() {
    XCTAssertEqual(parse("macinity://keep-awake?minutes=30"), .keepAwake(minutes: 30))
    XCTAssertNil(parse("macinity://keep-awake?minutes=999"))
    XCTAssertNil(parse("macinity://keep-awake?minutes=abc"))
    XCTAssertNil(parse("macinity://keep-awake"))
  }

  func testStopAndOpen() {
    XCTAssertEqual(parse("macinity://keep-awake/stop"), .stopKeepAwake)
    XCTAssertEqual(parse("macinity://open/diagnostics"), .open(.diagnostics))
    XCTAssertNil(parse("macinity://open/unknown-section"))
    XCTAssertNil(parse("macinity://open/diagnostics/extra"))
  }

  func testRejectsOtherSchemesAndHosts() {
    XCTAssertNil(parse("https://keep-awake?minutes=15"))
    XCTAssertNil(parse("macinity://delete/everything"))
  }
}
