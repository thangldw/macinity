import Foundation
import ToolboxMonitoring
import XCTest

@testable import Toolbox

@MainActor
final class MonitoringPreferencesTests: XCTestCase {
  func testPausedDisplayIsStaleAndBackgroundCadencePreservesFreshness() {
    let time = SampleTime(wall: Date(), monotonic: 100)
    let sample = MetricSample(
      value: 25.0, availability: .available, unit: .percent, time: time, source: "fixture")
    XCTAssertEqual(
      MonitoringDisplayState(paused: true).availability(of: sample, at: 101, maximumAge: 3), .stale)
    let background = MonitoringDisplayState(minimumMaximumAge: 15)
    XCTAssertEqual(background.availability(of: sample, at: 105, maximumAge: 3), .available)
    XCTAssertEqual(background.availability(of: sample, at: 116, maximumAge: 3), .stale)
    let denied = MetricSample<Double>(
      availability: .permissionRequired, unit: .percent, time: time, source: "fixture")
    XCTAssertEqual(
      MonitoringDisplayState(paused: true).availability(of: denied, at: 101, maximumAge: 3),
      .permissionRequired)
  }

  func testMenuBarDefaultsOffPersistsAndUnknownIndicatorMigratesSafely() async {
    let suite = "ToolboxMonitoringPreferences." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let first = MonitoringViewModel(defaults: defaults)
    XCTAssertFalse(first.menuBarEnabled)
    XCTAssertEqual(first.menuBarIndicator, .cpu)
    first.menuBarEnabled = true
    first.menuBarIndicator = .network
    await first.stop()
    let second = MonitoringViewModel(defaults: defaults)
    XCTAssertTrue(second.menuBarEnabled)
    XCTAssertEqual(second.menuBarIndicator, .network)
    for _ in 0..<50 {
      second.menuBarEnabled = false
      second.menuBarEnabled = true
    }
    second.menuBarEnabled = false
    await second.stop()
    defaults.set("future-value", forKey: "toolbox.monitoring.menuBar.indicator")
    let migrated = MonitoringViewModel(defaults: defaults)
    XCTAssertFalse(migrated.menuBarEnabled)
    XCTAssertEqual(migrated.menuBarIndicator, .cpu)
    XCTAssertNil(defaults.object(forKey: "toolbox.onboarding.completed.v2"))
    await migrated.stop()
  }
}
