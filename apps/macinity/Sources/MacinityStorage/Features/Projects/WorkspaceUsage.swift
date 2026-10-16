import Foundation

struct WorkspaceUsage: Sendable {
  let artifactBytes: Int64?
  let otherBytes: Int64?

  init(snapshot: StorageSnapshot, artifacts: [ProjectArtifact]) {
    guard let folders = snapshot.comparisonFolders else {
      artifactBytes = nil
      otherBytes = nil
      return
    }
    func canonical(_ path: String) -> String {
      URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
    }
    let root = canonical(snapshot.rootURL.path)
    var paths = Set<String>()
    for artifact in artifacts where artifact.safety == .safe {
      guard canonical(artifact.artifactURL.deletingLastPathComponent().path) == root else {
        artifactBytes = nil
        otherBytes = nil
        return
      }
      // Scanner aliases must use the analyzer's root spelling for dictionary lookup.
      paths.insert(
        snapshot.rootURL.appendingPathComponent(artifact.artifactURL.lastPathComponent).path)
    }
    let matched = paths.compactMap { folders[$0] }
    var sum: Int64 = 0
    for bytes in matched {
      let addition = sum.addingReportingOverflow(bytes)
      guard bytes >= 0, !addition.overflow else {
        artifactBytes = nil
        otherBytes = nil
        return
      }
      sum = addition.partialValue
    }
    guard sum <= snapshot.scannedBytes else {
      artifactBytes = nil
      otherBytes = nil
      return
    }
    artifactBytes = sum
    otherBytes = snapshot.scannedBytes - sum
  }
}
