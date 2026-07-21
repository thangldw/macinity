import AppKit
import Foundation
import SwiftUI

@MainActor
final class SimilarPhotoViewModel: ObservableObject {
  @Published var rootURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
    "Pictures")
  @Published var snapshot: SimilarPhotoSnapshot?
  @Published var selectedPaths: Set<String> = []
  @Published var isWorking = false
  @Published var status = "Chọn thư mục ảnh để bắt đầu"
  @Published var errorMessage: String?
  private let scanner = SimilarPhotoScanner()
  private let history = HistoryStore()
  private var task: Task<Void, Never>?

  var selectedBytes: Int64 {
    snapshot?.groups.flatMap(\.photos).filter { selectedPaths.contains($0.id) }.reduce(0) {
      $0 + $1.bytes
    } ?? 0
  }

  func chooseRoot() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.directoryURL = rootURL
    if panel.runModal() == .OK, let url = panel.url {
      rootURL = url
      snapshot = nil
      selectedPaths = []
    }
  }

  func scan() {
    task?.cancel()
    isWorking = true
    errorMessage = nil
    selectedPaths = []
    status = "Đang phân tích đặc trưng hình ảnh bằng Vision…"
    let scanner = self.scanner
    let root = rootURL
    task = Task {
      do {
        snapshot = try await Task.detached(priority: .userInitiated) {
          try scanner.scan(rootURL: root)
        }.value
        status = "Tìm thấy \(snapshot?.groups.count ?? 0) chuỗi ảnh tương tự"
      } catch is CancellationError { status = "Đã dừng quét" } catch {
        errorMessage = error.localizedDescription
        status = "Không thể quét ảnh"
      }
      isWorking = false
    }
  }

  func selectSuggestions() {
    selectedPaths = Set(
      snapshot?.groups.flatMap { group in
        group.photos.filter { $0.id != group.recommendedID }.map(\.id)
      } ?? [])
  }
  func toggle(_ photo: SimilarPhoto) -> Binding<Bool> {
    Binding(
      get: { self.selectedPaths.contains(photo.id) },
      set: { selected in
        if selected {
          self.selectedPaths.insert(photo.id)
        } else {
          self.selectedPaths.remove(photo.id)
        }
      })
  }
  func cancel() { task?.cancel() }
  func reveal(_ url: URL) { NSWorkspace.shared.activateFileViewerSelecting([url]) }

  func trashSelected() {
    let root = rootURL.resolvingSymlinksInPath().path + "/"
    let photos = snapshot?.groups.flatMap(\.photos).filter { selectedPaths.contains($0.id) } ?? []
    let history = self.history
    isWorking = true
    Task {
      let errors = await Task.detached {
        var errors: [String] = []
        for photo in photos {
          let url = photo.url.resolvingSymlinksInPath()
          guard url.path.hasPrefix(root) else {
            errors.append("Đường dẫn không an toàn: \(url.path)")
            continue
          }
          do { try FileManager.default.trashItem(at: url, resultingItemURL: nil) } catch {
            errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
          }
        }
        return errors
      }.value
      errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
      let moved = photos.filter { photo in !FileManager.default.fileExists(atPath: photo.url.path) }
      history.record(
        action: "Loại ảnh tương tự", paths: moved.map { $0.url.path },
        bytes: moved.reduce(0) { $0 + $1.bytes }, recoverable: true,
        note: "Ảnh đã chuyển vào Trash sau khi người dùng duyệt")
      isWorking = false
      scan()
    }
  }
}
