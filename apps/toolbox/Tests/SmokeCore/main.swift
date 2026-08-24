import Foundation
import ToolboxCore

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else {
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
    exit(1)
  }
}

let manager = FileManager.default
let fixtureRoot = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
let allowed = fixtureRoot.appendingPathComponent("allowed")
let outside = fixtureRoot.appendingPathComponent("outside")
defer { try? manager.removeItem(at: fixtureRoot) }
try manager.createDirectory(at: allowed, withIntermediateDirectories: true)
try manager.createDirectory(at: outside, withIntermediateDirectories: true)
try manager.createSymbolicLink(
  at: allowed.appendingPathComponent("escape"), withDestinationURL: outside)

let candidate = allowed.appendingPathComponent("cache/item")
let accepted = try PathSafetyPolicy.validate(candidate: candidate, allowedRoots: [allowed])
require(accepted.path == candidate.path, "descendant path should be accepted")

do {
  _ = try PathSafetyPolicy.validate(
    candidate: allowed.appendingPathComponent("escape/item"), allowedRoots: [allowed])
  require(false, "symlink escape should be rejected")
} catch PathSafetyError.outsideAllowedRoots {
  // Expected.
}

let record = EvidenceRecord(
  path: "/tmp/cache", kind: .projectArtifact, safety: .safe,
  reasons: ["Generated artifact"], observedAt: Date(timeIntervalSince1970: 1))
let encoded = try JSONEncoder().encode(record)
let decoded = try JSONDecoder().decode(EvidenceRecord.self, from: encoded)
require(decoded == record, "evidence record should round-trip")
require(AppMetadata.name == "Toolbox", "unified product name should be Toolbox")
require(
  AppMetadata.applicationSupportDirectory(base: fixtureRoot).lastPathComponent == "Toolbox",
  "support data should use the Toolbox directory")
require(AppLanguage.defaultLanguage == .english, "English should be the default language")
ScanActivityRegistry.shared.begin()
require(ScanActivityRegistry.shared.isActive, "scan registry should report active work")
ScanActivityRegistry.shared.end()
require(!ScanActivityRegistry.shared.isActive, "scan registry should clear completed work")

let evidenceDirectory = fixtureRoot.appendingPathComponent("evidence-store")
let evidenceStore = EvidenceStore(directory: evidenceDirectory)
try evidenceStore.upsert(record)
try evidenceStore.upsert(
  EvidenceRecord(
    path: record.path, kind: record.kind, safety: .review, reasons: ["new"],
    observedAt: Date(timeIntervalSince1970: 2)))
let storedEvidence = try evidenceStore.load()
require(storedEvidence.count == 1, "evidence upsert should replace the same path-kind")
require(storedEvidence[0].safety == .review, "latest evidence should win")

let ledger = ActivityLedger(directory: fixtureRoot.appendingPathComponent("activity-ledger"))
let activity = ActivityEntry(
  kind: .cleanup, status: .succeeded, paths: [record.path], affectedBytes: 10,
  recoverable: true, errors: [])
try ledger.append(activity)
let storedActivity = try ledger.load()
require(storedActivity == [activity], "activity ledger should persist entries")

let corruptDirectory = fixtureRoot.appendingPathComponent("corrupt-store")
try manager.createDirectory(at: corruptDirectory, withIntermediateDirectories: true)
try Data("{".utf8).write(to: corruptDirectory.appendingPathComponent("evidence-v1.json"))
do {
  _ = try EvidenceStore(directory: corruptDirectory).load()
  require(false, "corrupt evidence should throw")
} catch {
  let names = try manager.contentsOfDirectory(atPath: corruptDirectory.path)
  require(
    names.count { $0.hasPrefix("evidence-v1.corrupt-") } == 1,
    "corrupt evidence should be quarantined")
}

let migrationRoot = fixtureRoot.appendingPathComponent("migration")
let legacyDiskora = migrationRoot.appendingPathComponent("Diskora")
let legacyChangeora = migrationRoot.appendingPathComponent("Changeora")
let migratedToolbox = migrationRoot.appendingPathComponent("Toolbox")
try manager.createDirectory(at: legacyDiskora, withIntermediateDirectories: true)
try manager.createDirectory(at: legacyChangeora, withIntermediateDirectories: true)
let legacyHistory = legacyDiskora.appendingPathComponent("history.json")
let legacySessions = legacyChangeora.appendingPathComponent("sessions.json")
try Data(
  #"[{"action":"Cleanup","bytes":42,"date":0,"id":"11111111-1111-1111-1111-111111111111","note":"legacy","paths":["/tmp/cache"],"recoverable":true}]"#
    .utf8
).write(to: legacyHistory)
try Data(
  #"[{"comparison":{"after":{"createdAt":60,"id":"22222222-2222-2222-2222-222222222224","inaccessiblePaths":[],"items":[],"name":"after","truncated":false},"before":{"createdAt":0,"id":"22222222-2222-2222-2222-222222222223","inaccessiblePaths":[],"items":[],"name":"before","truncated":false},"changes":[],"id":"22222222-2222-2222-2222-222222222222"},"events":[],"finishedAt":60,"id":"22222222-2222-2222-2222-222222222221","startedAt":0,"title":"Legacy trace"}]"#
    .utf8
).write(to: legacySessions)
let historyBeforeMigration = try Data(contentsOf: legacyHistory)
let sessionsBeforeMigration = try Data(contentsOf: legacySessions)
let migration = MigrationService(legacyRoot: migrationRoot, toolboxDirectory: migratedToolbox)
let migrationAssessment = migration.inspect()
require(migrationAssessment.cleanupEntriesAvailable == 1, "migration should inspect cleanup data")
require(migrationAssessment.traceSessionsAvailable == 1, "migration should inspect trace data")
let firstMigration = try migration.migrate()
let secondMigration = try migration.migrate()
require(firstMigration == secondMigration, "migration should be idempotent")
let historyAfterMigration = try Data(contentsOf: legacyHistory)
let sessionsAfterMigration = try Data(contentsOf: legacySessions)
let migrationActivities = try ActivityLedger(directory: migratedToolbox).load()
require(
  historyAfterMigration == historyBeforeMigration,
  "migration should preserve Diskora data")
require(
  sessionsAfterMigration == sessionsBeforeMigration,
  "migration should preserve Changeora data")
require(
  migrationActivities.filter { $0.kind == .migration }.count == 1,
  "migration should record one activity")

let corruptMigrationRoot = fixtureRoot.appendingPathComponent("corrupt-migration")
let corruptDiskora = corruptMigrationRoot.appendingPathComponent("Diskora")
let corruptToolbox = corruptMigrationRoot.appendingPathComponent("Toolbox")
try manager.createDirectory(at: corruptDiskora, withIntermediateDirectories: true)
let corruptHistory = corruptDiskora.appendingPathComponent("history.json")
let corruptSource = Data("{".utf8)
try corruptSource.write(to: corruptHistory)
do {
  _ = try MigrationService(
    legacyRoot: corruptMigrationRoot, toolboxDirectory: corruptToolbox
  ).migrate()
  require(false, "corrupt migration source should fail")
} catch {
  require(
    !manager.fileExists(
      atPath: corruptToolbox.appendingPathComponent("migration-v1.json").path),
    "failed migration should not write a completion marker")
  let preservedCorruptSource = try Data(contentsOf: corruptHistory)
  require(preservedCorruptSource == corruptSource, "failed migration should preserve its source")
}

print("PASS: ToolboxCore path safety, evidence and migration contracts")
