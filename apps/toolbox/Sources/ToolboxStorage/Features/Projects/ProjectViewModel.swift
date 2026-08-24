import Foundation
import SwiftUI
import ToolboxCore

@MainActor
final class ProjectViewModel: ObservableObject {
  @Published private(set) var roots: [URL] = []
  @Published private(set) var report: ProjectScanReport?
  @Published var selectedIDs = Set<String>()
  @Published private(set) var isWorking = false
  @Published private(set) var status = "Chọn project root để bắt đầu."
  @Published var errorMessage: String?

  private let scanner: ProjectScanner
  private let evidenceStore: EvidenceStore
  private let activityLedger: ActivityLedger
  private let historyStore: HistoryStore
  private let cleanupService: ProjectCleanupService
  private var scanTask: Task<Void, Never>?

  init(
    scanner: ProjectScanner = ProjectScanner(), evidenceStore: EvidenceStore = EvidenceStore(),
    activityLedger: ActivityLedger = ActivityLedger(), historyStore: HistoryStore = HistoryStore(),
    cleanupService: ProjectCleanupService = ProjectCleanupService()
  ) {
    self.scanner = scanner
    self.evidenceStore = evidenceStore
    self.activityLedger = activityLedger
    self.historyStore = historyStore
    self.cleanupService = cleanupService
  }

  var selectedArtifacts: [ProjectArtifact] {
    (report?.artifacts ?? []).filter { selectedIDs.contains($0.id) && $0.safety == .safe }
  }

  var selectedBytes: Int64 { selectedArtifacts.reduce(0) { $0 + $1.bytes } }

  func addRoots(_ urls: [URL]) {
    roots = Array(Set(roots + urls.map { $0.resolvingSymlinksInPath().standardizedFileURL }))
      .sorted { $0.path < $1.path }
    report = nil
    selectedIDs.removeAll()
    status = "Đã chọn \(roots.count) project root."
  }

  func removeRoot(_ url: URL) {
    roots.removeAll { $0 == url }
    report = nil
    selectedIDs.removeAll()
    status = roots.isEmpty ? "Chọn project root để bắt đầu." : "Đã cập nhật phạm vi quét."
  }

  func scan() {
    guard !roots.isEmpty, !isWorking else { return }
    isWorking = true
    errorMessage = nil
    selectedIDs.removeAll()
    status = "Đang tìm artifact có thể tạo lại…"
    ScanActivityRegistry.shared.begin()
    let roots = roots
    let scanner = scanner
    let evidenceStore = evidenceStore

    scanTask = Task {
      let result = await scanner.scan(roots: roots)
      guard !Task.isCancelled else {
        ScanActivityRegistry.shared.end()
        isWorking = false
        status = "Đã hủy quét."
        return
      }
      report = result
      selectedIDs = Set(result.artifacts.filter { $0.safety == .safe }.map(\.id))
      for artifact in result.artifacts {
        do {
          try evidenceStore.upsert(
            EvidenceRecord(
              path: artifact.artifactURL.path, kind: .projectArtifact,
              safety: artifact.safety, reasons: artifact.reasons, observedAt: Date()))
        } catch {
          errorMessage = "Không thể lưu evidence: \(error.localizedDescription)"
        }
      }
      ScanActivityRegistry.shared.end()
      isWorking = false
      status =
        result.cancelled
        ? "Đã hủy quét với kết quả một phần."
        : "Tìm thấy \(result.artifacts.count) artifact trong \(result.scannedProjectCount) project."
    }
  }

  func cancel() {
    scanTask?.cancel()
    scanTask = nil
  }

  func cleanSelected() {
    let artifacts = selectedArtifacts
    guard !artifacts.isEmpty, !isWorking else { return }
    isWorking = true
    errorMessage = nil
    status = "Đang chuyển artifact đã xác nhận vào Trash…"
    let roots = roots
    let cleanupService = cleanupService
    let historyStore = historyStore
    let activityLedger = activityLedger

    Task {
      let outcomes = await Task.detached(priority: .userInitiated) {
        artifacts.map { cleanupService.moveToTrash($0, allowedRoots: roots) }
      }.value
      let moves = outcomes.compactMap(\.move)
      let affectedBytes = outcomes.reduce(Int64(0)) { $0 + $1.affectedBytes }
      let errors = outcomes.compactMap(\.error)
      let successfulPaths = outcomes.filter { $0.error == nil }.map { $0.artifact.artifactURL.path }
      let fullyRecoverable = !successfulPaths.isEmpty && moves.count == successfulPaths.count

      if !moves.isEmpty {
        historyStore.record(
          action: "Dọn artifact dự án", paths: successfulPaths, bytes: affectedBytes,
          recoverable: true, note: "Artifact đã xác nhận được chuyển nguyên thư mục vào Trash",
          moves: moves)
      }
      do {
        try activityLedger.append(
          ActivityEntry(
            kind: .cleanup, status: errors.isEmpty ? .succeeded : .failed,
            paths: artifacts.map { $0.artifactURL.path }, affectedBytes: affectedBytes,
            recoverable: fullyRecoverable, errors: errors))
      } catch {
        errorMessage = "Không thể ghi activity: \(error.localizedDescription)"
      }
      if !errors.isEmpty {
        errorMessage = errors.joined(separator: "\n")
      }
      selectedIDs.removeAll()
      isWorking = false
      if errors.isEmpty {
        status = "Đã chuyển \(ByteCount.string(affectedBytes)) vào Trash."
      } else if affectedBytes > 0 {
        status = "Đã chuyển \(ByteCount.string(affectedBytes)); \(errors.count) mục thất bại."
      } else {
        status = "Không thể chuyển artifact đã chọn vào Trash."
      }
      scan()
    }
  }
}
