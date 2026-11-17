import AppKit
import Foundation
import MacinityCore

@MainActor
final class NearDuplicatePhotoViewModel: ObservableObject {
  static let similarityRange = 0.80...1.0
  typealias Trasher = @MainActor ([SimilarPhoto], URL, String) async -> [String]

  private struct PairKey: Hashable {
    let first: String
    let second: String
    init(_ a: String, _ b: String) { (first, second) = a < b ? (a, b) : (b, a) }
  }

  @Published var rootURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
    "Pictures")
  @Published private(set) var minimumSimilarity = 0.90
  @Published var folderFilter: String?
  @Published private(set) var allGroups: [SimilarPhotoGroup] = []
  @Published private(set) var deleteIDs: Set<String> = []
  @Published private(set) var isWorking = false
  @Published private(set) var hasScanned = false
  @Published private(set) var skippedPhotos = 0
  @Published private(set) var skippedFiles = 0
  @Published private(set) var trashErrors: [String] = []
  @Published private(set) var isTrashing = false
  /// Why the last Keep/Remove change was refused; cleared by the next accepted change.
  @Published private(set) var hint: String?
  @Published var status = L10n.text("Chọn thư mục ảnh để bắt đầu")
  @Published var errorMessage: String?

  private var snapshot: NearDuplicateSnapshot?
  /// Photos already moved to the Trash; they leave the results without another scan.
  private var removedIDs: Set<String> = []
  /// Per-photo choices the user made; everything else follows the suggestion.
  private var overrides: [String: Bool] = [:]
  private var directDistance: [PairKey: Float] = [:]
  private var task: Task<Void, Never>?
  private var scanGeneration = 0
  /// Trash is validated against the folder that was actually scanned, not the editable path.
  private var scannedRoot: URL?
  private let trasher: Trasher
  private let cacheURL: URL

  init(trasher: Trasher? = nil, cacheURL: URL? = nil) {
    self.cacheURL =
      cacheURL
      ?? AppMetadata.applicationSupportDirectory().appendingPathComponent(
        "photo-fingerprints-v1.json")
    self.trasher =
      trasher ?? { photos, root, note in
        await PhotoTrashService().trash(photos: photos, root: root, note: note)
      }
  }

  /// Groups after the folder filter; summary and Trash act on these only.
  var groups: [SimilarPhotoGroup] {
    guard let folderFilter else { return allGroups }
    return allGroups.filter { group in
      group.photos.contains { $0.url.deletingLastPathComponent().path == folderFilter }
    }
  }

  var folders: [String] {
    Array(Set(allGroups.flatMap(\.photos).map { $0.url.deletingLastPathComponent().path }))
      .sorted()
  }

  private var visiblePhotos: [SimilarPhoto] { groups.flatMap(\.photos) }
  var deleteCount: Int { visiblePhotos.count { deleteIDs.contains($0.id) } }
  var keepCount: Int { visiblePhotos.count - deleteCount }
  var bytesFreed: Int64 {
    visiblePhotos.filter { deleteIDs.contains($0.id) }.reduce(0) { $0 + $1.bytes }
  }

  func isDeleting(_ photo: SimilarPhoto) -> Bool { deleteIDs.contains(photo.id) }

  /// Measured similarity to the photo suggested to keep; nil when the two were never compared
  /// directly (they only belong to the same group through other photos).
  func similarityToKeeper(_ photo: SimilarPhoto, in group: SimilarPhotoGroup) -> Double? {
    guard photo.id != group.recommendedID,
      let distance = directDistance[PairKey(photo.id, group.recommendedID)]
    else { return nil }
    return 1 - Double(distance)
  }

  /// The photo to compare against: the best photo of the group that is currently kept.
  func keptPhoto(for photo: SimilarPhoto, in group: SimilarPhotoGroup) -> SimilarPhoto? {
    group.photos.first { $0.id != photo.id && !deleteIDs.contains($0.id) }
  }

  func load(snapshot: NearDuplicateSnapshot, root: URL? = nil) {
    self.snapshot = snapshot
    scannedRoot = root
    hint = nil
    skippedPhotos = snapshot.skippedPhotos
    skippedFiles = snapshot.skippedCount
    removedIDs = []
    overrides = [:]
    folderFilter = nil
    regroup()
  }

  func setMinimumSimilarity(_ value: Double) {
    minimumSimilarity = min(
      max(value, Self.similarityRange.lowerBound), Self.similarityRange.upperBound)
    regroup()
  }

  /// Returns false when the change would leave a group with no photo to keep.
  @discardableResult
  func setDelete(_ photo: SimilarPhoto, _ value: Bool) -> Bool {
    guard let group = allGroups.first(where: { $0.photos.contains { $0.id == photo.id } }) else {
      return false
    }
    if value {
      let stillKept = group.photos.filter { $0.id != photo.id && !deleteIDs.contains($0.id) }
      guard !stillKept.isEmpty else {
        hint = L10n.text("Mỗi nhóm phải giữ lại ít nhất một ảnh")
        return false
      }
    }
    hint = nil
    overrides[photo.id] = value
    recomputeDecisions()
    return true
  }

  func applySuggestions() {
    overrides = [:]
    recomputeDecisions()
  }

  func chooseRoot() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.directoryURL = rootURL
    if panel.runModal() == .OK, let url = panel.url {
      rootURL = url
      snapshot = nil
      scannedRoot = nil
      hint = nil
      removedIDs = []
      overrides = [:]
      allGroups = []
      deleteIDs = []
      folderFilter = nil
      trashErrors = []
      errorMessage = nil
      hasScanned = false
    }
  }

  @discardableResult
  func scan() -> Task<Void, Never> {
    task?.cancel()
    scanGeneration += 1
    let generation = scanGeneration
    isWorking = true
    errorMessage = nil
    trashErrors = []
    hint = nil
    status = L10n.text("Đang quét ảnh…")
    ScanActivityRegistry.shared.begin()
    let root = rootURL
    let cacheURL = self.cacheURL
    let newTask = Task {
      // A newer scan owns the visible state; an older one only releases its activity token.
      do {
        let result = try await CancellableWork.run {
          try NearDuplicateScanner().scan(rootURL: root, cacheURL: cacheURL) {
            [weak self] progress in
            Task { @MainActor in self?.report(progress) }
          }
        }
        if generation == scanGeneration {
          load(snapshot: result, root: root)
          hasScanned = true
          status = String(format: L10n.text("Tìm thấy %lld nhóm ảnh giống nhau"), allGroups.count)
        }
      } catch is CancellationError {
        if generation == scanGeneration { status = L10n.text("Đã dừng quét") }
      } catch {
        if generation == scanGeneration {
          errorMessage = error.localizedDescription
          status = L10n.text("Không thể quét ảnh")
        }
      }
      ScanActivityRegistry.shared.end()
      if generation == scanGeneration { isWorking = false }
    }
    task = newTask
    return newTask
  }

  func cancel() { task?.cancel() }

  func trashSelected() {
    Task { await trashSelectedAsync() }
  }

  func trashSelectedAsync() async {
    guard !isWorking else { return }
    trashErrors = []
    var photos: [SimilarPhoto] = []
    var blockedGroups = 0
    for group in groups {
      let removals = group.photos.filter { deleteIDs.contains($0.id) }
      guard !removals.isEmpty else { continue }
      // Never trash a group's copies unless a photo to keep is still on disk.
      let keeperExists = group.photos.contains {
        !deleteIDs.contains($0.id) && FileManager.default.fileExists(atPath: $0.url.path)
      }
      if keeperExists { photos += removals } else { blockedGroups += 1 }
    }
    if blockedGroups > 0 {
      trashErrors.append(
        String(format: L10n.text("Bỏ qua %lld nhóm vì không còn ảnh giữ lại trên đĩa"), blockedGroups))
    }
    guard !photos.isEmpty else { return }
    isWorking = true
    isTrashing = true
    let errors = await trasher(
      photos, scannedRoot ?? rootURL, "Ảnh đã chuyển vào Trash sau khi người dùng duyệt")
    trashErrors += errors
    removedIDs.formUnion(
      photos.filter { !FileManager.default.fileExists(atPath: $0.url.path) }.map(\.id))
    isTrashing = false
    isWorking = false
    regroup()
  }

  private func report(_ progress: NearDuplicateProgress) {
    guard isWorking else { return }
    switch progress.phase {
    case .enumerating: status = L10n.text("Đang liệt kê ảnh…")
    case .hashing:
      status = String(
        format: L10n.text("Đang tính dấu vân tay ảnh %lld/%lld"), progress.completed,
        progress.total)
    case .confirming:
      status = String(
        format: L10n.text("Đang đối chiếu ảnh giống nhau %lld/%lld"), progress.completed,
        progress.total)
    }
  }

  private func regroup() {
    guard let snapshot else {
      allGroups = []
      deleteIDs = []
      directDistance = [:]
      return
    }
    var remap: [Int: Int] = [:]
    var photos: [SimilarPhoto] = []
    for (index, photo) in snapshot.photos.enumerated() where !removedIDs.contains(photo.id) {
      remap[index] = photos.count
      photos.append(photo)
    }
    let pairs = snapshot.pairs.compactMap { pair -> PhotoPairDistance? in
      guard let first = remap[pair.first], let second = remap[pair.second] else { return nil }
      return PhotoPairDistance(first: first, second: second, distance: pair.distance)
    }
    directDistance = [:]
    for pair in pairs {
      let key = PairKey(photos[pair.first].id, photos[pair.second].id)
      directDistance[key] = min(directDistance[key] ?? .infinity, pair.distance)
    }
    allGroups = NearDuplicateGrouping.groups(
      photos: photos, pairs: pairs, minimumSimilarity: minimumSimilarity)
    if let folderFilter, !folders.contains(folderFilter) { self.folderFilter = nil }
    recomputeDecisions()
  }

  /// Suggestion first, then the user's choices. By default only photos that were compared
  /// directly with the photo to keep, at the current similarity, are marked Remove; a group
  /// never ends up with nothing to keep.
  private func recomputeDecisions() {
    var result: Set<String> = []
    for group in allGroups {
      var chosen = Set(
        group.photos.filter { photo in
          if let override = overrides[photo.id] { return override }
          guard photo.id != group.recommendedID,
            let similarity = similarityToKeeper(photo, in: group)
          else { return false }
          return similarity >= minimumSimilarity - 1e-6
        }.map(\.id))
      if chosen.count == group.photos.count { chosen.remove(group.recommendedID) }
      result.formUnion(chosen)
    }
    deleteIDs = result
  }
}
