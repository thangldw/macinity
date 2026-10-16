import Foundation
import MacinityCore

struct StorageCheckpoint: Codable, Sendable {
  let rootPath: String
  let date: Date
  let totalBytes: Int64
  let folders: [String: Int64]
  // Optional fields preserve decoding of existing checkpoints; old records establish no comparison.
  var schemaVersion: Int? = nil
  var rootIdentity: String? = nil
  var inaccessibleCount: Int? = nil
  var foldersComplete: Bool? = nil
}

struct StorageDelta: Identifiable, Sendable {
  let path: String
  let bytes: Int64
  var id: String { path }
}

struct StorageComparison: Sendable {
  let previousDate: Date?
  let deltas: [StorageDelta]
  let status: String

  static func compare(previous: StorageCheckpoint?, current: StorageCheckpoint) -> StorageComparison
  {
    guard let previous else {
      return .init(
        previousDate: nil, deltas: [],
        status: "Baseline saved. Scan the same location again to compare growth.")
    }
    guard previous.schemaVersion == 2, current.schemaVersion == 2,
      previous.rootPath == current.rootPath, let identity = current.rootIdentity,
      previous.rootIdentity == identity,
      previous.inaccessibleCount == 0, current.inaccessibleCount == 0,
      previous.foldersComplete == true, current.foldersComplete == true,
      previous.date < current.date,
      previous.folders.values.allSatisfy({ $0 >= 0 }),
      current.folders.values.allSatisfy({ $0 >= 0 })
    else {
      return .init(
        previousDate: previous.date, deltas: [],
        status:
          "Scans are not comparable: scope, identity, coverage or checkpoint format differs. A new baseline was saved."
      )
    }
    let deltas = Set(previous.folders.keys).union(current.folders.keys).compactMap {
      path -> StorageDelta? in
      let delta = (current.folders[path] ?? 0) - (previous.folders[path] ?? 0)
      return delta == 0 ? nil : .init(path: path, bytes: delta)
    }.sorted { abs($0.bytes) == abs($1.bytes) ? $0.path < $1.path : abs($0.bytes) > abs($1.bytes) }
    return .init(
      previousDate: previous.date, deltas: deltas,
      status:
        "Comparable observed folder changes. Decreases do not prove APFS space was freed; changes do not identify their cause."
    )
  }
}

struct StorageTrendStore: Sendable {
  private var url: URL {
    AppMetadata.applicationSupportDirectory().appendingPathComponent("storage-checkpoints.json")
  }
  func compareAndSave(_ snapshot: StorageSnapshot) throws -> StorageComparison {
    var all = try load()
    let old = all.last { $0.rootPath == snapshot.rootURL.path }
    let current = StorageCheckpoint(
      rootPath: snapshot.rootURL.path, date: snapshot.completedAt,
      totalBytes: snapshot.scannedBytes,
      folders: snapshot.comparisonFolders ?? [:],
      schemaVersion: 2, rootIdentity: snapshot.rootIdentity,
      inaccessibleCount: snapshot.inaccessibleCount,
      foldersComplete: snapshot.comparisonFolders != nil)
    all.append(current)
    all = Array(all.suffix(50))
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(all).write(to: url, options: .atomic)
    return StorageComparison.compare(previous: old, current: current)
  }
  private func load() throws -> [StorageCheckpoint] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard ((attributes[.size] as? NSNumber)?.int64Value ?? Int64.max) <= 32_000_000 else {
      throw CocoaError(.fileReadTooLarge)
    }
    let data = try Data(contentsOf: url)
    guard data.count <= 32_000_000 else { throw CocoaError(.fileReadTooLarge) }
    return try JSONDecoder().decode([StorageCheckpoint].self, from: data)
  }
}
