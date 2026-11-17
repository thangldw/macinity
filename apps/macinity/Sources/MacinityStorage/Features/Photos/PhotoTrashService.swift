import Foundation
import MacinityCore

struct TrashOutcome: Sendable {
  var errors: [String] = []
  /// Photos that really left their folder, whether or not a recovery record could be made.
  var moved: [SimilarPhoto] = []
  var moves: [TrashMoveRecord] = []
}

/// Moves reviewed photos to the Trash (never deletes), validating each path against the scanned
/// root and recording the moves so they can be restored from the Recovery page.
@MainActor
struct PhotoTrashService {
  private let history = HistoryStore()
  private let activityLedger = ActivityLedger()

  /// Trash folders (`~/.Trash`, `<volume>/.Trashes`) are never valid targets: a copy already in
  /// the Trash must not count as the photo the user keeps.
  nonisolated static func isInsideTrash(_ url: URL) -> Bool {
    url.pathComponents.contains { $0 == ".Trash" || $0 == ".Trashes" }
  }

  /// Pure move step. `trash` performs the move and returns the new location when macOS reports
  /// one; tests inject a fake so the real Trash is never touched.
  nonisolated static func moveToTrash(
    photos: [SimilarPhoto], root: URL, trash: (URL) throws -> URL?
  ) -> TrashOutcome {
    let root = root.resolvingSymlinksInPath().standardizedFileURL
    var outcome = TrashOutcome()
    for photo in photos {
      guard !isInsideTrash(photo.url) else {
        outcome.errors.append(
          String(format: L10n.text("Không chuyển ảnh trong Trash: %@"), photo.url.path))
        continue
      }
      let url: URL
      do {
        url = try PathSafetyPolicy.validate(candidate: photo.url, allowedRoots: [root])
      } catch {
        outcome.errors.append(
          String(format: L10n.text("Đường dẫn không an toàn: %@"), photo.url.path))
        continue
      }
      // The reviewed file must still be the same regular file: not swapped for a symlink to
      // another file and not rewritten since the scan.
      let values = try? photo.url.resourceValues(forKeys: [
        .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey,
      ])
      guard values?.isRegularFile == true, values?.isSymbolicLink != true,
        Int64(values?.fileSize ?? -1) == photo.bytes
      else {
        outcome.errors.append(
          String(format: L10n.text("Ảnh đã thay đổi từ lúc quét: %@"), photo.url.path))
        continue
      }
      do {
        let trashed = try trash(url)
        outcome.moved.append(photo)
        if let trashed {
          outcome.moves.append(
            TrashMoveRecord(originalPath: url.path, trashPath: trashed.path, bytes: photo.bytes))
        }
      } catch {
        outcome.errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
      }
    }
    return outcome
  }

  /// Returns one message per file that could not be moved; the rest still move.
  func trash(photos: [SimilarPhoto], root: URL, note: String) async -> [String] {
    let outcome = await Task.detached {
      Self.moveToTrash(photos: photos, root: root) { url in
        var trashedURL: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &trashedURL)
        return trashedURL as URL?
      }
    }.value
    history.record(
      action: "Loại ảnh tương tự", paths: outcome.moved.map { $0.url.path },
      bytes: outcome.moved.reduce(0) { $0 + $1.bytes }, recoverable: !outcome.moves.isEmpty,
      note: note, moves: outcome.moves)
    try? activityLedger.append(
      ActivityEntry(
        kind: .cleanup, status: outcome.errors.isEmpty ? .succeeded : .failed,
        paths: photos.map { $0.url.path },
        affectedBytes: outcome.moved.reduce(0) { $0 + $1.bytes },
        recoverable: !outcome.moves.isEmpty, errors: outcome.errors))
    return outcome.errors
  }
}
