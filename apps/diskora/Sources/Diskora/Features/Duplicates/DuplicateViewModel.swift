import AppKit
import Foundation
import SwiftUI

@MainActor
final class DuplicateViewModel: ObservableObject {
  @Published var rootURL = FileManager.default.homeDirectoryForCurrentUser
  @Published var snapshot: DuplicateSnapshot?
  @Published var selectedPaths: Set<String> = []
  @Published var isWorking = false
  @Published var status = "Chọn Quét tệp trùng lặp để bắt đầu"
  @Published var summary: String?
  @Published var errorMessage: String?
  @Published var lastReportURL: URL?

  private let scanner = DuplicateScanner()
  private let history = HistoryStore()
  private var task: Task<Void, Never>?

  var selectedFiles: [DuplicateFile] {
    snapshot?.groups.flatMap(\.files).filter { selectedPaths.contains($0.url.path) } ?? []
  }

  var selectedBytes: Int64 { selectedFiles.reduce(0) { $0 + $1.bytes } }

  func isSelected(_ file: DuplicateFile) -> Binding<Bool> {
    Binding(
      get: { self.selectedPaths.contains(file.url.path) },
      set: { selected in
        if selected {
          self.selectedPaths.insert(file.url.path)
        } else {
          self.selectedPaths.remove(file.url.path)
        }
      }
    )
  }

  func chooseRoot() {
    let panel = NSOpenPanel()
    panel.title = "Chọn nơi tìm tệp trùng lặp"
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.directoryURL = rootURL
    if panel.runModal() == .OK, let url = panel.url {
      rootURL = url
      snapshot = nil
      selectedPaths = []
      summary = nil
      status = "Sẵn sàng quét \(url.path)"
    }
  }

  func scan(preserveSummary: Bool = false) {
    task?.cancel()
    isWorking = true
    errorMessage = nil
    if !preserveSummary { summary = nil }
    selectedPaths = []
    status = "Đang nhóm theo kích thước và kiểm tra nội dung…"
    let scanner = self.scanner
    let root = rootURL
    task = Task {
      do {
        let result = try await Task.detached(priority: .userInitiated) {
          try scanner.scan(rootURL: root)
        }.value
        snapshot = result
        status =
          "Tìm thấy \(result.groups.count) nhóm • Có thể giải phóng \(ByteCount.string(result.reclaimableBytes))"
      } catch is CancellationError {
        status = "Đã dừng quét"
      } catch {
        errorMessage = error.localizedDescription
        status = "Không thể hoàn tất quá trình quét"
      }
      isWorking = false
    }
  }

  func cancel() { task?.cancel() }

  func selectRecommendedCopies() {
    selectedPaths = Set(snapshot?.groups.flatMap { $0.files.dropFirst().map { $0.url.path } } ?? [])
  }

  func clearSelection() { selectedPaths = [] }

  func trashSelected() {
    let files = selectedFiles
    guard !files.isEmpty else { return }
    isWorking = true
    let scanner = self.scanner
    let root = rootURL
    let originalPairs: [(String, String)] = (snapshot?.groups ?? []).flatMap {
      group -> [(String, String)] in
      guard let original = group.files.first?.url.path else { return [] }
      return group.files.dropFirst().map { ($0.url.path, original) }
    }
    let originals = Dictionary(uniqueKeysWithValues: originalPairs)
    let history = self.history
    Task {
      let result = await Task.detached {
        scanner.moveToTrash(files: files, retainedOriginalByPath: originals, within: root)
      }.value
      summary =
        "Đã chuyển \(result.movedCount) tệp (\(ByteCount.string(result.movedBytes))) vào Trash."
      history.record(
        action: "Loại tệp trùng lặp", paths: files.map { $0.url.path }, bytes: result.movedBytes,
        recoverable: true,
        note: "Bản sao đã chuyển vào Trash; báo cáo: \(result.reportURL?.path ?? "không có")")
      lastReportURL = result.reportURL
      if !result.errors.isEmpty { errorMessage = result.errors.joined(separator: "\n") }
      isWorking = false
      scan(preserveSummary: true)
    }
  }

  func reveal(_ url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
}
