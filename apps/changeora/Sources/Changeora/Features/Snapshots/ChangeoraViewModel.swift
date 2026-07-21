import AppKit
import Foundation
import SwiftUI

@MainActor
final class ChangeoraViewModel: ObservableObject {
  @Published private(set) var sessions: [WatchSession]
  @Published private(set) var activeSnapshot: SystemSnapshot?
  @Published var selectedSessionID: UUID?
  @Published private(set) var isScanning = false
  @Published private(set) var statusMessage: String?
  @Published var errorMessage: String?

  private let scanner: SystemSnapshotScanner
  private let diffEngine: SnapshotDiffEngine
  private let store: SnapshotStore

  init(
    scanner: SystemSnapshotScanner = SystemSnapshotScanner(),
    diffEngine: SnapshotDiffEngine = SnapshotDiffEngine(),
    store: SnapshotStore = SnapshotStore()
  ) {
    self.scanner = scanner
    self.diffEngine = diffEngine
    self.store = store
    sessions = store.loadSessions().sorted { $0.finishedAt > $1.finishedAt }
    activeSnapshot = store.loadActiveSnapshot()
    selectedSessionID = sessions.first?.id
  }

  var selectedSession: WatchSession? {
    if let selectedSessionID,
      let session = sessions.first(where: { $0.id == selectedSessionID })
    {
      return session
    }
    return sessions.first
  }

  var currentSnapshot: SystemSnapshot? {
    activeSnapshot ?? selectedSession?.comparison.after
  }

  func startWatching() {
    guard activeSnapshot == nil, !isScanning else { return }
    capture(name: "Trước khi cài đặt") { [weak self] snapshot in
      guard let self else { return }
      do {
        try store.saveActiveSnapshot(snapshot)
        activeSnapshot = snapshot
        statusMessage = "Đã lưu trạng thái ban đầu. Hãy cài hoặc cập nhật ứng dụng rồi quay lại."
      } catch {
        errorMessage = "Không thể lưu snapshot: \(error.localizedDescription)"
      }
    }
  }

  func finishWatching(title: String) {
    guard let baseline = activeSnapshot, !isScanning else { return }
    capture(name: "Sau khi cài đặt") { [weak self] snapshot in
      guard let self else { return }
      let comparison = diffEngine.compare(before: baseline, after: snapshot).compacted()
      let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
      let session = WatchSession(
        title: cleanTitle.isEmpty ? "Phiên thay đổi" : cleanTitle,
        startedAt: baseline.createdAt,
        finishedAt: snapshot.createdAt,
        comparison: comparison
      )
      sessions.insert(session, at: 0)
      if sessions.count > 100 { sessions.removeLast(sessions.count - 100) }
      selectedSessionID = session.id
      activeSnapshot = nil
      do {
        try store.saveSessions(sessions)
        try store.clearActiveSnapshot()
        statusMessage =
          comparison.changes.isEmpty
          ? "Không phát hiện thay đổi trong phạm vi theo dõi."
          : "Đã phát hiện \(comparison.changes.count) thay đổi."
      } catch {
        errorMessage = "Không thể lưu kết quả: \(error.localizedDescription)"
      }
    }
  }

  func cancelWatching() {
    guard !isScanning else { return }
    do {
      try store.clearActiveSnapshot()
      activeSnapshot = nil
      statusMessage = "Đã hủy phiên theo dõi."
    } catch {
      errorMessage = "Không thể hủy phiên: \(error.localizedDescription)"
    }
  }

  func select(_ session: WatchSession) {
    selectedSessionID = session.id
  }

  func reveal(_ item: SnapshotItem) {
    let url = URL(fileURLWithPath: item.path)
    if FileManager.default.fileExists(atPath: item.path) {
      NSWorkspace.shared.activateFileViewerSelecting([url])
    } else {
      NSWorkspace.shared.selectFile(
        nil, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
  }

  func markdownReport(for session: WatchSession) -> String {
    let comparison = session.comparison
    var lines = [
      "# Changeora report",
      "",
      "- Phiên: \(session.title)",
      "- Bắt đầu: \(session.startedAt.formatted(date: .numeric, time: .standard))",
      "- Kết thúc: \(session.finishedAt.formatted(date: .numeric, time: .standard))",
      "- Tổng thay đổi: \(comparison.changes.count)",
      "- Quan trọng: \(comparison.importantCount)",
      "",
      "| Mức | Thay đổi | Loại | Tên | Đường dẫn | Chủ sở hữu gợi ý |",
      "| --- | --- | --- | --- | --- | --- |",
    ]
    lines += comparison.changes.map { change in
      let item = change.item
      return
        "| \(change.risk.title) | \(change.kind.rawValue) | \(item.category.rawValue) | \(escape(item.name)) | `\(escape(item.path))` | \(escape(item.ownerHint ?? "—")) |"
    }
    lines.append("")
    lines.append("Generated locally by Changeora \(AppMetadata.version).")
    return lines.joined(separator: "\n")
  }

  private func capture(
    name: String,
    completion: @escaping @MainActor (SystemSnapshot) -> Void
  ) {
    isScanning = true
    statusMessage = "Đang chụp trạng thái hệ thống…"
    errorMessage = nil
    let scanner = scanner
    Task {
      let snapshot = await Task.detached(priority: .userInitiated) {
        scanner.capture(name: name)
      }.value
      isScanning = false
      completion(snapshot)
    }
  }

  private func escape(_ value: String) -> String {
    value.replacingOccurrences(of: "|", with: "\\|")
      .replacingOccurrences(of: "\n", with: " ")
  }
}
