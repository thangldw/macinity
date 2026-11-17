import XCTest

@testable import MacinityStorage

final class NearDuplicateGroupingTests: XCTestCase {
  private func photo(
    _ path: String, w: Int = 100, h: Int = 100, sharp: Double = 1, bytes: Int64 = 100
  ) -> SimilarPhoto {
    SimilarPhoto(
      url: URL(fileURLWithPath: path), bytes: bytes, capturedAt: .distantPast, pixelWidth: w,
      pixelHeight: h, sharpnessScore: sharp)
  }

  private func pair(_ a: Int, _ b: Int, _ d: Float) -> PhotoPairDistance {
    PhotoPairDistance(first: a, second: b, distance: d)
  }

  func testThresholdSplitsPairs() {
    let photos = [photo("/a"), photo("/b"), photo("/c"), photo("/d")]
    let pairs = [pair(0, 1, 0.08), pair(2, 3, 0.15)]
    XCTAssertEqual(
      NearDuplicateGrouping.groups(photos: photos, pairs: pairs, minimumSimilarity: 0.90).count, 1)
    XCTAssertEqual(
      NearDuplicateGrouping.groups(photos: photos, pairs: pairs, minimumSimilarity: 0.80).count, 2)
  }

  func testChainedPairsFormOneGroupAndReportWeakestLink() throws {
    let photos = [photo("/a"), photo("/b"), photo("/c")]
    let groups = NearDuplicateGrouping.groups(
      photos: photos, pairs: [pair(0, 1, 0.05), pair(1, 2, 0.09)], minimumSimilarity: 0.90)
    let group = try XCTUnwrap(groups.first)
    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(group.photos.count, 3)
    XCTAssertEqual(group.maximumDistance, 0.09, accuracy: 1e-6)
  }

  func testPairAtExactThresholdIsIncluded() {
    let groups = NearDuplicateGrouping.groups(
      photos: [photo("/a"), photo("/b")], pairs: [pair(0, 1, 0.10)], minimumSimilarity: 0.90)
    XCTAssertEqual(groups.count, 1)
  }

  func testKeepPrefersResolutionThenSharpnessThenBytesAndTieBreaksByPath() {
    let big = photo("/big", w: 200, h: 200)
    let small = photo("/small", w: 100, h: 100, sharp: 9, bytes: 999)
    var result = NearDuplicateGrouping.suggestKeep([small, big])
    XCTAssertEqual(result.photo.id, "/big")
    XCTAssertEqual(result.reason, .highestResolution)

    result = NearDuplicateGrouping.suggestKeep([photo("/x", sharp: 1), photo("/y", sharp: 5)])
    XCTAssertEqual(result.photo.id, "/y")
    XCTAssertEqual(result.reason, .sharpest)

    result = NearDuplicateGrouping.suggestKeep([photo("/x", bytes: 10), photo("/y", bytes: 50)])
    XCTAssertEqual(result.photo.id, "/y")
    XCTAssertEqual(result.reason, .largestFile)

    result = NearDuplicateGrouping.suggestKeep([photo("/b"), photo("/a")])
    XCTAssertEqual(result.photo.id, "/a")
  }

  func testGroupsSortedByReclaimableBytesAndPhotosBestFirst() throws {
    let photos = [
      photo("/a", w: 200, h: 200, bytes: 10), photo("/b", bytes: 10),
      photo("/c", w: 200, h: 200, bytes: 500), photo("/d", bytes: 500),
    ]
    let groups = NearDuplicateGrouping.groups(
      photos: photos, pairs: [pair(0, 1, 0.01), pair(2, 3, 0.01)], minimumSimilarity: 0.90)
    XCTAssertEqual(groups.map(\.reclaimableBytes), [500, 10])
    XCTAssertEqual(try XCTUnwrap(groups.first).photos.first?.id, "/c")
    XCTAssertEqual(try XCTUnwrap(groups.first).recommendedID, "/c")
  }

  func testSharpnessDifferencesWithinNoiseFallThroughToFileSize() {
    let result = NearDuplicateGrouping.suggestKeep([
      photo("/x", sharp: 5.0, bytes: 10), photo("/y", sharp: 5.1, bytes: 50),
    ])
    XCTAssertEqual(result.photo.id, "/y")
    XCTAssertEqual(result.reason, .largestFile)
    let clear = NearDuplicateGrouping.suggestKeep([
      photo("/x", sharp: 5.0, bytes: 50), photo("/y", sharp: 8.0, bytes: 10),
    ])
    XCTAssertEqual(clear.photo.id, "/y")
    XCTAssertEqual(clear.reason, .sharpest)
  }
}
