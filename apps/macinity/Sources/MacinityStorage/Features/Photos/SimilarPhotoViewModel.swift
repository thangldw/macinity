import AppKit
import Foundation
import MacinityCore
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
    ScanActivityRegistry.shared.begin()
    let scanner = self.scanner
    let root = rootURL
    task = Task {
      do {
        snapshot = try await CancellableWork.run { try scanner.scan(rootURL: root) }
        status = "Tìm thấy \(snapshot?.groups.count ?? 0) chuỗi ảnh tương tự"
      } catch is CancellationError { status = "Đã dừng quét" } catch {
        errorMessage = error.localizedDescription
        status = "Không thể quét ảnh"
      }
      ScanActivityRegistry.shared.end()
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
    let photos = snapshot?.groups.flatMap(\.photos).filter { selectedPaths.contains($0.id) } ?? []
    let root = rootURL
    isWorking = true
    Task {
      let errors = await PhotoTrashService().trash(
        photos: photos, root: root, note: "Ảnh đã chuyển vào Trash sau khi người dùng duyệt")
      errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
      isWorking = false
      scan()
    }
  }
}
