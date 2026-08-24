import Foundation
import ToolboxCore

enum ProjectEcosystem: String, Codable, CaseIterable, Identifiable, Sendable {
  case swift = "Swift"
  case node = "Node.js"
  case python = "Python"
  case rust = "Rust"
  case gradle = "Gradle"
  case flutter = "Flutter"
  case cocoapods = "CocoaPods"

  var id: String { rawValue }
}

struct ProjectArtifact: Codable, Hashable, Identifiable, Sendable {
  let projectRoot: URL
  let artifactURL: URL
  let ecosystem: ProjectEcosystem
  let bytes: Int64
  let modifiedAt: Date?
  let safety: SafetyLevel
  let reasons: [String]

  var id: String {
    "\(projectRoot.standardizedFileURL.path)|\(artifactURL.standardizedFileURL.path)|\(ecosystem.rawValue)"
  }
}

struct ProjectScanIssue: Codable, Hashable, Sendable {
  let path: String
  let message: String
}

struct ProjectScanReport: Codable, Hashable, Sendable {
  let roots: [URL]
  let scannedProjectCount: Int
  let artifacts: [ProjectArtifact]
  let issues: [ProjectScanIssue]
  let cancelled: Bool

  var reclaimableBytes: Int64 {
    artifacts.filter { $0.safety == .safe }.reduce(0) { $0 + $1.bytes }
  }
}

struct ProjectRule: Sendable {
  let ecosystem: ProjectEcosystem
  let anyMarkers: Set<String>
  let artifactPaths: Set<String>
}
