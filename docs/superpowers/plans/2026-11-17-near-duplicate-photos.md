# Near-duplicate Photo Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Find same-picture and very-similar photos (default >= 90% estimated) across a whole chosen folder and present a review list where each photo is Keep or Delete before anything is moved to Trash.

**Architecture:** Two stages. Stage 1 computes a 64-bit dHash per photo (cached on disk by path+size+mtime) and finds candidate pairs through a multi-index hash lookup instead of all pairs. Stage 2 confirms candidates with Vision feature-print distance. Pure grouping code turns confirmed pair distances into groups for any threshold, so the slider regroups without rescanning. A new view model holds the per-photo Keep/Delete decisions; Trash reuses the existing journal/recovery path.

**Tech Stack:** Swift 6 (SwiftPM only, no Xcode project), ImageIO, Vision (`VNGenerateImageFeaturePrintRequest`), SwiftUI, XCTest. Work in `apps/macinity`.

**Spec:** `docs/superpowers/specs/2026-11-17-near-duplicate-photos-design.md`

**Commits:** make them only if the user asks; each task ends with a test checkpoint instead.

## Global Constraints

- macOS 13+, `swift-tools-version: 6.0`; no new dependencies; Vision + ImageIO only.
- Threshold default 90%, slider range 80%–100%; similarity shown = `1 - Vision distance`, labelled as an estimate, never a probability.
- Deletion = `FileManager.trashItem` after `PathSafetyPolicy.validate(candidate:allowedRoots:)`, recorded in `HistoryStore` and `ActivityLedger` as today. No permanent delete, nothing automatic, nothing deleted without the confirmation alert.
- Every group always keeps at least one photo.
- Scanner skips symlinks and package contents (`.skipsPackageDescendants`); extensions: jpg, jpeg, png, heic, heif, tif, tiff, webp.
- Cache: JSON in `AppMetadata.applicationSupportDirectory()`, file `photo-fingerprints-v1.json`, max 200,000 entries, atomic writes, an unreadable file is never overwritten.
- UI strings in `MacinityStorage` views follow the existing pattern: Vietnamese source literals, with an entry in each of `Resources/{en,ja,zh-Hans}.lproj/Storage.strings`.
- Burst mode (same folder, 10 s) stays available as a separate mode.

## Review Focus

- Flat or identical images (black frames, blank screenshots) hash identically and form huge buckets: the scan must still finish, skip those buckets, and report how many were skipped.
- A photo and its EXIF-rotated copy must be treated as the same picture (thumbnail applies orientation).
- Corrupt, zero-byte or undecodable files (HEIC variants, truncated JPEG) are counted as skipped and never abort the scan.
- Moving the slider or applying suggestions must never leave a group with every photo marked Delete.
- A file that disappeared or sits outside the scanned root at Trash time is reported per file; the remaining files still move.

---

### Task 1: dHash fingerprint

**Files:**
- Create: `Sources/MacinityStorage/Features/Photos/PhotoFingerprint.swift`
- Test: `Tests/MacinityStorageTests/PhotoFingerprintTests.swift`

**Interfaces:**
- Produces: `enum PhotoFingerprint { static func dHash(gray9x8: [UInt8]) -> UInt64; static func hamming(_ a: UInt64, _ b: UInt64) -> Int; static func dHash(of url: URL) -> UInt64? }`

- [ ] **Step 1: Write failing tests** in `PhotoFingerprintTests` (`@testable import MacinityStorage`):
  - `testDHashOfIncreasingRowsIsAllOnes`: 72 bytes where each row of 9 is `0,10,…,80` → `UInt64.max`.
  - `testDHashOfConstantImageIsZero`: 72 equal bytes → `0`.
  - `testHammingCountsDifferingBits`: `hamming(0b1010, 0b0110) == 2`.
  - `testResizedCopyIsCloseAndDifferentImageIsFar`: write a 400×300 gradient-with-shapes PNG, a 100×75 resize of it, and a checkerboard PNG to a temp dir (helper builds `CGImage` via `CGContext`, writes with `CGImageDestination`); `hamming(resized, original) <= 6`, `hamming(checkerboard, original) >= 20`.
  - `testRotatedByExifOrientationMatches`: same original saved with `kCGImagePropertyOrientation = 6` on a pre-rotated pixel buffer → `hamming <= 6` against the upright original hash.
  - `testUnreadableFileReturnsNil`: zero-byte file → `nil`.
