import Foundation

public enum EvidenceKind: String, Codable, CaseIterable, Sendable {
  case applicationArtifact
  case projectArtifact
  case traceChange
  case cleanup
  case restore
}

public struct EvidenceRecord: Codable, Hashable, Sendable {
  public let path: String
  public let kind: EvidenceKind
  public let safety: SafetyLevel
  public let reasons: [String]
  public let observedAt: Date

  public init(
    path: String, kind: EvidenceKind, safety: SafetyLevel, reasons: [String],
    observedAt: Date
  ) {
    self.path = path
    self.kind = kind
    self.safety = safety
    self.reasons = reasons
    self.observedAt = observedAt
  }
}

public enum ActivityKind: String, Codable, CaseIterable, Sendable {
  case cleanup
  case command
  case restore
  case trace
  case migration
  case export
}

public enum ActivityStatus: String, Codable, CaseIterable, Sendable {
  case started
  case succeeded
  case failed
  case cancelled
}

public struct ActivityEntry: Codable, Hashable, Identifiable, Sendable {
  public let id: UUID
  public let kind: ActivityKind
  public let status: ActivityStatus
  public let occurredAt: Date
  public let paths: [String]
  public let affectedBytes: Int64
  public let recoverable: Bool
  public let errors: [String]

  public init(
    id: UUID = UUID(), kind: ActivityKind, status: ActivityStatus = .succeeded,
    occurredAt: Date = Date(), paths: [String], affectedBytes: Int64,
    recoverable: Bool, errors: [String]
  ) {
    self.id = id
    self.kind = kind
    self.status = status
    self.occurredAt = occurredAt
    self.paths = paths
    self.affectedBytes = affectedBytes
    self.recoverable = recoverable
    self.errors = errors
  }
}
