# Toolbox 2.0 Evidence Workflows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the unified parity shell into the differentiated Toolbox 2.0 product with shared evidence, project-aware cleanup, Install Trace, verified legacy migration, and unified Recovery.

**Architecture:** Keep feature modules independent and connect them through versioned `ToolboxCore` protocols and records. All persistence is atomic and local; all mutation is preflighted through the shared path-safety policy and recorded in a unified activity ledger.

**Tech Stack:** Swift 6, SwiftUI, AppKit drag/drop, Foundation Codable stores, CoreServices/FSEvents, XCTest, temporary-directory integration fixtures.

**Spec:** `docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md`

## Global Constraints

- Complete the foundation plan first.
- macOS 13 or later; Swift tools 6.0 or later.
- No CLI, privileged helper, Endpoint Security extension, telemetry, or automatic mutation.
- User-selected project roots only; do not execute project scripts or hooks.
- Unknown folders, source, manifests, lockfiles, `.git`, secrets, VM disks, and Docker volumes never receive `safe` classification.
- Legacy data is copy-then-verify; legacy directories are never modified or deleted.
- Each task ends with focused verification and a small commit.

---

## File map

```text
apps/toolbox/Sources/ToolboxCore/
├── EvidenceStore.swift                    # Versioned atomic evidence persistence
├── ActivityLedger.swift                   # Cleanup/restore/trace/migration/export events
├── MigrationService.swift                 # Idempotent legacy import
└── StoreRecovery.swift                    # Corrupt-file quarantine
apps/toolbox/Sources/ToolboxStorage/
├── Features/Projects/ProjectModels.swift
├── Features/Projects/ProjectScanner.swift
├── Features/Projects/ProjectViewModel.swift
├── Views/ProjectsView.swift
└── Features/History/UnifiedRecoveryAdapter.swift
apps/toolbox/Sources/ToolboxChanges/
├── Features/Trace/InstallTraceCoordinator.swift
├── Features/Trace/InstallerMetadata.swift
└── Views/InstallTraceDropView.swift
apps/toolbox/Sources/Toolbox/
├── ToolboxCoordinator.swift               # Shared stores and cross-module routing
├── OnboardingView.swift                   # Permission and migration status
└── SettingsView.swift                     # Scan roots, schedule, update policy
```

### Task 1: Add the versioned evidence store and activity ledger

**Files:**
- Create: `apps/toolbox/Sources/ToolboxCore/EvidenceStore.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/ActivityLedger.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/StoreRecovery.swift`
- Modify: `apps/toolbox/Sources/ToolboxCore/EvidenceModels.swift`
- Modify: `apps/toolbox/Tests/ToolboxCoreTests/ToolboxCoreTests.swift`

**Interfaces:**
- Produces: `EvidenceStore.load() throws -> [EvidenceRecord]`
- Produces: `EvidenceStore.upsert(_:) throws`
- Produces: `ActivityLedger.load() throws -> [ActivityEntry]`
- Produces: `ActivityLedger.append(_:) throws`
- Produces: `StoreRecovery.quarantine(_:) throws -> URL`

- [ ] **Step 1: Write failing atomic-store and quarantine tests**

```swift
func testEvidenceUpsertIsStableByCanonicalPathAndKind() throws {
  let directory = try temporaryDirectory()
  let store = EvidenceStore(directory: directory)
  try store.upsert(EvidenceRecord(path: "/tmp/a", kind: .projectArtifact, safety: .safe,
    reasons: ["first"], observedAt: Date(timeIntervalSince1970: 1)))
  try store.upsert(EvidenceRecord(path: "/tmp/a", kind: .projectArtifact, safety: .review,
    reasons: ["new"], observedAt: Date(timeIntervalSince1970: 2)))
  XCTAssertEqual(try store.load().count, 1)
  XCTAssertEqual(try store.load().first?.safety, .review)
}

func testCorruptStoreIsQuarantinedInsteadOfOverwritten() throws {
  let directory = try temporaryDirectory()
  try Data("{".utf8).write(to: directory.appendingPathComponent("evidence-v1.json"))
  XCTAssertThrowsError(try EvidenceStore(directory: directory).load())
  XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path)
    .filter { $0.hasPrefix("evidence-v1.corrupt-") }.count, 1)
}
```