- [ ] **Step 2:** `swift test --filter PhotoFingerprintTests` → FAIL (type not defined).
- [ ] **Step 3: Implement** `dHash(gray9x8:)`: for row y in 0..<8, x in 0..<8, bit `y*8+x` set when `pixel[y*9+x] < pixel[y*9+x+1]`. `dHash(of:)` builds an ImageIO thumbnail (`kCGImageSourceCreateThumbnailFromImageAlways`, `kCGImageSourceCreateThumbnailWithTransform: true`, max pixel 64), draws it into a 9×8 `DeviceGray` `CGContext` with `.high` interpolation, returns `dHash(gray9x8:)`; `nil` on any failure. `hamming` = `(a ^ b).nonzeroBitCount`.
- [ ] **Step 4:** run the filter again → PASS.

### Task 2: Candidate-pair index

**Files:**
- Create: `Sources/MacinityStorage/Features/Photos/PhotoHashIndex.swift`
- Test: `Tests/MacinityStorageTests/PhotoHashIndexTests.swift`

**Interfaces:**
- Consumes: `PhotoFingerprint.hamming`.
- Produces: `struct PhotoHashPair: Hashable, Sendable { let first: Int; let second: Int; let hamming: Int }` (`first < second`, indices into the input array) and `struct PhotoHashIndex { init(hashes: [UInt64]); func candidatePairs(maxHamming: Int = 10, maxBucket: Int = 5_000) -> (pairs: [PhotoHashPair], skippedBuckets: Int) }`.

- [ ] **Step 1: Write failing tests:**
  - `testMatchesBruteForceForRandomHashes`: seeded generator, 300 hashes of which 60 are copies of earlier ones with 0–10 random bit flips; for `maxHamming` 3 and 10 the returned pair set equals the brute-force set of all pairs with `hamming <= maxHamming`, and `skippedBuckets == 0`.
  - `testIdenticalHashesPairAtDistanceZero`.
  - `testOversizedBucketIsSkippedAndCounted`: 10 identical hashes with `maxBucket: 5` → no pairs from them, `skippedBuckets > 0`.
  - `testEmptyAndSingleInput` return no pairs.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** multi-index hashing: split the 64 bits into `maxHamming + 1` contiguous chunks as evenly as possible (pigeonhole: any pair within `maxHamming` shares at least one equal chunk); bucket indices by `(chunk, chunk value)`; for each bucket with `count <= maxBucket` test all pairs, keep those with `hamming <= maxHamming`, dedupe with a `Set<PhotoHashPair>`; buckets over the cap increment `skippedBuckets` and are not expanded. Return pairs sorted by `(first, second)` for determinism.
- [ ] **Step 4:** run → PASS.

### Task 3: Fingerprint cache

**Files:**
- Create: `Sources/MacinityStorage/Features/Photos/PhotoFingerprintCache.swift`
- Test: `Tests/MacinityStorageTests/PhotoFingerprintCacheTests.swift`

**Interfaces:**
- Produces: `struct PhotoFingerprintCache { static let maxEntries = 200_000; private(set) var isWritable: Bool; init(fileURL: URL); func hash(path: String, size: Int64, modified: Date) -> UInt64?; mutating func store(path: String, size: Int64, modified: Date, hash: UInt64); mutating func prune(keeping paths: Set<String>); func save() throws }`

- [ ] **Step 1: Write failing tests:** round trip through a temp file; changed size or modification date returns `nil`; a corrupt file gives `isWritable == false` and the file bytes are unchanged after `save()`; storing `maxEntries + 5` distinct paths keeps `maxEntries`; `prune(keeping:)` drops other paths.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** with a `Codable` entry `{size, modifiedSeconds (Int64), hash (String hex)}` keyed by path; modification compared at whole-second resolution; when over `maxEntries` drop arbitrary oldest-inserted entries (keep an insertion-ordered array of keys); `save()` is a no-op when `!isWritable`, otherwise creates the directory and writes `.atomic`; file larger than 64 MiB counts as unreadable.
- [ ] **Step 4:** run → PASS.

