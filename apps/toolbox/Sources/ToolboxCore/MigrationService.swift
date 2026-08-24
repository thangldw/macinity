import Foundation

public struct MigrationAssessment: Equatable, Sendable {
  public let detectedSourcePaths: [String]
  public let cleanupEntriesAvailable: Int
  public let traceSessionsAvailable: Int
  public let hasActiveSnapshot: Bool
  public let hasTrustedBaseline: Bool
  public let alreadyMigrated: Bool
  public let errors: [String]

  public var hasLegacyData: Bool { !detectedSourcePaths.isEmpty }
}

public struct MigrationReport: Codable, Equatable, Sendable {
  public let cleanupEntriesImported: Int
  public let traceSessionsImported: Int
  public let activeSnapshotImported: Bool
  public let trustedBaselineImported: Bool
  public let sourcePaths: [String]
  public let completedAt: Date
}

public enum MigrationError: LocalizedError, Equatable, Sendable {
  case unreadableSource(path: String, reason: String)
  case corruptCompletionMarker(path: String, reason: String)
  case verificationFailed(path: String)

  public var errorDescription: String? {
    switch self {
    case .unreadableSource(let path, let reason):
      "Không thể đọc dữ liệu cũ tại \(path): \(reason)"
    case .corruptCompletionMarker(let path, let reason):
      "Migration marker không hợp lệ tại \(path): \(reason)"
    case .verificationFailed(let path):
      "Không thể xác minh dữ liệu đã migrate tại \(path)"
    }
  }
}

public struct MigrationService: Sendable {
  private struct HistorySource: Sendable {
    let domain: LegacySourceDomain
    let url: URL
  }

  private struct PreparedMigration: Sendable {
    let history: [LegacyCleanupHistoryEntry]
    let sessions: [LegacyWatchSession]
    let activeSnapshot: LegacySystemSnapshot?
    let baseline: LegacySystemSnapshot?
    let sourcePaths: [String]
  }

  private static let activityID = UUID(uuidString: "a5dd569a-b821-57f9-b598-9fba8d5210b4")!
  private let legacyRoot: URL
  private let toolboxDirectory: URL
  private let decoder = JSONDecoder()

  public init(
    legacyRoot: URL = AppMetadata.applicationSupportDirectory().deletingLastPathComponent(),
    toolboxDirectory: URL = AppMetadata.applicationSupportDirectory()
  ) {
    self.legacyRoot = legacyRoot.standardizedFileURL
    self.toolboxDirectory = toolboxDirectory.standardizedFileURL
  }

  public func inspect() -> MigrationAssessment {
    do {
      if let report = try loadCompletionMarker() {
        return MigrationAssessment(
          detectedSourcePaths: report.sourcePaths,
          cleanupEntriesAvailable: report.cleanupEntriesImported,
          traceSessionsAvailable: report.traceSessionsImported,
          hasActiveSnapshot: report.activeSnapshotImported,
          hasTrustedBaseline: report.trustedBaselineImported,
          alreadyMigrated: true, errors: [])
      }
    } catch {
      return MigrationAssessment(
        detectedSourcePaths: existingSourceURLs().map(\.path), cleanupEntriesAvailable: 0,
        traceSessionsAvailable: 0, hasActiveSnapshot: false, hasTrustedBaseline: false,
        alreadyMigrated: false, errors: [error.localizedDescription])
    }

    do {
      let prepared = try prepare()
      return MigrationAssessment(
        detectedSourcePaths: prepared.sourcePaths,
        cleanupEntriesAvailable: prepared.history.count,
        traceSessionsAvailable: prepared.sessions.count,
        hasActiveSnapshot: prepared.activeSnapshot != nil,
        hasTrustedBaseline: prepared.baseline != nil,
        alreadyMigrated: false, errors: [])
    } catch {
      return MigrationAssessment(
        detectedSourcePaths: existingSourceURLs().map(\.path), cleanupEntriesAvailable: 0,
        traceSessionsAvailable: 0, hasActiveSnapshot: false, hasTrustedBaseline: false,
        alreadyMigrated: false, errors: [error.localizedDescription])
    }
  }

  public func migrate() throws -> MigrationReport {
    if let completed = try loadCompletionMarker() { return completed }
    let prepared = try prepare()

    let historyURL = toolboxDirectory.appendingPathComponent("history.json")
    let sessionsURL = toolboxDirectory.appendingPathComponent("sessions.json")
    let activeURL = toolboxDirectory.appendingPathComponent("active-snapshot.json")
    let baselineURL = toolboxDirectory.appendingPathComponent("trusted-baseline.json")

    let existingHistory: [LegacyCleanupHistoryEntry] = try decodeDestinationIfPresent(historyURL)
    let existingSessions: [LegacyWatchSession] = try decodeDestinationIfPresent(sessionsURL)
    let mergedHistory = merge(existingHistory, prepared.history)
    let mergedSessions = merge(existingSessions, prepared.sessions)

    if !prepared.history.isEmpty {
      try write(mergedHistory, to: historyURL)
      let verified: [LegacyCleanupHistoryEntry] = try decodeSource(historyURL)
      guard Set(prepared.history.map(\.id)).isSubset(of: Set(verified.map(\.id))) else {
        throw MigrationError.verificationFailed(path: historyURL.path)
      }
    }
    if !prepared.sessions.isEmpty {
      try write(mergedSessions, to: sessionsURL)
      let verified: [LegacyWatchSession] = try decodeSource(sessionsURL)
      guard Set(prepared.sessions.map(\.id)).isSubset(of: Set(verified.map(\.id))) else {
        throw MigrationError.verificationFailed(path: sessionsURL.path)
      }
    }

    let activeImported = try copySnapshotIfDestinationIsEmpty(
      prepared.activeSnapshot, destination: activeURL)
    let baselineImported = try copySnapshotIfDestinationIsEmpty(
      prepared.baseline, destination: baselineURL)
    let report = MigrationReport(
      cleanupEntriesImported: prepared.history.count,
      traceSessionsImported: prepared.sessions.count,
      activeSnapshotImported: activeImported, trustedBaselineImported: baselineImported,
      sourcePaths: prepared.sourcePaths, completedAt: Date())

    try ActivityLedger(directory: toolboxDirectory).append(
      ActivityEntry(
        id: Self.activityID, kind: .migration, status: .succeeded,
        paths: prepared.sourcePaths, affectedBytes: prepared.history.reduce(0) { $0 + $1.bytes },
        recoverable: false, errors: []))
    try write(report, to: completionMarkerURL)
    guard try loadCompletionMarker() == report else {
      throw MigrationError.verificationFailed(path: completionMarkerURL.path)
    }
    return report
  }

