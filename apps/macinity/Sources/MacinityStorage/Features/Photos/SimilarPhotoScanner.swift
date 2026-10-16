import Foundation
import ImageIO
import Vision

struct SimilarPhoto: Identifiable, Sendable {
  let url: URL
  let bytes: Int64
  let capturedAt: Date
  let pixelWidth: Int
  let pixelHeight: Int
  let sharpnessScore: Double
  var id: String { url.path }
  var pixelCount: Int { pixelWidth * pixelHeight }
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
      let metadata = imageMetadata(
        url: url, fallback: values.contentModificationDate ?? .distantPast)
      photos.append(
        SimilarPhoto(
          url: url.standardizedFileURL,
          bytes: Int64(values.fileSize ?? 0),
          capturedAt: metadata.date,
          pixelWidth: metadata.width,
          pixelHeight: metadata.height,
          sharpnessScore: 0
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
            let measuredPhoto = SimilarPhoto(
              url: photo.url, bytes: photo.bytes, capturedAt: photo.capturedAt,
              pixelWidth: photo.pixelWidth, pixelHeight: photo.pixelHeight,
              sharpnessScore: sharpnessScore(at: photo.url))
            candidates.append(Candidate(photo: measuredPhoto, observation: observation))
            analyzed += 1
          } catch { skipped += 1 }
        }
        guard candidates.count > 1 else { continue }
        var parent = Array(candidates.indices)
        func root(of index: Int) -> Int {
          var current = index
          while parent[current] != current { current = parent[current] }
          return current
        }
        func unite(_ first: Int, _ second: Int) {
          let firstRoot = root(of: first)
          let secondRoot = root(of: second)
          if firstRoot != secondRoot { parent[secondRoot] = firstRoot }
        }
        for firstIndex in candidates.indices {
          for secondIndex in candidates.indices where secondIndex > firstIndex {
            var distance: Float = 0
            try candidates[firstIndex].observation.computeDistance(
              &distance, to: candidates[secondIndex].observation)
            if distance <= distanceLimit { unite(firstIndex, secondIndex) }
          }
        }
        let components = Dictionary(grouping: candidates.indices) { root(of: $0) }
        for indices in components.values where indices.count > 1 {
          let groupCandidates = indices.map { candidates[$0] }
          let groupPhotos = groupCandidates.map(\.photo)
          let recommended =
            groupPhotos.max {
              ($0.pixelCount, $0.sharpnessScore, $0.bytes)
                < ($1.pixelCount, $1.sharpnessScore, $1.bytes)
            } ?? groupPhotos[0]
          var maximumDistance: Float = 0
          for firstIndex in groupCandidates.indices {
            for secondIndex in groupCandidates.indices where secondIndex > firstIndex {
              var distance: Float = 0
              try groupCandidates[firstIndex].observation.computeDistance(
                &distance, to: groupCandidates[secondIndex].observation)
              maximumDistance = max(maximumDistance, distance)
            }
          }
          output.append(
            SimilarPhotoGroup(
              id: groupPhotos.map(\.id).sorted().joined(separator: "|"),
              photos: groupPhotos.sorted {
                ($0.pixelCount, $0.sharpnessScore, $0.bytes)
                  > ($1.pixelCount, $1.sharpnessScore, $1.bytes)
              },
              recommendedID: recommended.id,
              maximumDistance: maximumDistance
            ))
        }
      }
    }
    return SimilarPhotoSnapshot(
      groups: output.sorted { $0.reclaimableBytes > $1.reclaimableBytes }, analyzedCount: analyzed,
      skippedCount: skipped)
  }

  private func imageMetadata(url: URL, fallback: Date) -> (date: Date, width: Int, height: Int) {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else { return (fallback, 0, 0) }
    let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
    let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
    guard let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
      let value = exif[kCGImagePropertyExifDateTimeOriginal] as? String
    else { return (fallback, width, height) }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return (formatter.date(from: value) ?? fallback, width, height)
  }

  private func sharpnessScore(at url: URL) -> Double {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceThumbnailMaxPixelSize: 96,
        ] as CFDictionary)
    else { return 0 }
    let width = image.width
    let height = image.height
    guard width > 1, height > 1 else { return 0 }
    var pixels = [UInt8](repeating: 0, count: width * height)
    let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
          bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue)
      else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard rendered else { return 0 }
    var difference = 0.0
    var comparisons = 0
    for y in 0..<height {
      for x in 0..<width {
        let value = Int(pixels[y * width + x])
        if x + 1 < width {
          difference += Double(abs(value - Int(pixels[y * width + x + 1])))
          comparisons += 1
        }
        if y + 1 < height {
          difference += Double(abs(value - Int(pixels[(y + 1) * width + x])))
          comparisons += 1
        }
      }
    }
    return comparisons > 0 ? difference / Double(comparisons) : 0
  }
}
