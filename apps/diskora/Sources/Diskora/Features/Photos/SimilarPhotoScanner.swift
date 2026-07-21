import Foundation
import ImageIO
import Vision

struct SimilarPhoto: Identifiable, Sendable {
  let url: URL
  let bytes: Int64
  let capturedAt: Date
  var id: String { url.path }
}

struct SimilarPhotoGroup: Identifiable, Sendable {
  let id: String
  let photos: [SimilarPhoto]
  let recommendedID: String
  let maximumDistance: Float
  var reclaimableBytes: Int64 {
    photos.filter { $0.id != recommendedID }.reduce(0) { $0 + $1.bytes }
  }
}

struct SimilarPhotoSnapshot: Sendable {
  let groups: [SimilarPhotoGroup]
  let analyzedCount: Int
  let skippedCount: Int
  var reclaimableBytes: Int64 { groups.reduce(0) { $0 + $1.reclaimableBytes } }
}

struct SimilarPhotoScanner: Sendable {
  private struct Candidate {
    let photo: SimilarPhoto
    let observation: VNFeaturePrintObservation
  }

  func scan(rootURL: URL, timeWindow: TimeInterval = 10, distanceLimit: Float = 0.35) throws
    -> SimilarPhotoSnapshot
  {
    let manager = FileManager()
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    let extensions = Set(["jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "webp"])
    let keys: Set<URLResourceKey> = [
      .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey,
    ]
    guard
      let enumerator = manager.enumerator(
        at: root, includingPropertiesForKeys: Array(keys), options: [.skipsPackageDescendants])
    else {
      throw CocoaError(.fileReadUnknown)
    }
    var photos: [SimilarPhoto] = []
    for case let url as URL in enumerator {
      if Task.isCancelled { throw CancellationError() }
      guard extensions.contains(url.pathExtension.lowercased()),
        let values = try? url.resourceValues(forKeys: keys),
        values.isRegularFile == true, values.isSymbolicLink != true
      else { continue }
      photos.append(
        SimilarPhoto(
          url: url.standardizedFileURL,
          bytes: Int64(values.fileSize ?? 0),
          capturedAt: captureDate(
            url: url, fallback: values.contentModificationDate ?? .distantPast)
        ))
    }

    let folderGroups = Dictionary(grouping: photos) { $0.url.deletingLastPathComponent().path }
    var output: [SimilarPhotoGroup] = []
    var analyzed = 0
    var skipped = 0
    for folderPhotos in folderGroups.values {
      let sorted = folderPhotos.sorted { $0.capturedAt < $1.capturedAt }
      var temporal: [[SimilarPhoto]] = []
      for photo in sorted {
        if let last = temporal.indices.last,
          let previous = temporal[last].last,
          photo.capturedAt.timeIntervalSince(previous.capturedAt) <= timeWindow
        {
          temporal[last].append(photo)
        } else {
          temporal.append([photo])
        }
      }
      for cluster in temporal where cluster.count > 1 {
        var candidates: [Candidate] = []
        for photo in cluster {
          if Task.isCancelled { throw CancellationError() }
          do {
            let request = VNGenerateImageFeaturePrintRequest()
            try VNImageRequestHandler(url: photo.url).perform([request])
            guard let observation = request.results?.first as? VNFeaturePrintObservation else {
              skipped += 1
              continue
            }
            candidates.append(Candidate(photo: photo, observation: observation))
            analyzed += 1
          } catch { skipped += 1 }
        }
        guard let first = candidates.first else { continue }
        var similar = [first]
        var maxDistance: Float = 0
        for candidate in candidates.dropFirst() {
          var distance: Float = 0
          try first.observation.computeDistance(&distance, to: candidate.observation)
          if distance <= distanceLimit {
            similar.append(candidate)
            maxDistance = max(maxDistance, distance)
          }
        }
        guard similar.count > 1 else { continue }
        let groupPhotos = similar.map(\.photo)
        let recommended = groupPhotos.max { $0.bytes < $1.bytes } ?? groupPhotos[0]
        output.append(
          SimilarPhotoGroup(
            id: similar.map { $0.photo.id }.sorted().joined(separator: "|"),
            photos: groupPhotos,
            recommendedID: recommended.id,
            maximumDistance: maxDistance
          ))
      }
    }
    return SimilarPhotoSnapshot(
      groups: output.sorted { $0.reclaimableBytes > $1.reclaimableBytes }, analyzedCount: analyzed,
      skippedCount: skipped)
  }

  private func captureDate(url: URL, fallback: Date) -> Date {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
      let value = exif[kCGImagePropertyExifDateTimeOriginal] as? String
    else { return fallback }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return formatter.date(from: value) ?? fallback
  }
}
