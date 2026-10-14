import Combine
import ToolboxMonitoring
import XCTest

@testable import Toolbox

final class ToolboxAppTests: XCTestCase {
  func testLegacyNavigationRawValuesRemainRestorable() {
    for legacy in ["home", "storage", "projects", "applications", "changes", "recovery"] {
      XCTAssertNotNil(ToolboxSection(rawValue: legacy))
    }
  }

  @MainActor
  func testRepeatedNavigationDoesNotRepublishUnchangedSelection() {
    let suite = "ToolboxRouteIdempotence." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("home", forKey: "toolbox.selectedSection")
    let coordinator = ToolboxCoordinator(defaults: defaults)
    var publications = 0
    let subscription = coordinator.objectWillChange.sink { publications += 1 }
    for _ in 0..<20 { coordinator.open(.section(.home)) }
    XCTAssertEqual(publications, 0)
    coordinator.open(.section(.processes))
    XCTAssertEqual(publications, 1)
    withExtendedLifetime(subscription) {}
  }

  @MainActor
  func testMonitoringRouteRestoresWithoutSelectingCleanup() {
    let key = "ToolboxNavigationTests." + UUID().uuidString
    let defaults = UserDefaults(suiteName: key)!
    defer { defaults.removePersistentDomain(forName: key) }
    defaults.set("processes", forKey: "toolbox.selectedSection")
    let coordinator = ToolboxCoordinator(defaults: defaults)
    XCTAssertEqual(coordinator.selectedSection, .processes)
    XCTAssertNil(coordinator.storageFocusPath)
    coordinator.open(.section(.storage))
    XCTAssertEqual(defaults.string(forKey: "toolbox.selectedSection"), "storage")
    XCTAssertNil(coordinator.storageFocusPath)
  }
  @MainActor
  func testProcessInspectionRouteRetainsStartIdentityAndLeavesStorageUnselected() {
    let suite = "OrvenInspectionRoute." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let coordinator = ToolboxCoordinator(defaults: defaults)
    let original = ProcessIdentity(pid: 41, startSeconds: 100, startMicroseconds: 2)
    let replacement = ProcessIdentity(pid: 41, startSeconds: 200, startMicroseconds: 3)
    coordinator.open(.inspectProcess(original))
    XCTAssertEqual(coordinator.selectedSection, .processes)
    XCTAssertEqual(coordinator.processFocus, original)
    XCTAssertNil(coordinator.storageFocusPath)
    coordinator.open(.inspectProcess(replacement))
    XCTAssertEqual(coordinator.processFocus, replacement)
    XCTAssertEqual(defaults.string(forKey: "toolbox.selectedSection"), "processes")
    XCTAssertNil(coordinator.storageFocusPath)
  }

}
