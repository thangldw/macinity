import Foundation

/// Persistent dHash cache keyed by path, invalidated when size or modification time change.
struct PhotoFingerprintCache {
  static let maxEntries = 200_000
  static let defaultMaxFileBytes = 64 * 1_024 * 1_024

  private struct Entry: Codable {
    var size: Int64
    var modified: Int64
    var hash: String
  }

  private struct Archive: Codable {
    var schemaVersion = 1
    var order: [String] = []
    var entries: [String: Entry] = [:]
  }

  private let fileURL: URL
  private let maxFileBytes: Int
  private var isDirty = false
  private var archive = Archive()
  private(set) var isWritable = true

  var count: Int { archive.entries.count }

  init(fileURL: URL, maxFileBytes: Int = defaultMaxFileBytes) {
    self.fileURL = fileURL
    self.maxFileBytes = maxFileBytes
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
    do {
      let size =
        (try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?
        .intValue ?? Int.max
      guard size <= maxFileBytes else { throw CocoaError(.fileReadTooLarge) }
      let decoded = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: fileURL))
      guard decoded.schemaVersion == 1 else { throw CocoaError(.fileReadCorruptFile) }
      archive = decoded
    } catch {
      isWritable = false
    }
  }

  func hash(path: String, size: Int64, modified: Date) -> UInt64? {
    guard let entry = archive.entries[path], entry.size == size,
      entry.modified == Int64(modified.timeIntervalSince1970)
    else { return nil }
    return UInt64(entry.hash, radix: 16)
  }

  mutating func store(path: String, size: Int64, modified: Date, hash: UInt64) {
    if archive.entries[path] == nil { archive.order.append(path) }
    archive.entries[path] = Entry(
      size: size, modified: Int64(modified.timeIntervalSince1970), hash: String(hash, radix: 16))
    isDirty = true
    if archive.order.count > Self.maxEntries {
      // Evict in bulk (oldest 10% beyond the cap) so eviction stays amortised O(1) per store.
      drop(oldest: archive.order.count - Self.maxEntries + Self.maxEntries / 10)
    }
  }

  private mutating func drop(oldest count: Int) {
    let count = min(count, archive.order.count)
    for key in archive.order.prefix(count) { archive.entries[key] = nil }
    archive.order.removeFirst(count)
  }

  mutating func prune(keeping paths: Set<String>) {
    isDirty = true
    archive.order.removeAll { !paths.contains($0) }
    archive.entries = archive.entries.filter { paths.contains($0.key) }
  }

  /// Writes only when something changed, and trims the oldest entries until the file stays
  /// under the size the loader accepts (otherwise the cache would silently stop loading).
  mutating func save() throws {
    guard isWritable, isDirty else { return }
    var data = try JSONEncoder().encode(archive)
    while data.count > maxFileBytes, !archive.order.isEmpty {
      drop(oldest: max(1, archive.order.count / 10))
      data = try JSONEncoder().encode(archive)
    }
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: fileURL, options: .atomic)
    isDirty = false
  }
}
