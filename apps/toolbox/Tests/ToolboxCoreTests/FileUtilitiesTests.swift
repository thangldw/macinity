import Foundation
import XCTest

@testable import ToolboxCore

final class FileUtilitiesTests: XCTestCase {
  func testChecksumRejectsSymlinkAndKnownDigestMatches() throws {
    let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let file = root.appendingPathComponent("sample.txt")
    try Data("abc".utf8).write(to: file)
    XCTAssertEqual(
      try FileChecksum.sha256(file),
      "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    XCTAssertThrowsError(try FileChecksum.sha256(file, maximumBytes: 2))
    let link = root.appendingPathComponent("link")
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
    XCTAssertThrowsError(try FileChecksum.sha256(link))
  }
  func testRenamePreviewApplyUndoAndConflictNeverOverwrite() throws {
    let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let a = root.appendingPathComponent("a.txt")
    let b = root.appendingPathComponent("b.txt")
    try Data("first".utf8).write(to: a)
    try Data("second".utf8).write(to: b)
    XCTAssertThrowsError(
      try FileUtilityOperations.renamePlan([a], find: "a", replace: "b", prefix: ""))
    XCTAssertEqual(try String(contentsOf: b, encoding: .utf8), "second")
    let plan = try FileUtilityOperations.renamePlan([a, b], find: "", replace: "", prefix: "new-")
    XCTAssertTrue(FileManager.default.fileExists(atPath: a.path), "Preview must not mutate")
    let journal = root.appendingPathComponent("journal.json")
    try FileUtilityOperations.applyRename(plan, journal: journal)
    XCTAssertFalse(FileManager.default.fileExists(atPath: a.path))
    XCTAssertEqual(
      try JSONDecoder().decode([RenameItem].self, from: Data(contentsOf: journal)).count, 2)
    try FileUtilityOperations.undoRename(plan)
    XCTAssertEqual(try String(contentsOf: a, encoding: .utf8), "first")
    let stale = try FileUtilityOperations.renamePlan([a], find: "", replace: "", prefix: "changed-")
    try Data("different data".utf8).write(to: a)
    XCTAssertThrowsError(try FileUtilityOperations.applyRename(stale, journal: journal))
    XCTAssertTrue(FileManager.default.fileExists(atPath: a.path))
  }
  func testRenameNormalizesTemporaryDirectoryAliasAndRejectsSymlinkLeaf() throws {
    let root = URL(fileURLWithPath: "/tmp").appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let file = root.appendingPathComponent("sample.txt")
    try Data("abc".utf8).write(to: file)
    let plan = try FileUtilityOperations.renamePlan([file], find: "", replace: "", prefix: "new-")
    let journal = root.appendingPathComponent("journal.json")
    try FileUtilityOperations.applyRename(plan, journal: journal)
    try FileUtilityOperations.undoRename(plan)
    XCTAssertEqual(try Data(contentsOf: file), Data("abc".utf8))
    let link = root.appendingPathComponent("link")
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
    XCTAssertThrowsError(
      try FileUtilityOperations.renamePlan([link], find: "", replace: "", prefix: "new-"))
  }
  func testTreeUsesContentAndExcludesSymlinks() throws {
    let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try Data("a".utf8).write(to: root.appendingPathComponent("a"))
    try FileManager.default.createSymbolicLink(
      at: root.appendingPathComponent("link"), withDestinationURL: root.appendingPathComponent("a"))
    let values = try FileUtilityOperations.tree(root, deadline: Date().addingTimeInterval(5))
    XCTAssertEqual(Set(values.keys), ["a"])
    XCTAssertThrowsError(try FileUtilityOperations.tree(root, deadline: .distantPast))
  }
}
