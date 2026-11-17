import UniformTypeIdentifiers
import XCTest

@testable import MacinityStorage

final class PhotoFingerprintTests: XCTestCase {
  func testDHashOfIncreasingRowsIsAllOnes() {
    let row: [UInt8] = [0, 10, 20, 30, 40, 50, 60, 70, 80]
    XCTAssertEqual(PhotoFingerprint.dHash(gray9x8: Array((0..<8).map { _ in row }.joined())), .max)
  }

  func testDHashOfConstantImageIsZero() {
    XCTAssertEqual(PhotoFingerprint.dHash(gray9x8: [UInt8](repeating: 7, count: 72)), 0)
  }

  func testHammingCountsDifferingBits() {
    XCTAssertEqual(PhotoFingerprint.hamming(0b1010, 0b0110), 2)
  }

  func testResizedCopyIsCloseAndDifferentImageIsFar() throws {
    let directory = PhotoFixtures.temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let original = PhotoFixtures.structured()
    let originalURL = PhotoFixtures.write(original, to: directory.appendingPathComponent("a.png"))
    let smallURL = PhotoFixtures.write(
      PhotoFixtures.resized(original, width: 100, height: 75),
      to: directory.appendingPathComponent("a-small.png"))
    let otherURL = PhotoFixtures.write(
      PhotoFixtures.checkerboard(), to: directory.appendingPathComponent("b.png"))
    let hash = try XCTUnwrap(PhotoFingerprint.dHash(of: originalURL))
    XCTAssertLessThanOrEqual(
      PhotoFingerprint.hamming(try XCTUnwrap(PhotoFingerprint.dHash(of: smallURL)), hash), 6)
    XCTAssertGreaterThanOrEqual(
      PhotoFingerprint.hamming(try XCTUnwrap(PhotoFingerprint.dHash(of: otherURL)), hash), 20)
  }

  func testRotatedByExifOrientationMatches() throws {
    let directory = PhotoFixtures.temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let original = PhotoFixtures.structured()
    let upright = PhotoFixtures.write(original, to: directory.appendingPathComponent("up.png"))
    let rotated = PhotoFixtures.write(
      PhotoFixtures.rotatedCounterClockwise(original),
      to: directory.appendingPathComponent("rot.jpg"), type: .jpeg, orientation: 6)
    XCTAssertLessThanOrEqual(
      PhotoFingerprint.hamming(
        try XCTUnwrap(PhotoFingerprint.dHash(of: rotated)),
        try XCTUnwrap(PhotoFingerprint.dHash(of: upright))), 8)
  }

  func testUnreadableFileReturnsNil() throws {
    let directory = PhotoFixtures.temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let empty = directory.appendingPathComponent("empty.jpg")
    FileManager.default.createFile(atPath: empty.path, contents: Data())
    XCTAssertNil(PhotoFingerprint.dHash(of: empty))
  }
}
