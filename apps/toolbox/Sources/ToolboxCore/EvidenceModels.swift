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
