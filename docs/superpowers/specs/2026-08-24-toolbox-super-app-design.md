# Toolbox 2.0 Super-App Design

Date: 2026-08-24
Status: Approved on 2026-08-25
Owner: thangldw

## Summary

Toolbox 2.0 replaces the separate Diskora and Changeora binaries with one native macOS application for developer and power-user hygiene. It has two primary jobs:

1. explain where developer storage is going and reclaim only reviewed, recoverable targets;
2. record what an installer or system-changing action changed and keep that evidence available during later cleanup.

The product promise is: **See what changed. Reclaim space safely.**

The public release is one signed and notarized universal application, one landing page, one Homebrew cask, and one Product Hunt launch. Diskora and Changeora remain visible as migration sources and release-history concepts, not as separately shipped products.

## Goals

- Give macOS developers one coherent workflow from change observation to evidence-based cleanup.
- Reduce the current nine-section Diskora navigation and separate Changeora workflow to six user-facing destinations.
- Preserve the existing local-first, review-before-action, Trash-backed recovery, and read-only observation boundaries.
- Migrate existing cleanup history, restore records, watch sessions, active snapshots, and trusted baselines without deleting legacy data.
- Ship a signed and notarized universal DMG that opens normally under Gatekeeper and can be installed by Homebrew.
- Reach 10,000 cumulative Toolbox DMG asset downloads within six months of the public 2.0 launch.

The adoption metric counts GitHub release-asset downloads, including downloads initiated by the Homebrew cask. It is an install-event proxy, not a unique-user or retained-user count.

## Non-goals

- No CLI companion.
- No privileged helper, Endpoint Security system extension, automatic blocking, malware verdict, or automatic uninstall.
- No automatic deletion, permanent-deletion default, or destination overwrite during restore.
- No cloud account, file-content upload, in-app analytics, advertising, or subscription system.
- No Windows or Linux build.
- No AI model inventory, environment-drift inventory, or reproducibility bundle in the 2.0 release; these remain post-launch candidates.

## Target user

The primary user is a macOS developer or power user who regularly installs developer tools, runs multiple package managers or runtimes, and loses storage to rebuildable caches and stale project artifacts. The user is comfortable granting optional Full Disk Access when the benefit and reduced-coverage fallback are explicit, but should not need terminal commands to use the product.

## Product structure

The application is named `Toolbox`, uses bundle identifier `com.thang.toolbox`, targets macOS 13 or later, and ships as version 2.0.0.

The main window uses a `NavigationSplitView` with these destinations:

1. **Home** — recoverable bytes, important recent changes, coverage, and the primary Start Install Trace action.
2. **Storage** — volume/folder analysis, large files, duplicates, and similar photos.
3. **Projects** — recognized developer caches and project-local generated artifacts.
4. **Applications** — installed applications, evidence-linked leftovers, and reviewed uninstall.
5. **Change Timeline** — active trace, completed sessions, baselines, comparisons, and exports.
6. **Recovery** — cleanup ledger, Trash locations, restore state, and errors.

The Home screen exposes no more than three primary actions: review recoverable space, review important changes, and start an install trace. Advanced filters and settings live inside their owning destinations or the standard Settings scene.

## Code architecture

`apps/toolbox` becomes the only shipping Swift package. It contains four targets with one-way dependencies:

```text
Toolbox executable
├── ToolboxStorage ──┐
├── ToolboxChanges ──┼──> ToolboxCore
└── app shell/UI ────┘
```

- `ToolboxCore` owns shared models, versioned persistence, localization, path validation, safety classification, the activity ledger, byte formatting, and migration.
- `ToolboxStorage` owns storage analysis, developer/project scanning, duplicate and similar-photo detection, application artifact discovery, approved cleanup commands, and Trash-backed mutations.
- `ToolboxChanges` owns system snapshots, FSEvents journaling, diffs, attribution, baselines, session comparison, and redacted export.
- `Toolbox` owns SwiftUI navigation, onboarding, settings, application lifecycle, cross-module coordination, and presentation-only view models.

Storage and change modules do not import one another. They exchange typed records through `ToolboxCore` protocols so either module can be tested independently.

After functional and migration parity is verified, `apps/diskora` and `apps/changeora` are removed from the 2.0 source tree. Their tagged release history and downloadable legacy assets remain untouched.

## Shared evidence and activity data

All new data is stored under `~/Library/Application Support/Toolbox` as versioned, atomically written files. Large snapshot payloads are compacted to changed items before persistence.

The shared core uses three durable concepts:

- `EvidenceRecord`: canonical path, evidence kind, producer/application hint, first/last observation, related trace session, confidence, and human-readable reasons.
- `TraceSession`: before/after snapshots, bounded FSEvents, coverage gaps, installer metadata, attribution, and comparison results.
- `ActivityEntry`: cleanup, approved command, restore, trace, migration, or export event with timestamp, status, affected bytes, exact targets, recoverability, and errors.

