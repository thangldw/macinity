import Darwin
import Foundation
import ToolboxCore

struct RecoveryItem: Identifiable, Hashable, Sendable {
  let id: UUID
  let originalPath: String
  let trashPath: String
  let bytes: Int64

}

struct RestoreResult: Sendable {
  let restoredCount: Int
  let restoredBytes: Int64
  let errors: [String]
}

struct UnifiedRecoveryAdapter: Sendable {
  private let allowedTrashRoots: [URL]
  private let allowedDestinationRoots: [URL]

  init(
    allowedTrashRoots: [URL] = Self.defaultTrashRoots(),
    allowedDestinationRoots: [URL] = Self.defaultDestinationRoots()
  ) {
    self.allowedTrashRoots = allowedTrashRoots
    self.allowedDestinationRoots = allowedDestinationRoots
  }

  func restore(_ item: RecoveryItem) -> RestoreResult {
    let manager = FileManager.default
    let source = URL(fileURLWithPath: item.trashPath)
    let destination = URL(fileURLWithPath: item.originalPath)
    guard manager.fileExists(atPath: source.path) else {
      return result(error: "\(source.lastPathComponent): không còn trong Trash")
    }
    guard !manager.fileExists(atPath: destination.path) else {
      return result(error: "\(destination.lastPathComponent): vị trí gốc đã có dữ liệu")
    }

    do {
      let validatedSource = try PathSafetyPolicy.validate(
        candidate: source, allowedRoots: allowedTrashRoots)
      let validatedDestination = try PathSafetyPolicy.validate(
        candidate: destination, allowedRoots: allowedDestinationRoots)
      try manager.createDirectory(
        at: validatedDestination.deletingLastPathComponent(), withIntermediateDirectories: true)
      try manager.moveItem(at: validatedSource, to: validatedDestination)
      return RestoreResult(
        restoredCount: 1, restoredBytes: item.bytes, errors: [])
    } catch {
      return result(error: "\(destination.lastPathComponent): \(error.localizedDescription)")
    }
  }

  private func result(error: String) -> RestoreResult {
    RestoreResult(restoredCount: 0, restoredBytes: 0, errors: [error])
  }

  private static func defaultTrashRoots() -> [URL] {
    let manager = FileManager.default
    var roots = [manager.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")]
    if let trash = try? manager.url(
      for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    {
      roots.append(trash)
    }
    let volumes = URL(fileURLWithPath: "/Volumes")
    let volumeURLs =
      (try? manager.contentsOfDirectory(at: volumes, includingPropertiesForKeys: nil)) ?? []
    roots += volumeURLs.map { $0.appendingPathComponent(".Trashes/\(getuid())") }
    return Array(Set(roots.map { $0.standardizedFileURL }))
  }

  private static func defaultDestinationRoots() -> [URL] {
    [
      FileManager.default.homeDirectoryForCurrentUser,
      URL(fileURLWithPath: "/Applications"),
      URL(fileURLWithPath: "/Library/Application Support"),
      URL(fileURLWithPath: "/Library/Caches"),
      URL(fileURLWithPath: "/Library/Preferences"),
      URL(fileURLWithPath: "/Library/LaunchAgents"),
      URL(fileURLWithPath: "/Library/LaunchDaemons"),
    ]
  }
}