### Task 4: Grouping and keep suggestion (pure)

**Files:**
- Modify: `Sources/MacinityStorage/Features/Photos/SimilarPhotoScanner.swift` (add `var keepReason: KeepReason = .highestResolution` to `SimilarPhotoGroup`)
- Create: `Sources/MacinityStorage/Features/Photos/NearDuplicateGrouping.swift`
- Test: `Tests/MacinityStorageTests/NearDuplicateGroupingTests.swift`

**Interfaces:**
- Consumes: `SimilarPhoto`, `SimilarPhotoGroup` (existing).
- Produces: `enum KeepReason: String, Sendable { case highestResolution, sharpest, largestFile }`; `struct PhotoPairDistance: Sendable, Equatable { let first: Int; let second: Int; let distance: Float }` (indices into a photos array); `enum NearDuplicateGrouping { static func groups(photos: [SimilarPhoto], pairs: [PhotoPairDistance], minimumSimilarity: Double) -> [SimilarPhotoGroup]; static func suggestKeep(_ photos: [SimilarPhoto]) -> (photo: SimilarPhoto, reason: KeepReason) }`

- [ ] **Step 1: Write failing tests** (helper `photo(path:w:h:sharp:bytes:)`):
  - `testThresholdSplitsPairs`: pairs with distance 0.08 and 0.15; at `0.90` only the 0.08 pair forms a group; at `0.80` both do.
  - `testChainedPairsFormOneGroupAndReportWeakestLink`: A–B 0.05, B–C 0.09 → one group of 3, `maximumDistance == 0.09`.
  - `testKeepPrefersResolutionThenSharpnessThenBytesAndTieBreaksByPath` asserting the `KeepReason` for each case.
  - `testGroupsSortedByReclaimableBytesDescendingAndPhotosBestFirst`.
  - `testPairAtExactThresholdIsIncluded` (distance 0.10 at similarity 0.90, tolerance 1e-6).
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** union-find over pairs whose `1 - Double(distance) >= minimumSimilarity - 1e-6`; group `maximumDistance` = largest distance among the pairs used inside it; `suggestKeep` orders by `(pixelCount, sharpnessScore, bytes)` descending with path ascending as last tie-break and derives `reason` from the first criterion that separated the winner from the runner-up (`largestFile` if all earlier ones tie); group `id` as the existing scanner builds it (sorted paths joined by `|`).
- [ ] **Step 4:** run → PASS.

### Task 5: Shared metadata helper and near-duplicate scanner

**Files:**
- Create: `Sources/MacinityStorage/Features/Photos/PhotoMetadata.swift` (move `imageMetadata` and `sharpnessScore` out of `SimilarPhotoScanner` as `enum PhotoMetadata { static func read(url: URL, fallback: Date) -> (date: Date, width: Int, height: Int); static func sharpness(at url: URL) -> Double }`; `SimilarPhotoScanner` calls them — behaviour unchanged)
- Create: `Sources/MacinityStorage/Features/Photos/NearDuplicateScanner.swift`
- Test: `Tests/MacinityStorageTests/NearDuplicateScannerTests.swift`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: `struct NearDuplicateProgress: Sendable { enum Phase: Sendable { case enumerating, hashing, confirming }; let phase: Phase; let completed: Int; let total: Int }`; `struct NearDuplicateSnapshot: Sendable { let photos: [SimilarPhoto]; let pairs: [PhotoPairDistance]; let scannedCount: Int; let cachedCount: Int; let skippedCount: Int; let skippedBuckets: Int }` (`photos` holds only photos in at least one confirmed pair); `struct NearDuplicateScanner: Sendable { static let confirmationDistanceLimit: Float = 0.20; func scan(rootURL: URL, cacheURL: URL, progress: @Sendable (NearDuplicateProgress) -> Void) throws -> NearDuplicateSnapshot }`.

