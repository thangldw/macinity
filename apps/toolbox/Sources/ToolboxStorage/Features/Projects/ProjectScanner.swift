import Foundation
import ToolboxCore

struct ProjectScanner: Sendable {
  static let rules: [ProjectRule] = [
    .init(ecosystem: .swift, anyMarkers: ["Package.swift"], artifactPaths: [".build"]),
    .init(ecosystem: .node, anyMarkers: ["package.json"], artifactPaths: ["node_modules"]),
    .init(
      ecosystem: .python, anyMarkers: ["pyproject.toml"], artifactPaths: [".venv", "venv"]),
    .init(ecosystem: .rust, anyMarkers: ["Cargo.toml"], artifactPaths: ["target"]),
    .init(
      ecosystem: .gradle, anyMarkers: ["settings.gradle", "settings.gradle.kts"],
      artifactPaths: [".gradle", "build"]),
    .init(
      ecosystem: .flutter, anyMarkers: ["pubspec.yaml"],
      artifactPaths: [".dart_tool", "build"]),
    .init(ecosystem: .cocoapods, anyMarkers: ["Podfile"], artifactPaths: ["Pods"]),
  ]

  private let maximumDiscoveryDepth: Int

  init(maximumDiscoveryDepth: Int = 5) {
    self.maximumDiscoveryDepth = maximumDiscoveryDepth
  }

  func scan(roots: [URL]) async -> ProjectScanReport {
    let manager = FileManager()
    let normalizedRoots = Array(
      Set(roots.map { $0.resolvingSymlinksInPath().standardizedFileURL })
    ).sorted { $0.path < $1.path }
    var artifactsByPath: [String: ProjectArtifact] = [:]
    var issues: [ProjectScanIssue] = []
    var scannedProjects = Set<String>()
    var cancelled = false

    for root in normalizedRoots {
      if Task.isCancelled {
        cancelled = true
        break
      }
      guard isDirectory(root, manager: manager) else {
        issues.append(ProjectScanIssue(path: root.path, message: "Thư mục không còn tồn tại."))
        continue
      }
      scanDirectory(
        root, selectedRoot: root, depth: 0, manager: manager,
        scannedProjects: &scannedProjects, artifactsByPath: &artifactsByPath, issues: &issues,
        cancelled: &cancelled)
    }

    let artifacts = artifactsByPath.values.sorted {
      if $0.projectRoot.path != $1.projectRoot.path {
        return $0.projectRoot.path < $1.projectRoot.path
      }
      return $0.artifactURL.path < $1.artifactURL.path
    }
    return ProjectScanReport(
      roots: normalizedRoots, scannedProjectCount: scannedProjects.count, artifacts: artifacts,
      issues: issues.sorted { $0.path < $1.path }, cancelled: cancelled)
  }

