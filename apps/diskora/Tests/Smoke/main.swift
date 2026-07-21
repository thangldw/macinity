import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else {
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
    exit(1)
  }
}

let manager = FileManager.default
let temporary = manager.temporaryDirectory.appendingPathComponent(
  UUID().uuidString, isDirectory: true)
defer { try? manager.removeItem(at: temporary) }

do {
  let cache = temporary.appendingPathComponent("Library/Caches", isDirectory: true)
  try manager.createDirectory(at: cache, withIntermediateDirectories: true)
  try Data(repeating: 1, count: 8_192).write(to: cache.appendingPathComponent("sample.bin"))

  let target = CleaningTarget(
    id: "test",
    name: "Test",
    detail: "",
    relativePath: "Library/Caches",
    symbol: "folder",
    isSelectedByDefault: true
  )
  let service = CleanerService(homeURL: temporary)
  let sampleSize = try service.size(of: service.url(for: target))
  require(sampleSize > 0, "Không tính được dung lượng tệp mẫu")

  let result = service.clean(target: target)
  require(result.removedItems == 1, "Không xóa đúng số lượng mục")
  require(result.errors.isEmpty, "Quá trình dọn dẹp trả về lỗi")
  require(manager.fileExists(atPath: cache.path), "Đã xóa nhầm thư mục gốc")
  let remainingItems = try manager.contentsOfDirectory(atPath: cache.path)
  require(remainingItems.isEmpty, "Thư mục chưa được dọn sạch")

  let unsafe = CleaningTarget(
    id: "escape",
    name: "Escape",
    detail: "",
    relativePath: "../../etc",
    symbol: "folder",
    isSelectedByDefault: false
  )
  do {
    _ = try service.url(for: unsafe)
    require(false, "Không chặn đường dẫn vượt khỏi thư mục người dùng")
  } catch is CleanerError {
    // Expected.
  }

  let documents = temporary.appendingPathComponent("Documents", isDirectory: true)
  try manager.createDirectory(at: documents, withIntermediateDirectories: true)
  let largePDF = documents.appendingPathComponent("report.pdf")
  try Data(repeating: 2, count: 16_384).write(to: largePDF)
  let snapshot = try StorageAnalyzer(homeURL: temporary).scan(
    rootURL: temporary, largeFileThreshold: 1)
  require(snapshot.fileCount == 1, "Trình phân tích đếm sai số tệp")
  require(
    snapshot.largeFiles.first?.url.lastPathComponent == largePDF.lastPathComponent,
    "Không phát hiện tệp lớn")
  require(
    snapshot.categories.contains(where: { $0.category == .documents }),
    "Không phân loại được tài liệu")
  require(snapshot.topFolders.first?.name == "Documents", "Không tính đúng thư mục lớn nhất")

  let duplicatePDF = documents.appendingPathComponent("report-copy.pdf")
  try manager.copyItem(at: largePDF, to: duplicatePDF)
  let fakeTrash = temporary.appendingPathComponent(".Trash", isDirectory: true)
  try manager.createDirectory(at: fakeTrash, withIntermediateDirectories: true)
  try manager.copyItem(at: largePDF, to: fakeTrash.appendingPathComponent("ignored-copy.pdf"))
  try Data(repeating: 3, count: 12_000).write(
    to: documents.appendingPathComponent("proposal-final.pdf"))
  try Data(repeating: 4, count: 13_000).write(
    to: documents.appendingPathComponent("proposal-old.pdf"))
  let duplicateSnapshot = try DuplicateScanner().scan(rootURL: temporary, minimumBytes: 1)
  require(duplicateSnapshot.groups.count == 1, "Không nhóm đúng tệp trùng lặp")
  require(duplicateSnapshot.groups[0].files.count == 2, "Không xác nhận đủ bản sao bằng SHA-256")
  require(
    duplicateSnapshot.groups[0].hasDifferentNames,
    "Không cảnh báo nội dung giống hệt nhưng tên khác")
  require(duplicateSnapshot.reclaimableBytes > 0, "Không tính được dung lượng có thể giải phóng")
  require(
    !duplicateSnapshot.nameWarnings.isEmpty, "Không cảnh báo tên gần giống nhưng nội dung khác")

  let protectedRoot = temporary.appendingPathComponent("Protected", isDirectory: true)
  try manager.createDirectory(at: protectedRoot, withIntermediateDirectories: true)
  let rejected = DuplicateScanner().moveToTrash(
    files: [DuplicateFile(url: largePDF, bytes: 16_384, modifiedAt: nil)],
    retainedOriginalByPath: [largePDF.path: duplicatePDF.path],
    within: protectedRoot
  )
  require(
    rejected.movedCount == 0 && !rejected.errors.isEmpty, "Không chặn tệp nằm ngoài phạm vi đã quét"
  )
  require(manager.fileExists(atPath: largePDF.path), "Đã di chuyển nhầm tệp ngoài phạm vi")

  if let imagePath = ProcessInfo.processInfo.environment["MAC_CLEANER_TEST_IMAGE"] {
    let photoFolder = temporary.appendingPathComponent("Photos", isDirectory: true)
    try manager.createDirectory(at: photoFolder, withIntermediateDirectories: true)
    let firstPhoto = photoFolder.appendingPathComponent("burst-001.png")
    let secondPhoto = photoFolder.appendingPathComponent("burst-002.png")
    try manager.copyItem(at: URL(fileURLWithPath: imagePath), to: firstPhoto)
    try manager.copyItem(at: URL(fileURLWithPath: imagePath), to: secondPhoto)
    let now = Date()
    try manager.setAttributes([.modificationDate: now], ofItemAtPath: firstPhoto.path)
    try manager.setAttributes(
      [.modificationDate: now.addingTimeInterval(1)], ofItemAtPath: secondPhoto.path)
    let photos = try SimilarPhotoScanner().scan(rootURL: photoFolder)
    require(
      photos.groups.count == 1 && photos.groups[0].photos.count == 2,
      "Không nhóm được chuỗi ảnh tương tự bằng Vision")
  }

  print("PASS: cleaner, storage analyzer, duplicate and similar-photo smoke tests")
} catch {
  FileHandle.standardError.write(Data("FAIL: \(error.localizedDescription)\n".utf8))
  exit(1)
}
