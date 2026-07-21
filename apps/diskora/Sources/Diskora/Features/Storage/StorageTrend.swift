import Foundation

struct StorageCheckpoint: Codable, Sendable {
  let rootPath: String
  let date: Date
  let totalBytes: Int64
  let folders: [String: Int64]
}

struct StorageDelta: Identifiable, Sendable {
  let path: String
  let bytes: Int64
  var id: String { path }
}

struct StorageTrendStore: Sendable {
  private var url: URL {
    AppMetadata.applicationSupportDirectory().appendingPathComponent("storage-checkpoints.json")
  }
  func compareAndSave(_ snapshot: StorageSnapshot) -> [StorageDelta] {
    let old = load().last { $0.rootPath == snapshot.rootURL.path }
    let folders = Dictionary(
      uniqueKeysWithValues: snapshot.topFolders.map { ($0.url.path, $0.bytes) })
    var all = load()
    all.append(
      .init(
        rootPath: snapshot.rootURL.path, date: Date(), totalBytes: snapshot.scannedBytes,
        folders: folders))
    all = Array(all.suffix(50))
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? JSONEncoder().encode(all).write(to: url, options: .atomic)
    guard let old else { return [] }
    return folders.map { StorageDelta(path: $0.key, bytes: $0.value - (old.folders[$0.key] ?? 0)) }
      .filter { $0.bytes != 0 }.sorted { abs($0.bytes) > abs($1.bytes) }
  }
  private func load() -> [StorageCheckpoint] {
    guard let data = try? Data(contentsOf: url) else { return [] }
    return (try? JSONDecoder().decode([StorageCheckpoint].self, from: data)) ?? []
  }
}
