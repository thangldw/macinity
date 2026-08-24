import Foundation
import ToolboxCore

#if canImport(ToolboxStorage)
  import ToolboxStorage
#endif

func makeProjectFixture(files: [String], under root: URL) throws -> URL {
  let project = root.appendingPathComponent("project")
  for relativePath in files {
    let file = project.appendingPathComponent(relativePath)
    try FileManager.default.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(relativePath.utf8).write(to: file)
  }
  return project
}

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
  let service = CleanerService(homeURL: temporary, removalMethod: .permanentForTesting)
  let sampleSize = try service.size(of: service.url(for: target))
  require(sampleSize > 0, "Không tính được dung lượng tệp mẫu")

  let result = service.clean(target: target)
  require(result.removedItems == 1, "Không xóa đúng số lượng mục")
  require(result.errors.isEmpty, "Quá trình dọn dẹp trả về lỗi")
  require(!result.recoverable, "Chế độ test không được đánh dấu có thể khôi phục")
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

  require(
    ApplicationScanner.matchesLeftoverName("com.example.note", applicationName: "Note"),
    "Không nhận diện được leftover theo thành phần tên")
  require(
    !ApplicationScanner.matchesLeftoverName("com.example.noteworthy", applicationName: "Note"),
    "Nhận nhầm leftover chỉ vì tên chứa chuỗi con")

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
    duplicateSnapshot.partialHashedCount >= duplicateSnapshot.hashedCount,
    "Partial-hash pipeline không lọc trước full SHA-256")
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
    require(
      photos.groups[0].photos.allSatisfy { $0.pixelWidth > 0 && $0.pixelHeight > 0 },
      "Không đọc được độ phân giải ảnh")
  }

  let undoOriginal = temporary.appendingPathComponent("Restored/sample.txt")
  let undoTrash = temporary.appendingPathComponent("FakeTrash/sample.txt")
  try manager.createDirectory(
    at: undoTrash.deletingLastPathComponent(), withIntermediateDirectories: true)
  try Data("undo".utf8).write(to: undoTrash)
  let history = HistoryStore(directory: temporary.appendingPathComponent("History"))
  history.record(
    action: "Undo smoke", paths: [undoOriginal.path], bytes: 4, recoverable: true, note: "test",
    moves: [
      TrashMoveRecord(originalPath: undoOriginal.path, trashPath: undoTrash.path, bytes: 4)
    ])
  let undoEntry = history.load().first!
  let restored = history.restore(entryID: undoEntry.id)
  require(restored.restoredCount == 1, "Undo Center không khôi phục đúng mục")
  require(manager.fileExists(atPath: undoOriginal.path), "Undo Center không trả mục về vị trí gốc")

  let migrationRoot = temporary.appendingPathComponent("LegacyMigration")
  let legacyDiskora = migrationRoot.appendingPathComponent("Diskora")
  let migratedToolbox = migrationRoot.appendingPathComponent("Toolbox")
  try manager.createDirectory(at: legacyDiskora, withIntermediateDirectories: true)
  let legacyEntry = CleanupHistoryEntry(
    id: UUID(), date: Date(timeIntervalSince1970: 1), action: "Legacy cleanup",
    paths: ["/tmp/legacy-cache"], bytes: 128, recoverable: false, note: "legacy",
    moves: nil)
  try JSONEncoder().encode([legacyEntry]).write(
    to: legacyDiskora.appendingPathComponent("history.json"))
  let migrationReport = try MigrationService(
    legacyRoot: migrationRoot, toolboxDirectory: migratedToolbox
  ).migrate()
  let migratedHistory = HistoryStore(directory: migratedToolbox).load()
  require(migrationReport.cleanupEntriesImported == 1, "Sai số bản ghi Diskora đã migrate")
  require(
    migratedHistory.first?.action == "Legacy cleanup",
    "Diskora history không đọc được sau migration")

  let project = try makeProjectFixture(
    files: ["package.json", "package-lock.json", "node_modules/pkg/index.js"],
    under: temporary.appendingPathComponent("Projects"))
  let projectReport = await ProjectScanner().scan(roots: [project])
  require(projectReport.artifacts.count == 1, "Project scan phải chỉ nhận diện artifact đã biết")
  require(
    projectReport.artifacts[0].artifactURL.lastPathComponent == "node_modules",
    "Project scan không nhận diện node_modules")
  require(
    !projectReport.artifacts.contains { $0.artifactURL.lastPathComponent == "package-lock.json" },
    "Project scan không được đề xuất lockfile")
  let projectCleanup = ProjectCleanupService(removalMethod: .permanentForTesting)
    .moveToTrash(projectReport.artifacts[0], allowedRoots: [project])
  require(projectCleanup.error == nil, "Project cleanup không xử lý artifact đã xác nhận")
  require(
    !manager.fileExists(atPath: project.appendingPathComponent("node_modules").path),
    "Project cleanup chưa xóa artifact trong chế độ test")
  require(
    manager.fileExists(atPath: project.appendingPathComponent("package-lock.json").path),
    "Project cleanup đã xóa nhầm lockfile")

  let unknownProject = try makeProjectFixture(
    files: ["src/main.swift", "mystery-cache/blob"],
    under: temporary.appendingPathComponent("UnknownProjects"))
  let unknownReport = await ProjectScanner().scan(roots: [unknownProject])
  require(unknownReport.artifacts.isEmpty, "Project scan không được suy đoán artifact chưa biết")

  let symlinkProject = try makeProjectFixture(
    files: ["package.json"], under: temporary.appendingPathComponent("SymlinkProjects"))
  let outsideArtifact = temporary.appendingPathComponent("OutsideArtifact")
  try manager.createDirectory(at: outsideArtifact, withIntermediateDirectories: true)
  try manager.createSymbolicLink(
    at: symlinkProject.appendingPathComponent("node_modules"),
    withDestinationURL: outsideArtifact)
  let symlinkReport = await ProjectScanner().scan(roots: [symlinkProject])
  require(
    symlinkReport.artifacts.first?.safety == .protected,
    "Project scan phải chặn symlink artifact vượt khỏi root")

  print("PASS: cleaner, storage analyzer, project, duplicate and similar-photo smoke tests")
} catch {
  FileHandle.standardError.write(Data("FAIL: \(error.localizedDescription)\n".utf8))
  exit(1)
}