- [ ] **Step 2: Run focused tests and verify missing stores**

Run: `cd apps/toolbox && swift test --filter ToolboxCoreTests`

Expected: FAIL because the stores and `ActivityEntry` do not exist.

- [ ] **Step 3: Implement version envelopes and atomic writes**

```swift
struct StoreEnvelope<Value: Codable>: Codable {
  let schemaVersion: Int
  var values: [Value]
}

public enum ActivityKind: String, Codable, Sendable {
  case cleanup, command, restore, trace, migration, export
}

public struct ActivityEntry: Codable, Hashable, Sendable, Identifiable {
  public let id: UUID
  public let kind: ActivityKind
  public let occurredAt: Date
  public let paths: [String]
  public let affectedBytes: Int64
  public let recoverable: Bool
  public let errors: [String]

  public init(
    id: UUID = UUID(), kind: ActivityKind, occurredAt: Date = Date(), paths: [String],
    affectedBytes: Int64, recoverable: Bool, errors: [String]
  ) {
    self.id = id
    self.kind = kind
    self.occurredAt = occurredAt
    self.paths = paths
    self.affectedBytes = affectedBytes
    self.recoverable = recoverable
    self.errors = errors
  }
}
```

Every save encodes to data and uses `Data.write(options: .atomic)`. Decode failure renames the corrupt file with a timestamp suffix and throws a typed error; it never writes an empty replacement during that call.

- [ ] **Step 4: Run tests and lint**

Run: `cd apps/toolbox && swift test --filter ToolboxCoreTests && swift format lint --recursive --parallel Sources/ToolboxCore Tests/ToolboxCoreTests`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/toolbox/Sources/ToolboxCore apps/toolbox/Tests/ToolboxCoreTests
git commit -m "feat: add shared evidence and activity stores"
```

### Task 2: Add project-aware artifact scanning

**Files:**
- Create: `apps/toolbox/Sources/ToolboxStorage/Features/Projects/ProjectModels.swift`
- Create: `apps/toolbox/Sources/ToolboxStorage/Features/Projects/ProjectScanner.swift`
- Create: `apps/toolbox/Sources/ToolboxStorage/Features/Projects/ProjectViewModel.swift`
- Create: `apps/toolbox/Sources/ToolboxStorage/Views/ProjectsView.swift`
- Create: `apps/toolbox/Tests/ToolboxStorageTests/ProjectScannerTests.swift`

**Interfaces:**
- Produces: `ProjectScanner.scan(roots:) async -> ProjectScanReport`
- Produces: `ProjectArtifact` with `projectRoot`, `artifactURL`, `ecosystem`, `bytes`, `modifiedAt`, `safety`, and `reasons`
- Consumes: `EvidenceStore.upsert(_:)`, `PathSafetyPolicy.validate(candidate:allowedRoots:)`

- [ ] **Step 1: Write failing marker and protection tests**

```swift
func testNodeProjectFindsNodeModulesButProtectsLockfile() async throws {
  let root = try fixtureProject(files: ["package.json", "package-lock.json", "node_modules/pkg/a.js"])
  let report = await ProjectScanner().scan(roots: [root])
  XCTAssertEqual(report.artifacts.map { $0.artifactURL.lastPathComponent }, ["node_modules"])
  XCTAssertFalse(report.artifacts.contains { $0.artifactURL.lastPathComponent == "package-lock.json" })
}

