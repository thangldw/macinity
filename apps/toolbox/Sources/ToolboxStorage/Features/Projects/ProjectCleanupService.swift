import Foundation
import ToolboxCore

struct ProjectCleanupOutcome: Sendable {
  let artifact: ProjectArtifact
  let affectedBytes: Int64
  let move: TrashMoveRecord?
  let error: String?
}

struct ProjectCleanupService: Sendable {
  private let removalMethod: CleanupRemovalMethod

  init(removalMethod: CleanupRemovalMethod = .trash) {
    self.removalMethod = removalMethod
  }

  func moveToTrash(_ artifact: ProjectArtifact, allowedRoots: [URL]) -> ProjectCleanupOutcome {
    do {
      guard artifact.safety == .safe else {
        throw CleanerError.unsafePath(artifact.artifactURL.path)
      }
      let validated = try PathSafetyPolicy.validate(
        candidate: artifact.artifactURL, allowedRoots: allowedRoots)
      let move: TrashMoveRecord?
      switch removalMethod {
      case .trash:
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: validated, resultingItemURL: &resultingURL)
        move = resultingURL.map {
          TrashMoveRecord(
            originalPath: validated.path, trashPath: ($0 as URL).path, bytes: artifact.bytes)
        }
      case .permanentForTesting:
        try FileManager.default.removeItem(at: validated)
        move = nil
      }
      return ProjectCleanupOutcome(
        artifact: artifact, affectedBytes: artifact.bytes, move: move, error: nil)
    } catch {
      return ProjectCleanupOutcome(
        artifact: artifact, affectedBytes: 0, move: nil, error: error.localizedDescription)
    }
  }
}