- [ ] **Step 1: Write failing tests** in a temp directory (helpers from Task 1 tests may be copied into a shared `PhotoFixtures` file in the test target):
  - `testFindsResizedCopyInAnotherFolderAndIgnoresDifferentImage`: `a.png` (400×300), `sub/a-small.png` (100×75), `b.png` (checkerboard) → one pair, both of its photos' names are `a.png`/`a-small.png`, `distance <= 0.20`, `scannedCount == 3`.
  - `testSecondScanUsesCache`: scan twice with the same `cacheURL` → second `cachedCount == 3`.
  - `testCorruptAndZeroByteFilesAreSkippedNotFatal`: add `bad.jpg` (zero bytes) and `trunc.jpg` (first 20 bytes of a real JPEG) → scan succeeds, `skippedCount >= 2`.
  - `testSymlinksAndPackagesAreIgnored`.
  - `testCancellationThrows`: cancel the surrounding `Task` before scan → `CancellationError`, cache file not created.
  - `testIdenticalFlatImagesAreReportedAsSkippedBuckets`: 6 solid-colour PNGs with `maxBucket` lowered through an internal init parameter `maxBucket: Int = 5_000` → no crash, `skippedBuckets > 0`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement** `scan`: enumerate (same keys/extensions/skips as `SimilarPhotoScanner`); for each photo look up the cache, else compute `dHash(of:)` (nil → skipped); `prune` then `save` the cache once after hashing (also on non-cancelled completion only); `PhotoHashIndex.candidatePairs(maxHamming: 10)`; compute a `VNFeaturePrintObservation` only for photos that appear in a candidate pair (nil → skipped, and its pairs dropped); keep pairs with `computeDistance <= confirmationDistanceLimit`; compute `PhotoMetadata.sharpness` only for photos kept; remap indices to the compacted `photos` array. Check `Task.isCancelled` in each loop and call `progress` at most every 50 items per phase.
- [ ] **Step 4:** run → PASS (Vision runs on macOS CI; if the synthetic gradient is flaky, strengthen the pattern, do not loosen the limit).

### Task 6: View model with decisions, shared Trash service

**Files:**
- Create: `Sources/MacinityStorage/Features/Photos/PhotoTrashService.swift` (extract the move-to-Trash + `HistoryStore.record` + `ActivityLedger.append` logic from `SimilarPhotoViewModel.trashSelected` as `struct PhotoTrashService { func trash(photos: [SimilarPhoto], root: URL, note: String) async -> [String] }` returning error messages; `SimilarPhotoViewModel.trashSelected` calls it, behaviour unchanged)
- Create: `Sources/MacinityStorage/Features/Photos/NearDuplicatePhotoViewModel.swift`
- Test: `Tests/MacinityStorageTests/NearDuplicatePhotoViewModelTests.swift`

**Interfaces:**
- Consumes: `NearDuplicateSnapshot`, `NearDuplicateGrouping`, `NearDuplicateScanner`.
- Produces: `@MainActor final class NearDuplicatePhotoViewModel: ObservableObject` with `@Published` `rootURL: URL`, `minimumSimilarity: Double` (0.90, clamped to 0.80...1.0), `folderFilter: String?`, `groups: [SimilarPhotoGroup]` (after filter), `deleteIDs: Set<String>`, `isWorking: Bool`, `status: String`, `errorMessage: String?`, `skippedBuckets: Int`; methods `load(snapshot: NearDuplicateSnapshot)`, `scan()`, `cancel()`, `chooseRoot()`, `setMinimumSimilarity(_:)`, `isDeleting(_ photo: SimilarPhoto) -> Bool`, `setDelete(_ photo: SimilarPhoto, _ value: Bool)`, `applySuggestions()`, `trashSelected()`; computed `keepCount: Int`, `deleteCount: Int`, `bytesFreed: Int64`, `folders: [String]`.

