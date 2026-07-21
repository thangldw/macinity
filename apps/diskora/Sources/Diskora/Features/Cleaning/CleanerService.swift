import Foundation

enum CleanerError: LocalizedError {
  case unsafePath(String)

  var errorDescription: String? {
    switch self {
    case .unsafePath(let path):
      return "Đường dẫn không an toàn đã bị chặn: \(path)"
    }
  }
}

struct CleanerService: Sendable {
  let homeURL: URL

  init(homeURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
    self.homeURL = homeURL.standardizedFileURL
  }

  func url(for target: CleaningTarget) throws -> URL {
    let safeHome = homeURL.resolvingSymlinksInPath().standardizedFileURL
    let candidate =
      homeURL
      .appendingPathComponent(target.relativePath, isDirectory: true)
      .resolvingSymlinksInPath()
      .standardizedFileURL
    let homePath = safeHome.path.hasSuffix("/") ? safeHome.path : safeHome.path + "/"

    guard candidate.path.hasPrefix(homePath), candidate.path != safeHome.path else {
      throw CleanerError.unsafePath(candidate.path)
    }
    return candidate
  }

  func scan(targets: [CleaningTarget]) async -> [ScanResult] {
    await withTaskGroup(of: ScanResult.self) { group in
      for target in targets {
        group.addTask {
          do {
            return ScanResult(target: target, bytes: try size(of: try url(for: target)), issue: nil)
          } catch {
            return ScanResult(target: target, bytes: 0, issue: error.localizedDescription)
          }
        }
      }

      var results: [ScanResult] = []
      for await result in group { results.append(result) }
      let order = Dictionary(uniqueKeysWithValues: targets.enumerated().map { ($1.id, $0) })
      return results.sorted { order[$0.id, default: 0] < order[$1.id, default: 0] }
    }
  }

  func size(of root: URL) throws -> Int64 {
    let manager = FileManager()
    var isDirectory: ObjCBool = false
    guard manager.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return 0 }
    guard isDirectory.boolValue else {
      let values = try root.resourceValues(forKeys: [.fileSizeKey])
      return Int64(values.fileSize ?? 0)
    }

    let keys: Set<URLResourceKey> = [
      .isRegularFileKey, .isSymbolicLinkKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey,
      .fileSizeKey,
    ]
    guard
      let enumerator = manager.enumerator(
        at: root,
        includingPropertiesForKeys: Array(keys),
        options: [],
        errorHandler: { _, _ in true }
      )
    else { return 0 }

    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
      let values = try? fileURL.resourceValues(forKeys: keys)
      guard values?.isRegularFile == true, values?.isSymbolicLink != true else { continue }
      total += Int64(
        max(
          values?.totalFileAllocatedSize ?? 0, values?.fileAllocatedSize ?? 0, values?.fileSize ?? 0
        ))
    }
    return total
  }

  func clean(target: CleaningTarget) -> CleanupResult {
    do {
      let root = try url(for: target)
      let before = (try? size(of: root)) ?? 0
      let manager = FileManager()
      guard manager.fileExists(atPath: root.path) else {
        return CleanupResult(target: target, reclaimedBytes: 0, removedItems: 0, errors: [])
      }

      let children = try manager.contentsOfDirectory(
        at: root,
        includingPropertiesForKeys: nil,
        options: []
      )
      var removed = 0
      var errors: [String] = []
      for child in children {
        do {
          try manager.removeItem(at: child)
          removed += 1
        } catch {
          errors.append("\(child.lastPathComponent): \(error.localizedDescription)")
        }
      }
      let after = (try? size(of: root)) ?? 0
      return CleanupResult(
        target: target,
        reclaimedBytes: max(0, before - after),
        removedItems: removed,
        errors: errors
      )
    } catch {
      return CleanupResult(
        target: target, reclaimedBytes: 0, removedItems: 0, errors: [error.localizedDescription])
    }
  }
}
