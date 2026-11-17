import Foundation

struct PhotoHashPair: Hashable, Sendable {
  let first: Int
  let second: Int
  let hamming: Int
}

/// Finds hash pairs within a Hamming radius without comparing every pair.
///
/// Identical hashes are collapsed into classes first (a class larger than `maxIdentical`, such
/// as hundreds of blank frames, is skipped and its photos are counted). Distinct hashes are then
/// indexed with multi-index hashing: split the 64 bits into `maxHamming + 1` chunks, so any two
/// hashes within `maxHamming` bits share at least one identical chunk (pigeonhole).
struct PhotoHashIndex {
  let hashes: [UInt64]

  init(hashes: [UInt64]) { self.hashes = hashes }

  func candidatePairs(maxHamming: Int = 10, maxBucket: Int = 5_000, maxIdentical: Int = 1_000)
    -> (pairs: [PhotoHashPair], skippedBuckets: Int, skippedPhotos: Int)
  {
    guard hashes.count > 1, maxHamming >= 0 else { return ([], 0, 0) }

    var classes: [UInt64: [Int]] = [:]
    for (index, hash) in hashes.enumerated() { classes[hash, default: []].append(index) }
    var representatives: [UInt64] = []
    var members: [[Int]] = []
    var skippedPhotos = 0
    for (hash, indices) in classes.sorted(by: { $0.key < $1.key }) {
      if indices.count > maxIdentical {
        skippedPhotos += indices.count
      } else {
        representatives.append(hash)
        members.append(indices)
      }
    }

    var pairs: Set<PhotoHashPair> = []
    for indices in members where indices.count > 1 {
      for position in indices.indices {
        for other in indices[(position + 1)...] {
          pairs.insert(PhotoHashPair(first: indices[position], second: other, hamming: 0))
        }
      }
    }

    // Four 16-bit chunks: two hashes within `maxHamming` bits differ by at most
    // `maxHamming / 4` bits in at least one chunk (pigeonhole), so each hash probes the buckets
    // within that radius of its own chunk values. Buckets stay tiny for varied photos, which
    // keeps the work near-linear instead of quadratic.
    let radius = maxHamming / Self.chunkCount
    let probes = Self.probeMasks(radius: radius)
    var tables = [[UInt16: [Int]]](repeating: [:], count: Self.chunkCount)
    for (index, hash) in representatives.enumerated() {
      for chunk in 0..<Self.chunkCount {
        tables[chunk][Self.chunkValue(hash, chunk), default: []].append(index)
      }
    }
    var skippedBucketKeys: Set<UInt32> = []
    var seen: Set<Int> = []
    for (low, hash) in representatives.enumerated() {
      seen.removeAll(keepingCapacity: true)
      for chunk in 0..<Self.chunkCount {
        let value = Self.chunkValue(hash, chunk)
        for mask in probes {
          let key = value ^ mask
          guard let bucket = tables[chunk][key] else { continue }
          guard bucket.count <= maxBucket else {
            skippedBucketKeys.insert(UInt32(chunk) << 16 | UInt32(key))
            continue
          }
          for high in bucket where high > low {
            guard seen.insert(high).inserted else { continue }
            let distance = PhotoFingerprint.hamming(hash, representatives[high])
            guard distance <= maxHamming else { continue }
            for first in members[low] {
              for second in members[high] {
                pairs.insert(
                  PhotoHashPair(
                    first: min(first, second), second: max(first, second), hamming: distance))
              }
            }
          }
        }
      }
    }
    let skippedBuckets = skippedBucketKeys.count
    return (
      pairs.sorted { ($0.first, $0.second) < ($1.first, $1.second) }, skippedBuckets,
      skippedPhotos
    )
  }

  private static let chunkCount = 4

  private static func chunkValue(_ hash: UInt64, _ chunk: Int) -> UInt16 {
    UInt16(truncatingIfNeeded: hash >> UInt64(chunk * 16))
  }

  /// Every 16-bit mask with at most `radius` set bits (always includes 0).
  private static func probeMasks(radius: Int) -> [UInt16] {
    (0...UInt16.max).filter { $0.nonzeroBitCount <= radius }
  }
}
