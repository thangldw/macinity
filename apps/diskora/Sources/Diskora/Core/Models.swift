import Foundation

struct CleaningTarget: Identifiable, Hashable, Sendable {
  let id: String
  let name: String
  let detail: String
  let relativePath: String
  let symbol: String
  let isSelectedByDefault: Bool

  static let defaults: [CleaningTarget] = [
    .init(
      id: "user-caches", name: "Bộ nhớ đệm", detail: "Dữ liệu tạm của các ứng dụng",
      relativePath: "Library/Caches", symbol: "shippingbox", isSelectedByDefault: true),
    .init(
      id: "user-logs", name: "Nhật ký ứng dụng", detail: "Các tệp log trong tài khoản người dùng",
      relativePath: "Library/Logs", symbol: "doc.text", isSelectedByDefault: true),
    .init(
      id: "trash", name: "Thùng rác", detail: "Tệp đã chuyển vào Thùng rác", relativePath: ".Trash",
      symbol: "trash", isSelectedByDefault: false),
    .init(
      id: "xcode-derived-data", name: "Xcode Derived Data",
      detail: "Sản phẩm build và chỉ mục có thể tạo lại",
      relativePath: "Library/Developer/Xcode/DerivedData", symbol: "hammer",
      isSelectedByDefault: true),
    .init(
      id: "xcode-archives", name: "Xcode Archives",
      detail: "Bản lưu trữ ứng dụng; nên kiểm tra trước khi xóa",
      relativePath: "Library/Developer/Xcode/Archives", symbol: "archivebox",
      isSelectedByDefault: false),
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
  let reclaimedBytes: Int64
  let removedItems: Int
  let errors: [String]
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
