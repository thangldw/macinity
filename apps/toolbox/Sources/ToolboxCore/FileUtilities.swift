import CryptoKit
import Darwin
import Foundation

public struct FileStamp: Codable, Sendable, Equatable {
  public let device: Int32
  public let inode: UInt64
  public let size: Int64
  public let seconds: Int64
  public let nanoseconds: Int64
  public init(path: String) throws {
    var info = stat()
    guard lstat(path, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG else {
      throw CocoaError(.fileReadUnsupportedScheme)
    }
    device = info.st_dev
    inode = info.st_ino
    size = info.st_size
    seconds = Int64(info.st_mtimespec.tv_sec)
    nanoseconds = Int64(info.st_mtimespec.tv_nsec)
  }
}
public enum FileChecksum {
  public static func sha256(
    _ url: URL, maximumBytes: Int64 = 16 * 1024 * 1024 * 1024,
    deadline: Date = Date().addingTimeInterval(120)
  ) throws -> String {
    let before = try FileStamp(path: url.path)
    guard before.size <= maximumBytes else { throw CocoaError(.fileReadTooLarge) }
    let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
    guard descriptor >= 0 else { throw CocoaError(.fileReadNoPermission) }
    let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    defer { try? handle.close() }
    var info = stat()
    guard fstat(descriptor, &info) == 0, info.st_ino == before.inode, info.st_dev == before.device,
      info.st_size == before.size, (info.st_mode & S_IFMT) == S_IFREG
    else { throw CocoaError(.fileReadUnknown) }
    var hasher = SHA256()
    var total: Int64 = 0
    while true {
      try Task.checkCancellation()
      guard Date() < deadline else { throw CocoaError(.fileReadTooLarge) }
      let bytes = try handle.read(upToCount: 1_048_576) ?? Data()
      if bytes.isEmpty { break }
      total += Int64(bytes.count)
      guard total <= maximumBytes else { throw CocoaError(.fileReadTooLarge) }
      hasher.update(data: bytes)
    }
    guard total == before.size, try FileStamp(path: url.path) == before else {
      throw CocoaError(.fileReadUnknown)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }
}

public struct RenameItem: Codable, Sendable, Identifiable {
  public var id: String { source }
  public let source: String
  public let destination: String
  public let stamp: FileStamp
}
public enum FileUtilityOperations {
  private static func canonicalPath(_ path: String) throws -> String {
    guard let resolved = realpath(path, nil) else { throw CocoaError(.fileReadUnknown) }
    defer { free(resolved) }
    return String(cString: resolved)
  }
  public static func renamePlan(_ files: [URL], find: String, replace: String, prefix: String)
    throws -> [RenameItem]
  {
    guard files.count <= 2000, !replace.contains("/"), !prefix.contains("/"),
      !replace.contains("\0"), !prefix.contains("\0")
    else { throw CocoaError(.validationMissingMandatoryProperty) }
    var result: [RenameItem] = []
    var targets: Set<String> = []
    for selected in files {
      // Reject a symlink leaf, then normalize aliases such as /tmp and /private/tmp.
      let stamp = try FileStamp(path: selected.path)
      let file = URL(fileURLWithPath: try canonicalPath(selected.path))
      guard try FileStamp(path: file.path) == stamp else { throw CocoaError(.fileReadUnknown) }
      let name =
        prefix
        + (find.isEmpty
          ? file.lastPathComponent
          : file.lastPathComponent.replacingOccurrences(of: find, with: replace))
      guard !name.isEmpty, name != ".", name != "..", name.utf8.count <= 255 else {
        throw CocoaError(.fileWriteInvalidFileName)
      }
      let target = file.deletingLastPathComponent().appendingPathComponent(name)
      if target == file { continue }
      guard targets.insert(target.path.lowercased()).inserted,
        !FileManager.default.fileExists(atPath: target.path)
      else { throw CocoaError(.fileWriteFileExists) }
      result.append(
        .init(source: file.path, destination: target.path, stamp: try FileStamp(path: file.path)))
    }
    return result
  }
  /// Never overwrites a destination. Journal is written before the first mutation and retained on error.
  public static func applyRename(_ items: [RenameItem], journal: URL) throws {
    guard !items.isEmpty, items.count <= 2000 else { return }
    for item in items {
      guard try canonicalPath(item.source) == item.source,
        try FileStamp(path: item.source) == item.stamp,
        URL(fileURLWithPath: item.source).deletingLastPathComponent()
          == URL(fileURLWithPath: item.destination).deletingLastPathComponent(),
        !FileManager.default.fileExists(atPath: item.destination)
      else { throw CocoaError(.fileWriteFileExists) }
    }
    try FileManager.default.createDirectory(
      at: journal.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(items).write(to: journal, options: .atomic)
    for item in items {
      guard try canonicalPath(item.source) == item.source,
        try FileStamp(path: item.source) == item.stamp,
        renamex_np(item.source, item.destination, UInt32(RENAME_EXCL)) == 0
      else { throw CocoaError(.fileWriteUnknown) }
    }
  }
  public static func undoRename(_ items: [RenameItem]) throws {
    // Partial failures are recoverable: entries never moved are ignored; changed files are not touched.
    guard items.count <= 2000 else { throw CocoaError(.fileReadTooLarge) }
    for item in items.reversed() {
      guard
        URL(fileURLWithPath: item.source).deletingLastPathComponent()
          == URL(fileURLWithPath: item.destination).deletingLastPathComponent()
      else { throw CocoaError(.fileReadUnknown) }
      if (try? FileStamp(path: item.source)) == item.stamp { continue }
      guard try canonicalPath(item.destination) == item.destination,
        try FileStamp(path: item.destination) == item.stamp,
        renamex_np(item.destination, item.source, UInt32(RENAME_EXCL)) == 0
      else { throw CocoaError(.fileWriteUnknown) }
    }
  }
  public static func tree(_ root: URL, deadline: Date) throws -> [String: String] {
    var failure: Error?
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
      isDirectory.boolValue,
      let enumerator = FileManager.default.enumerator(
        at: root, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
        options: [.skipsPackageDescendants],
        errorHandler: { _, error in
          failure = error
          return false
        })
    else { throw CocoaError(.fileReadNoPermission) }
    var result: [String: String] = [:]
    var count = 0
    for case let url as URL in enumerator {
      try Task.checkCancellation()
      count += 1
      guard count <= 20000, Date() < deadline else { throw CocoaError(.fileReadTooLarge) }
      let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
      if values.isSymbolicLink == true {
        enumerator.skipDescendants()
        continue
      }
      guard values.isRegularFile == true else { continue }
      // Enumeration may canonicalize /var to /private/var; depth avoids slicing an alias path.
      let relative = url.pathComponents.suffix(enumerator.level).joined(separator: "/")
      result[relative] = try FileChecksum.sha256(url, deadline: deadline)
    }
    if let failure { throw failure }
    return result
  }
}
