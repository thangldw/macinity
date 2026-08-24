# Toolbox 2.0 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a buildable unified Toolbox Swift package that hosts the complete existing Diskora and Changeora behavior behind one native macOS shell while preserving the two legacy packages until migration parity is complete.

**Architecture:** Add `apps/toolbox` with an executable app shell and three library targets: `ToolboxCore`, `ToolboxStorage`, and `ToolboxChanges`. Port behavior mechanically first, expose one public module view from each feature library, and keep cross-module contracts in `ToolboxCore`.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation, CoreServices/FSEvents, Vision, CryptoKit, Swift Package Manager, XCTest, shell smoke tests.

**Spec:** `docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md`

## Global Constraints

- macOS 13 or later; Swift tools 6.0 or later.
- One shipping product named `Toolbox` with bundle identifier `com.thang.toolbox` and version `2.0.0`.
- English is default; Vietnamese remains first-class.
- No CLI, privileged helper, Endpoint Security extension, telemetry, automatic deletion, or destination overwrite.
- Unknown targets fail closed; mutations remain explicit and Trash-backed where possible.
- Keep `apps/diskora` and `apps/changeora` unchanged until the migration plan proves parity.
- Each task ends with focused verification and a small commit.

---

## File map

```text
apps/toolbox/
├── Package.swift                         # Four-target Swift package
├── Resources/                            # App icon, Info.plist, en.lproj strings
├── Sources/
│   ├── ToolboxCore/
│   │   ├── AppMetadata.swift             # Product constants and support directory
│   │   ├── Localization.swift            # AppLanguage and L10n
│   │   ├── SafetyModels.swift            # SafetyLevel and path validation contracts
│   │   └── EvidenceModels.swift          # Shared identifiers and cross-module records
│   ├── ToolboxStorage/                    # Ported Diskora models/features/views
│   ├── ToolboxChanges/                    # Ported Changeora models/features/views
│   └── Toolbox/
│       ├── ToolboxApp.swift               # @main entry point
│       ├── ToolboxShellView.swift         # Six-destination NavigationSplitView
│       └── HomeView.swift                 # Initial unified home surface
├── Tests/
│   ├── ToolboxCoreTests/
│   ├── ToolboxStorageTests/
│   └── ToolboxChangesTests/
└── scripts/
    ├── build_app.sh                       # Local .app assembly
    └── test_core.sh                       # Dependency-light smoke coverage
```

### Task 1: Create the unified package and shared core

**Files:**
- Create: `apps/toolbox/Package.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/AppMetadata.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/Localization.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/SafetyModels.swift`
- Create: `apps/toolbox/Sources/ToolboxCore/EvidenceModels.swift`
- Create: `apps/toolbox/Tests/ToolboxCoreTests/ToolboxCoreTests.swift`

**Interfaces:**
- Produces: `AppMetadata.applicationSupportDirectory() -> URL`
- Produces: `AppLanguage`, `L10n.text(_:)`, `ByteCount.string(_:)`
- Produces: `SafetyLevel`, `EvidenceKind`, `EvidenceRecord`
- Produces: `PathSafetyPolicy.validate(candidate:allowedRoots:) throws -> URL`

- [ ] **Step 1: Write failing core tests**

```swift
import Foundation
import XCTest
@testable import ToolboxCore

final class ToolboxCoreTests: XCTestCase {
  func testSafetyPolicyAcceptsDescendantAndRejectsRoot() throws {
    let root = URL(fileURLWithPath: NSTemporaryDirectory()).standardizedFileURL
    let accepted = try PathSafetyPolicy.validate(
      candidate: root.appendingPathComponent("cache/item"), allowedRoots: [root])
    XCTAssertEqual(accepted.path, root.appendingPathComponent("cache/item").path)
    XCTAssertThrowsError(
      try PathSafetyPolicy.validate(candidate: URL(fileURLWithPath: "/"), allowedRoots: [root]))
  }

  func testEvidenceRecordRoundTrips() throws {
    let record = EvidenceRecord(
      path: "/tmp/cache", kind: .projectArtifact, safety: .safe,
      reasons: ["Generated artifact"], observedAt: Date(timeIntervalSince1970: 1))
    let data = try JSONEncoder().encode(record)
    XCTAssertEqual(try JSONDecoder().decode(EvidenceRecord.self, from: data), record)
  }
}

private func temporaryDirectory() throws -> URL {
  let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}
```

