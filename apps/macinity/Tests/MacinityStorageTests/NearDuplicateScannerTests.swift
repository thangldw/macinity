import UniformTypeIdentifiers
import XCTest

@testable import MacinityStorage

final class NearDuplicateScannerTests: XCTestCase {
  private var directory: URL!
  private var cache: URL { directory.appendingPathComponent("cache.json") }
  private var photos: URL { directory.appendingPathComponent("photos") }

  override func setUp() {
    directory = PhotoFixtures.temporaryDirectory()
    try? FileManager.default.createDirectory(at: photos, withIntermediateDirectories: true)
  }
  override func tearDown() { try? FileManager.default.removeItem(at: directory) }

  private func makeLibrary() {
    let original = PhotoFixtures.structured(width: 800, height: 600)
    PhotoFixtures.write(original, to: photos.appendingPathComponent("a.png"))
    PhotoFixtures.write(
      PhotoFixtures.resized(original, width: 400, height: 300),
      to: photos.appendingPathComponent("sub/a-small.png"))
    PhotoFixtures.write(PhotoFixtures.checkerboard(), to: photos.appendingPathComponent("b.png"))
  }

  func testFindsResizedCopyInAnotherFolderAndIgnoresDifferentImage() throws {
    makeLibrary()
    let snapshot = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    XCTAssertEqual(snapshot.scannedCount, 3)
    XCTAssertEqual(snapshot.pairs.count, 1)
    XCTAssertEqual(
      Set(snapshot.photos.map { $0.url.lastPathComponent }), ["a.png", "a-small.png"])
    XCTAssertLessThanOrEqual(try XCTUnwrap(snapshot.pairs.first).distance, 0.20)
  }

  func testStronglyDownscaledCopyIsStillFound() throws {
    let original = PhotoFixtures.structured(width: 1600, height: 1200)
    PhotoFixtures.write(original, to: photos.appendingPathComponent("big.png"))
    PhotoFixtures.write(
      PhotoFixtures.resized(original, width: 200, height: 150),
      to: photos.appendingPathComponent("thumb.png"))
    let snapshot = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    XCTAssertEqual(snapshot.pairs.count, 1)
  }

  func testSecondScanUsesCache() throws {
    makeLibrary()
    _ = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    let second = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    XCTAssertEqual(second.cachedCount, 3)
  }

  func testCorruptAndZeroByteFilesAreSkippedNotFatal() throws {
    makeLibrary()
    FileManager.default.createFile(
      atPath: photos.appendingPathComponent("bad.jpg").path, contents: Data())
    let real = PhotoFixtures.write(
      PhotoFixtures.structured(), to: directory.appendingPathComponent("real.jpg"), type: .jpeg)
    try Data(contentsOf: real).prefix(20).write(to: photos.appendingPathComponent("trunc.jpg"))
    let snapshot = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    XCTAssertGreaterThanOrEqual(snapshot.skippedCount, 2)
    XCTAssertEqual(snapshot.pairs.count, 1)
  }

  func testSymlinksAndPackagesAreIgnored() throws {
    makeLibrary()
    try FileManager.default.createSymbolicLink(
      at: photos.appendingPathComponent("link.png"),
      withDestinationURL: photos.appendingPathComponent("a.png"))
    PhotoFixtures.write(
      PhotoFixtures.structured(), to: photos.appendingPathComponent("Thing.app/Contents/in.png"))
    let snapshot = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    XCTAssertEqual(snapshot.scannedCount, 3)
  }

  func testHiddenFoldersIncludingTrashAreNotScanned() throws {
    makeLibrary()
    let original = PhotoFixtures.structured(width: 800, height: 600)
    PhotoFixtures.write(original, to: photos.appendingPathComponent(".Trash/a-trashed.png"))
    PhotoFixtures.write(original, to: photos.appendingPathComponent(".Trashes/501/a-trashed.png"))
    let snapshot = try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    XCTAssertEqual(snapshot.scannedCount, 3)
    XCTAssertFalse(snapshot.photos.contains { $0.url.path.contains(".Trash") })
  }

  func testFeaturePrintRevisionRequiresRevisionTwo() {
    XCTAssertEqual(NearDuplicateScanner.featurePrintRevision(supported: [1, 2]), 2)
    XCTAssertEqual(NearDuplicateScanner.featurePrintRevision(supported: [2]), 2)
    XCTAssertNil(NearDuplicateScanner.featurePrintRevision(supported: [1]))
    XCTAssertNil(NearDuplicateScanner.featurePrintRevision(supported: []))
  }

  func testCancellationThrowsAndLeavesNoCache() async throws {
    makeLibrary()
    let photos = self.photos
    let cache = self.cache
    let task = Task.detached { () throws -> NearDuplicateSnapshot in
      while !Task.isCancelled { await Task.yield() }
      return try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache)
    }
    task.cancel()
    let result = await task.result
    XCTAssertThrowsError(try result.get()) { XCTAssertTrue($0 is CancellationError) }
    XCTAssertFalse(FileManager.default.fileExists(atPath: cache.path))
  }

  func testIdenticalFlatImagesAreReportedAsSkippedBuckets() throws {
    for (index, gray) in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6].enumerated() {
      PhotoFixtures.write(
        PhotoFixtures.solid(gray: gray), to: photos.appendingPathComponent("flat\(index).png"))
    }
    let snapshot = try NearDuplicateScanner(maxIdentical: 3).scan(rootURL: photos, cacheURL: cache)
    XCTAssertEqual(snapshot.skippedPhotos, 6)
    XCTAssertTrue(snapshot.pairs.isEmpty)
  }

  func testMissingRootIsAnErrorNotAnEmptyResult() {
    XCTAssertThrowsError(
      try NearDuplicateScanner().scan(
        rootURL: directory.appendingPathComponent("nope"), cacheURL: cache)
    ) {
      XCTAssertEqual($0 as? NearDuplicateScanner.ScanError, .unreadableRoot)
    }
  }

  func testCancellationKeepsHashesComputedSoFar() async throws {
    for index in 0..<130 {
      PhotoFixtures.write(
        PhotoFixtures.structured(width: 32 + index, height: 24),
        to: photos.appendingPathComponent("p\(index).png"))
    }
    let photos = self.photos
    let cache = self.cache
    let task = Task.detached { () throws -> NearDuplicateSnapshot in
      try NearDuplicateScanner().scan(rootURL: photos, cacheURL: cache) { progress in
        if progress.phase == .hashing { withUnsafeCurrentTask { $0?.cancel() } }
      }
    }
    let result = await task.result
    XCTAssertThrowsError(try result.get()) { XCTAssertTrue($0 is CancellationError) }
    XCTAssertGreaterThanOrEqual(PhotoFingerprintCache(fileURL: cache).count, 64)
  }
}
