import Foundation
import XCTest

@testable import ToolboxChanges

@MainActor
final class InstallTraceCoordinatorTests: XCTestCase {
  func testAcceptsOnlySupportedInstallerTypes() throws {
    let coordinator = InstallTraceCoordinator.previewOnly()

    XCTAssertNoThrow(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.dmg")))
    XCTAssertNoThrow(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.pkg")))
    XCTAssertNoThrow(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.app")))
    XCTAssertThrowsError(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.zip")))
  }

  func testInterruptedTraceLoadsAsReducedCoverage() throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = SnapshotStore(directory: directory)
    try store.saveActiveSnapshot(SystemSnapshot(name: "before", items: []))

    let state = InstallTraceCoordinator(store: store).recoveryState

    XCTAssertEqual(state, .interrupted(reducedCoverage: true))
  }

  func testStartPersistsBaselineBeforeTraceBecomesActive() async throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = SnapshotStore(directory: directory)
    let scanner = SystemSnapshotScanner(
      configuration: SnapshotConfiguration(locations: [], maximumItems: 10))
    let coordinator = InstallTraceCoordinator(scanner: scanner, store: store)
    let metadata = try coordinator.accept(url: URL(fileURLWithPath: "/tmp/Demo.pkg"))

    try await coordinator.start(metadata: metadata)

    XCTAssertNotNil(store.loadActiveSnapshot())
    XCTAssertEqual(coordinator.activeMetadata, metadata)
    try coordinator.cancel()
  }

  private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }
}