  private func scanDirectory(
    _ directory: URL, selectedRoot: URL, depth: Int, manager: FileManager,
    scannedProjects: inout Set<String>, artifactsByPath: inout [String: ProjectArtifact],
    issues: inout [ProjectScanIssue], cancelled: inout Bool
  ) {
    guard !Task.isCancelled else {
      cancelled = true
      return
    }

    let children: [URL]
    do {
      children = try manager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey],
        options: [])
    } catch {
      issues.append(ProjectScanIssue(path: directory.path, message: error.localizedDescription))
      return
    }

    let childNames = Set(children.map(\.lastPathComponent))
    let matchedRules = Self.rules.filter { !$0.anyMarkers.isDisjoint(with: childNames) }
    if !matchedRules.isEmpty {
      scannedProjects.insert(directory.standardizedFileURL.path)
      collectArtifacts(
        for: matchedRules, projectRoot: directory, selectedRoot: selectedRoot, manager: manager,
        artifactsByPath: &artifactsByPath, issues: &issues)
    }

    guard depth < maximumDiscoveryDepth else { return }
    let artifactNames = Set(Self.rules.flatMap(\.artifactPaths))
    let prunedNames: Set<String> = [
      ".git", ".hg", ".svn", "Library", "Movies", "Music", "Pictures",
      "Photos Library.photoslibrary",
    ]

    for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
      if Task.isCancelled {
        cancelled = true
        return
      }
      let name = child.lastPathComponent
      guard !prunedNames.contains(name), !artifactNames.contains(name) else { continue }
      guard !name.hasPrefix(".") else { continue }
      guard
        let values = try? child.resourceValues(
          forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey]),
        values.isDirectory == true, values.isSymbolicLink != true, values.isPackage != true
      else { continue }
      scanDirectory(
        child, selectedRoot: selectedRoot, depth: depth + 1, manager: manager,
        scannedProjects: &scannedProjects, artifactsByPath: &artifactsByPath, issues: &issues,
        cancelled: &cancelled)
    }
  }

  private func collectArtifacts(
    for rules: [ProjectRule], projectRoot: URL, selectedRoot: URL, manager: FileManager,
    artifactsByPath: inout [String: ProjectArtifact], issues: inout [ProjectScanIssue]
  ) {
    for rule in rules {
      for relativePath in rule.artifactPaths.sorted() {
        let candidate = projectRoot.appendingPathComponent(relativePath, isDirectory: true)
        guard manager.fileExists(atPath: candidate.path) else { continue }
        let key = candidate.standardizedFileURL.path
        guard artifactsByPath[key] == nil else { continue }

        let safety: SafetyLevel
        let bytes: Int64
        let reasons: [String]
        do {
          _ = try PathSafetyPolicy.validate(candidate: candidate, allowedRoots: [selectedRoot])
          safety = .safe
          bytes = directorySize(candidate, manager: manager)
          reasons = [reason(for: relativePath, ecosystem: rule.ecosystem)]
        } catch {
          safety = .protected
          bytes = 0
          reasons = ["Artifact vượt khỏi project root đã chọn nên bị chặn."]
          issues.append(ProjectScanIssue(path: candidate.path, message: error.localizedDescription))
        }

        let modifiedAt = try? candidate.resourceValues(forKeys: [.contentModificationDateKey])
          .contentModificationDate
        artifactsByPath[key] = ProjectArtifact(
          projectRoot: projectRoot, artifactURL: candidate, ecosystem: rule.ecosystem,
          bytes: bytes, modifiedAt: modifiedAt, safety: safety, reasons: reasons)
      }
    }
  }

  private func directorySize(_ root: URL, manager: FileManager) -> Int64 {
    let keys: Set<URLResourceKey> = [
      .isRegularFileKey, .isSymbolicLinkKey, .fileAllocatedSizeKey,
      .totalFileAllocatedSizeKey, .fileSizeKey,
    ]
    guard
      let enumerator = manager.enumerator(
        at: root, includingPropertiesForKeys: Array(keys), options: [.skipsPackageDescendants],
        errorHandler: { _, _ in true })
    else { return 0 }

    var total: Int64 = 0
    for case let file as URL in enumerator {
      if Task.isCancelled { break }
      let values = try? file.resourceValues(forKeys: keys)
      if values?.isSymbolicLink == true {
        enumerator.skipDescendants()
        continue
      }
      guard values?.isRegularFile == true else { continue }
      total += Int64(
        max(
          values?.totalFileAllocatedSize ?? 0, values?.fileAllocatedSize ?? 0,
          values?.fileSize ?? 0))
    }
    return total
  }

  private func isDirectory(_ url: URL, manager: FileManager) -> Bool {
    var isDirectory: ObjCBool = false
    return manager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
  }

  private func reason(for artifact: String, ecosystem: ProjectEcosystem) -> String {
    "\(artifact) được nhận diện từ marker \(ecosystem.rawValue) và có thể tạo lại."
  }
}
