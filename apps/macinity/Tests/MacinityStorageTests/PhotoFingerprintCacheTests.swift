import XCTest

@testable import MacinityStorage

final class PhotoFingerprintCacheTests: XCTestCase {
  private var directory: URL!
  private var file: URL { directory.appendingPathComponent("cache.json") }
  private let date = Date(timeIntervalSince1970: 1_700_000_000)

  override func setUp() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  }
  override func tearDown() { try? FileManager.default.removeItem(at: directory) }

  func testRoundTripAndInvalidation() throws {
    var cache = PhotoFingerprintCache(fileURL: file)
    cache.store(path: "/a.jpg", size: 10, modified: date, hash: 0xDEAD_BEEF_0000_0001)
    try cache.save()
    let reloaded = PhotoFingerprintCache(fileURL: file)
    XCTAssertEqual(reloaded.hash(path: "/a.jpg", size: 10, modified: date), 0xDEAD_BEEF_0000_0001)
    XCTAssertNil(reloaded.hash(path: "/a.jpg", size: 11, modified: date))
    XCTAssertNil(reloaded.hash(path: "/a.jpg", size: 10, modified: date.addingTimeInterval(5)))
    XCTAssertNil(reloaded.hash(path: "/missing.jpg", size: 10, modified: date))
  }

  func testCorruptFileIsNeverOverwritten() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let garbage = Data("not json".utf8)
    try garbage.write(to: file)
    var cache = PhotoFingerprintCache(fileURL: file)
    XCTAssertFalse(cache.isWritable)
    cache.store(path: "/a.jpg", size: 1, modified: date, hash: 1)
    try cache.save()
    XCTAssertEqual(try Data(contentsOf: file), garbage)
  }

  func testEntriesAreBounded() {
    var cache = PhotoFingerprintCache(fileURL: file)
    for index in 0..<(PhotoFingerprintCache.maxEntries + 5) {
      cache.store(path: "/p\(index)", size: 1, modified: date, hash: UInt64(index))
    }
    XCTAssertLessThanOrEqual(cache.count, PhotoFingerprintCache.maxEntries)
    XCTAssertGreaterThan(cache.count, PhotoFingerprintCache.maxEntries * 8 / 10)
    XCTAssertNil(cache.hash(path: "/p0", size: 1, modified: date))
    XCTAssertNotNil(
      cache.hash(path: "/p\(PhotoFingerprintCache.maxEntries + 4)", size: 1, modified: date))
  }

  func testPruneKeepsOnlyListedPaths() {
    var cache = PhotoFingerprintCache(fileURL: file)
    cache.store(path: "/a", size: 1, modified: date, hash: 1)
    cache.store(path: "/b", size: 1, modified: date, hash: 2)
    cache.prune(keeping: ["/b"])
    XCTAssertNil(cache.hash(path: "/a", size: 1, modified: date))
    XCTAssertEqual(cache.hash(path: "/b", size: 1, modified: date), 2)
  }

  func testSaveTrimsOldestEntriesToStayUnderTheLoadLimit() throws {
    var cache = PhotoFingerprintCache(fileURL: file, maxFileBytes: 4_000)
    for index in 0..<200 {
      cache.store(path: "/photos/path/number/\(index).jpg", size: 1, modified: date, hash: 1)
    }
    try cache.save()
    XCTAssertLessThanOrEqual(try Data(contentsOf: file).count, 4_000)
    let reloaded = PhotoFingerprintCache(fileURL: file, maxFileBytes: 4_000)
    XCTAssertTrue(reloaded.isWritable)
    XCTAssertNotNil(
      reloaded.hash(path: "/photos/path/number/199.jpg", size: 1, modified: date))
    XCTAssertNil(reloaded.hash(path: "/photos/path/number/0.jpg", size: 1, modified: date))
  }

  func testSaveWritesOnlyWhenSomethingChanged() throws {
    var cache = PhotoFingerprintCache(fileURL: file)
    try cache.save()
    XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    cache.store(path: "/a", size: 1, modified: date, hash: 1)
    try cache.save()
    try FileManager.default.removeItem(at: file)
    try cache.save()
    XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
  }
}