func testUnknownGeneratedLookingFolderIsNotOffered() async throws {
  let root = try fixtureProject(files: ["src/main.swift", "mystery-cache/blob"])
  let report = await ProjectScanner().scan(roots: [root])
  XCTAssertTrue(report.artifacts.isEmpty)
}

private func fixtureProject(files: [String]) throws -> URL {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  for relativePath in files {
    let file = root.appendingPathComponent(relativePath)
    try FileManager.default.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(relativePath.utf8).write(to: file)
  }
  return root
}
```

- [ ] **Step 2: Run focused tests and verify failure**

Run: `cd apps/toolbox && swift test --filter ProjectScannerTests`

Expected: FAIL because project models/scanner do not exist.

- [ ] **Step 3: Implement explicit ecosystem rules**

```swift
struct ProjectRule: Sendable {
  let ecosystem: ProjectEcosystem
  let anyMarkers: Set<String>
  let artifactPaths: Set<String>
}

static let rules: [ProjectRule] = [
  .init(ecosystem: .swift, anyMarkers: ["Package.swift"], artifactPaths: [".build"]),
  .init(ecosystem: .node, anyMarkers: ["package.json"], artifactPaths: ["node_modules"]),
  .init(ecosystem: .python, anyMarkers: ["pyproject.toml"], artifactPaths: [".venv", "venv"]),
  .init(ecosystem: .rust, anyMarkers: ["Cargo.toml"], artifactPaths: ["target"]),
  .init(ecosystem: .gradle, anyMarkers: ["settings.gradle", "settings.gradle.kts"], artifactPaths: [".gradle", "build"]),
  .init(ecosystem: .flutter, anyMarkers: ["pubspec.yaml"], artifactPaths: [".dart_tool", "build"]),
  .init(ecosystem: .cocoapods, anyMarkers: ["Podfile"], artifactPaths: ["Pods"]),
]
```

Only direct or recognized module descendants are traversed; `.git`, package contents, hidden unknown directories, and managed personal libraries are pruned. Results stream through the view model and persist typed evidence after a scan completes.

- [ ] **Step 4: Add the Projects UI and explicit cleanup review**

The view supports user-selected roots through `NSOpenPanel`, scan/cancel, ecosystem and safety filters, path reveal, exact-byte totals, and selection. Cleanup delegates to the existing Trash service only after `PathSafetyPolicy` revalidation against the selected project roots.

- [ ] **Step 5: Run unit, integration, and storage smoke tests**

Run: `cd apps/toolbox && swift test --filter ProjectScannerTests && swift run SmokeStorage`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox/Sources/ToolboxStorage apps/toolbox/Tests/ToolboxStorageTests
git commit -m "feat: add project-aware cleanup"
```

### Task 3: Add GUI Install Trace and dropped-installer handling

**Files:**
- Create: `apps/toolbox/Sources/ToolboxChanges/Features/Trace/InstallerMetadata.swift`
- Create: `apps/toolbox/Sources/ToolboxChanges/Features/Trace/InstallTraceCoordinator.swift`
- Create: `apps/toolbox/Sources/ToolboxChanges/Views/InstallTraceDropView.swift`
- Modify: `apps/toolbox/Sources/ToolboxChanges/Features/Snapshots/ChangeoraViewModel.swift`
- Create: `apps/toolbox/Tests/ToolboxChangesTests/InstallTraceCoordinatorTests.swift`

**Interfaces:**
- Produces: `InstallTraceCoordinator.accept(url:) throws -> InstallerMetadata`
- Produces: `InstallTraceCoordinator.start(metadata:) async throws`
- Produces: `InstallTraceCoordinator.finish(title:) async throws -> WatchSession`
- Produces: `InstallTraceCoordinator.previewOnly() -> InstallTraceCoordinator` for file-type validation without opening an installer
- Produces: `InstallTraceCoordinator.init(store:)` for interrupted-session recovery tests
- Consumes: existing snapshot scanner, FSEvent journal, diff engine, and snapshot store

