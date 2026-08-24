import AppKit
import Foundation
import SwiftUI
import ToolboxCore

@MainActor
final class ChangeoraViewModel: ObservableObject {
  @Published private(set) var sessions: [WatchSession]
  @Published private(set) var activeSnapshot: SystemSnapshot?
  @Published private(set) var baselineSnapshot: SystemSnapshot?
  @Published private(set) var adHocSession: WatchSession?
  @Published var selectedSessionID: UUID?
  @Published private(set) var isScanning = false
  @Published private(set) var statusMessage: String?
  @Published var errorMessage: String?

  private let scanner: SystemSnapshotScanner
  private let diffEngine: SnapshotDiffEngine
  private let store: SnapshotStore
  private let eventJournal: FSEventJournal

  init(
    scanner: SystemSnapshotScanner = SystemSnapshotScanner(),
    diffEngine: SnapshotDiffEngine = SnapshotDiffEngine(),
    store: SnapshotStore = SnapshotStore(),
    eventJournal: FSEventJournal = FSEventJournal()
  ) {
    self.scanner = scanner
    self.diffEngine = diffEngine
    self.store = store
    self.eventJournal = eventJournal
    sessions = store.loadSessions().sorted { $0.finishedAt > $1.finishedAt }
    activeSnapshot = store.loadActiveSnapshot()
    baselineSnapshot = store.loadBaseline()
    selectedSessionID = sessions.first?.id
  }

  func reloadFromStore() {
    sessions = store.loadSessions().sorted { $0.finishedAt > $1.finishedAt }
    activeSnapshot = store.loadActiveSnapshot()
    baselineSnapshot = store.loadBaseline()
    selectedSessionID = sessions.first?.id
  }

  var selectedSession: WatchSession? {
    if let selectedSessionID,
      let session = sessions.first(where: { $0.id == selectedSessionID })
    {
      return session
    }
    if let adHocSession, selectedSessionID == adHocSession.id { return adHocSession }
    return sessions.first
  }

  var currentSnapshot: SystemSnapshot? {
    activeSnapshot ?? selectedSession?.comparison.after
  }

  func startWatching() {
    guard activeSnapshot == nil, !isScanning else { return }
    capture(name: "Trước thay đổi") { [weak self] snapshot in
      guard let self else { return }
      do {
        try store.saveActiveSnapshot(snapshot)
        activeSnapshot = snapshot
        eventJournal.start(paths: scanner.monitoredRoots)
        statusMessage =
          "Đã lưu snapshot và bật FSEvents. Hãy cài, cập nhật hoặc gỡ ứng dụng rồi quay lại."
      } catch {
        errorMessage = "Không thể lưu snapshot: \(error.localizedDescription)"
      }
    }
  }

  func finishWatching(title: String) {
    guard let baseline = activeSnapshot, !isScanning else { return }
    let events = eventJournal.stop()
    capture(name: "Sau thay đổi") { [weak self] snapshot in
      guard let self else { return }
      let comparison = diffEngine.compare(
        before: baseline, after: snapshot, events: events,
        categoryForPath: { scanner.category(for: $0) }
      ).compacted()
      let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
      let session = WatchSession(
        title: cleanTitle.isEmpty ? "Phiên thay đổi" : cleanTitle,
        startedAt: baseline.createdAt,
        finishedAt: snapshot.createdAt,
        comparison: comparison,
        events: events
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
          : "Đã phát hiện \(comparison.changes.count) thay đổi từ snapshot và \(events.count) FSEvent."
      } catch {
        errorMessage = "Không thể lưu kết quả: \(error.localizedDescription)"
      }
    }
  }

