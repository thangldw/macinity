import Foundation

struct DeveloperLocation: Sendable {
  let id: String
  let name: String
  let detail: String
  let relativePath: String
  let safetyNote: String
}

struct StorageAnalyzer: Sendable {
  let homeURL: URL

  init(homeURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
    self.homeURL = homeURL.standardizedFileURL
  }

  private var developerLocations: [DeveloperLocation] {
    [
      .init(
        id: "xcode-simulators", name: "Xcode Simulators",
        detail: "Thiết bị mô phỏng và dữ liệu ứng dụng",
        relativePath: "Library/Developer/CoreSimulator",
        safetyNote:
          "Xóa runtime không dùng trong Xcode trước; dữ liệu simulator có thể chứa dữ liệu thử nghiệm."
      ),
      .init(
        id: "xcode-device-support", name: "iOS Device Support",
        detail: "Biểu tượng debug cho các phiên bản iOS",
        relativePath: "Library/Developer/Xcode/iOS DeviceSupport",
        safetyNote: "Có thể tạo lại khi kết nối thiết bị, nhưng cần tải lại."),
      .init(
        id: "docker", name: "Docker Desktop", detail: "Images, containers, volumes và build cache",
        relativePath: "Library/Containers/com.docker.docker/Data",
        safetyNote: "Không xóa trực tiếp; volume có thể chứa cơ sở dữ liệu quan trọng."),
      .init(
        id: "node-nvm", name: "Node.js — nvm", detail: "Các phiên bản Node được cài bởi nvm",
        relativePath: ".nvm/versions",
        safetyNote: "Giữ phiên bản đang active và phiên bản dự án đang yêu cầu."),
      .init(
        id: "python-pyenv", name: "Python — pyenv",
        detail: "Các phiên bản Python được cài bởi pyenv", relativePath: ".pyenv/versions",
        safetyNote: "Kiểm tra .python-version trong dự án trước khi gỡ."),
      .init(
        id: "asdf", name: "asdf runtimes", detail: "Runtime được quản lý bởi asdf",
        relativePath: ".asdf/installs", safetyNote: "Kiểm tra .tool-versions trong các dự án."),
      .init(
        id: "conda", name: "Conda environments", detail: "Môi trường Conda và package cache",
        relativePath: ".conda",
        safetyNote: "Môi trường có thể chứa package và notebook chưa sao lưu."),
      .init(
        id: "android", name: "Android SDK", detail: "SDK, system images và emulator Android",
        relativePath: "Library/Android/sdk",
        safetyNote: "Nên gỡ platform và emulator qua SDK Manager."),
      .init(
        id: "gradle", name: "Gradle", detail: "Cache dependency và Gradle distributions",
        relativePath: ".gradle",
        safetyNote: "Cache có thể tạo lại nhưng lần build tiếp theo sẽ tải lại."),
      .init(
        id: "cocoapods", name: "CocoaPods", detail: "Cache và repository specs",
        relativePath: "Library/Caches/CocoaPods", safetyNote: "Có thể tạo lại khi chạy pod install."
      ),
      .init(
        id: "iphone-backups", name: "iPhone/iPad Backups", detail: "Bản sao lưu thiết bị iOS",
        relativePath: "Library/Application Support/MobileSync/Backup",
        safetyNote: "Có thể chứa dữ liệu cá nhân duy nhất; chỉ xóa bản backup đã xác định."),
    ]
  }