Storage candidates may reference trace-session evidence. Change records may link to a matching Storage or Applications result through a typed `Review in Storage` action. Paths are canonical identifiers; display strings are localized at presentation time and are never persisted as policy inputs.

## Workflow: Reclaim Space

1. The user starts a scan from Home, Storage, Projects, or Applications.
2. Scanners stream recognized candidates without blocking navigation.
3. The evidence resolver attaches category, project markers, modification/activity dates, application identity, and related trace-session provenance.
4. The safety policy classifies each candidate as `safe`, `review`, or `protected` and supplies concrete reasons.
5. The review UI shows exact path, measured bytes, evidence, expected rebuild cost, selected action, and recoverability.
6. Immediately before mutation, Toolbox re-resolves and revalidates every canonical target.
7. Files move through `FileManager.trashItem`; allowlisted developer-tool commands run only with fixed executable paths and enumerated arguments.
8. The activity ledger records the observed result, Trash paths, failures, and restore eligibility.

Project scanning is opt-in by user-selected roots. Version 2.0 recognizes project markers and generated artifacts for Swift/SwiftPM, Node.js, Python, Rust, Gradle/Android, Flutter, and CocoaPods. It does not execute repository scripts or hooks. Source, manifests, lockfiles, `.git`, secrets, virtual-machine disks, Docker volumes, and unknown folders are never classified `safe`.

Scheduled work remains scan-and-notify only. It may surface changed recoverable bytes but cannot invoke a mutation service.

## Workflow: Install Trace

1. The user starts a trace manually or drops a `.dmg`, `.pkg`, or `.app` onto the Start Install Trace surface.
2. Toolbox records available installer metadata, captures the before snapshot, persists it atomically, and starts the bounded FSEvents journal.
3. For a dropped item, Toolbox opens it with `NSWorkspace`; it does not bypass Installer, Gatekeeper, or user authorization.
4. The user installs, updates, removes, or first-runs the target, then explicitly finishes the trace.
5. Toolbox stops the journal, captures the after snapshot, merges snapshot and event-only changes, and records coverage gaps.
6. The diff engine assigns evidence-based severity and attribution without declaring malware.
7. The timeline groups changes by application, persistence, shell/PATH, developer tooling, configuration, and ordinary application data.
8. Supported artifacts can be opened in Finder, exported in redacted Markdown/JSON, or routed to Storage for separate review.

If Toolbox closes during an active trace, the persisted before snapshot remains recoverable. On next launch, the user can resume journaling from the new launch point, finish with an explicit reduced-coverage warning, or cancel the session. Toolbox never presents an interrupted trace as complete coverage.

## Safety and privacy invariants

- Unknown or ambiguous targets fail closed as `protected` or `review`.
- Mutation requires explicit selection and confirmation in the foreground.
- Canonical targets must remain inside an approved user-domain root or a narrowly defined application target.
- Symlinks are resolved immediately before mutation; a resolved target outside the approved boundary is rejected.
- Root, home root, source roots, protected personal libraries, system paths, and unresolved variables or globs cannot become recursive mutation targets.
- Trash restore never overwrites an existing destination.
- Nonrecoverable allowlisted commands are labeled before confirmation and logged separately from Trash-backed actions.
- Permission failures and inaccessible paths produce visible coverage deficits, not successful empty results.
- Reports replace the current home-directory prefix with `~` and exclude file contents.
- The application sends no scan data, file metadata, or telemetry. A user-initiated update check may fetch public release metadata and clearly remains separate from scanning.

## Legacy migration

First launch looks for legacy data under `~/Library/Application Support/Diskora`, `MacCleaner`, and `Changeora`.

Migration is copy-then-verify:

1. decode legacy JSON with the legacy models;
2. transform it into versioned Toolbox records;
3. atomically write new files;
4. decode the new files and compare record identities/counts;
5. write a migration marker and human-readable migration report only after verification.

Legacy directories are never deleted or modified. A partial failure remains retryable and is shown in onboarding and Recovery. Duplicate imports are prevented by stable legacy record identifiers.

The old `com.thang.diskora.scheduled-scan` LaunchAgent is detected but not silently modified. Toolbox offers to replace it with the new scan-only label after explicit confirmation. Full Disk Access must be granted again to the new Toolbox binary; onboarding explains this and the app remains usable with reduced coverage when permission is declined.

## Error handling and recovery

- Scanner errors attach to their exact root/category while other scanners continue.
- Cancellation stops new traversal promptly and preserves already streamed read-only results, marked incomplete.
- Atomic-store write failures leave the previous valid file intact and surface a retry action.
- Corrupt persisted files are quarantined by rename, never overwritten; Toolbox reports the affected domain and continues with empty in-memory state for that domain.
- A mutation precondition failure removes the target from the pending batch and leaves other independently validated targets available for review.
- Partial Trash moves are recorded individually so successfully moved items remain restorable.
- Export failures do not alter the underlying session.

