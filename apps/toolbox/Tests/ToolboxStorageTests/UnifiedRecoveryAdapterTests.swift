import Foundation
import XCTest

@testable import ToolboxStorage

final class UnifiedRecoveryAdapterTests: XCTestCase {
  func testRecoveryNeverOverwritesExistingDestination() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appendingPathComponent("Trash/item")
    let destination = root.appendingPathComponent("Original/item")
    try FileManager.default.createDirectory(
      at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("trashed".utf8).write(to: source)
    try Data("existing".utf8).write(to: destination)
    let item = RecoveryItem(
      id: UUID(), originalPath: destination.path, trashPath: source.path, bytes: 7)
    let adapter = UnifiedRecoveryAdapter(
      allowedTrashRoots: [source.deletingLastPathComponent()],
      allowedDestinationRoots: [destination.deletingLastPathComponent()])

    let result = adapter.restore(item)

    XCTAssertEqual(result.restoredCount, 0)
    XCTAssertEqual(try Data(contentsOf: destination), Data("existing".utf8))
    XCTAssertEqual(try Data(contentsOf: source), Data("trashed".utf8))
  }
}
