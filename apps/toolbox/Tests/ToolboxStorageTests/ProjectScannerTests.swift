import Foundation
import XCTest

@testable import ToolboxStorage

final class ProjectScannerTests: XCTestCase {
  func testNodeProjectFindsNodeModulesButProtectsLockfile() async throws {
    let root = try fixtureProject(
      files: ["package.json", "package-lock.json", "node_modules/pkg/a.js"])
    defer { try? FileManager.default.removeItem(at: root) }

    let report = await ProjectScanner().scan(roots: [root])

    XCTAssertEqual(report.artifacts.map { $0.artifactURL.lastPathComponent }, ["node_modules"])
    XCTAssertFalse(
      report.artifacts.contains { $0.artifactURL.lastPathComponent == "package-lock.json" })
  }

  func testUnknownGeneratedLookingFolderIsNotOffered() async throws {
    let root = try fixtureProject(files: ["src/main.swift", "mystery-cache/blob"])
    defer { try? FileManager.default.removeItem(at: root) }

    let report = await ProjectScanner().scan(roots: [root])

    XCTAssertTrue(report.artifacts.isEmpty)
  }

  func testSymlinkArtifactEscapingSelectedRootIsProtected() async throws {
    let root = try fixtureProject(files: ["package.json"])
    defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
    let outside = root.deletingLastPathComponent().appendingPathComponent("outside")
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    try FileManager.default.createSymbolicLink(
      at: root.appendingPathComponent("node_modules"), withDestinationURL: outside)

    let report = await ProjectScanner().scan(roots: [root])

    XCTAssertEqual(report.artifacts.first?.safety, .protected)
  }

  func testCleanupRevalidatesAndRemovesOnlyRecognizedArtifact() async throws {
    let root = try fixtureProject(files: ["package.json", "node_modules/pkg/a.js"])
    defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
    let report = await ProjectScanner().scan(roots: [root])
    let artifact = try XCTUnwrap(report.artifacts.first)

    let outcome = ProjectCleanupService(removalMethod: .permanentForTesting)
      .moveToTrash(artifact, allowedRoots: [root])

    XCTAssertNil(outcome.error)
    XCTAssertFalse(FileManager.default.fileExists(atPath: artifact.artifactURL.path))
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: root.appendingPathComponent("package.json").path))
  }

  private func fixtureProject(files: [String]) throws -> URL {
    let root = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("project")
    for relativePath in files {
      let file = root.appendingPathComponent(relativePath)
      try FileManager.default.createDirectory(
        at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
      try Data(relativePath.utf8).write(to: file)
    }
    return root
  }
}
