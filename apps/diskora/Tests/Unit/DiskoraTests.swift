import Foundation
import XCTest

@testable import Diskora

final class DiskoraTests: XCTestCase {
  func testCleanerBlocksPathsOutsideHome() throws {
    let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let service = CleanerService(homeURL: home, removalMethod: .permanentForTesting)
    let target = CleaningTarget(
      id: "escape", name: "Escape", detail: "", relativePath: "../../etc", symbol: "folder",
      isSelectedByDefault: false)

    XCTAssertThrowsError(try service.url(for: target)) { error in
      XCTAssertTrue(error is CleanerError)
    }
  }

  func testCleanerOnlyRemovesChildrenOfSelectedTarget() throws {
    let manager = FileManager.default
    let home = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? manager.removeItem(at: home) }
    let cache = home.appendingPathComponent("Library/Caches", isDirectory: true)
    try manager.createDirectory(at: cache, withIntermediateDirectories: true)
    try Data(repeating: 1, count: 4_096).write(to: cache.appendingPathComponent("sample.bin"))

    let target = CleaningTarget(
      id: "cache", name: "Cache", detail: "", relativePath: "Library/Caches", symbol: "folder",
      isSelectedByDefault: true)
    let result = CleanerService(homeURL: home, removalMethod: .permanentForTesting).clean(
      target: target)

    XCTAssertEqual(result.removedItems, 1)
    XCTAssertTrue(result.errors.isEmpty)
    XCTAssertFalse(result.recoverable)
    XCTAssertTrue(manager.fileExists(atPath: cache.path))
    XCTAssertTrue(try manager.contentsOfDirectory(atPath: cache.path).isEmpty)
  }

  func testLeftoverNameMatchingDoesNotUseSubstringMatches() {
    XCTAssertTrue(
      ApplicationScanner.matchesLeftoverName("com.example.note", applicationName: "Note"))
    XCTAssertFalse(
      ApplicationScanner.matchesLeftoverName("com.example.noteworthy", applicationName: "Note"))
  }
}