- [ ] **Step 1: Write failing file-type and interrupted-session tests**

```swift
func testAcceptsOnlySupportedInstallerTypes() throws {
  let coordinator = InstallTraceCoordinator.previewOnly()
  XCTAssertNoThrow(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.dmg")))
  XCTAssertNoThrow(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.pkg")))
  XCTAssertNoThrow(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.app")))
  XCTAssertThrowsError(try coordinator.accept(url: URL(fileURLWithPath: "/tmp/App.zip")))
}

func testInterruptedTraceLoadsAsReducedCoverage() throws {
  let store = try traceFixtureWithActiveSnapshot()
  let state = InstallTraceCoordinator(store: store).recoveryState
  XCTAssertEqual(state, .interrupted(reducedCoverage: true))
}

private func traceFixtureWithActiveSnapshot() throws -> SnapshotStore {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  let store = SnapshotStore(directory: directory)
  try store.saveActiveSnapshot(SystemSnapshot(name: "before", items: []))
  return store
}
```

- [ ] **Step 2: Run focused tests and verify missing coordinator**

Run: `cd apps/toolbox && swift test --filter InstallTraceCoordinatorTests`

Expected: FAIL because trace coordinator and recovery state are undefined.

- [ ] **Step 3: Implement metadata acceptance and explicit lifecycle**

```swift
public struct InstallerMetadata: Codable, Hashable, Sendable {
  public let sourceURL: URL
  public let displayName: String
  public let kind: InstallerKind
  public let observedAt: Date
}

public enum InterruptedTraceRecovery: Equatable {
  case none
  case interrupted(reducedCoverage: Bool)
}
```

Starting persists the before snapshot before journaling. Dropped installers open only through `NSWorkspace.shared.open`; the coordinator never mounts, executes, authorizes, or bypasses Gatekeeper itself. Finishing persists the compacted comparison and evidence records.

- [ ] **Step 4: Add the SwiftUI drop surface**

Use `.dropDestination(for: URL.self)` and a standard Open panel fallback. The view shows accepted type, source path, active duration, coverage state, Finish, Cancel, and reduced-coverage recovery choices. Unsupported types remain read-only errors.

- [ ] **Step 5: Run tests and changes smoke**

Run: `cd apps/toolbox && swift test --filter InstallTraceCoordinatorTests && swift run SmokeChanges`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox/Sources/ToolboxChanges apps/toolbox/Tests/ToolboxChangesTests
git commit -m "feat: add GUI install trace workflow"
```

### Task 4: Implement idempotent legacy migration

**Files:**
- Create: `apps/toolbox/Sources/ToolboxCore/MigrationService.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/LegacyModels.swift`
- Create: `apps/toolbox/Tests/ToolboxCoreTests/Fixtures/diskora-history.json`
- Create: `apps/toolbox/Tests/ToolboxCoreTests/Fixtures/changeora-sessions.json`
- Create: `apps/toolbox/Tests/ToolboxCoreTests/MigrationServiceTests.swift`
- Create: `apps/toolbox/Sources/Toolbox/OnboardingView.swift`

**Interfaces:**
- Produces: `MigrationService.inspect() -> MigrationAssessment`
- Produces: `MigrationService.migrate() throws -> MigrationReport`
- Produces: stable legacy IDs derived from source domain plus original record UUID

- [ ] **Step 1: Add failing copy-verify and idempotency tests**

```swift
func testMigrationCopiesAndPreservesLegacyFiles() throws {
  let fixture = try LegacyMigrationFixture.make()
  let report = try fixture.service.migrate()
  XCTAssertEqual(report.cleanupEntriesImported, 1)
  XCTAssertEqual(report.traceSessionsImported, 1)
  XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.legacyHistory.path))
  XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.legacySessions.path))
}

func testMigrationIsIdempotent() throws {
  let fixture = try LegacyMigrationFixture.make()
  _ = try fixture.service.migrate()
  _ = try fixture.service.migrate()
  XCTAssertEqual(try fixture.activityLedger.load().filter { $0.kind == .migration }.count, 1)
}

