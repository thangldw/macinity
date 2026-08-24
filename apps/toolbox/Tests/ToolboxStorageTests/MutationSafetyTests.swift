import Foundation
import XCTest

@testable import ToolboxStorage

final class MutationSafetyTests: XCTestCase {
  func testCleanerRejectsSymlinkEscapingApprovedRoot() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let allowed = root.appendingPathComponent("home")
    let outside = root.appendingPathComponent("outside")
    try FileManager.default.createDirectory(at: allowed, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    try Data("protected".utf8).write(to: outside.appendingPathComponent("item"))
    try FileManager.default.createSymbolicLink(
      at: allowed.appendingPathComponent("escape"), withDestinationURL: outside)
    let service = CleanerService(homeURL: allowed, removalMethod: .permanentForTesting)
    let target = CleaningTarget(
      id: "escape", name: "Escape", detail: "", relativePath: "escape/item",
      symbol: "folder", isSelectedByDefault: false)

    XCTAssertThrowsError(try service.validatedURL(for: target))
  }

  func testDeveloperCommandRejectsExecutableOutsideFixedPaths() {
    let action = DeveloperCleanupAction(
      tool: .simulator, executable: URL(fileURLWithPath: "/tmp/xcrun"),
      arguments: ["simctl", "delete", "unavailable"], detail: "", estimatedBytes: 0,
      confidence: .safe)

    let result = DeveloperCleanupService().run(action)

    XCTAssertFalse(result.succeeded)
  }

  func testLegacyScheduledAgentIsRetainedWhenToolboxBootstrapFails() async throws {
    let manager = FileManager.default
    let home = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? manager.removeItem(at: home) }
    let agents = home.appendingPathComponent("Library/LaunchAgents")
    let app = home.appendingPathComponent("Toolbox.app")
    try manager.createDirectory(at: agents, withIntermediateDirectories: true)
    try manager.createDirectory(at: app, withIntermediateDirectories: true)
    let legacy = agents.appendingPathComponent("com.thang.diskora.scheduled-scan.plist")
    try Data("legacy".utf8).write(to: legacy)
    let service = ScheduledScanService(
      homeURL: home, bundleURL: app, launchctl: FailingLaunchctlRunner(),
      notifications: GrantedNotificationAuthorizer())

    do {
      try await service.replaceLegacyLaunchAgent(intervalHours: 24)
      XCTFail("Expected bootstrap failure")
    } catch {
      XCTAssertTrue(manager.fileExists(atPath: legacy.path))
      XCTAssertFalse(
        manager.fileExists(
          atPath: agents.appendingPathComponent("com.thang.toolbox.scheduled-scan.plist").path))
    }
  }
}

private struct FailingLaunchctlRunner: LaunchctlRunning {
  func run(_ arguments: [String]) throws {
    if arguments.first == "bootstrap" { throw CocoaError(.executableNotLoadable) }
  }
}

private struct GrantedNotificationAuthorizer: NotificationAuthorizing {
  func requestAuthorization() async throws -> Bool { true }
}
