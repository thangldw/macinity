import Foundation

enum AppMetadata {
  static let name = "Changeora"
  static let tagline = "See what changed on your Mac."
  static let author = "Thang"
  static let version = "1.0.0"
  static let build = "1"
  static let copyright = "Copyright © 2026 Thang. MIT License."
  static let summary =
    "Theo dõi và giải thích thay đổi hệ thống sau khi cài hoặc cập nhật ứng dụng."

  static func applicationSupportDirectory() -> URL {
    let manager = FileManager.default
    let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let directory = base.appendingPathComponent(name, isDirectory: true)
    try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}
