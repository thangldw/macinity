import AppKit
import Combine
import MacinityMonitoring
import SwiftUI
import XCTest

@testable import Macinity

final class MacinityAppTests: XCTestCase {
  @MainActor
  func testDeveloperWorkspaceFitsMinimumWindowWithoutVerticalOverflow() {
    let suite = "MacinityWorkspaceLayout." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("developerTools", forKey: "toolbox.selectedSection")
    let coordinator = MacinityCoordinator(defaults: defaults)
    let view = NSHostingView(rootView: MacinityShellView(coordinator: coordinator))
    view.frame = NSRect(x: 0, y: 0, width: 960, height: 640)
    view.layoutSubtreeIfNeeded()
    XCTAssertLessThanOrEqual(view.fittingSize.height, 640)
    XCTAssertLessThanOrEqual(view.fittingSize.width, 960)
  }

  @MainActor
  func testAllWorkspaceRoutesFitMinimumWindow() {
    let suite = "MacinityRouteLayout." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    for section in MacinitySection.allCases {
      defaults.set(section.rawValue, forKey: "toolbox.selectedSection")
      let coordinator = MacinityCoordinator(defaults: defaults)
      let view = NSHostingView(rootView: MacinityShellView(coordinator: coordinator))
      view.frame = NSRect(x: 0, y: 0, width: 960, height: 640)
      view.layoutSubtreeIfNeeded()
      XCTAssertLessThanOrEqual(view.fittingSize.height, 640, section.rawValue)
      XCTAssertLessThanOrEqual(view.fittingSize.width, 960, section.rawValue)
    }
  }

  func testDeveloperInventoryDoesNotExecuteOrCollapseDistinctInstallations() {
    let paths: Set<String> = [
      "/opt/homebrew/bin/python3", "/usr/bin/python3", "/test/.cargo/bin/cargo",
      "/test/.local/bin/node",
    ]
    let entries = DeveloperToolInventory.scan(
      home: "/test", executable: { paths.contains($0) },
      directory: { $0 == "/test/.local/bin/node" })
    XCTAssertEqual(Set(entries.map(\.path)), paths.subtracting(["/test/.local/bin/node"]))
    XCTAssertEqual(entries.filter { $0.name == "python3" }.count, 2)
    XCTAssertEqual(Set(entries.map(\.id)).count, entries.count)
  }

  func testDeveloperInventoryMissingToolsAreNotReportedAsInstalled() {
    XCTAssertTrue(DeveloperToolInventory.scan(executable: { _ in false }).isEmpty)
  }

  func testLegacyNavigationRawValuesRemainRestorable() {
    for legacy in ["home", "storage", "projects", "applications", "changes", "recovery"] {
      XCTAssertNotNil(MacinitySection(rawValue: legacy))
    }
  }

  func testEveryRestorableRouteHasExactlyOneWorkspaceDestination() {
    let routes = MacinityArea.allCases.flatMap(\.sections)
    XCTAssertEqual(Set(routes), Set(MacinitySection.allCases))
    XCTAssertEqual(routes.count, Set(routes).count)
    for area in MacinityArea.allCases {
      XCTAssertFalse(area.sections.isEmpty)
      XCTAssertTrue(area.sections.allSatisfy { $0.area == area })
    }
  }

  @MainActor
  func testWorkspaceSwitchRestoresPageWithoutSelectingMutationTargets() {
    let suite = "MacinityWorkspaceNavigation." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("recovery", forKey: "toolbox.selectedSection")
    let coordinator = MacinityCoordinator(defaults: defaults)
    coordinator.openArea(.software)
    XCTAssertEqual(coordinator.selectedSection, .applications)
    coordinator.open(.section(.projects))
    coordinator.openArea(.files)
    XCTAssertEqual(coordinator.selectedSection, .recovery)
    coordinator.openArea(.software)
    XCTAssertEqual(coordinator.selectedSection, .projects)
    coordinator.openArea(.software)
    XCTAssertEqual(coordinator.selectedSection, .projects)
    XCTAssertNil(coordinator.storageFocusPath)
    XCTAssertNil(coordinator.processFocus)
    XCTAssertEqual(defaults.string(forKey: "toolbox.selectedSection"), "projects")
  }

  func testToolSearchIsBoundedAndMatchesLocalizedDestinationNames() {
    XCTAssertEqual(Set(MacinitySection.matching(" \n ")), Set(MacinitySection.allCases))
    XCTAssertTrue(MacinitySection.matching("nonexistent-tool-8429").isEmpty)
    XCTAssertTrue(MacinitySection.matching(MacinitySection.sensors.title).contains(.sensors))
    XCTAssertEqual(
      Set(MacinitySection.matching(MacinityArea.network.title)), Set(MacinityArea.network.sections))
  }

  @MainActor
  func testRepeatedNavigationDoesNotRepublishUnchangedSelection() {
    let suite = "MacinityRouteIdempotence." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set("home", forKey: "toolbox.selectedSection")
    let coordinator = MacinityCoordinator(defaults: defaults)
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
    let key = "MacinityNavigationTests." + UUID().uuidString
    let defaults = UserDefaults(suiteName: key)!
    defer { defaults.removePersistentDomain(forName: key) }
    defaults.set("processes", forKey: "toolbox.selectedSection")
    let coordinator = MacinityCoordinator(defaults: defaults)
    XCTAssertEqual(coordinator.selectedSection, .processes)
    XCTAssertNil(coordinator.storageFocusPath)
    coordinator.open(.section(.storage))
    XCTAssertEqual(defaults.string(forKey: "toolbox.selectedSection"), "storage")
    XCTAssertNil(coordinator.storageFocusPath)
  }
  @MainActor
  func testProcessInspectionRouteRetainsStartIdentityAndLeavesStorageUnselected() {
    let suite = "MacinityInspectionRoute." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let coordinator = MacinityCoordinator(defaults: defaults)
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