  func cancelWatching() {
    guard !isScanning else { return }
    do {
      _ = eventJournal.stop()
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

  func createBaseline() {
    guard !isScanning, activeSnapshot == nil else { return }
    capture(name: "Baseline tin cậy") { [weak self] snapshot in
      guard let self else { return }
      do {
        try store.saveBaseline(snapshot)
        baselineSnapshot = snapshot
        statusMessage = "Đã lưu baseline gồm \(snapshot.items.count) mục."
      } catch { errorMessage = "Không thể lưu baseline: \(error.localizedDescription)" }
    }
  }

  func compareWithBaseline() {
    guard let baselineSnapshot, !isScanning, activeSnapshot == nil else { return }
    capture(name: "Trạng thái hiện tại") { [weak self] snapshot in
      guard let self else { return }
      let comparison = diffEngine.compare(before: baselineSnapshot, after: snapshot).compacted()
      let session = WatchSession(
        title: "So sánh với baseline", startedAt: baselineSnapshot.createdAt,
        finishedAt: snapshot.createdAt, comparison: comparison)
      adHocSession = session
      selectedSessionID = session.id
      statusMessage = "Baseline có \(comparison.changes.count) thay đổi."
    }
  }

  func compareSessions(olderID: UUID, newerID: UUID) {
    guard let older = sessions.first(where: { $0.id == olderID }),
      let newer = sessions.first(where: { $0.id == newerID }), older.id != newer.id
    else { return }
    let comparison = diffEngine.compare(
      before: older.comparison.after, after: newer.comparison.after
    ).compacted()
    let session = WatchSession(
      title: "\(older.title) ↔ \(newer.title)", startedAt: older.finishedAt,
      finishedAt: newer.finishedAt, comparison: comparison)
    adHocSession = session
    selectedSessionID = session.id
    statusMessage = "So sánh hai phiên có \(comparison.changes.count) thay đổi."
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
      "# Toolbox Change Timeline report",
      "",
      "- Phiên: \(session.title)",
      "- Bắt đầu: \(session.startedAt.formatted(date: .numeric, time: .standard))",
      "- Kết thúc: \(session.finishedAt.formatted(date: .numeric, time: .standard))",
      "- Tổng thay đổi: \(comparison.changes.count)",
      "- Quan trọng: \(comparison.importantCount)",
      "- FSEvents: \(session.events?.count ?? 0)",
      "- Privacy: đường dẫn trong home đã được thay bằng `~`.",
      "",
      "| Mức | Thay đổi | Loại | Tên | Đường dẫn | Attribution | Lý do |",
      "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    lines += comparison.changes.map { change in
      let item = change.item
      return
        "| \(change.risk.title) | \(change.kind.rawValue) | \(item.category.rawValue) | \(escape(item.name)) | `\(escape(redact(item.path)))` | \(escape(change.attributedApplication ?? item.ownerHint ?? "—")) | \(escape(change.riskReason ?? "—")) |"
    }
    lines.append("")
    lines.append("Generated locally by Toolbox \(AppMetadata.version).")
    return lines.joined(separator: "\n")
  }

  func jsonReport(for session: WatchSession) throws -> String {
    let payload: [String: Any] = [
      "title": session.title,
      "startedAt": session.startedAt.ISO8601Format(),
      "finishedAt": session.finishedAt.ISO8601Format(),
      "eventCount": session.events?.count ?? 0,
      "changes": session.comparison.changes.map { change in
        [
          "risk": change.risk.title,
          "kind": change.kind.rawValue,
          "category": change.item.category.rawValue,
          "name": change.item.name,
          "path": redact(change.item.path),
          "attribution": change.attributedApplication ?? NSNull(),
          "reason": change.riskReason ?? NSNull(),
        ] as [String: Any]
      },
    ]
    let data = try JSONSerialization.data(
      withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    return String(decoding: data, as: UTF8.self)
  }

  private func capture(
    name: String,
    completion: @escaping @MainActor (SystemSnapshot) -> Void
  ) {
    isScanning = true
    ScanActivityRegistry.shared.begin()
    statusMessage = "Đang chụp trạng thái hệ thống…"
    errorMessage = nil
    let scanner = scanner
    Task {
      let snapshot = await Task.detached(priority: .userInitiated) {
        scanner.capture(name: name)
      }.value
      ScanActivityRegistry.shared.end()
      isScanning = false
      completion(snapshot)
    }
  }

  private func escape(_ value: String) -> String {
    value.replacingOccurrences(of: "|", with: "\\|")
      .replacingOccurrences(of: "\n", with: " ")
  }

  private func redact(_ path: String) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
    if path == home { return "~" }
    if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
    return path
  }
}
