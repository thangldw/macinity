import XCTest

@testable import MacinityStorage

final class PhotoHashIndexTests: XCTestCase {
  private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
      state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return state
    }
  }

  private func randomHashes() -> [UInt64] {
    var generator = SeededGenerator(state: 42)
    var hashes = (0..<240).map { _ in UInt64.random(in: .min ... .max, using: &generator) }
    for _ in 0..<60 {
      var copy = hashes[Int.random(in: 0..<240, using: &generator)]
      for _ in 0..<Int.random(in: 0...10, using: &generator) {
        copy ^= 1 << UInt64.random(in: 0..<64, using: &generator)
      }
      hashes.append(copy)
    }
    return hashes
  }

  private func bruteForce(_ hashes: [UInt64], _ maxHamming: Int) -> Set<PhotoHashPair> {
    var result: Set<PhotoHashPair> = []
    for first in hashes.indices {
      for second in hashes.indices where second > first {
        let distance = PhotoFingerprint.hamming(hashes[first], hashes[second])
        if distance <= maxHamming {
          result.insert(PhotoHashPair(first: first, second: second, hamming: distance))
        }
      }
    }
    return result
  }

  func testMatchesBruteForceForRandomHashes() {
    let hashes = randomHashes()
    for maxHamming in [3, 10] {
      let result = PhotoHashIndex(hashes: hashes).candidatePairs(maxHamming: maxHamming)
      XCTAssertEqual(Set(result.pairs), bruteForce(hashes, maxHamming), "maxHamming \(maxHamming)")
      XCTAssertEqual(result.skippedBuckets, 0)
    }
  }

  func testIdenticalHashesPairAtDistanceZero() {
    let result = PhotoHashIndex(hashes: [5, 5]).candidatePairs()
    XCTAssertEqual(result.pairs, [PhotoHashPair(first: 0, second: 1, hamming: 0)])
  }

  func testOversizedIdenticalClassIsSkippedAndCountedInPhotos() {
    let result = PhotoHashIndex(hashes: [UInt64](repeating: 9, count: 10))
      .candidatePairs(maxHamming: 3, maxIdentical: 5)
    XCTAssertTrue(result.pairs.isEmpty)
    XCTAssertEqual(result.skippedPhotos, 10)
  }

  func testIdenticalClassWithinCapPairsAllMembers() {
    let result = PhotoHashIndex(hashes: [4, 4, 4]).candidatePairs()
    XCTAssertEqual(result.pairs.count, 3)
    XCTAssertEqual(result.skippedPhotos, 0)
  }

  func testOversizedBucketOfDistinctHashesIsCounted() {
    let hashes = (0..<8).map { UInt64($0 + 1) << 16 }
    let result = PhotoHashIndex(hashes: hashes).candidatePairs(maxHamming: 3, maxBucket: 3)
    XCTAssertGreaterThan(result.skippedBuckets, 0)
  }

  func testEmptyAndSingleInput() {
    XCTAssertTrue(PhotoHashIndex(hashes: []).candidatePairs().pairs.isEmpty)
    XCTAssertTrue(PhotoHashIndex(hashes: [1]).candidatePairs().pairs.isEmpty)
  }
}
