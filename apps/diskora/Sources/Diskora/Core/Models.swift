import Foundation

enum CleanupConfidence: String, Codable, CaseIterable, Comparable, Sendable {
  case safe
  case review
  case dangerous

  static func < (lhs: CleanupConfidence, rhs: CleanupConfidence) -> Bool {
    lhs.rank < rhs.rank
  }

  var rank: Int {
    switch self {
    case .safe: 0
    case .review: 1
    case .dangerous: 2
    }
  }

  var title: String {
    switch self {
    case .safe: "An toàn"
    case .review: "Cần xem lại"
    case .dangerous: "Nguy hiểm"
    }
  }

  var symbol: String {
    switch self {
    case .safe: "checkmark.shield"
    case .review: "exclamationmark.triangle"
    case .dangerous: "hand.raised"
    }
  }
}

struct TrashMoveRecord: Codable, Identifiable, Hashable, Sendable {
  let id: UUID
  let originalPath: String
  let trashPath: String
  let bytes: Int64
  var restoredAt: Date?

  init(
    id: UUID = UUID(), originalPath: String, trashPath: String, bytes: Int64,
    restoredAt: Date? = nil
  ) {
    self.id = id
    self.originalPath = originalPath
    self.trashPath = trashPath
    self.bytes = bytes
    self.restoredAt = restoredAt
  }
}

struct CleaningTarget: Identifiable, Hashable, Sendable {
  let id: String
  let name: String
  let detail: String
  let relativePath: String
  let symbol: String
  let isSelectedByDefault: Bool
  var confidence: CleanupConfidence = .safe
  var confidenceReason: String = "Dữ liệu có thể tạo lại và được chuyển vào Trash."

  static let defaults: [CleaningTarget] = [
    .init(
      id: "user-caches", name: "Bộ nhớ đệm", detail: "Dữ liệu tạm của các ứng dụng",
      relativePath: "Library/Caches", symbol: "shippingbox", isSelectedByDefault: true),
    .init(
      id: "user-logs", name: "Nhật ký ứng dụng", detail: "Các tệp log trong tài khoản người dùng",
      relativePath: "Library/Logs", symbol: "doc.text", isSelectedByDefault: true),
    .init(
      id: "trash", name: "Thùng rác", detail: "Tệp đã chuyển vào Thùng rác", relativePath: ".Trash",
      symbol: "trash", isSelectedByDefault: false, confidence: .dangerous,
      confidenceReason: "Dọn chính Trash là thao tác vĩnh viễn và không thể hoàn tác."),
    .init(
      id: "xcode-derived-data", name: "Xcode Derived Data",
      detail: "Sản phẩm build và chỉ mục có thể tạo lại",
      relativePath: "Library/Developer/Xcode/DerivedData", symbol: "hammer",
      isSelectedByDefault: true),
    .init(
      id: "xcode-archives", name: "Xcode Archives",
      detail: "Bản lưu trữ ứng dụng; nên kiểm tra trước khi xóa",
      relativePath: "Library/Developer/Xcode/Archives", symbol: "archivebox",
      isSelectedByDefault: false, confidence: .review,
      confidenceReason: "Archive có thể cần để symbolicate crash hoặc phát hành lại ứng dụng."),
    .init(
      id: "npm-cache", name: "NPM Cache", detail: "Bộ nhớ đệm gói npm",
      relativePath: ".npm/_cacache", symbol: "cube.box", isSelectedByDefault: true),
    .init(
      id: "yarn-cache", name: "Yarn Cache", detail: "Bộ nhớ đệm gói Yarn",
      relativePath: "Library/Caches/Yarn", symbol: "cube.box", isSelectedByDefault: true),
    .init(
      id: "pip-cache", name: "Pip Cache", detail: "Bộ nhớ đệm gói Python",
      relativePath: "Library/Caches/pip", symbol: "chevron.left.forwardslash.chevron.right",
      isSelectedByDefault: true),
  ]
}

struct ScanResult: Identifiable, Sendable {
  let target: CleaningTarget
  let bytes: Int64
  let issue: String?

  var id: String { target.id }
}

struct CleanupResult: Sendable {
  let target: CleaningTarget
  let affectedBytes: Int64
  let removedItems: Int
  let errors: [String]
  let recoverable: Bool
  let moves: [TrashMoveRecord]
}

enum ByteCount {
  static func string(_ bytes: Int64) -> String {
    guard bytes > 0 else { return "0 KB" }
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    formatter.countStyle = .file
    formatter.includesUnit = true
    formatter.isAdaptive = true
    return formatter.string(fromByteCount: bytes)
  }
}
