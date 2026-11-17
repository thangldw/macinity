import Foundation
import ImageIO
import MacinityCore
import Vision

struct NearDuplicateProgress: Sendable {
  enum Phase: Sendable { case enumerating, hashing, confirming }
  let phase: Phase
  let completed: Int
  let total: Int
}

struct NearDuplicateSnapshot: Sendable {
  /// Only photos that belong to at least one confirmed pair.
  let photos: [SimilarPhoto]
  /// Indices point into `photos`; distance is the Vision feature-print distance.
  let pairs: [PhotoPairDistance]
  let scannedCount: Int
  let cachedCount: Int
  let skippedCount: Int
  /// Photos left out of the comparison because many share an identical fingerprint.
  let skippedPhotos: Int
}

/// Stage 1: cached dHash and an index find candidate pairs across the whole root.
/// Stage 2: Vision feature-print distance confirms them. Nothing here modifies files.
struct NearDuplicateScanner: Sendable {
  /// 80% estimated similarity is the lowest the UI offers.
  static let confirmationDistanceLimit: Float = 0.20
  static let candidateHamming = 10
  private static let extensions: Set<String> = [
    "jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "webp",
  ]

  var maxBucket = 5_000
  var maxIdentical = 1_000

  enum ScanError: Error, LocalizedError {
    case unsupportedSystem
    case unreadableRoot
    var errorDescription: String? {
      switch self {
      case .unsupportedSystem: L10n.text("Phiên bản macOS này chưa hỗ trợ so sánh ảnh giống nhau")
      case .unreadableRoot: L10n.text("Không đọc được thư mục này")
      }
    }
  }

  /// The 0.0–1.0 similarity scale is only valid for feature-print revision 2; revision 1 uses a
  /// different scale, so without revision 2 the feature must not run.
  static func featurePrintRevision(supported: Set<Int>) -> Int? {
    supported.contains(2) ? 2 : nil
  }

  private struct PhotoFile {
    let url: URL
    let bytes: Int64
    let modified: Date
  }

  func scan(
    rootURL: URL, cacheURL: URL, progress: @Sendable (NearDuplicateProgress) -> Void = { _ in }
  ) throws -> NearDuplicateSnapshot {
    guard
      Self.featurePrintRevision(supported: Set(VNGenerateImageFeaturePrintRequest.supportedRevisions))
        != nil
    else { throw ScanError.unsupportedSystem }
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    // A missing or permission-denied root would otherwise look like "no duplicates found".
    guard (try? FileManager.default.contentsOfDirectory(atPath: root.path)) != nil else {
      throw ScanError.unreadableRoot
    }
    let files = try enumerate(root)
    progress(.init(phase: .enumerating, completed: files.count, total: files.count))

    var cache = PhotoFingerprintCache(fileURL: cacheURL)
    var hashes = [UInt64?](repeating: nil, count: files.count)
    var cached = 0
    var pending: [Int] = []
    for (position, file) in files.enumerated() {
      if let known = cache.hash(path: file.url.path, size: file.bytes, modified: file.modified) {
        hashes[position] = known
        cached += 1
      } else {
        pending.append(position)
      }
    }
    // Decode in parallel batches; cancellation is checked between batches because GCD worker
    // threads do not see the task's cancellation.
    let batchSize = 64
    for batchStart in stride(from: 0, to: pending.count, by: batchSize) {
      if Task.isCancelled {
        try? cache.save()  // keep the hashes computed so far for the next scan
        throw CancellationError()
      }
      let batch = Array(pending[batchStart..<min(batchStart + batchSize, pending.count)])
      let results = HashResults(count: batch.count)
      DispatchQueue.concurrentPerform(iterations: batch.count) { offset in
        results.set(offset, PhotoFingerprint.dHash(of: files[batch[offset]].url))
      }
      for (offset, position) in batch.enumerated() {
        guard let computed = results.get(offset) else { continue }
        let file = files[position]
        cache.store(
          path: file.url.path, size: file.bytes, modified: file.modified, hash: computed)
        hashes[position] = computed
      }
      progress(.init(phase: .hashing, completed: batchStart + batch.count, total: pending.count))
    }
    if Task.isCancelled { throw CancellationError() }
    try? cache.save()

    let usable = files.indices.filter { hashes[$0] != nil }
    let skipped = files.count - usable.count
    let candidates = PhotoHashIndex(hashes: usable.compactMap { hashes[$0] })
      .candidatePairs(
        maxHamming: Self.candidateHamming, maxBucket: maxBucket, maxIdentical: maxIdentical)

    var observations: [Int: VNFeaturePrintObservation] = [:]
    let involved = Set(candidates.pairs.flatMap { [$0.first, $0.second] }).sorted()
    var failed = 0
    for (position, index) in involved.enumerated() {
      if Task.isCancelled { throw CancellationError() }
      if let observation = Self.featurePrint(of: files[usable[index]].url) {
        observations[index] = observation
      } else {
        failed += 1
      }
      if position % 50 == 0 {
        progress(.init(phase: .confirming, completed: position, total: involved.count))
      }
    }

    var confirmed: [(first: Int, second: Int, distance: Float)] = []
    for pair in candidates.pairs {
      if Task.isCancelled { throw CancellationError() }
      guard let a = observations[pair.first], let b = observations[pair.second] else { continue }
      var distance: Float = 0
      guard (try? a.computeDistance(&distance, to: b)) != nil,
        distance <= Self.confirmationDistanceLimit
      else { continue }
      confirmed.append((pair.first, pair.second, distance))
    }

    let kept = Set(confirmed.flatMap { [$0.first, $0.second] }).sorted()
    var remap: [Int: Int] = [:]
    var photos: [SimilarPhoto] = []
    for index in kept {
      if Task.isCancelled { throw CancellationError() }
      let file = files[usable[index]]
      let metadata = PhotoMetadata.read(url: file.url, fallback: file.modified)
      remap[index] = photos.count
      photos.append(
        SimilarPhoto(
          url: file.url, bytes: file.bytes, capturedAt: metadata.date,
          pixelWidth: metadata.width, pixelHeight: metadata.height,
          sharpnessScore: PhotoMetadata.sharpness(at: file.url)))
    }
    let pairs = confirmed.compactMap { pair -> PhotoPairDistance? in
      guard let first = remap[pair.first], let second = remap[pair.second] else { return nil }
      return PhotoPairDistance(first: first, second: second, distance: pair.distance)
    }
    return NearDuplicateSnapshot(
      photos: photos, pairs: pairs, scannedCount: files.count, cachedCount: cached,
      skippedCount: skipped + failed, skippedPhotos: candidates.skippedPhotos)
  }

