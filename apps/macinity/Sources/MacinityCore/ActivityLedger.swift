import Foundation

public struct ActivityLedger: Sendable {
  private static let schemaVersion = 1
  private let fileURL: URL

  public init(directory: URL = AppMetadata.applicationSupportDirectory()) {
    fileURL = directory.appendingPathComponent("activity-v1.json")
  }

  public func load() throws -> [ActivityEntry] {
    try StoreRecovery.load(ActivityEntry.self, from: fileURL, schemaVersion: Self.schemaVersion)
  }

  public func append(_ entry: ActivityEntry) throws {
    var entries = try load()
    entries.removeAll { $0.id == entry.id }
    entries.append(entry)
    entries.sort {
      if $0.occurredAt != $1.occurredAt { return $0.occurredAt > $1.occurredAt }
      return $0.id.uuidString < $1.id.uuidString
    }
    try StoreRecovery.save(entries, to: fileURL, schemaVersion: Self.schemaVersion)
  }
}
