import Foundation
import SwiftUI
import ToolboxCore

@MainActor
final class InstallTraceCoordinator: ObservableObject {
  @Published private(set) var activeMetadata: InstallerMetadata?
  @Published private(set) var recoveryState: InterruptedTraceRecovery
  @Published private(set) var isWorking = false
  @Published private(set) var statusMessage: String?
  @Published private(set) var reducedCoverage = false
  @Published private(set) var startedAt: Date?

  private let scanner: SystemSnapshotScanner
  private let diffEngine: SnapshotDiffEngine
  private let store: SnapshotStore
  private let eventJournal: FSEventJournal
  private let evidenceStore: EvidenceStore
  private let activityLedger: ActivityLedger

  init(
    scanner: SystemSnapshotScanner = SystemSnapshotScanner(),
    diffEngine: SnapshotDiffEngine = SnapshotDiffEngine(), store: SnapshotStore = SnapshotStore(),
    eventJournal: FSEventJournal = FSEventJournal(), evidenceStore: EvidenceStore? = nil,
    activityLedger: ActivityLedger? = nil
  ) {
    self.scanner = scanner
    self.diffEngine = diffEngine
    self.store = store
    self.eventJournal = eventJournal
    self.evidenceStore = evidenceStore ?? EvidenceStore(directory: store.directoryURL)
    self.activityLedger = activityLedger ?? ActivityLedger(directory: store.directoryURL)
    activeMetadata = store.loadActiveTraceMetadata()
    let activeSnapshot = store.loadActiveSnapshot()
    recoveryState = activeSnapshot == nil ? .none : .interrupted(reducedCoverage: true)
    reducedCoverage = activeSnapshot != nil
    startedAt = activeSnapshot?.createdAt
  }

  static func previewOnly() -> InstallTraceCoordinator {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("toolbox-install-trace-preview-\(UUID().uuidString)")
    return InstallTraceCoordinator(store: SnapshotStore(directory: directory))
  }

  func accept(url: URL) throws -> InstallerMetadata {
    let normalized = url.standardizedFileURL
    let kind: InstallerKind =
      switch normalized.pathExtension.lowercased() {
      case "dmg": .diskImage
      case "pkg": .installerPackage
      case "app": .applicationBundle
      default: throw InstallTraceError.unsupportedType(normalized.path)
      }
    return InstallerMetadata(
      sourceURL: normalized,
      displayName: normalized.deletingPathExtension().lastPathComponent,
      kind: kind,
      observedAt: Date())
  }

  func start(metadata: InstallerMetadata) async throws {
    guard store.loadActiveSnapshot() == nil, activeMetadata == nil else {
      throw InstallTraceError.traceAlreadyActive
    }
    isWorking = true
    statusMessage = "Đang chụp trạng thái trước khi mở installer…"
    defer { isWorking = false }

    let scanner = scanner
    let before = await Task.detached(priority: .userInitiated) {
      scanner.capture(name: "Trước Install Trace")
    }.value
    try store.saveActiveSnapshot(before)
    do {
      try store.saveActiveTraceMetadata(metadata)
    } catch {
      try? store.clearActiveSnapshot()
      throw error
    }
    eventJournal.start(paths: scanner.monitoredRoots)
    activeMetadata = metadata
    startedAt = before.createdAt
    recoveryState = .none
    reducedCoverage = false
    statusMessage = "Baseline đã lưu. macOS có thể mở installer an toàn."
  }

  func resumeInterruptedTrace() throws {
    guard store.loadActiveSnapshot() != nil else { throw InstallTraceError.noActiveTrace }
    eventJournal.start(paths: scanner.monitoredRoots)
    activeMetadata = store.loadActiveTraceMetadata()
    startedAt = store.loadActiveSnapshot()?.createdAt
    recoveryState = .none
    reducedCoverage = true
    statusMessage = "Đã tiếp tục theo dõi; thời gian app không chạy có coverage giảm."
  }

  func finish(title: String) async throws -> WatchSession {
    guard let before = store.loadActiveSnapshot() else { throw InstallTraceError.noActiveTrace }
    isWorking = true
    statusMessage = "Đang chụp trạng thái sau thay đổi…"
    let events = eventJournal.stop()
    defer { isWorking = false }

    let scanner = scanner
    let after = await Task.detached(priority: .userInitiated) {
      scanner.capture(name: "Sau Install Trace")
    }.value
    let comparison = diffEngine.compare(
      before: before, after: after, events: events,
      categoryForPath: { scanner.category(for: $0) }
    ).compacted()
    let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let session = WatchSession(
      title: cleanTitle.isEmpty ? activeMetadata?.displayName ?? "Install Trace" : cleanTitle,
      startedAt: before.createdAt, finishedAt: after.createdAt, comparison: comparison,
      events: events)

    var sessions = store.loadSessions()
    sessions.removeAll { $0.id == session.id }
    sessions.insert(session, at: 0)
    if sessions.count > 100 { sessions.removeLast(sessions.count - 100) }
    try store.saveSessions(sessions)
    try store.clearActiveSnapshot()
    try store.clearActiveTraceMetadata()

    var evidenceErrors: [String] = []
    for change in comparison.changes {
      do {
        try evidenceStore.upsert(
          EvidenceRecord(
            path: change.item.path, kind: .traceChange, safety: safety(for: change.risk),
            reasons: [change.riskReason ?? "Install Trace change"],
            observedAt: after.createdAt))
      } catch {
        evidenceErrors.append(error.localizedDescription)
      }
    }
    try? activityLedger.append(
      ActivityEntry(
        kind: .trace, status: evidenceErrors.isEmpty ? .succeeded : .failed,
        occurredAt: after.createdAt, paths: comparison.changes.map { $0.item.path },
        affectedBytes: comparison.changes.reduce(0) { $0 + $1.item.size }, recoverable: false,
        errors: evidenceErrors))

    activeMetadata = nil
    startedAt = nil
    recoveryState = .none
    reducedCoverage = false
    statusMessage = "Install Trace đã lưu \(comparison.changes.count) thay đổi."
    return session
  }

  func cancel() throws {
    _ = eventJournal.stop()
    try store.clearActiveSnapshot()
    try store.clearActiveTraceMetadata()
    try? activityLedger.append(
      ActivityEntry(
        kind: .trace, status: .cancelled, paths: activeMetadata.map { [$0.sourceURL.path] } ?? [],
        affectedBytes: 0, recoverable: false, errors: []))
    activeMetadata = nil
    startedAt = nil
    recoveryState = .none
    reducedCoverage = false
    statusMessage = "Đã hủy Install Trace."
  }

  private func safety(for risk: ChangeRisk) -> SafetyLevel {
    switch risk {
    case .informational: .safe
    case .review: .review
    case .important: .protected
    }
  }
}