  private var historySources: [HistorySource] {
    [
      HistorySource(
        domain: .diskora, url: legacyRoot.appendingPathComponent("Diskora/history.json")),
      HistorySource(
        domain: .macCleaner, url: legacyRoot.appendingPathComponent("MacCleaner/history.json")),
    ]
  }

  private var changeoraDirectory: URL {
    legacyRoot.appendingPathComponent("Changeora", isDirectory: true)
  }

  private var completionMarkerURL: URL {
    toolboxDirectory.appendingPathComponent("migration-v1.json")
  }

  private func prepare() throws -> PreparedMigration {
    let manager = FileManager.default
    var history: [LegacyCleanupHistoryEntry] = []
    var sourcePaths: [String] = []
    for source in historySources where manager.fileExists(atPath: source.url.path) {
      let entries: [LegacyCleanupHistoryEntry] = try decodeSource(source.url)
      history.append(contentsOf: entries.map { $0.migrated(from: source.domain) })
      sourcePaths.append(source.url.path)
    }

    let sessionsURL = changeoraDirectory.appendingPathComponent("sessions.json")
    let activeURL = changeoraDirectory.appendingPathComponent("active-snapshot.json")
    let baselineURL = changeoraDirectory.appendingPathComponent("trusted-baseline.json")
    let sessions: [LegacyWatchSession]
    if manager.fileExists(atPath: sessionsURL.path) {
      let values: [LegacyWatchSession] = try decodeSource(sessionsURL)
      sessions = values.map { $0.migrated() }
      sourcePaths.append(sessionsURL.path)
    } else {
      sessions = []
    }
    let activeSource: LegacySystemSnapshot? = try decodeOptionalSource(
      activeURL, sourcePaths: &sourcePaths)
    let baselineSource: LegacySystemSnapshot? = try decodeOptionalSource(
      baselineURL, sourcePaths: &sourcePaths)

    return PreparedMigration(
      history: merge([], history), sessions: merge([], sessions),
      activeSnapshot: activeSource?.migrated(), baseline: baselineSource?.migrated(),
      sourcePaths: sourcePaths.sorted())
  }

  private func existingSourceURLs() -> [URL] {
    let candidates =
      historySources.map(\.url) + [
        changeoraDirectory.appendingPathComponent("sessions.json"),
        changeoraDirectory.appendingPathComponent("active-snapshot.json"),
        changeoraDirectory.appendingPathComponent("trusted-baseline.json"),
      ]
    return candidates.filter { FileManager.default.fileExists(atPath: $0.path) }
  }

  private func decodeOptionalSource<Value: Decodable>(
    _ url: URL, sourcePaths: inout [String]
  ) throws -> Value? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let value: Value = try decodeSource(url)
    sourcePaths.append(url.path)
    return value
  }

  private func decodeSource<Value: Decodable>(_ url: URL) throws -> Value {
    do {
      return try decoder.decode(Value.self, from: Data(contentsOf: url))
    } catch {
      throw MigrationError.unreadableSource(path: url.path, reason: error.localizedDescription)
    }
  }

  private func decodeDestinationIfPresent<Value: Decodable>(_ url: URL) throws -> [Value] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    return try decodeSource(url)
  }

  private func merge<Value: Identifiable>(_ existing: [Value], _ imported: [Value]) -> [Value]
  where Value.ID == UUID {
    var values = existing
    let existingIDs = Set(existing.map(\.id))
    values.append(contentsOf: imported.filter { !existingIDs.contains($0.id) })
    return values
  }

  private func copySnapshotIfDestinationIsEmpty(
    _ snapshot: LegacySystemSnapshot?, destination: URL
  ) throws -> Bool {
    guard let snapshot, !FileManager.default.fileExists(atPath: destination.path) else {
      return false
    }
    try write(snapshot, to: destination)
    let verified: LegacySystemSnapshot = try decodeSource(destination)
    guard verified == snapshot else {
      throw MigrationError.verificationFailed(path: destination.path)
    }
    return true
  }

  private func loadCompletionMarker() throws -> MigrationReport? {
    guard FileManager.default.fileExists(atPath: completionMarkerURL.path) else { return nil }
    do {
      return try decoder.decode(MigrationReport.self, from: Data(contentsOf: completionMarkerURL))
    } catch {
      throw MigrationError.corruptCompletionMarker(
        path: completionMarkerURL.path, reason: error.localizedDescription)
    }
  }

  private func write<Value: Encodable>(_ value: Value, to url: URL) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(value).write(to: url, options: .atomic)
  }
}
