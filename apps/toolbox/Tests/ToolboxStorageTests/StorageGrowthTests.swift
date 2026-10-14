import Foundation
import XCTest

@testable import ToolboxStorage

final class StorageGrowthTests: XCTestCase {
  private func checkpoint(
    _ date: Date, folders: [String: Int64], identity: String = "1:2", unreadable: Int = 0
  ) -> StorageCheckpoint {
    .init(
      rootPath: "/fixture", date: date, totalBytes: 100, folders: folders,
      schemaVersion: 2, rootIdentity: identity, inaccessibleCount: unreadable, foldersComplete: true
    )
  }
  func testGrowthAccountsForRemovedItemsAndRejectsIncompatibleCoverage() {
    let start = Date(timeIntervalSince1970: 100)
    let end = Date(timeIntervalSince1970: 200)
    let old = checkpoint(start, folders: ["/fixture/a": 10, "/fixture/gone": 50])
    let next = checkpoint(end, folders: ["/fixture/a": 30, "/fixture/new": 5])
    let result = StorageComparison.compare(previous: old, current: next)
    XCTAssertEqual(result.deltas.map(\.path), ["/fixture/gone", "/fixture/a", "/fixture/new"])
    XCTAssertEqual(result.deltas.map(\.bytes), [-50, 20, 5])
    for incompatible in [
      checkpoint(end, folders: [:], identity: "1:3"),
      checkpoint(end, folders: [:], unreadable: 1), checkpoint(start, folders: [:]),
    ] {
      XCTAssertTrue(StorageComparison.compare(previous: old, current: incompatible).deltas.isEmpty)
    }
    let legacy = StorageCheckpoint(
      rootPath: "/fixture", date: start, totalBytes: 100, folders: old.folders)
    XCTAssertTrue(StorageComparison.compare(previous: legacy, current: next).deltas.isEmpty)
  }
  func testComparisonRetainsFoldersOutsideTopThirtyAndInventoryIncludesSourceOnlyProject()
    async throws
  {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    for index in 0..<35 {
      let folder = root.appendingPathComponent("folder-\(index)")
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      try Data([1]).write(to: folder.appendingPathComponent("file"))
    }
    try Data("{}".utf8).write(to: root.appendingPathComponent("package.json"))
    let scan = try StorageAnalyzer().scan(rootURL: root)
    XCTAssertEqual(scan.topFolders.count, 30)
    XCTAssertEqual(scan.comparisonFolders?.count, 36)
    XCTAssertNotNil(scan.rootIdentity)
    let projects = await ProjectScanner().scan(roots: [root])
    XCTAssertTrue(projects.artifacts.isEmpty)
    XCTAssertEqual(projects.inventory?.first?.ecosystems, [.node])
    XCTAssertEqual(projects.inventory?.first?.markers, ["package.json"])
  }
  func testDirectoryNamedLikeManifestDoesNotAuthorizeArtifactRecognition() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("package.json"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("node_modules"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let report = await ProjectScanner().scan(roots: [root])
    XCTAssertTrue(report.artifacts.isEmpty)
    XCTAssertTrue((report.inventory ?? []).isEmpty)
  }

  func testWorkspacePartitionMatchesFilesystemAliases() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let artifact = root.appendingPathComponent("node_modules")
    try FileManager.default.createDirectory(at: artifact, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try Data("{}".utf8).write(to: root.appendingPathComponent("package.json"))
    try Data([1]).write(to: artifact.appendingPathComponent("fixture"))
    let report = await ProjectScanner().scan(roots: [root])
    let snapshot = try StorageAnalyzer().scan(rootURL: root)
    let observedArtifact = try XCTUnwrap(report.artifacts.first)
    let measuredPath = try XCTUnwrap(
      snapshot.comparisonFolders?.keys.first {
        URL(fileURLWithPath: $0).lastPathComponent == "node_modules"
      })
    let aliasPath =
      measuredPath.hasPrefix("/private/var/")
      ? String(measuredPath.dropFirst("/private".count)) : "/private" + measuredPath
    let aliased = ProjectArtifact(
      projectRoot: observedArtifact.projectRoot,
      artifactURL: URL(fileURLWithPath: aliasPath, isDirectory: true),
      ecosystem: observedArtifact.ecosystem, bytes: observedArtifact.bytes,
      modifiedAt: observedArtifact.modifiedAt, safety: observedArtifact.safety,
      reasons: observedArtifact.reasons)
    XCTAssertNotEqual(aliased.artifactURL.path, measuredPath)
    let usage = WorkspaceUsage(snapshot: snapshot, artifacts: [aliased])
    XCTAssertGreaterThan(observedArtifact.bytes, 0)
    XCTAssertEqual(usage.artifactBytes, observedArtifact.bytes)
    XCTAssertEqual(usage.otherBytes, snapshot.scannedBytes - observedArtifact.bytes)
  }

}
