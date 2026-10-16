import Foundation

enum LegacySourceDomain: String, Codable, Sendable {
  case diskora
  case macCleaner
  case changeora
}

struct LegacyTrashMoveRecord: Codable, Hashable, Sendable {
  let id: UUID
  let originalPath: String
  let trashPath: String
  let bytes: Int64
  var restoredAt: Date?
}

struct LegacyCleanupHistoryEntry: Codable, Hashable, Identifiable, Sendable {
  let id: UUID
  let date: Date
  let action: String
  let paths: [String]
  let bytes: Int64
  let recoverable: Bool
  let note: String
  var moves: [LegacyTrashMoveRecord]?
}

enum LegacySnapshotCategory: String, Codable, Sendable {
  case application = "Ứng dụng"
  case launchAgent = "LaunchAgent"
  case launchDaemon = "LaunchDaemon"
  case privilegedHelper = "Privileged Helper"
  case systemExtension = "System Extension"
  case applicationSupport = "Application Support"
  case cache = "Cache"
  case preference = "Preference"
  case container = "Container"
  case loginItem = "Login Item"
  case backgroundTask = "Background Task"
  case packageReceipt = "Package Receipt"
  case kernelExtension = "Kernel Extension"
  case configurationProfile = "Configuration Profile"
  case browserExtension = "Browser Extension"
  case shellConfiguration = "Shell / PATH"
}

struct LegacySnapshotItem: Codable, Hashable, Sendable {
  let id: String
  let category: LegacySnapshotCategory
  let name: String
  let path: String
  let size: Int64
  let modifiedAt: Date?
  let bundleIdentifier: String?
  let version: String?
  let teamIdentifier: String?
  let signatureStatus: String?
  let ownerHint: String?
}

struct LegacySystemSnapshot: Codable, Hashable, Sendable {
  let id: UUID
  let name: String
  let createdAt: Date
  let items: [LegacySnapshotItem]
  let inaccessiblePaths: [String]
  let truncated: Bool
}

enum LegacyChangeKind: String, Codable, Sendable {
  case added = "Đã thêm"
  case removed = "Đã gỡ"
  case modified = "Đã thay đổi"
}

enum LegacyChangeRisk: Int, Codable, Sendable {
  case informational = 0
  case review = 1
  case important = 2
}

struct LegacyChangeRecord: Codable, Hashable, Sendable {
  let id: String
  let kind: LegacyChangeKind
  let risk: LegacyChangeRisk
  let before: LegacySnapshotItem?
  let after: LegacySnapshotItem?
  let riskReason: String?
  let attributedApplication: String?
}

struct LegacyFileSystemEvent: Codable, Hashable, Sendable {
  let id: UUID
  let path: String
  let occurredAt: Date
  let flags: UInt32
}

struct LegacySnapshotComparison: Codable, Hashable, Sendable {
  let id: UUID
  let before: LegacySystemSnapshot
  let after: LegacySystemSnapshot
  let changes: [LegacyChangeRecord]
}

struct LegacyWatchSession: Codable, Hashable, Identifiable, Sendable {
  let id: UUID
  let title: String
  let startedAt: Date
  let finishedAt: Date
  let comparison: LegacySnapshotComparison
  let events: [LegacyFileSystemEvent]?
}

enum LegacyIdentifier {
  static func stableUUID(domain: LegacySourceDomain, originalID: UUID) -> UUID {
    let input = Array("toolbox-v1|\(domain.rawValue)|\(originalID.uuidString.lowercased())".utf8)
    let first = fnv1a(input, seed: 0xcbf2_9ce4_8422_2325)
    let second = fnv1a(input.reversed(), seed: 0x8422_2325_cbf2_9ce4)
    var bytes = withUnsafeBytes(of: first.bigEndian, Array.init)
    bytes.append(contentsOf: withUnsafeBytes(of: second.bigEndian, Array.init))
    bytes[6] = (bytes[6] & 0x0f) | 0x50
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    return UUID(
      uuid: (
        bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
      ))
  }

  private static func fnv1a<S: Sequence>(_ bytes: S, seed: UInt64) -> UInt64
  where S.Element == UInt8 {
    bytes.reduce(seed) { ($0 ^ UInt64($1)) &* 0x100_0000_01b3 }
  }
}

extension LegacyCleanupHistoryEntry {
  func migrated(from domain: LegacySourceDomain) -> LegacyCleanupHistoryEntry {
    LegacyCleanupHistoryEntry(
      id: LegacyIdentifier.stableUUID(domain: domain, originalID: id), date: date, action: action,
      paths: paths, bytes: bytes, recoverable: recoverable, note: note,
      moves: moves?.map { move in
        LegacyTrashMoveRecord(
          id: LegacyIdentifier.stableUUID(domain: domain, originalID: move.id),
          originalPath: move.originalPath, trashPath: move.trashPath, bytes: move.bytes,
          restoredAt: move.restoredAt)
      })
  }
}

extension LegacyWatchSession {
  func migrated() -> LegacyWatchSession {
    let domain = LegacySourceDomain.changeora
    return LegacyWatchSession(
      id: LegacyIdentifier.stableUUID(domain: domain, originalID: id), title: title,
      startedAt: startedAt, finishedAt: finishedAt,
      comparison: LegacySnapshotComparison(
        id: LegacyIdentifier.stableUUID(domain: domain, originalID: comparison.id),
        before: comparison.before.migrated(), after: comparison.after.migrated(),
        changes: comparison.changes),
      events: events?.map {
        LegacyFileSystemEvent(
          id: LegacyIdentifier.stableUUID(domain: domain, originalID: $0.id), path: $0.path,
          occurredAt: $0.occurredAt, flags: $0.flags)
      })
  }
}

extension LegacySystemSnapshot {
  func migrated() -> LegacySystemSnapshot {
    LegacySystemSnapshot(
      id: LegacyIdentifier.stableUUID(domain: .changeora, originalID: id), name: name,
      createdAt: createdAt, items: items, inaccessiblePaths: inaccessiblePaths,
      truncated: truncated)
  }
}
