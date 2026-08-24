import Foundation
import XCTest

@testable import ToolboxStorage

final class ToolboxStorageTests: XCTestCase {
  func testCleanerBlocksPathsOutsideHome() throws {
    let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let service = CleanerService(homeURL: home, removalMethod: .permanentForTesting)
    let target = CleaningTarget(
      id: "escape", name: "Escape", detail: "", relativePath: "../../etc", symbol: "folder",
      isSelectedByDefault: false)

    XCTAssertThrowsError(try service.url(for: target)) { error in
      XCTAssertTrue(error is CleanerError)
    }
  }

  func testDefaultTargetsNeverSelectDangerousItems() {
    XCTAssertFalse(
      CleaningTarget.defaults.contains {
        $0.isSelectedByDefault && $0.confidence == .dangerous
      })
  }

  func testLeftoverMatchingDoesNotUseSubstringMatches() {
    XCTAssertTrue(
      ApplicationScanner.matchesLeftoverName("com.example.note", applicationName: "Note"))
    XCTAssertFalse(
      ApplicationScanner.matchesLeftoverName(
        "com.example.noteworthy", applicationName: "Note"))
  }

  func testUndoRestoresWithoutOverwriting() throws {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? manager.removeItem(at: root) }
    let original = root.appendingPathComponent("Original/sample.txt")
    let trashed = root.appendingPathComponent("Trash/sample.txt")
    try manager.createDirectory(
      at: trashed.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("recoverable".utf8).write(to: trashed)

    let store = HistoryStore(
      directory: root.appendingPathComponent("Store"),
      recoveryAdapter: UnifiedRecoveryAdapter(
        allowedTrashRoots: [trashed.deletingLastPathComponent()],
        allowedDestinationRoots: [original.deletingLastPathComponent()]))
    store.record(
      action: "Test", paths: [original.path], bytes: 11, recoverable: true,
      note: "Undo test",
      moves: [TrashMoveRecord(originalPath: original.path, trashPath: trashed.path, bytes: 11)])
    let entry = try XCTUnwrap(store.load().first)

    let result = store.restore(entryID: entry.id)

    XCTAssertEqual(result.restoredCount, 1)
    XCTAssertTrue(result.errors.isEmpty)
    XCTAssertTrue(manager.fileExists(atPath: original.path))
    XCTAssertFalse(manager.fileExists(atPath: trashed.path))
  }
}