- [ ] **Step 1: Write failing tests** (`@MainActor`, build a snapshot by hand and call `load`):
  - `testSuggestionsArePrefilledOnLoad`: every non-recommended photo is in `deleteIDs`, recommended ones are not.
  - `testCannotMarkEveryPhotoOfAGroupForDeletion`: `setDelete(recommended, true)` is refused while all others are deleted (state unchanged).
  - `testSwitchingKeepPhotoIsAllowed`: unmark another photo, then marking the old recommended one is accepted.
  - `testSlidingThresholdRegroupsAndKeepsUserOverrides`: manually keep a suggested-delete photo, move the slider 0.90 → 0.80 → 0.90; that photo is still kept; photos no longer in any group leave `deleteIDs`.
  - `testSummaryCounts`: `keepCount`, `deleteCount`, `bytesFreed` match the decisions.
  - `testFolderFilterShowsOnlyGroupsTouchingFolder`.
  - `testApplySuggestionsResetsDecisions`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3: Implement.** Decisions are stored as `deleteIDs`; `setDelete` rejects a change that would leave a group with zero kept photos; regrouping calls `NearDuplicateGrouping.groups` on the stored snapshot and reconciles `deleteIDs` (keep overrides for photos still grouped, add suggestions for photos newly grouped, drop the rest); `trashSelected` passes only `deleteIDs` photos to `PhotoTrashService` with root = `rootURL`, then rescans. `scan()` runs `NearDuplicateScanner` detached, cache at `AppMetadata.applicationSupportDirectory()/photo-fingerprints-v1.json`, registers with `ScanActivityRegistry` like `SimilarPhotoViewModel`, and writes `status` including the skipped-bucket count when > 0.
- [ ] **Step 4:** run → PASS; also run `swift test --filter MacinityStorageTests` to confirm the `SimilarPhotoViewModel` refactor changed nothing.

### Task 7: Review list UI and wiring

**Files:**
- Create: `Sources/MacinityStorage/Views/NearDuplicatePhotosView.swift`, `Sources/MacinityStorage/Views/PhotoCompareSheet.swift`
- Modify: `Sources/MacinityStorage/Views/ContentView.swift` (create `NearDuplicatePhotoViewModel`, show a segmented picker "Cả thư viện" / "Chụp liên tiếp" inside the `.similarPhotos` case: first segment `NearDuplicatePhotosView`, second the existing `SimilarPhotosView`)
- Modify: `Resources/{en,ja,zh-Hans}.lproj/Storage.strings` (one entry per new Vietnamese literal)

**Interfaces:**
- Consumes: `NearDuplicatePhotoViewModel` from Task 6.

- [ ] **Step 1: Build the view** per the spec: page header with deleted-bytes total; per-group section header `"N ảnh • giống ≥ X% (ước lượng) • giải phóng Y"`; one row per photo with thumbnail (downsampled via ImageIO, not full `NSImage(contentsOf:)`), filename, containing folder, resolution, size, capture date, sharpness, a Keep/Delete segmented control bound to `isDeleting`/`setDelete`, and for the recommended photo the localized keep reason (`KeepReason` → text); a "So sánh" button opening `PhotoCompareSheet` (keep candidate vs chosen photo, side by side, same downsampled loader at larger size); bottom bar with similarity slider (80–100%, step 1, default 90), folder filter menu, summary `Giữ N · Xóa M · Giải phóng X`, "Áp dụng đề xuất", scan/stop, and "Chuyển vào Trash…" with the existing confirmation alert (disabled while working or when `deleteCount == 0`). Status line shows skipped-bucket warning text when `skippedBuckets > 0`.
- [ ] **Step 2: Wire `ContentView`**; add all new Vietnamese literals to the three `Storage.strings` files (English, Japanese, Simplified Chinese).
- [ ] **Step 3: Verify:** `swift build` succeeds; `./scripts/lint_localizations.swift` passes; `swift test` passes for the whole package.
- [ ] **Step 4: Manual check** (record the result honestly in the final report): run `./script/build_and_run.sh` (or the app from `swift run Macinity`), pick a folder containing a few photos plus a resized copy in a subfolder, confirm the group appears at 90%, the slider regroups, Keep/Delete toggles refuse an all-delete group, compare sheet opens, and Trash moves only Delete photos and they are recoverable from the Recovery page. If the app cannot be launched in the session, say the UI was not exercised.
