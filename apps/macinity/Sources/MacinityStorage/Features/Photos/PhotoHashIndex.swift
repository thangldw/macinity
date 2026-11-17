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

    var buckets: [UInt64: [Int]] = [:]
    for (chunk, range) in Self.chunkRanges(count: min(64, maxHamming + 1)).enumerated() {
      let mask: UInt64 = range.count == 64 ? .max : (1 << UInt64(range.count)) - 1
      for (index, hash) in representatives.enumerated() {
        let value = (hash >> UInt64(range.lowerBound)) & mask
        // Chunk number occupies the top byte so equal values in different chunks stay apart.
        buckets[UInt64(chunk) << 56 | value, default: []].append(index)
      }
    }
    var checked: Set<[Int]> = []
    var skippedBuckets = 0
    for bucket in buckets.values where bucket.count > 1 {
      guard bucket.count <= maxBucket else {
        skippedBuckets += 1
        continue
      }
      for position in bucket.indices {
        for other in bucket[(position + 1)...] {
          let low = min(bucket[position], other)
          let high = max(bucket[position], other)
          guard checked.insert([low, high]).inserted else { continue }
          let distance = PhotoFingerprint.hamming(representatives[low], representatives[high])
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
    return (
      pairs.sorted { ($0.first, $0.second) < ($1.first, $1.second) }, skippedBuckets,
      skippedPhotos
    )
  }

  /// Splits 0..<64 into `count` contiguous ranges whose lengths differ by at most one.
  private static func chunkRanges(count: Int) -> [Range<Int>] {
    let base = 64 / count
    let extra = 64 % count
    var start = 0
    return (0..<count).map { index in
      let length = base + (index < extra ? 1 : 0)
      defer { start += length }
      return start..<(start + length)
    }
  }
}