private struct LegacyMigrationFixture {
  let service: MigrationService
  let activityLedger: ActivityLedger
  let legacyHistory: URL
  let legacySessions: URL

  static func make() throws -> LegacyMigrationFixture {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let diskora = root.appendingPathComponent("Diskora")
    let changeora = root.appendingPathComponent("Changeora")
    let toolbox = root.appendingPathComponent("Toolbox")
    try FileManager.default.createDirectory(at: diskora, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: changeora, withIntermediateDirectories: true)
    let history = diskora.appendingPathComponent("history.json")
    let sessions = changeora.appendingPathComponent("sessions.json")
    let fixtures = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().appendingPathComponent("Fixtures")
    try FileManager.default.copyItem(
      at: fixtures.appendingPathComponent("diskora-history.json"), to: history)
    try FileManager.default.copyItem(
      at: fixtures.appendingPathComponent("changeora-sessions.json"), to: sessions)
    let ledger = ActivityLedger(directory: toolbox)
    return LegacyMigrationFixture(
      service: MigrationService(legacyRoot: root, toolboxDirectory: toolbox),
      activityLedger: ledger, legacyHistory: history, legacySessions: sessions)
  }
}
```

- [ ] **Step 2: Run focused tests and verify migration types are missing**

Run: `cd apps/toolbox && swift test --filter MigrationServiceTests`

Expected: FAIL.

- [ ] **Step 3: Implement copy-then-verify migration**

Decode `Diskora/history.json`, `MacCleaner/history.json`, `Changeora/sessions.json`, `active-snapshot.json`, and `trusted-baseline.json` through exact legacy Codable shapes. Write Toolbox records atomically, decode them again, compare stable IDs/counts, then write `migration-v1.json` and one migration activity. A thrown decode or verification error writes no completion marker and remains retryable.

- [ ] **Step 4: Add onboarding migration and permission states**

Onboarding displays detected legacy sources, records imported, errors, retry, reduced Full Disk Access coverage, and the fact that originals remain untouched. It never claims permission is granted based only on a button click; it verifies readable sentinel roots.

- [ ] **Step 5: Run migration tests twice and verify fixtures remain unchanged**

Run: `cd apps/toolbox && swift test --filter MigrationServiceTests && git diff --exit-code -- apps/toolbox/Tests/ToolboxCoreTests/Fixtures`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox/Sources/ToolboxCore apps/toolbox/Sources/Toolbox/OnboardingView.swift apps/toolbox/Tests/ToolboxCoreTests
git commit -m "feat: migrate Diskora and Changeora data"
```

### Task 5: Harden mutations and unify Recovery, scheduling, update checks, and routing

**Files:**
- Create: `apps/toolbox/Sources/ToolboxStorage/Features/History/UnifiedRecoveryAdapter.swift`
- Modify: `apps/toolbox/Sources/ToolboxStorage/Features/Cleaning/CleanerService.swift`
- Modify: `apps/toolbox/Sources/ToolboxStorage/Features/Applications/ApplicationManager.swift`
- Modify: `apps/toolbox/Sources/ToolboxStorage/Features/Developer/DeveloperCleanupService.swift`
- Modify: `apps/toolbox/Sources/ToolboxStorage/Views/HistoryView.swift`
- Create: `apps/toolbox/Sources/Toolbox/ToolboxCoordinator.swift`
- Create: `apps/toolbox/Sources/Toolbox/ReleaseUpdateChecker.swift`
- Create: `apps/toolbox/Sources/Toolbox/SettingsView.swift`
- Modify: `apps/toolbox/Sources/Toolbox/ToolboxShellView.swift`
- Modify: `apps/toolbox/Sources/Toolbox/HomeView.swift`
- Create: `apps/toolbox/Tests/ToolboxCoreTests/CrossModuleContractTests.swift`
- Create: `apps/toolbox/Tests/ToolboxStorageTests/MutationSafetyTests.swift`
- Create: `apps/toolbox/Tests/ToolboxAppTests/ReleaseUpdateCheckerTests.swift`

