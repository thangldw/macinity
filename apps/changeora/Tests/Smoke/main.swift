import Foundation

enum SmokeFailure: Error {
  case assertion(String)
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
  if !condition() { throw SmokeFailure.assertion(message) }
}

func writePlist(_ dictionary: [String: Any], to url: URL) throws {
  let data = try PropertyListSerialization.data(
    fromPropertyList: dictionary, format: .xml, options: 0)
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
  try data.write(to: url)
}

func makeApplication(at url: URL, version: String) throws {
  try writePlist(
    [
      "CFBundleIdentifier": "com.example.demo",
      "CFBundleName": "Demo",
      "CFBundleShortVersionString": version,
    ],
    to: url.appendingPathComponent("Contents/Info.plist")
  )
}

let manager = FileManager.default
let root = manager.temporaryDirectory.appendingPathComponent("changeora-smoke-\(UUID().uuidString)")
defer { try? manager.removeItem(at: root) }

do {
  let applications = root.appendingPathComponent("Applications")
  let agents = root.appendingPathComponent("LaunchAgents")
  let daemons = root.appendingPathComponent("LaunchDaemons")
  let preferences = root.appendingPathComponent("Preferences")
  let support = root.appendingPathComponent("Application Support")
  for directory in [applications, agents, daemons, preferences, support] {
    try manager.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  let oldSupport = support.appendingPathComponent("OldVendor", isDirectory: true)
  try manager.createDirectory(at: oldSupport, withIntermediateDirectories: true)
  try manager.createDirectory(
    at: support.appendingPathComponent("StableVendor", isDirectory: true),
    withIntermediateDirectories: true)
  let preference = preferences.appendingPathComponent("com.example.demo.plist")
  try Data("before".utf8).write(to: preference)

  let configuration = SnapshotConfiguration(
    locations: [
      ScanLocation(category: .application, url: applications, maximumDepth: 1),
      ScanLocation(category: .launchAgent, url: agents, maximumDepth: 1),
      ScanLocation(category: .launchDaemon, url: daemons, maximumDepth: 1),
      ScanLocation(category: .preference, url: preferences, maximumDepth: 1),
      ScanLocation(category: .applicationSupport, url: support, maximumDepth: 1),
    ],
    maximumItems: 100
  )
  let scanner = SystemSnapshotScanner(configuration: configuration)
  let before = scanner.capture(name: "before")

  try makeApplication(at: applications.appendingPathComponent("Demo.app"), version: "1.0")
  try writePlist(
    ["Label": "com.example.agent", "Program": "/Applications/Demo.app/Contents/MacOS/Demo"],
    to: agents.appendingPathComponent("com.example.agent.plist")
  )
  try writePlist(
    ["Label": "com.example.daemon", "Program": "/Library/PrivilegedHelperTools/demo"],
    to: daemons.appendingPathComponent("com.example.daemon.plist")
  )
  try Data("after-with-more-data".utf8).write(to: preference)
  try manager.setAttributes(
    [.modificationDate: Date().addingTimeInterval(5)], ofItemAtPath: preference.path)
  try manager.removeItem(at: oldSupport)

  let after = scanner.capture(name: "after")
  let comparison = SnapshotDiffEngine().compare(before: before, after: after)
  let compacted = comparison.compacted()

  try expect(comparison.addedCount == 3, "expected app, agent and daemon additions")
  try expect(comparison.removedCount == 1, "expected removed support directory")
  try expect(comparison.modifiedCount == 1, "expected modified preference")
  try expect(comparison.importantCount == 1, "launch daemon addition must be important")
  try expect(
    comparison.changes.contains { $0.item.category == .application && $0.kind == .added },
    "application addition missing")
  try expect(
    comparison.changes.contains { $0.item.ownerHint == "com.example.agent" },
    "launch agent attribution missing")
  try expect(
    compacted.before.items.count < before.items.count,
    "compacted history must omit unchanged snapshot items")

  let storeDirectory = root.appendingPathComponent("Store")
  let store = SnapshotStore(directory: storeDirectory)
  let session = WatchSession(
    title: "Smoke", startedAt: before.createdAt, finishedAt: after.createdAt,
    comparison: compacted)
  try store.saveSessions([session])
  try store.saveActiveSnapshot(before)
  try expect(store.loadSessions() == [session], "session persistence failed")
  try expect(store.loadActiveSnapshot() == before, "active snapshot persistence failed")
  try store.clearActiveSnapshot()
  try expect(store.loadActiveSnapshot() == nil, "active snapshot cleanup failed")

  print("PASS: snapshot scan, diff, risk classification and persistence")
} catch {
  fputs("FAIL: \(error)\n", stderr)
  exit(1)
}
