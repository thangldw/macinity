import Foundation
import XCTest

@testable import Changeora

final class ChangeoraTests: XCTestCase {
  func testSnapshotDetectsNestedApplicationSupportChanges() throws {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? manager.removeItem(at: root) }
    let vendor = root.appendingPathComponent("Vendor", isDirectory: true)
    try manager.createDirectory(at: vendor, withIntermediateDirectories: true)

    let scanner = SystemSnapshotScanner(
      configuration: SnapshotConfiguration(
        locations: [
          ScanLocation(category: .applicationSupport, url: root, maximumDepth: 2)
        ],
        maximumItems: 100))
    let before = scanner.capture(name: "before")
    let file = vendor.appendingPathComponent("installed.db")
    try Data("installed".utf8).write(to: file)
    let after = scanner.capture(name: "after")
    let comparison = SnapshotDiffEngine().compare(before: before, after: after)

    XCTAssertTrue(
      comparison.changes.contains { $0.after?.path == file.path && $0.kind == .added })
  }

  func testLaunchDaemonAdditionIsImportant() {
    let item = SnapshotItem(
      id: "daemon|test", category: .launchDaemon, name: "test", path: "/tmp/test", size: 1,
      modifiedAt: nil, bundleIdentifier: nil, version: nil, teamIdentifier: nil,
      signatureStatus: nil, ownerHint: "test")
    let before = SystemSnapshot(name: "before", items: [])
    let after = SystemSnapshot(name: "after", items: [item])
    let comparison = SnapshotDiffEngine().compare(before: before, after: after)

    XCTAssertEqual(comparison.changes.first?.risk, .important)
    XCTAssertNotNil(comparison.changes.first?.riskReason)
  }

  func testFSEventAddsDeepChangeMissingFromSnapshot() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let path = root.appendingPathComponent("Vendor/deep/item.db").path
    let before = SystemSnapshot(name: "before", items: [])
    let after = SystemSnapshot(name: "after", items: [])
    let comparison = SnapshotDiffEngine().compare(
      before: before, after: after,
      events: [FileSystemEvent(path: path, flags: 0)],
      categoryForPath: { _ in .applicationSupport })

    XCTAssertEqual(comparison.changes.count, 1)
    XCTAssertTrue(comparison.changes[0].riskReason?.contains("FSEvents") == true)
  }
}
