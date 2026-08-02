import Foundation
import XCTest

@testable import Diskora

final class DiskoraTests: XCTestCase {
  func testEnglishLocalizationResourceCoversCoreInterface() throws {
    let resource = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Resources/en.lproj/Localizable.strings")
    let data = try Data(contentsOf: resource)
    let strings = try XCTUnwrap(
      PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String])

    XCTAssertGreaterThan(strings.count, 150)
    XCTAssertEqual(strings["Dọn nhanh"], "Quick Clean")
    XCTAssertEqual(strings["Cần xem lại"], "Review")
    XCTAssertEqual(strings["Khôi phục"], "Restore")
    XCTAssertEqual(AppLanguage.english.rawValue, "en")
    XCTAssertEqual(AppLanguage.vietnamese.rawValue, "vi")
  }

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

  func testCleanerOnlyRemovesChildrenOfSelectedTarget() throws {
    let manager = FileManager.default
    let home = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? manager.removeItem(at: home) }
    let cache = home.appendingPathComponent("Library/Caches", isDirectory: true)
    try manager.createDirectory(at: cache, withIntermediateDirectories: true)
    try Data(repeating: 1, count: 4_096).write(to: cache.appendingPathComponent("sample.bin"))

    let target = CleaningTarget(
      id: "cache", name: "Cache", detail: "", relativePath: "Library/Caches", symbol: "folder",
      isSelectedByDefault: true)
    let result = CleanerService(homeURL: home, removalMethod: .permanentForTesting).clean(
      target: target)

    XCTAssertEqual(result.removedItems, 1)
    XCTAssertTrue(result.errors.isEmpty)
    XCTAssertFalse(result.recoverable)
    XCTAssertTrue(manager.fileExists(atPath: cache.path))
    XCTAssertTrue(try manager.contentsOfDirectory(atPath: cache.path).isEmpty)
  }

  func testLeftoverNameMatchingDoesNotUseSubstringMatches() {
    XCTAssertTrue(
      ApplicationScanner.matchesLeftoverName("com.example.note", applicationName: "Note"))
    XCTAssertFalse(
      ApplicationScanner.matchesLeftoverName("com.example.noteworthy", applicationName: "Note"))
  }

  func testUndoCenterRestoresRecordedTrashMoveWithoutOverwrite() throws {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? manager.removeItem(at: root) }
    let original = root.appendingPathComponent("Original/sample.txt")
    let trashed = root.appendingPathComponent("Trash/sample.txt")
    try manager.createDirectory(
      at: trashed.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("recoverable".utf8).write(to: trashed)

    let store = HistoryStore(directory: root.appendingPathComponent("Store"))
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
    XCTAssertEqual(store.load().first?.pendingRestoreCount, 0)
  }
}
