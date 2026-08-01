import Foundation

struct DeepCleanDefinition: Identifiable, Sendable {
  let id: String
  let name: String
  let detail: String
  let relativePath: String
  let confidence: CleanupConfidence
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
        relativePath: ".gradle/caches", confidence: .safe),
      .init(
        id: "swiftpm", name: "SwiftPM Cache", detail: "Cache Swift Package Manager",
        relativePath: "Library/Caches/org.swift.swiftpm", confidence: .safe),
      .init(
        id: "cocoapods", name: "CocoaPods Cache", detail: "Pods có thể tải lại",
        relativePath: "Library/Caches/CocoaPods", confidence: .safe),
      .init(
        id: "homebrew", name: "Homebrew Cache", detail: "Các gói đã tải về",
        relativePath: "Library/Caches/Homebrew", confidence: .safe),
      .init(
        id: "sim-cache", name: "Simulator Cache", detail: "Cache của Xcode Simulator",
        relativePath: "Library/Developer/CoreSimulator/Caches", confidence: .safe),
      .init(
        id: "device-support", name: "iOS Device Support",
        detail: "Có thể cần tải lại khi debug thiết bị cũ",
        relativePath: "Library/Developer/Xcode/iOS DeviceSupport", confidence: .review),
      .init(
        id: "sim-devices", name: "Simulator Devices",
        detail: "Có thể chứa dữ liệu ứng dụng thử nghiệm",
        relativePath: "Library/Developer/CoreSimulator/Devices", confidence: .review),
      .init(
        id: "ios-backups", name: "iPhone/iPad Backups",
        detail: "Có thể là bản sao dữ liệu duy nhất",
        relativePath: "Library/Application Support/MobileSync/Backup", confidence: .review),
      .init(
        id: "docker", name: "Docker Data", detail: "Volume có thể chứa database quan trọng",
        relativePath: "Library/Containers/com.docker.docker/Data", confidence: .dangerous),
      .init(
        id: "nvm", name: "nvm Versions", detail: "Kiểm tra .nvmrc của dự án",
        relativePath: ".nvm/versions", confidence: .dangerous),
      .init(
        id: "pyenv", name: "pyenv Versions", detail: "Kiểm tra .python-version của dự án",
        relativePath: ".pyenv/versions", confidence: .dangerous),
      .init(
        id: "conda", name: "Conda Environments", detail: "Môi trường có thể chứa package riêng",
        relativePath: ".conda/envs", confidence: .dangerous),
    ]
    rows = definitions.map { DeepCleanRow(definition: $0, selected: $0.confidence == .safe) }
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
    let selected = rows.filter { $0.selected && $0.definition.confidence != .dangerous }
    guard !selected.isEmpty else { return }
    isWorking = true
    let service = self.service
    let history = self.history
    Task {
      var affected: Int64 = 0
      var errors: [String] = []
      var paths: [String] = []
      var recoverable = true
      var moves: [TrashMoveRecord] = []
      for row in selected {
        let target = CleaningTarget(
          id: row.id, name: row.definition.name, detail: row.definition.detail,
          relativePath: row.definition.relativePath, symbol: "folder", isSelectedByDefault: false)
        let result = await Task.detached { service.clean(target: target) }.value
        affected += result.affectedBytes
        errors += result.errors
        paths.append(row.definition.relativePath)
        recoverable = recoverable && result.recoverable
        moves += result.moves
      }
      history.record(
        action: "Dọn chuyên sâu", paths: paths, bytes: affected, recoverable: recoverable,
        note: "Đã chuyển nội dung cache/thư mục đã xác nhận vào Trash", moves: moves)
      errorMessage = errors.isEmpty ? nil : errors.joined(separator: "\n")
      isWorking = false
      status = "Đã chuyển \(ByteCount.string(affected)) vào Trash"
      scan()
    }
  }
}
