import AppKit
import Foundation

@MainActor
final class AnalyzerViewModel: ObservableObject {
  @Published var rootURL = FileManager.default.homeDirectoryForCurrentUser
  @Published var snapshot: StorageSnapshot?
  @Published var isScanning = false
  @Published var status = "Chọn Quét dung lượng để bắt đầu"
  @Published var errorMessage: String?
  @Published var folderDeltas: [StorageDelta] = []

  private var scanTask: Task<Void, Never>?
  private let analyzer = StorageAnalyzer()
  private let trendStore = StorageTrendStore()

  func chooseRoot() {
    let panel = NSOpenPanel()
    panel.title = "Chọn thư mục hoặc ổ đĩa cần phân tích"
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.directoryURL = rootURL
    if panel.runModal() == .OK, let url = panel.url {
      rootURL = url
      snapshot = nil
      status = "Sẵn sàng quét \(url.path)"
    }
  }

  func scan() {
    scanTask?.cancel()
    isScanning = true
    errorMessage = nil
    status = "Đang phân tích \(rootURL.path)…"
    let analyzer = self.analyzer
    let root = rootURL
    scanTask = Task {
      do {
        let result = try await Task.detached(priority: .userInitiated) {
          try analyzer.scan(rootURL: root)
        }.value
        snapshot = result
        folderDeltas = trendStore.compareAndSave(result)
        status =
          "Đã quét \(result.fileCount.formatted()) tệp • \(ByteCount.string(result.scannedBytes))"
      } catch is CancellationError {
        status = "Đã dừng quét"
      } catch {
        errorMessage = error.localizedDescription
        status = "Không thể hoàn tất quá trình quét"
      }
      isScanning = false
    }
  }

  func cancel() {
    scanTask?.cancel()
  }

  func reveal(_ url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
}