- [ ] **Step 2: Run the tests to verify the target is missing**

Run: `cd apps/toolbox && swift test --filter ToolboxCoreTests`

Expected: FAIL because `Package.swift` or `ToolboxCore` does not exist.

- [ ] **Step 3: Add the package and minimal shared contracts**

```swift
public enum SafetyLevel: String, Codable, Sendable {
  case safe, review, protected
}

public enum EvidenceKind: String, Codable, Sendable {
  case applicationArtifact, projectArtifact, traceChange, cleanup, restore
}

public struct EvidenceRecord: Codable, Hashable, Sendable {
  public let path: String
  public let kind: EvidenceKind
  public let safety: SafetyLevel
  public let reasons: [String]
  public let observedAt: Date

  public init(
    path: String, kind: EvidenceKind, safety: SafetyLevel, reasons: [String],
    observedAt: Date
  ) {
    self.path = path
    self.kind = kind
    self.safety = safety
    self.reasons = reasons
    self.observedAt = observedAt
  }
}
```

`Package.swift` must declare libraries `ToolboxCore`, `ToolboxStorage`, and `ToolboxChanges`, executable `Toolbox`, and one test target per library. The executable depends on all three libraries; feature libraries depend only on `ToolboxCore`.

- [ ] **Step 4: Implement fail-closed canonical path validation**

```swift
public enum PathSafetyError: Error, Equatable { case emptyRoots, broadTarget, outsideAllowedRoots }

public enum PathSafetyPolicy {
  public static func validate(candidate: URL, allowedRoots: [URL]) throws -> URL {
    guard !allowedRoots.isEmpty else { throw PathSafetyError.emptyRoots }
    let resolved = candidate.resolvingSymlinksInPath().standardizedFileURL
    guard resolved.path != "/", resolved.path != FileManager.default.homeDirectoryForCurrentUser.path
    else { throw PathSafetyError.broadTarget }
    let inside = allowedRoots.map { $0.resolvingSymlinksInPath().standardizedFileURL.path }
      .contains { resolved.path.hasPrefix($0 + "/") }
    guard inside else { throw PathSafetyError.outsideAllowedRoots }
    return resolved
  }
}
```

- [ ] **Step 5: Run focused tests and lint**

