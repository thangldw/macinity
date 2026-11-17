import XCTest

@testable import MacinityStorage

final class PhotoTrashServiceTests: XCTestCase {
  func testPathsInsideATrashFolderAreRecognised() {
    XCTAssertTrue(PhotoTrashService.isInsideTrash(URL(fileURLWithPath: "/Users/a/.Trash/x.jpg")))
    XCTAssertTrue(PhotoTrashService.isInsideTrash(URL(fileURLWithPath: "/Volumes/V/.Trashes/501/x.jpg")))
    XCTAssertFalse(PhotoTrashService.isInsideTrash(URL(fileURLWithPath: "/Users/a/Pictures/Trash.jpg")))
  }

  private var directory: URL!
  override func setUp() { directory = PhotoFixtures.temporaryDirectory() }
  override func tearDown() { try? FileManager.default.removeItem(at: directory) }

  private func photo(_ name: String, bytes: Int = 5) throws -> SimilarPhoto {
    let url = directory.appendingPathComponent(name)
    try Data(repeating: 1, count: bytes).write(to: url)
    return SimilarPhoto(
      url: url, bytes: Int64(bytes), capturedAt: .distantPast, pixelWidth: 1, pixelHeight: 1,
      sharpnessScore: 0)
  }

  private func fakeTrash(_ url: URL) throws -> URL? {
    let destination = directory.appendingPathComponent("trash-" + url.lastPathComponent)
    try FileManager.default.moveItem(at: url, to: destination)
    return destination
  }

  func testOnlyFilesActuallyMovedAreReportedAsMoved() throws {
    let good = try photo("good.jpg")
    let missing = SimilarPhoto(
      url: directory.appendingPathComponent("gone.jpg"), bytes: 5, capturedAt: .distantPast,
      pixelWidth: 1, pixelHeight: 1, sharpnessScore: 0)
    let outcome = PhotoTrashService.moveToTrash(
      photos: [good, missing], root: directory, trash: fakeTrash)
    XCTAssertEqual(outcome.moved.map(\.id), [good.id])
    XCTAssertEqual(outcome.moves.count, 1)
    XCTAssertEqual(outcome.errors.count, 1)
  }

  func testMovedFileWithoutResultingURLStillCountsAsMovedButHasNoRecoveryRecord() throws {
    let good = try photo("good.jpg")
    let outcome = PhotoTrashService.moveToTrash(photos: [good], root: directory) { url in
      try FileManager.default.removeItem(at: url)
      return nil
    }
    XCTAssertEqual(outcome.moved.map(\.id), [good.id])
    XCTAssertTrue(outcome.moves.isEmpty)
  }

  func testFileSwappedForSymlinkOrResizedSinceScanIsRefused() throws {
    let swapped = try photo("swapped.jpg")
    let target = try photo("target.jpg")
    try FileManager.default.removeItem(at: swapped.url)
    try FileManager.default.createSymbolicLink(at: swapped.url, withDestinationURL: target.url)
    var resized = try photo("resized.jpg")
    resized = SimilarPhoto(
      url: resized.url, bytes: 999, capturedAt: .distantPast, pixelWidth: 1, pixelHeight: 1,
      sharpnessScore: 0)
    let outcome = PhotoTrashService.moveToTrash(
      photos: [swapped, resized], root: directory, trash: fakeTrash)
    XCTAssertTrue(outcome.moved.isEmpty)
    XCTAssertEqual(outcome.errors.count, 2)
    XCTAssertTrue(FileManager.default.fileExists(atPath: target.url.path))
  }
}
