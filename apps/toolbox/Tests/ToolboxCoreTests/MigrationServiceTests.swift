import Foundation
import XCTest

@testable import ToolboxCore

final class MigrationServiceTests: XCTestCase {
  func testMigrationCopiesAndPreservesLegacyFiles() throws {
    let fixture = try LegacyMigrationFixture.make()
    let historyBefore = try Data(contentsOf: fixture.legacyHistory)
    let sessionsBefore = try Data(contentsOf: fixture.legacySessions)

    let report = try fixture.service.migrate()

    XCTAssertEqual(report.cleanupEntriesImported, 1)
    XCTAssertEqual(report.traceSessionsImported, 1)
    XCTAssertEqual(try Data(contentsOf: fixture.legacyHistory), historyBefore)
    XCTAssertEqual(try Data(contentsOf: fixture.legacySessions), sessionsBefore)
    XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.toolboxHistory.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.toolboxSessions.path))
  }

  func testMigrationIsIdempotent() throws {
    let fixture = try LegacyMigrationFixture.make()

    let first = try fixture.service.migrate()
    let second = try fixture.service.migrate()

    XCTAssertEqual(second, first)
    XCTAssertEqual(try fixture.activityLedger.load().filter { $0.kind == .migration }.count, 1)
  }

  func testInspectReportsLegacyDataBeforeMigration() throws {
    let fixture = try LegacyMigrationFixture.make()

    let assessment = fixture.service.inspect()

    XCTAssertFalse(assessment.alreadyMigrated)
    XCTAssertEqual(assessment.cleanupEntriesAvailable, 1)
    XCTAssertEqual(assessment.traceSessionsAvailable, 1)
    XCTAssertTrue(assessment.errors.isEmpty)
  }

  func testCorruptSourceLeavesNoCompletionMarker() throws {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let diskora = root.appendingPathComponent("Diskora")
    let toolbox = root.appendingPathComponent("Toolbox")
    try manager.createDirectory(at: diskora, withIntermediateDirectories: true)
    let history = diskora.appendingPathComponent("history.json")
    let original = Data("{".utf8)
    try original.write(to: history)
    let service = MigrationService(legacyRoot: root, toolboxDirectory: toolbox)

    XCTAssertThrowsError(try service.migrate())
    XCTAssertEqual(try Data(contentsOf: history), original)
    XCTAssertFalse(
      manager.fileExists(atPath: toolbox.appendingPathComponent("migration-v1.json").path))
  }
}

private struct LegacyMigrationFixture {
  let service: MigrationService
  let activityLedger: ActivityLedger
  let legacyHistory: URL
  let legacySessions: URL
  let toolboxHistory: URL
  let toolboxSessions: URL

  static func make() throws -> LegacyMigrationFixture {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let diskora = root.appendingPathComponent("Diskora")
    let changeora = root.appendingPathComponent("Changeora")
    let toolbox = root.appendingPathComponent("Toolbox")
    try manager.createDirectory(at: diskora, withIntermediateDirectories: true)
    try manager.createDirectory(at: changeora, withIntermediateDirectories: true)
    let history = diskora.appendingPathComponent("history.json")
    let sessions = changeora.appendingPathComponent("sessions.json")
    let fixtures = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().appendingPathComponent("Fixtures")
    try manager.copyItem(at: fixtures.appendingPathComponent("diskora-history.json"), to: history)
    try manager.copyItem(
      at: fixtures.appendingPathComponent("changeora-sessions.json"), to: sessions)

    return LegacyMigrationFixture(
      service: MigrationService(legacyRoot: root, toolboxDirectory: toolbox),
      activityLedger: ActivityLedger(directory: toolbox), legacyHistory: history,
      legacySessions: sessions, toolboxHistory: toolbox.appendingPathComponent("history.json"),
      toolboxSessions: toolbox.appendingPathComponent("sessions.json"))
  }
}