Run: `cd apps/toolbox && swift test --filter ToolboxCoreTests && swift format lint --recursive --parallel Sources/ToolboxCore Tests/ToolboxCoreTests Package.swift`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox
git commit -m "feat: establish Toolbox core package"
```

### Task 2: Port Diskora as the storage module

**Files:**
- Create: `apps/toolbox/Sources/ToolboxStorage/**`
- Create: `apps/toolbox/Tests/ToolboxStorageTests/ToolboxStorageTests.swift`
- Create: `apps/toolbox/Tests/SmokeStorage/main.swift`
- Modify: `apps/toolbox/Package.swift`

**Interfaces:**
- Consumes: `ToolboxCore.ByteCount`, `SafetyLevel`, `PathSafetyPolicy`
- Produces: `public enum StorageDestination { storage, projects, applications, recovery }`
- Produces: `public struct StorageModuleView: View`
- Produces: `public struct StorageModuleSummary: Sendable { recoverableBytes: Int64; issueCount: Int }`

- [ ] **Step 1: Copy the Diskora sources into the new module without editing legacy files**

```bash
mkdir -p apps/toolbox/Sources/ToolboxStorage
cp -R apps/diskora/Sources/Diskora/Core apps/toolbox/Sources/ToolboxStorage/
cp -R apps/diskora/Sources/Diskora/Features apps/toolbox/Sources/ToolboxStorage/
cp -R apps/diskora/Sources/Diskora/Views apps/toolbox/Sources/ToolboxStorage/
```

Rename the copied `Views/ContentView.swift` declaration to `StorageModuleView`, remove its language picker and outer navigation, and expose a focused internal `StorageSectionView` switch. Do not copy `DiskoraApp.swift`, `AppMetadata.swift`, or the old localization implementation.

Remove the copied `ByteCount` declaration so every storage file resolves `ToolboxCore.ByteCount`; keep storage-specific `CleanupConfidence` and `TrashMoveRecord` inside `ToolboxStorage`.

- [ ] **Step 2: Port the current Diskora unit assertions before changing behavior**

```swift
import XCTest
@testable import ToolboxStorage

final class ToolboxStorageTests: XCTestCase {
  func testDefaultCleaningTargetsNeverSelectDangerousItems() {
    XCTAssertFalse(
      CleaningTarget.defaults.contains { $0.isSelectedByDefault && $0.confidence == .dangerous })
  }

  func testCanonicalLeftoverMatchingRejectsShortAmbiguousNames() {
    XCTAssertFalse(ApplicationScanner.matchesLeftoverName("go", applicationName: "Go"))
  }
}
```

- [ ] **Step 3: Run the storage tests to expose compile and access failures**

Run: `cd apps/toolbox && swift test --filter ToolboxStorageTests`

Expected: FAIL on the renamed module facade and imports/access levels.

- [ ] **Step 4: Make the mechanical module port compile**

Add `import ToolboxCore` where shared types are referenced. Keep feature implementation private/internal and expose only:

```swift
public struct StorageModuleView: View {
  private let destination: StorageDestination
  public init(destination: StorageDestination) { self.destination = destination }
  public var body: some View { StorageSectionView(destination: destination) }
}

public struct StorageModuleSummary: Sendable, Equatable {
  public let recoverableBytes: Int64
  public let issueCount: Int
}
```

Retain existing Diskora scanner, cleanup, duplicate, similar-photo, application, schedule, and history behavior unchanged in this task.

- [ ] **Step 5: Run ported unit and smoke tests**

Run: `cd apps/toolbox && swift test --filter ToolboxStorageTests && swift run SmokeStorage`

Expected: PASS with the existing cleaner, storage analyzer, duplicate, and similar-photo smoke behavior.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox
git commit -m "feat: port Diskora into Toolbox storage module"
```

### Task 3: Port Changeora as the changes module

**Files:**
- Create: `apps/toolbox/Sources/ToolboxChanges/**`
- Create: `apps/toolbox/Tests/ToolboxChangesTests/ToolboxChangesTests.swift`
- Create: `apps/toolbox/Tests/SmokeChanges/main.swift`
- Modify: `apps/toolbox/Package.swift`

**Interfaces:**
- Consumes: `ToolboxCore.EvidenceRecord`
- Produces: `public struct ChangeTimelineModuleView: View`
- Produces: `public struct ChangeModuleSummary: Sendable { importantCount: Int; activeTrace: Bool }`

- [ ] **Step 1: Copy Changeora domain sources without editing legacy files**

```bash
mkdir -p apps/toolbox/Sources/ToolboxChanges
cp -R apps/changeora/Sources/Changeora/Core apps/toolbox/Sources/ToolboxChanges/
cp -R apps/changeora/Sources/Changeora/Features apps/toolbox/Sources/ToolboxChanges/
cp -R apps/changeora/Sources/Changeora/Views apps/toolbox/Sources/ToolboxChanges/
```

Rename the copied `Views/ContentView.swift` declaration to `ChangeTimelineModuleView`, remove its independent app shell/language picker, and do not copy `ChangeoraApp.swift`, `AppMetadata.swift`, or the old localization implementation.

- [ ] **Step 2: Port deterministic diff and persistence tests**

```swift
import XCTest
@testable import ToolboxChanges

final class ToolboxChangesTests: XCTestCase {
  func testImportantPersistenceChangeSortsBeforeInformationalChange() {
    let daemon = SnapshotItem(
      id: "daemon|test", category: .launchDaemon, name: "test", path: "/tmp/test",
      size: 1, modifiedAt: nil, bundleIdentifier: nil, version: nil,
      teamIdentifier: nil, signatureStatus: nil, ownerHint: "test")
    let application = SnapshotItem(
      id: "application|test", category: .application, name: "App", path: "/tmp/App.app",
      size: 1, modifiedAt: nil, bundleIdentifier: "example.app", version: "1",
      teamIdentifier: nil, signatureStatus: nil, ownerHint: nil)
    let comparison = SnapshotDiffEngine().compare(
      before: SystemSnapshot(name: "before", items: []),
      after: SystemSnapshot(name: "after", items: [application, daemon]))
    XCTAssertEqual(comparison.changes.first?.risk, .important)
  }

  func testEventOnlyDeepChangeIsRetained() {
    let path = "/tmp/Vendor/deep/item.db"
    let comparison = SnapshotDiffEngine().compare(
      before: SystemSnapshot(name: "before", items: []),
      after: SystemSnapshot(name: "after", items: []),
      events: [FileSystemEvent(path: path, flags: 0)],
      categoryForPath: { _ in .applicationSupport })
    XCTAssertEqual(comparison.changes.count, 1)
    XCTAssertTrue(comparison.changes[0].riskReason?.contains("FSEvents") == true)
  }
}
```

- [ ] **Step 3: Run focused tests to expose missing facade and fixture helpers**

Run: `cd apps/toolbox && swift test --filter ToolboxChangesTests`

Expected: FAIL until the module facade and test fixtures exist.

- [ ] **Step 4: Complete the mechanical module port**

Expose only the SwiftUI facade and summary:

```swift
public struct ChangeTimelineModuleView: View {
  public init() {}
  public var body: some View { ChangeTimelineSectionView() }
}

public struct ChangeModuleSummary: Sendable, Equatable {
  public let importantCount: Int
  public let activeTrace: Bool
}
```

Keep snapshot scanning, FSEvents, diffing, attribution, baselines, comparisons, and export behavior unchanged.

- [ ] **Step 5: Run unit and smoke tests**

Run: `cd apps/toolbox && swift test --filter ToolboxChangesTests && swift run SmokeChanges`

Expected: PASS with snapshot, diff, risk, redaction, and persistence coverage.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox
git commit -m "feat: port Changeora into Toolbox changes module"
```

### Task 4: Build the unified app shell and resources

**Files:**
- Create: `apps/toolbox/Sources/Toolbox/ToolboxApp.swift`
- Create: `apps/toolbox/Sources/Toolbox/ToolboxShellView.swift`
- Create: `apps/toolbox/Sources/Toolbox/HomeView.swift`
- Create: `apps/toolbox/Resources/Info.plist`
- Create: `apps/toolbox/Resources/en.lproj/Localizable.strings`
- Create: `apps/toolbox/scripts/build_app.sh`
- Create: `apps/toolbox/Tests/ToolboxAppTests/ToolboxAppTests.swift`
- Modify: `apps/toolbox/Package.swift`

**Interfaces:**
- Consumes: `StorageModuleView`, `ChangeTimelineModuleView`
- Produces: six stable `ToolboxSection` navigation identifiers

- [ ] **Step 1: Add a failing navigation contract test**

```swift
func testToolboxNavigationHasExactlySixStableSections() {
  XCTAssertEqual(
    ToolboxSection.allCases.map(\.rawValue),
    ["home", "storage", "projects", "applications", "changes", "recovery"])
}
```

- [ ] **Step 2: Run the test to verify the executable shell is absent**

Run: `cd apps/toolbox && swift test --filter testToolboxNavigationHasExactlySixStableSections`

Expected: FAIL because `ToolboxSection` is undefined.

- [ ] **Step 3: Implement the six-destination shell**

```swift
enum ToolboxSection: String, CaseIterable, Identifiable {
  case home, storage, projects, applications, changes, recovery
  var id: String { rawValue }
}
```

`ToolboxShellView` owns the language setting and navigation selection. Storage, Projects, Applications, and Recovery call `StorageModuleView(destination:)`; before project-aware scanning lands, `.projects` presents the existing developer-storage workflow. Changes routes to `ChangeTimelineModuleView`; Home shows three non-mutating cards.

Add a `ToolboxAppTests` target depending on the `Toolbox` executable target so the navigation contract test compiles through `@testable import Toolbox`.

- [ ] **Step 4: Add bundle metadata and local app assembly**

The plist must set `CFBundleDisplayName=Toolbox`, `CFBundleIdentifier=com.thang.toolbox`, `CFBundleShortVersionString=2.0.0`, `CFBundleVersion=1`, and `LSMinimumSystemVersion=13.0`. `build_app.sh` assembles `dist/Toolbox.app`, copies the executable, plist, icon, and `en.lproj`, then applies local ad-hoc signing for development verification.

- [ ] **Step 5: Verify build, bundle, localization, and launch metadata**

Run: `cd apps/toolbox && swift test && swift build && ./scripts/build_app.sh && plutil -lint Resources/Info.plist Resources/en.lproj/Localizable.strings && codesign --verify --deep --strict dist/Toolbox.app`

Expected: PASS; `dist/Toolbox.app/Contents/MacOS/Toolbox` exists.

- [ ] **Step 6: Commit**

```bash
git add apps/toolbox
git commit -m "feat: add unified Toolbox app shell"
```

### Task 5: Add a unified CI lane without removing legacy validation

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `docs/ARCHITECTURE.md`

**Interfaces:**
- Consumes: `apps/toolbox` build/test scripts
- Produces: required Toolbox format, test, smoke, and release-build checks

- [ ] **Step 1: Add a CI contract assertion script**

```bash
rg -q 'working-directory: apps/toolbox' .github/workflows/ci.yml
rg -q 'swift test' .github/workflows/ci.yml
rg -q './scripts/test_core.sh' .github/workflows/ci.yml
rg -q 'swift build -c release' .github/workflows/ci.yml
```

- [ ] **Step 2: Run the assertions and verify they fail**

Expected: FAIL because CI only has `diskora` and `changeora` matrix entries.

- [ ] **Step 3: Add the Toolbox job and update docs to label it pre-release**

Keep the legacy matrix until the evidence/migration plan removes it. Add a separate `toolbox` job using `macos-15`, Swift format lint, `swift test`, both smoke executables, release build, app assembly, plist lint, localization presence, and ad-hoc codesign verification.

- [ ] **Step 4: Run the complete local foundation gate**

Run: `cd apps/toolbox && swift format lint --recursive --parallel Sources Tests Package.swift && swift test && swift run SmokeStorage && swift run SmokeChanges && swift build -c release && ./scripts/build_app.sh`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/ci.yml README.md docs/ARCHITECTURE.md
git commit -m "ci: validate unified Toolbox application"
```

## Foundation completion gate

Run:

```bash
git status --short
cd apps/toolbox
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
swift run SmokeStorage
swift run SmokeChanges
swift build -c release
./scripts/build_app.sh
codesign --verify --deep --strict dist/Toolbox.app
```

Expected: clean worktree after commits and all checks PASS. The legacy applications still build independently at this checkpoint.
