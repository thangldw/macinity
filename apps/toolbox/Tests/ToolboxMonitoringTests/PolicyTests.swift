import XCTest

@testable import ToolboxMonitoring

final class PolicyTests: XCTestCase {
  func testInactiveAndClosedWindowsRequireOptInSamplingAndSleepAlwaysPauses() {
    for visible in [true, false] {
      for menu in [true, false] {
        XCTAssertEqual(
          SamplingPolicy.mode(
            appActive: false, mainWindowVisible: visible, sleeping: false, menuBarEnabled: menu),
          menu ? .menuBar : .paused)
        XCTAssertEqual(
          SamplingPolicy.mode(
            appActive: true, mainWindowVisible: visible, sleeping: true, menuBarEnabled: menu),
          .paused)
      }
    }
    XCTAssertEqual(
      SamplingPolicy.mode(
        appActive: true, mainWindowVisible: false, sleeping: false, menuBarEnabled: true), .menuBar)
    XCTAssertEqual(
      SamplingPolicy.mode(
        appActive: true, mainWindowVisible: false, sleeping: false, menuBarEnabled: false), .paused)
    XCTAssertEqual(
      SamplingPolicy.mode(
        appActive: true, mainWindowVisible: true, sleeping: false, menuBarEnabled: false), .active)
  }
}