## Localization and accessibility

English remains the default and Vietnamese remains first-class. Existing localized strings move into the Toolbox resource bundle and new user-visible strings ship in both languages. Japanese remains documentation-only for 2.0.

All primary actions have keyboard access, VoiceOver labels, non-color status symbols, selectable paths, and Dynamic Type-compatible layout. Safety meaning cannot depend on color alone.

## Verification strategy

### Automated checks

- Swift format lint across sources, tests, and package manifests.
- Unit tests for safety classification, canonical-path enforcement, symlink escape rejection, evidence linking, diffing, migration idempotency, persistence corruption, and restore conflicts.
- Integration tests with temporary directories for project recognition, streamed scans, partial failures, interrupted trace recovery, Trash manifests, and legacy fixtures.
- Standalone smoke tests for storage scan, project scan, cleanup preview, snapshot/diff, migration, and redacted export.
- Release build for arm64 and x86_64, followed by universal-binary verification.
- Bundle-resource checks for English and Vietnamese.
- Codesign verification, notarization submission/stapling, Gatekeeper assessment, checksum verification, and DMG mount/launch smoke test.

### Performance checks

- Navigation and cancellation remain responsive because filesystem traversal and hashing never run on the main actor.
- On the same generated fixture and machine, each migrated v1 scanner must be no more than 20 percent slower than its v1 implementation.
- Peak memory on the generated fixture must not exceed 1.25 times the corresponding v1 scanner.
- Cancellation must stop scanner progress publication within one second.

Measured commands, fixtures, hardware, macOS version, elapsed time, and peak memory are recorded in a release evidence report so the performance claims are reproducible.

### Manual release gates

- Verify onboarding, optional Full Disk Access, migration, scan, cleanup, restore, interrupted trace, export, update check, and uninstall on a clean macOS account.
- Complete at least five real Trash/restore drills without overwrite or data loss.
- Complete a signed beta with at least 20 macOS developers and resolve every severity-1 and severity-2 product defect before public launch.
- Verify the exact notarized DMG and Homebrew installation path on both Apple Silicon and Intel hardware or equivalent verified CI runners.

## Distribution and launch

Toolbox 2.0 ships as `Toolbox-2.0.0.dmg` plus `Toolbox-2.0.0.dmg.sha256`. The DMG contains the universal signed and notarized app. A Homebrew cask installs the same GitHub release asset so manual and Homebrew downloads contribute to the same public counter.

The landing page is a static, accessibility-tested site under `site/`, deployed to GitHub Pages by a dedicated workflow. It includes:

- the one-sentence promise and a direct DMG download;
- one primary 30–60 second demo showing Install Trace followed by evidence-linked cleanup;
- screenshots of Home, Projects, Change Timeline, and Recovery;
- explicit local-first, no-telemetry, Trash-backed, and permission boundaries;
- build-from-source, checksum, privacy, security, and support links.

The application itself contains no analytics. The landing page may use cookieless aggregate analytics to measure visit-to-download conversion, with disclosure in the site privacy notice.

Developer ID certificates and notarization credentials remain user-owned and are configured only as protected release secrets. No certificate, password, private key, or notarization token is committed to the repository.

Product Hunt receives one Toolbox launch only after the public binary and landing page are live. The launch package contains the required square thumbnail, at least two 1270x760 gallery images, a public YouTube demo, concise tagline/description, relevant topics, maker attribution, and a first comment explaining the problem, trust model, and build journey.

The six-month adoption report records monthly DMG downloads, GitHub stars, issue/feedback volume, landing-page conversion, and release cadence. Only DMG downloads are the primary 10,000-event KPI; the other metrics are diagnostic.

## Rollout

1. Establish the unified package and shared core without changing behavior.
2. Port storage and change functionality with regression fixtures.
3. Add evidence linking, Projects, Install Trace drop handling, and unified navigation.
4. Add migration, onboarding, recovery hardening, and accessibility/localization parity.
5. Produce the universal signed/notarized beta and run the 20-developer beta gate.
6. Publish 2.0, Homebrew installation, landing page, release evidence, and support material.
7. Launch once on Product Hunt and publish the six-month adoption dashboard from public counters.

Each phase must pass its scoped tests before the next phase removes or replaces legacy code.

## Post-launch candidates

- **Environment Drift:** explain Homebrew, runtime, shell/PATH, and developer-tool changes against a trusted baseline.
- **AI Storage:** inventory Ollama, Hugging Face, Core ML, and related model/cache storage without classifying models as safe deletion by default.
- **Workspace Dormancy:** identify generated artifacts belonging to projects with no recent activity.
- **Reproducibility Bundle:** export a redacted machine setup and change-evidence bundle for debugging or developer onboarding.

These candidates require usage feedback after 2.0 and do not delay the initial launch.
