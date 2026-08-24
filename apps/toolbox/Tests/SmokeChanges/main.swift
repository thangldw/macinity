import Foundation
import ToolboxCore

#if canImport(ToolboxChanges)
  import ToolboxChanges
#endif

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
    comparison.changes.first(where: { $0.item.category == .launchDaemon })?.riskReason != nil,
    "important change must explain its risk")
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
  try store.saveBaseline(before)
  try expect(store.loadSessions() == [session], "session persistence failed")
  try expect(store.loadActiveSnapshot() == before, "active snapshot persistence failed")
  try expect(store.loadBaseline() == before, "baseline persistence failed")
  try store.clearActiveSnapshot()
  try expect(store.loadActiveSnapshot() == nil, "active snapshot cleanup failed")

  let nestedRoot = root.appendingPathComponent("Nested Support")
  let nestedVendor = nestedRoot.appendingPathComponent("Vendor")
  try manager.createDirectory(at: nestedVendor, withIntermediateDirectories: true)
  let nestedScanner = SystemSnapshotScanner(
    configuration: SnapshotConfiguration(
      locations: [
        ScanLocation(category: .applicationSupport, url: nestedRoot, maximumDepth: 2)
      ], maximumItems: 100))
  let nestedBefore = nestedScanner.capture(name: "nested-before")
  let nestedFile = nestedVendor.appendingPathComponent("installed.db")
  try Data("installed".utf8).write(to: nestedFile)
  let nestedAfter = nestedScanner.capture(name: "nested-after")
  let nestedComparison = SnapshotDiffEngine().compare(before: nestedBefore, after: nestedAfter)
  try expect(
    nestedComparison.changes.contains { $0.after?.path == nestedFile.path },
    "nested application support change missing")

  let eventOnlyPath = nestedVendor.appendingPathComponent("deeper/event-only.db").path
  let eventComparison = SnapshotDiffEngine().compare(
    before: SystemSnapshot(name: "event-before", items: []),
    after: SystemSnapshot(name: "event-after", items: []),
    events: [FileSystemEvent(path: eventOnlyPath, flags: 0)],
    categoryForPath: { _ in .applicationSupport })
  try expect(
    eventComparison.changes.count == 1
      && eventComparison.changes[0].riskReason?.contains("FSEvents") == true,
    "FSEvents did not preserve deep change evidence")

  let tracePreview = await MainActor.run { InstallTraceCoordinator.previewOnly() }
  let acceptedInstaller = try await MainActor.run {
    try tracePreview.accept(url: URL(fileURLWithPath: "/tmp/Demo.DMG"))
  }
  try expect(
    acceptedInstaller.kind == .diskImage,
    "Install Trace did not accept a DMG")
  do {
    _ = try await MainActor.run {
      try tracePreview.accept(url: URL(fileURLWithPath: "/tmp/Demo.zip"))
    }
    try expect(false, "Install Trace accepted an unsupported archive")
  } catch InstallTraceError.unsupportedType {
    // Expected.
  }

  let interruptedDirectory = root.appendingPathComponent("InterruptedTrace")
  let interruptedStore = SnapshotStore(directory: interruptedDirectory)
  try interruptedStore.saveActiveSnapshot(SystemSnapshot(name: "before", items: []))
  let interruptedState = await MainActor.run {
    InstallTraceCoordinator(store: interruptedStore).recoveryState
  }
  try expect(
    interruptedState == .interrupted(reducedCoverage: true),
    "interrupted trace must report reduced coverage")

  let lifecycleDirectory = root.appendingPathComponent("TraceLifecycle")
  let lifecycleStore = SnapshotStore(directory: lifecycleDirectory)
  let lifecycleScanner = SystemSnapshotScanner(
    configuration: SnapshotConfiguration(locations: [], maximumItems: 10))
  let lifecycleCoordinator = await MainActor.run {
    InstallTraceCoordinator(scanner: lifecycleScanner, store: lifecycleStore)
  }
  let lifecycleMetadata = try await MainActor.run {
    try lifecycleCoordinator.accept(url: URL(fileURLWithPath: "/tmp/Lifecycle.pkg"))
  }
  try await lifecycleCoordinator.start(metadata: lifecycleMetadata)
  try expect(lifecycleStore.loadActiveSnapshot() != nil, "trace baseline was not persisted")
  let lifecycleSession = try await lifecycleCoordinator.finish(title: "Lifecycle")
  try expect(lifecycleSession.title == "Lifecycle", "trace session title was not preserved")
  try expect(lifecycleStore.loadActiveSnapshot() == nil, "finished trace kept active baseline")
  try expect(lifecycleStore.loadSessions().count == 1, "finished trace was not persisted")

  let migrationRoot = root.appendingPathComponent("LegacyMigration")
  let legacyChangeora = migrationRoot.appendingPathComponent("Changeora")
  let migratedToolbox = migrationRoot.appendingPathComponent("Toolbox")
  try manager.createDirectory(at: legacyChangeora, withIntermediateDirectories: true)
  let legacySession = WatchSession(
    title: "Legacy trace", startedAt: before.createdAt, finishedAt: after.createdAt,
    comparison: compacted)
  let encoder = JSONEncoder()
  try encoder.encode([legacySession]).write(
    to: legacyChangeora.appendingPathComponent("sessions.json"))
  try encoder.encode(before).write(
    to: legacyChangeora.appendingPathComponent("active-snapshot.json"))
  try encoder.encode(before).write(
    to: legacyChangeora.appendingPathComponent("trusted-baseline.json"))
  let migrationReport = try MigrationService(
    legacyRoot: migrationRoot, toolboxDirectory: migratedToolbox
  ).migrate()
  let migratedStore = SnapshotStore(directory: migratedToolbox)
  try expect(migrationReport.traceSessionsImported == 1, "trace migration count was wrong")
  try expect(
    migratedStore.loadSessions().first?.title == "Legacy trace",
    "Changeora session was not readable after migration")
  try expect(
    migratedStore.loadActiveSnapshot()?.name == before.name,
    "active Changeora snapshot was not readable after migration")
  try expect(
    migratedStore.loadBaseline()?.name == before.name,
    "trusted Changeora baseline was not readable after migration")

  print("PASS: snapshot scan, diff, install trace, risk classification and persistence")
} catch {
  fputs("FAIL: \(error)\n", stderr)
  exit(1)
}
