import Foundation

enum SnapshotCategory: String, Codable, CaseIterable, Identifiable, Sendable {
  case application = "Ứng dụng"
  case launchAgent = "LaunchAgent"
  case launchDaemon = "LaunchDaemon"
  case privilegedHelper = "Privileged Helper"
  case systemExtension = "System Extension"
  case applicationSupport = "Application Support"
  case cache = "Cache"
  case preference = "Preference"
  case container = "Container"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .application: "app"
    case .launchAgent: "person.badge.clock"
    case .launchDaemon: "gearshape.2"
    case .privilegedHelper: "lock.shield"
    case .systemExtension: "puzzlepiece.extension"
    case .applicationSupport: "folder.badge.gearshape"
    case .cache: "shippingbox"
    case .preference: "slider.horizontal.3"
    case .container: "square.stack.3d.up"
    }
  }
}

struct SnapshotItem: Identifiable, Codable, Hashable, Sendable {
  let id: String
  let category: SnapshotCategory
  let name: String
  let path: String
  let size: Int64
  let modifiedAt: Date?
  let bundleIdentifier: String?
  let version: String?
  let teamIdentifier: String?
  let signatureStatus: String?
  let ownerHint: String?

  var comparisonFingerprint: String {
    [
      String(size),
      modifiedAt.map { String($0.timeIntervalSince1970.rounded()) } ?? "",
      bundleIdentifier ?? "",
      version ?? "",
      teamIdentifier ?? "",
      signatureStatus ?? "",
      ownerHint ?? "",
    ].joined(separator: "|")
  }
}

struct SystemSnapshot: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let name: String
  let createdAt: Date
  let items: [SnapshotItem]
  let inaccessiblePaths: [String]
  let truncated: Bool

  init(
    id: UUID = UUID(),
    name: String,
    createdAt: Date = Date(),
    items: [SnapshotItem],
    inaccessiblePaths: [String] = [],
    truncated: Bool = false
  ) {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.items = items
    self.inaccessiblePaths = inaccessiblePaths
    self.truncated = truncated
  }
}

enum ChangeKind: String, Codable, CaseIterable, Sendable {
  case added = "Đã thêm"
  case removed = "Đã gỡ"
  case modified = "Đã thay đổi"

  var symbol: String {
    switch self {
    case .added: "plus.circle.fill"
    case .removed: "minus.circle.fill"
    case .modified: "arrow.triangle.2.circlepath.circle.fill"
    }
  }
}

enum ChangeRisk: Int, Codable, CaseIterable, Comparable, Sendable {
  case informational = 0
  case review = 1
  case important = 2

  static func < (lhs: ChangeRisk, rhs: ChangeRisk) -> Bool { lhs.rawValue < rhs.rawValue }

  var title: String {
    switch self {
    case .informational: "Thông tin"
    case .review: "Nên xem"
    case .important: "Quan trọng"
    }
  }

  var symbol: String {
    switch self {
    case .informational: "info.circle"
    case .review: "eye.circle"
    case .important: "exclamationmark.shield"
    }
  }
}

struct ChangeRecord: Identifiable, Codable, Hashable, Sendable {
  let id: String
  let kind: ChangeKind
  let risk: ChangeRisk
  let before: SnapshotItem?
  let after: SnapshotItem?

  var item: SnapshotItem { after ?? before! }
}

struct SnapshotComparison: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let before: SystemSnapshot
  let after: SystemSnapshot
  let changes: [ChangeRecord]

  init(
    id: UUID = UUID(), before: SystemSnapshot, after: SystemSnapshot,
    changes: [ChangeRecord]
  ) {
    self.id = id
    self.before = before
    self.after = after
    self.changes = changes
  }

  var importantCount: Int { changes.count { $0.risk == .important } }
  var reviewCount: Int { changes.count { $0.risk == .review } }
  var addedCount: Int { changes.count { $0.kind == .added } }
  var removedCount: Int { changes.count { $0.kind == .removed } }
  var modifiedCount: Int { changes.count { $0.kind == .modified } }
}

struct WatchSession: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  let title: String
  let startedAt: Date
  let finishedAt: Date
  let comparison: SnapshotComparison

  init(
    id: UUID = UUID(), title: String, startedAt: Date, finishedAt: Date,
    comparison: SnapshotComparison
  ) {
    self.id = id
    self.title = title
    self.startedAt = startedAt
    self.finishedAt = finishedAt
    self.comparison = comparison
  }
}
