import Foundation

enum CleanupRisk: String, CaseIterable, Sendable {
  case safe = "An toàn"
  case review = "Cần xem lại"
  case dangerous = "Không xóa tự động"

  var symbol: String {
    self == .safe
      ? "checkmark.shield" : self == .review ? "exclamationmark.triangle" : "hand.raised"
  }
}

struct DeepCleanDefinition: Identifiable, Sendable {
  let id: String
  let name: String
  let detail: String
  let relativePath: String
  let risk: CleanupRisk
}

struct DeepCleanRow: Identifiable {
  let definition: DeepCleanDefinition
  var bytes: Int64 = 0
  var selected = false
  var id: String { definition.id }
}

@MainActor
final class DeepCleanViewModel: ObservableObject {
  @Published var rows: [DeepCleanRow]
  @Published var isWorking = false
  @Published var status = "Sẵn sàng quét chuyên sâu"
  @Published var errorMessage: String?
  private let service = CleanerService()
  private let history = HistoryStore()

  init() {
    let definitions: [DeepCleanDefinition] = [
      .init(
        id: "gradle", name: "Gradle Cache", detail: "Dependency và distribution có thể tải lại",
        relativePath: ".gradle/caches", risk: .safe),
      .init(
        id: "swiftpm", name: "SwiftPM Cache", detail: "Cache Swift Package Manager",
        relativePath: "Library/Caches/org.swift.swiftpm", risk: .safe),
      .init(
        id: "cocoapods", name: "CocoaPods Cache", detail: "Pods có thể tải lại",
        relativePath: "Library/Caches/CocoaPods", risk: .safe),
      .init(
        id: "homebrew", name: "Homebrew Cache", detail: "Các gói đã tải về",
        relativePath: "Library/Caches/Homebrew", risk: .safe),
      .init(
        id: "sim-cache", name: "Simulator Cache", detail: "Cache của Xcode Simulator",
        relativePath: "Library/Developer/CoreSimulator/Caches", risk: .safe),
      .init(
        id: "device-support", name: "iOS Device Support",
        detail: "Có thể cần tải lại khi debug thiết bị cũ",
        relativePath: "Library/Developer/Xcode/iOS DeviceSupport", risk: .review),
      .init(
        id: "sim-devices", name: "Simulator Devices",
        detail: "Có thể chứa dữ liệu ứng dụng thử nghiệm",
        relativePath: "Library/Developer/CoreSimulator/Devices", risk: .review),
      .init(
        id: "ios-backups", name: "iPhone/iPad Backups",
        detail: "Có thể là bản sao dữ liệu duy nhất",
        relativePath: "Library/Application Support/MobileSync/Backup", risk: .review),
      .init(
        id: "docker", name: "Docker Data", detail: "Volume có thể chứa database quan trọng",
        relativePath: "Library/Containers/com.docker.docker/Data", risk: .dangerous),
      .init(
        id: "nvm", name: "nvm Versions", detail: "Kiểm tra .nvmrc của dự án",
        relativePath: ".nvm/versions", risk: .dangerous),
      .init(
        id: "pyenv", name: "pyenv Versions", detail: "Kiểm tra .python-version của dự án",
        relativePath: ".pyenv/versions", risk: .dangerous),
      .init(
        id: "conda", name: "Conda Environments", detail: "Môi trường có thể chứa package riêng",
        relativePath: ".conda/envs", risk: .dangerous),
    ]
    rows = definitions.map { DeepCleanRow(definition: $0, selected: $0.risk == .safe) }
  }

  var selectedBytes: Int64 { rows.filter(\.selected).reduce(0) { $0 + $1.bytes } }

  func scan() {
    isWorking = true
    status = "Đang quét dữ liệu chuyên sâu…"
    errorMessage = nil
    let targets = rows.map {
      CleaningTarget(
        id: $0.id, name: $0.definition.name, detail: $0.definition.detail,
        relativePath: $0.definition.relativePath, symbol: "folder", isSelectedByDefault: false)
    }
    Task {
      let results = await service.scan(targets: targets)
      for result in results {
        if let i = rows.firstIndex(where: { $0.id == result.id }) { rows[i].bytes = result.bytes }
      }
      isWorking = false
      status = "Có thể xem xét \(ByteCount.string(rows.reduce(0) { $0 + $1.bytes }))"
    }
  }

  func cleanSelected() {
    let selected = rows.filter { $0.selected && $0.definition.risk != .dangerous }
    guard !selected.isEmpty else { return }
    isWorking = true
    let service = self.service
    let history = self.history
    Task {
      var reclaimed: Int64 = 0
      var errors: [String] = []
      var paths: [String] = []
      for row in selected {
        let target = CleaningTarget(
          id: row.id, name: row.definition.name, detail: row.definition.detail,
          relativePath: row.definition.relativePath, symbol: "folder", isSelectedByDefault: false)
        let result = await Task.detached { service.clean(target: target) }.value
        reclaimed += result.reclaimedBytes
        errors += result.errors
        paths.append(row.definition.relativePath)
      }
      history.record(
        action: "Dọn chuyên sâu", paths: paths, bytes: reclaimed, recoverable: false,
        note: "Đã xóa nội dung cache/thư mục đã xác nhận")
      errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
      isWorking = false
      status = "Đã giải phóng \(ByteCount.string(reclaimed))"
      scan()
    }
  }
}