**Interfaces:**
- Produces: `ToolboxRoute.reviewStorage(path:)`
- Produces: `RecoveryItem.init(id:originalPath:trashPath:bytes:)`
- Produces: unified `RecoveryItem` projection over legacy Trash moves and new activities
- Produces: `ReleaseUpdateChecker.latestVersion() async throws -> SemanticVersion?`
- Produces: `CleanerService.validatedURL(for:) throws -> URL`
- Consumes: module summaries and evidence paths

- [ ] **Step 1: Write failing route and restore-conflict tests**

```swift
func testReviewStorageRoutePreservesCanonicalPath() throws {
  let route = ToolboxRoute.reviewStorage(path: "/tmp/project/.build")
  XCTAssertEqual(route.storagePath, "/tmp/project/.build")
}

func testRecoveryNeverOverwritesExistingDestination() throws {
  let fixture = try RecoveryFixture.destinationConflict()
  let result = fixture.adapter.restore(fixture.item)
  XCTAssertEqual(result.restoredCount, 0)
  XCTAssertEqual(try Data(contentsOf: fixture.destination), Data("existing".utf8))
}

func testCleanerRejectsSymlinkEscapingApprovedRoot() throws {
  let fixture = try MutationSafetyFixture.symlinkEscape()
  XCTAssertThrowsError(try fixture.service.validatedURL(for: fixture.target))
}

private struct RecoveryFixture {
  let adapter: UnifiedRecoveryAdapter
  let item: RecoveryItem
  let destination: URL

  static func destinationConflict() throws -> RecoveryFixture {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let source = root.appendingPathComponent("Trash/item")
    let destination = root.appendingPathComponent("Original/item")
    try FileManager.default.createDirectory(
      at: source.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("trashed".utf8).write(to: source)
    try Data("existing".utf8).write(to: destination)
    let item = RecoveryItem(
      id: UUID(), originalPath: destination.path, trashPath: source.path, bytes: 7)
    return RecoveryFixture(adapter: UnifiedRecoveryAdapter(), item: item, destination: destination)
  }
}

private struct MutationSafetyFixture {
  let service: CleanerService
  let target: CleaningTarget

  static func symlinkEscape() throws -> MutationSafetyFixture {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let allowed = root.appendingPathComponent("home")
    let outside = root.appendingPathComponent("outside")
    try FileManager.default.createDirectory(at: allowed, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
    try Data("protected".utf8).write(to: outside.appendingPathComponent("item"))
    try FileManager.default.createSymbolicLink(
      at: allowed.appendingPathComponent("escape"), withDestinationURL: outside)
    return MutationSafetyFixture(
      service: CleanerService(homeURL: allowed, removalMethod: .permanentForTesting),
      target: CleaningTarget(
        id: "escape", name: "Escape", detail: "", relativePath: "escape/item",
        symbol: "folder", isSelectedByDefault: false))
  }
}
```

- [ ] **Step 2: Run tests and verify unified types are missing**

Run: `cd apps/toolbox && swift test --filter CrossModuleContractTests`

Expected: FAIL.

- [ ] **Step 3: Apply shared preflight validation to every mutation path**

`CleanerService`, application uninstall, developer cleanup, and restore must canonicalize and revalidate each target immediately before action. The developer command service continues to allow only fixed executable URLs plus enumerated argument sets and records nonrecoverable commands distinctly. Add `MutationSafetyFixture` in `MutationSafetyTests.swift` to create an allowed root containing a symlink to a sibling directory and assert the resolved target is rejected.

- [ ] **Step 4: Add coordinator routing and summary refresh**

