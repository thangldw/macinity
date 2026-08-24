import Foundation
import ToolboxCore

struct CleanupHistoryEntry: Codable, Identifiable, Sendable {
  let id: UUID
  let date: Date
  let action: String
  let paths: [String]
  let bytes: Int64
  let recoverable: Bool
  let note: String
  var moves: [TrashMoveRecord]?

  var pendingRestoreCount: Int {
    moves?.count { $0.restoredAt == nil } ?? 0
  }
}

struct RestoreResult: Sendable {
  let restoredCount: Int
  let restoredBytes: Int64
  let errors: [String]
}

struct HistoryStore: Sendable {
  private let directory: URL

  init(directory: URL = AppMetadata.applicationSupportDirectory()) {
    self.directory = directory
  }

  private var fileURL: URL {
    directory.appendingPathComponent("history.json")
  }

  func load() -> [CleanupHistoryEntry] {
    guard let data = try? Data(contentsOf: fileURL) else { return [] }
    return (try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data)) ?? []
  }

  func record(
    action: String, paths: [String], bytes: Int64, recoverable: Bool, note: String,
    moves: [TrashMoveRecord] = []
  ) {
    var entries = load()
    entries.insert(
      .init(
        id: UUID(), date: Date(), action: action, paths: paths, bytes: bytes,
        recoverable: recoverable, note: note, moves: moves.isEmpty ? nil : moves), at: 0)
    entries = Array(entries.prefix(500))
    save(entries)
  }

  func restore(entryID: UUID) -> RestoreResult {
    var entries = load()
    guard let entryIndex = entries.firstIndex(where: { $0.id == entryID }),
      var moves = entries[entryIndex].moves
    else {
      return RestoreResult(
        restoredCount: 0, restoredBytes: 0,
        errors: ["Lịch sử này không có thông tin vị trí trong Trash."])
    }

    let manager = FileManager()
    var restoredCount = 0
    var restoredBytes: Int64 = 0
    var errors: [String] = []
    for index in moves.indices where moves[index].restoredAt == nil {
      let move = moves[index]
      let source = URL(fileURLWithPath: move.trashPath).standardizedFileURL
      let destination = URL(fileURLWithPath: move.originalPath).standardizedFileURL
      guard manager.fileExists(atPath: source.path) else {
        errors.append("\(source.lastPathComponent): không còn trong Trash")
        continue
      }
      guard !manager.fileExists(atPath: destination.path) else {
        errors.append("\(destination.lastPathComponent): vị trí gốc đã có dữ liệu")
        continue
      }
      do {
        try manager.createDirectory(
          at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try manager.moveItem(at: source, to: destination)
        moves[index].restoredAt = Date()
        restoredCount += 1
        restoredBytes += move.bytes
      } catch {
        errors.append("\(destination.lastPathComponent): \(error.localizedDescription)")
      }
    }
    entries[entryIndex].moves = moves
    save(entries)
    return RestoreResult(
      restoredCount: restoredCount, restoredBytes: restoredBytes, errors: errors)
  }

  private func save(_ entries: [CleanupHistoryEntry]) {
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
  @Published var statusMessage: String?
  @Published var errorMessage: String?
  @Published var isRestoring = false
  private let store = HistoryStore()
  func refresh() { entries = store.load() }

  func restore(_ entry: CleanupHistoryEntry) {
    guard !isRestoring, entry.pendingRestoreCount > 0 else { return }
    isRestoring = true
    let store = store
    Task {
      let result = await Task.detached { store.restore(entryID: entry.id) }.value
      statusMessage =
        "Đã khôi phục \(result.restoredCount) mục (\(ByteCount.string(result.restoredBytes)))."
      errorMessage = result.errors.isEmpty ? nil : result.errors.joined(separator: "\n")
      entries = store.load()
      isRestoring = false
    }
  }
}
