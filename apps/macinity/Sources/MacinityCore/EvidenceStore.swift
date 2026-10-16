import Foundation

public struct EvidenceStore: Sendable {
  private static let schemaVersion = 1
  private let fileURL: URL

  public init(directory: URL = AppMetadata.applicationSupportDirectory()) {
    fileURL = directory.appendingPathComponent("evidence-v1.json")
  }

  public func load() throws -> [EvidenceRecord] {
    try StoreRecovery.load(
      EvidenceRecord.self, from: fileURL, schemaVersion: Self.schemaVersion)
  }

  public func upsert(_ record: EvidenceRecord) throws {
    let normalized = normalize(record)
    var records = try load()
    records.removeAll {
      normalizePath($0.path) == normalized.path && $0.kind == normalized.kind
    }
    records.append(normalized)
    records.sort {
      if $0.observedAt != $1.observedAt { return $0.observedAt > $1.observedAt }
      if $0.path != $1.path { return $0.path < $1.path }
      return $0.kind.rawValue < $1.kind.rawValue
    }
    try StoreRecovery.save(records, to: fileURL, schemaVersion: Self.schemaVersion)
  }

  private func normalize(_ record: EvidenceRecord) -> EvidenceRecord {
    EvidenceRecord(
      path: normalizePath(record.path), kind: record.kind, safety: record.safety,
      reasons: record.reasons, observedAt: record.observedAt)
  }

  private func normalizePath(_ path: String) -> String {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
  }
}
