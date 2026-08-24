import Foundation

enum InstallerKind: String, Codable, CaseIterable, Sendable {
  case diskImage
  case installerPackage
  case applicationBundle

  var displayName: String {
    switch self {
    case .diskImage: "DMG"
    case .installerPackage: "PKG"
    case .applicationBundle: "App"
    }
  }
}

struct InstallerMetadata: Codable, Hashable, Sendable {
  let sourceURL: URL
  let displayName: String
  let kind: InstallerKind
  let observedAt: Date
}

enum InterruptedTraceRecovery: Equatable, Sendable {
  case none
  case interrupted(reducedCoverage: Bool)
}

enum InstallTraceError: LocalizedError, Equatable {
  case unsupportedType(String)
  case traceAlreadyActive
  case noActiveTrace

  var errorDescription: String? {
    switch self {
    case .unsupportedType(let path):
      "Toolbox chỉ nhận .dmg, .pkg hoặc .app: \(path)"
    case .traceAlreadyActive:
      "Một Install Trace đang hoạt động."
    case .noActiveTrace:
      "Không có Install Trace đang hoạt động."
    }
  }
}
