import Foundation

enum AppMetadata {
  static let name = "Diskora"
  static let tagline = "See where your space goes."
  static let author = "Thang"
  static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.3.0"
  }
  static var build: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "4"
  }
  static let copyright = "Copyright © 2026 Thang. MIT License."
  static let summary = "Công cụ phân tích và quản lý dung lượng dành cho macOS."

  static func applicationSupportDirectory() -> URL {
    let manager = FileManager.default
    let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let current = base.appendingPathComponent("Diskora", isDirectory: true)
    let legacy = base.appendingPathComponent("MacCleaner", isDirectory: true)
    if !manager.fileExists(atPath: current.path), manager.fileExists(atPath: legacy.path) {
      try? manager.moveItem(at: legacy, to: current)
    }
    try? manager.createDirectory(at: current, withIntermediateDirectories: true)
    return current
  }
}
