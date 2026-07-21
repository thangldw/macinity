import Foundation

enum StorageCategory: String, CaseIterable, Sendable {
  case applications = "Ứng dụng"
  case documents = "Tài liệu"
  case images = "Hình ảnh"
  case video = "Video"
  case audio = "Âm thanh"
  case archives = "Tệp nén"
  case developer = "Developer"
  case other = "Khác"

  var symbol: String {
    switch self {
    case .applications: return "app.dashed"
    case .documents: return "doc"
    case .images: return "photo"
    case .video: return "film"
    case .audio: return "music.note"
    case .archives: return "archivebox"
    case .developer: return "hammer"
    case .other: return "square.grid.2x2"
    }
  }
}

struct StorageEntry: Identifiable, Sendable {
  let url: URL
  let bytes: Int64
  let modifiedAt: Date?

  var id: String { url.path }
  var name: String { url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent }
}

struct CategoryUsage: Identifiable, Sendable {
  let category: StorageCategory
  let bytes: Int64

  var id: String { category.rawValue }
}

struct DeveloperUsage: Identifiable, Sendable {
  let id: String
  let name: String
  let detail: String
  let url: URL
  let bytes: Int64
  let safetyNote: String
}

struct StorageSnapshot: Sendable {
  let rootURL: URL
  let scannedBytes: Int64
  let fileCount: Int
  let inaccessibleCount: Int
  let topFolders: [StorageEntry]
  let largeFiles: [StorageEntry]
  let categories: [CategoryUsage]
  let developerData: [DeveloperUsage]
  let completedAt: Date
}
