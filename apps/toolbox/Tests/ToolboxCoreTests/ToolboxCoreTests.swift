import Foundation
import XCTest

@testable import ToolboxCore

final class ToolboxCoreTests: XCTestCase {
  func testSafetyPolicyAcceptsDescendant() throws {
    let root = try temporaryDirectory()
    let candidate = root.appendingPathComponent("cache/item")

    let accepted = try PathSafetyPolicy.validate(candidate: candidate, allowedRoots: [root])

    XCTAssertEqual(accepted.path, candidate.path)
  }

  func testSafetyPolicyRejectsBroadRoot() throws {
    let root = try temporaryDirectory()

    XCTAssertThrowsError(
      try PathSafetyPolicy.validate(candidate: URL(fileURLWithPath: "/"), allowedRoots: [root])
    ) { error in
      XCTAssertEqual(error as? PathSafetyError, .broadTarget)
    }
  }

  func testSafetyPolicyRejectsSymlinkEscape() throws {
    let fixtureRoot = try temporaryDirectory()
    let allowed = fixtureRoot.appendingPathComponent("allowed")
    let outside = fixtureRoot.appendingPathComponent("outside")
    try FileManager.default.createDirectory(at: allowed, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    try FileManager.default.createSymbolicLink(
      at: allowed.appendingPathComponent("escape"), withDestinationURL: outside)

    XCTAssertThrowsError(
      try PathSafetyPolicy.validate(
        candidate: allowed.appendingPathComponent("escape/item"), allowedRoots: [allowed])
    ) { error in
      XCTAssertEqual(error as? PathSafetyError, .outsideAllowedRoots)
    }
  }

  func testEvidenceRecordRoundTrips() throws {
    let record = EvidenceRecord(
      path: "/tmp/cache", kind: .projectArtifact, safety: .safe,
      reasons: ["Generated artifact"], observedAt: Date(timeIntervalSince1970: 1))

    let data = try JSONEncoder().encode(record)

    XCTAssertEqual(try JSONDecoder().decode(EvidenceRecord.self, from: data), record)
  }

  func testEvidenceUpsertIsStableByCanonicalPathAndKind() throws {
    let directory = try temporaryDirectory()
    let store = EvidenceStore(directory: directory)
    try store.upsert(
      EvidenceRecord(
        path: "/tmp/a", kind: .projectArtifact, safety: .safe,
        reasons: ["first"], observedAt: Date(timeIntervalSince1970: 1)))
    try store.upsert(
      EvidenceRecord(
        path: "/tmp/a", kind: .projectArtifact, safety: .review,
        reasons: ["new"], observedAt: Date(timeIntervalSince1970: 2)))

    XCTAssertEqual(try store.load().count, 1)
    XCTAssertEqual(try store.load().first?.safety, .review)
  }

  func testCorruptStoreIsQuarantinedInsteadOfOverwritten() throws {
    let directory = try temporaryDirectory()
    try Data("{".utf8).write(to: directory.appendingPathComponent("evidence-v1.json"))

    XCTAssertThrowsError(try EvidenceStore(directory: directory).load())
    XCTAssertEqual(
      try FileManager.default.contentsOfDirectory(atPath: directory.path)
        .filter { $0.hasPrefix("evidence-v1.corrupt-") }.count,
      1)
    XCTAssertFalse(
      FileManager.default.fileExists(
        atPath: directory.appendingPathComponent("evidence-v1.json").path))
  }

  func testActivityLedgerPersistsStatusAndExactTargets() throws {
    let directory = try temporaryDirectory()
    let ledger = ActivityLedger(directory: directory)
    let entry = ActivityEntry(
      kind: .cleanup, status: .succeeded, occurredAt: Date(timeIntervalSince1970: 3),
      paths: ["/tmp/cache"], affectedBytes: 42, recoverable: true, errors: [])

    try ledger.append(entry)

    XCTAssertEqual(try ledger.load(), [entry])
  }

  func testProductMetadataUsesUnifiedSupportDirectory() {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    XCTAssertEqual(AppMetadata.name, "Toolbox")
    XCTAssertEqual(AppMetadata.applicationSupportDirectory(base: base).lastPathComponent, "Toolbox")
  }

  func testEnglishIsTheDefaultLanguage() {
    XCTAssertEqual(AppLanguage.defaultLanguage, .english)
    XCTAssertEqual(AppLanguage.english.locale.identifier, "en")
    XCTAssertEqual(AppLanguage.vietnamese.locale.identifier, "vi")
  }

  private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: url) }
    return url
  }
}
