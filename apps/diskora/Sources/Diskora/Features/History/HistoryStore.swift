import Foundation

struct CleanupHistoryEntry: Codable, Identifiable, Sendable {
  let id: UUID
  let date: Date
  let action: String
  let paths: [String]
  let bytes: Int64
  let recoverable: Bool
  let note: String
}

struct HistoryStore: Sendable {
  private var fileURL: URL {
    AppMetadata.applicationSupportDirectory().appendingPathComponent("history.json")
  }

  func load() -> [CleanupHistoryEntry] {
    guard let data = try? Data(contentsOf: fileURL) else { return [] }
    return (try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data)) ?? []
  }

  func record(action: String, paths: [String], bytes: Int64, recoverable: Bool, note: String) {
    var entries = load()
    entries.insert(
      .init(
        id: UUID(), date: Date(), action: action, paths: paths, bytes: bytes,
        recoverable: recoverable, note: note), at: 0)
    entries = Array(entries.prefix(500))
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(entries)
      try data.write(to: fileURL, options: .atomic)
    } catch {
      return
    }
  }
}

@MainActor
final class HistoryViewModel: ObservableObject {
  @Published var entries: [CleanupHistoryEntry] = []
  private let store = HistoryStore()
  func refresh() { entries = store.load() }
}