The app coordinator owns shared stores, selected section, optional storage focus path, migration state, and module summaries. `Review in Storage` changes section and focus path only; it never selects or cleans the target automatically.

- [ ] **Step 5: Migrate scheduled scan only after explicit confirmation**

Detect `~/Library/LaunchAgents/com.thang.diskora.scheduled-scan.plist`. The Settings screen offers replacement with `com.thang.toolbox.scheduled-scan`; confirmation bootstraps the new scan-only agent before removing the old label. On any bootstrap failure, retain the old file and report the exact error.

- [ ] **Step 6: Add an isolated, user-initiated update check**

`ReleaseUpdateChecker` requests only `https://api.github.com/repos/thangldw/toolbox/releases/latest`, decodes `tag_name`, and returns a semantic version. It receives an injected `URLSessionProtocol` in tests; the request contains no path, scan, evidence, or device fields. Settings labels the network action and never runs it during scanning.

```swift
struct SemanticVersion: Comparable, Equatable {
  let major: Int
  let minor: Int
  let patch: Int

  static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
  }
}

protocol URLSessionProtocol: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
```

- [ ] **Step 7: Complete localization and accessibility parity**

Add English and Vietnamese strings for all new navigation, project, trace, migration, permission, recovery, and update states. Unit tests parse the strings file and require every source-language key used by `L10n.text` to exist in English. Add VoiceOver labels to icon-only controls, keyboard shortcuts to scan/cancel/finish, selectable paths, and symbol-plus-text safety status.

- [ ] **Step 8: Run full behavioral gate**

Run: `cd apps/toolbox && swift test && swift run SmokeStorage && swift run SmokeChanges && ./scripts/build_app.sh`

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add apps/toolbox
git commit -m "feat: connect Toolbox evidence and recovery workflows"
```

### Task 6: Remove legacy shipping packages after parity

**Files:**
- Delete: `apps/diskora/**`
- Delete: `apps/changeora/**`
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/OPERATIONS.md`

**Interfaces:**
- Consumes: all Toolbox tests, smoke checks, migration fixtures, and build scripts
- Produces: one shipping app and one CI contract

- [ ] **Step 1: Capture the final legacy parity gate before deletion**

Run:

```bash
cd apps/diskora && ./scripts/test_core.sh && swift build -c release
cd ../changeora && ./scripts/test_core.sh && swift build -c release
cd ../toolbox && swift test && swift run SmokeStorage && swift run SmokeChanges && swift build -c release
```

Expected: all available checks PASS; full XCTest for legacy packages may require full Xcode but their smoke and release builds must pass.

- [ ] **Step 2: Remove legacy package directories and matrix jobs**

```bash
git rm -r apps/diskora apps/changeora
```

Update CI to validate only `apps/toolbox`. Documentation must state that tags through `v1.4.0` retain the two historical binaries and that 2.0 migrates their Application Support data.

- [ ] **Step 3: Verify no runtime or CI reference points to removed paths**

Run: `rg -n 'apps/(diskora|changeora)|cd apps/diskora|cd apps/changeora' . --glob '!CHANGELOG.md' --glob '!docs/superpowers/**'`

Expected: no stale operational reference.

- [ ] **Step 4: Run the complete Toolbox gate after deletion**

Run: `cd apps/toolbox && swift format lint --recursive --parallel Sources Tests Package.swift && swift test && swift run SmokeStorage && swift run SmokeChanges && swift build -c release && ./scripts/build_app.sh && codesign --verify --deep --strict dist/Toolbox.app`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: retire standalone Diskora and Changeora apps"
```

## Evidence-workflow completion gate

Run the Task 6 full gate, then perform manual smoke checks for project-root selection, Install Trace start/finish/cancel, interrupted trace recovery, migration retry, cross-module Review in Storage, cleanup preview, Trash move, and conflict-safe restore. Record results in `docs/release-evidence/toolbox-2.0.0.md` during the release plan.
