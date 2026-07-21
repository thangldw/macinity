import Foundation
import SwiftUI

struct TargetRow: Identifiable {
  let target: CleaningTarget
  var bytes: Int64 = 0
  var issue: String?
  var isSelected: Bool

  var id: String { target.id }
}

@MainActor
final class CleanerViewModel: ObservableObject {
  @Published var rows = CleaningTarget.defaults.map {
    TargetRow(target: $0, isSelected: $0.isSelectedByDefault)
  }
  @Published var isWorking = false
  @Published var hasScanned = false
  @Published var status = "Sẵn sàng quét các tệp có thể dọn dẹp"
  @Published var cleanupSummary: String?
  @Published var errorDetails: String?

  private let service: CleanerService
  private let history = HistoryStore()

  init(service: CleanerService = CleanerService()) {
    self.service = service
  }

  var selectedBytes: Int64 {
    rows.filter(\.isSelected).reduce(0) { $0 + $1.bytes }
  }

  var selectedCount: Int { rows.filter(\.isSelected).count }

  func scan(resetSummary: Bool = true) {
    guard !isWorking else { return }
    isWorking = true
    if resetSummary { cleanupSummary = nil }
    errorDetails = nil
    status = "Đang quét…"
    let targets = rows.map(\.target)

    Task {
      let results = await service.scan(targets: targets)
      for result in results {
        guard let index = rows.firstIndex(where: { $0.id == result.id }) else { continue }
        rows[index].bytes = result.bytes
        rows[index].issue = result.issue
      }
      hasScanned = true
      isWorking = false
      status = "Đã quét xong • Có thể giải phóng \(ByteCount.string(selectedBytes))"
    }
  }

  func cleanSelected() {
    guard !isWorking else { return }
    let selected = rows.filter(\.isSelected).map(\.target)
    guard !selected.isEmpty else { return }
    isWorking = true
    errorDetails = nil
    status = "Đang dọn dẹp…"
    let service = self.service
    let history = self.history

    Task {
      var results: [CleanupResult] = []
      for target in selected {
        results.append(await Task.detached { service.clean(target: target) }.value)
      }
      let reclaimed = results.reduce(Int64(0)) { $0 + $1.reclaimedBytes }
      let removed = results.reduce(0) { $0 + $1.removedItems }
      let errors = results.flatMap { result in
        result.errors.map { "\(result.target.name): \($0)" }
      }
      cleanupSummary = "Đã giải phóng \(ByteCount.string(reclaimed)) từ \(removed) mục."
      if !errors.isEmpty {
        errorDetails = errors.joined(separator: "\n")
      }
      history.record(
        action: "Dọn nhanh", paths: selected.map(\.relativePath), bytes: reclaimed,
        recoverable: false, note: "Đã xóa nội dung cache/log đã xác nhận")
      isWorking = false
      scan(resetSummary: false)
    }
  }
}
