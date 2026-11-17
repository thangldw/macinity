import Foundation

enum KeepReason: String, Sendable {
  case highestResolution, sharpest, largestFile
}

/// A confirmed pair of photos; indices point into the snapshot's `photos` array.
struct PhotoPairDistance: Sendable, Equatable {
  let first: Int
  let second: Int
  let distance: Float
}

enum NearDuplicateGrouping {
  /// Links photos whose estimated similarity (`1 - distance`) reaches the threshold. A chain of
  /// links forms one group; `maximumDistance` is the weakest link actually used.
  static func groups(
    photos: [SimilarPhoto], pairs: [PhotoPairDistance], minimumSimilarity: Double
  ) -> [SimilarPhotoGroup] {
    let linked = pairs.filter {
      photos.indices.contains($0.first) && photos.indices.contains($0.second)
        && 1 - Double($0.distance) >= minimumSimilarity - 1e-6
    }
    var parent = Array(photos.indices)
    func root(_ index: Int) -> Int {
      var current = index
      while parent[current] != current { current = parent[current] }
      return current
    }
    for pair in linked {
      let a = root(pair.first)
      let b = root(pair.second)
      if a != b { parent[b] = a }
    }
    var weakest: [Int: Float] = [:]
    for pair in linked {
      let key = root(pair.first)
      weakest[key] = max(weakest[key] ?? 0, pair.distance)
    }
    let members = Dictionary(grouping: photos.indices.filter { weakest[root($0)] != nil }) {
      root($0)
    }
    return members.map { key, indices in
      let groupPhotos = ordered(indices.map { photos[$0] })
      let suggestion = suggestKeep(groupPhotos)
      return SimilarPhotoGroup(
        id: groupPhotos.map(\.id).sorted().joined(separator: "|"), photos: groupPhotos,
        recommendedID: suggestion.photo.id, maximumDistance: weakest[key] ?? 0,
        keepReason: suggestion.reason)
    }.sorted {
      ($0.reclaimableBytes, $1.id) > ($1.reclaimableBytes, $0.id)
    }
  }

  static func suggestKeep(_ photos: [SimilarPhoto]) -> (photo: SimilarPhoto, reason: KeepReason) {
    let sorted = ordered(photos)
    let best = sorted[0]
    guard sorted.count > 1 else { return (best, .highestResolution) }
    let next = sorted[1]
    if best.pixelCount != next.pixelCount { return (best, .highestResolution) }
    if sharpnessBucket(best.sharpnessScore) != sharpnessBucket(next.sharpnessScore) {
      return (best, .sharpest)
    }
    return (best, .largestFile)
  }

  /// Sharpness comes from a 96px thumbnail and varies a few percent between recompressions of
  /// the same picture; 5% steps keep that noise from deciding which copy to keep.
  private static func sharpnessBucket(_ value: Double) -> Int {
    Int((log(max(value, 0.01)) / log(1.05)).rounded())
  }

  /// Best first: pixels, then sharpness, then bytes, then path for a stable result.
  private static func ordered(_ photos: [SimilarPhoto]) -> [SimilarPhoto] {
    photos.sorted {
      if $0.pixelCount != $1.pixelCount { return $0.pixelCount > $1.pixelCount }
      let (lhs, rhs) = (sharpnessBucket($0.sharpnessScore), sharpnessBucket($1.sharpnessScore))
      if lhs != rhs { return lhs > rhs }
      if $0.bytes != $1.bytes { return $0.bytes > $1.bytes }
      return $0.id < $1.id
    }
  }
}