  /// Both sides of a comparison are reduced to the same small size first, so a resized copy is
  /// judged by its content rather than by its resolution (measured: full-size prints of a 1/4
  /// copy differ far more than 128px prints).
  static let featurePrintPixels = 128

  private static func featurePrint(of url: URL) -> VNFeaturePrintObservation? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let thumbnail = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: featurePrintPixels,
        ] as CFDictionary)
    else { return nil }
    let request = VNGenerateImageFeaturePrintRequest()
    request.revision = 2
    guard (try? VNImageRequestHandler(cgImage: thumbnail).perform([request])) != nil else {
      return nil
    }
    return request.results?.first as? VNFeaturePrintObservation
  }

  private func enumerate(_ root: URL) throws -> [PhotoFile] {
    let keys: Set<URLResourceKey> = [
      .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey,
      .ubiquitousItemDownloadingStatusKey,
    ]
    guard
      let enumerator = FileManager().enumerator(
        at: root, includingPropertiesForKeys: Array(keys),
        options: [.skipsPackageDescendants, .skipsHiddenFiles], errorHandler: { _, _ in true })
    else { throw CocoaError(.fileReadUnknown) }
    var files: [PhotoFile] = []
    for case let url as URL in enumerator {
      if Task.isCancelled { throw CancellationError() }
      guard Self.extensions.contains(url.pathExtension.lowercased()),
        let values = try? url.resourceValues(forKeys: keys),
        values.isRegularFile == true, values.isSymbolicLink != true,
        // Reading an iCloud placeholder would download it just to compare it.
        values.ubiquitousItemDownloadingStatus != .notDownloaded
      else { continue }
      files.append(
        PhotoFile(
          url: url.standardizedFileURL, bytes: Int64(values.fileSize ?? 0),
          modified: values.contentModificationDate ?? .distantPast))
    }
    return files.sorted { $0.url.path < $1.url.path }
  }
}

/// Thread-safe slots for results computed in `DispatchQueue.concurrentPerform`.
private final class HashResults: @unchecked Sendable {
  private let lock = NSLock()
  private var values: [UInt64?]
  init(count: Int) { values = [UInt64?](repeating: nil, count: count) }
  func set(_ index: Int, _ value: UInt64?) {
    lock.lock()
    values[index] = value
    lock.unlock()
  }
  func get(_ index: Int) -> UInt64? {
    lock.lock()
    defer { lock.unlock() }
    return values[index]
  }
}
