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

print("PASS: ToolboxCore path safety and evidence contracts")