  func scan(rootURL: URL, largeFileThreshold: Int64 = 100 * 1_024 * 1_024) throws -> StorageSnapshot
  {
    let manager = FileManager()
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    let keys: Set<URLResourceKey> = [
      .isRegularFileKey, .isSymbolicLinkKey, .fileAllocatedSizeKey,
      .totalFileAllocatedSizeKey, .fileSizeKey, .contentModificationDateKey,
    ]
    var inaccessibleCount = 0
    guard
      let enumerator = manager.enumerator(
        at: root,
        includingPropertiesForKeys: Array(keys),
        options: [],
        errorHandler: { _, _ in
          inaccessibleCount += 1
          return true
        }
      )
    else {
      throw CocoaError(.fileReadUnknown)
    }

    let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
    let devDefinitions = developerLocations.map { definition in
      (definition, homeURL.appendingPathComponent(definition.relativePath).standardizedFileURL)
    }
    var total: Int64 = 0
    var count = 0
    var folderSizes: [String: Int64] = [:]
    var categorySizes: [StorageCategory: Int64] = [:]
    var developerSizes: [String: Int64] = [:]
    var largeFiles: [StorageEntry] = []

    for case let fileURL as URL in enumerator {
      if Task.isCancelled { throw CancellationError() }
      guard let values = try? fileURL.resourceValues(forKeys: keys),
        values.isRegularFile == true,
        values.isSymbolicLink != true
      else { continue }
      let normalizedFileURL =
        fileURL.path.hasPrefix(rootPath)
        ? fileURL.standardizedFileURL
        : fileURL.resolvingSymlinksInPath().standardizedFileURL
      let bytes = Int64(
        max(values.totalFileAllocatedSize ?? 0, values.fileAllocatedSize ?? 0, values.fileSize ?? 0)
      )
      total += bytes
      count += 1

      let relative =
        normalizedFileURL.path.hasPrefix(rootPath)
        ? String(normalizedFileURL.path.dropFirst(rootPath.count))
        : normalizedFileURL.lastPathComponent
      if let first = relative.split(separator: "/").first {
        folderSizes[String(first), default: 0] += bytes
      }
      categorySizes[category(for: normalizedFileURL), default: 0] += bytes

      for (definition, location) in devDefinitions
      where normalizedFileURL.path == location.path
        || normalizedFileURL.path.hasPrefix(location.path + "/")
      {
        developerSizes[definition.id, default: 0] += bytes
      }
      if bytes >= largeFileThreshold {
        largeFiles.append(
          StorageEntry(
            url: normalizedFileURL, bytes: bytes, modifiedAt: values.contentModificationDate))
        if largeFiles.count > 400 {
          largeFiles.sort { $0.bytes > $1.bytes }
          largeFiles.removeLast(100)
        }
      }
    }

    let topFolders = folderSizes.map { name, bytes in
      StorageEntry(url: root.appendingPathComponent(name), bytes: bytes, modifiedAt: nil)
    }.sorted { $0.bytes > $1.bytes }

    let categories = StorageCategory.allCases.map {
      CategoryUsage(category: $0, bytes: categorySizes[$0, default: 0])
    }.filter { $0.bytes > 0 }.sorted { $0.bytes > $1.bytes }

    let developerData = devDefinitions.compactMap { definition, url -> DeveloperUsage? in
      let bytes = developerSizes[definition.id, default: 0]
      guard bytes > 0 else { return nil }
      return DeveloperUsage(
        id: definition.id, name: definition.name, detail: definition.detail, url: url, bytes: bytes,
        safetyNote: definition.safetyNote)
    }.sorted { $0.bytes > $1.bytes }

    return StorageSnapshot(
      rootURL: root,
      scannedBytes: total,
      fileCount: count,
      inaccessibleCount: inaccessibleCount,
      topFolders: Array(topFolders.prefix(30)),
      largeFiles: Array(largeFiles.sorted { $0.bytes > $1.bytes }.prefix(200)),
      categories: categories,
      developerData: developerData,
      completedAt: Date()
    )
  }

  private func category(for url: URL) -> StorageCategory {
    let path = url.path.lowercased()
    let ext = url.pathExtension.lowercased()
    if path.contains("/developer/") || path.contains("/.gradle/") || path.contains("/.npm/")
      || path.contains("/node_modules/") || path.contains("/.venv/")
    {
      return .developer
    }
    if path.contains(".app/contents/") { return .applications }
    if ["jpg", "jpeg", "png", "gif", "heic", "tiff", "webp", "raw"].contains(ext) {
      return .images
    }
    if ["mov", "mp4", "m4v", "mkv", "avi", "webm"].contains(ext) { return .video }
    if ["mp3", "m4a", "wav", "flac", "aac", "aiff"].contains(ext) { return .audio }
    if ["zip", "rar", "7z", "tar", "gz", "dmg", "pkg", "iso"].contains(ext) { return .archives }
    if [
      "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md", "rtf", "pages", "numbers",
      "key",
    ].contains(ext) {
      return .documents
    }
    return .other
  }
}
