# Toolbox 2.0 Foundation As-Built Record

Date: 2026-08-25
Status: completed
Release: `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Objective and release identity

This record replaces the executed foundation plan. The objective was to establish one SwiftPM package and one native Toolbox executable while preserving Diskora and Changeora behavior long enough to verify the port. The work was implemented on `2026-08-25` in commits `2160541`, `1d480a6`, `f3a5108`, `4b623b7`, and `e780df5`; later evidence/recovery work retired the legacy packages in `2c1eb1d`. The final stable tag is `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

### Implemented file map

| Area | As-built files and responsibility |
| --- | --- |
| Package | `apps/toolbox/Package.swift` defines `ToolboxCore`, `ToolboxStorage`, `ToolboxChanges`, `Toolbox`, `SmokeCore`, and four XCTest targets. |
| Core | `Sources/ToolboxCore/AppMetadata.swift`, `Localization.swift`, `SafetyModels.swift`, and `EvidenceModels.swift` establish application support, language/formatting, normalized-path safety, and shared evidence types. |
| Storage | `Sources/ToolboxStorage/**`, `Tests/ToolboxStorageTests/**`, `Tests/SmokeStorage/main.swift`, and `scripts/test_storage.sh` contain the ported storage, application, developer, cleanup, history, duplicate, photo, and storage-trend functionality. |
| Changes | `Sources/ToolboxChanges/**`, `Tests/ToolboxChangesTests/**`, `Tests/SmokeChanges/main.swift`, and `scripts/test_changes.sh` contain the ported snapshot, FSEvents, diff, baseline, history, and Change Timeline functionality. |
| App shell | `Sources/Toolbox/ToolboxApp.swift`, `ToolboxShellView.swift`, `HomeView.swift`, `Resources/**`, app tests, and `scripts/build_app.sh` produce one app and one window. |
| CI/docs | `.github/workflows/ci.yml`, `README.md`, and `docs/ARCHITECTURE.md` changed the supported build/test contract to Toolbox. |

### Contracts and failure modes

Dependency direction is `ToolboxStorage -> ToolboxCore`, `ToolboxChanges -> ToolboxCore`, and `Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges`; Storage and Changes do not import one another. The stable navigation identifiers are Home, Storage, Projects, Applications, Change Timeline, and Recovery. The bundle is `com.thang.toolbox`, version `2.0.0`, macOS 13+.

Path safety normalizes and resolves candidates, rejects root/home/out-of-boundary targets and symlink escapes, and treats unknown targets as review/protected rather than safe. Ported scanners surface inaccessible locations as coverage errors instead of successful empty scans. Mutation remains behind review and confirmation; this foundation did not authorize automatic deletion. English and Vietnamese resources ship in the bundle; Japanese remains documentation-only.

### Execution record

| Commit | Recorded outcome |
| --- | --- |
| `2160541` | Created the unified package, Core types, path-safety policy, metadata/localization primitives, Core tests, and `SmokeCore`. |
| `1d480a6` | Ported Diskora into `ToolboxStorage` with storage, cleanup, applications, developer, duplicate, photo, history, tests, and smoke coverage. |
| `f3a5108` | Ported Changeora into `ToolboxChanges` with snapshots, FSEvents, diffs, baselines, sessions, views, tests, and smoke coverage. |
| `4b623b7` | Added the Toolbox executable, six-destination `NavigationSplitView`, Home, resources, app bundle script, and app-shell tests. |
| `e780df5` | Added the Toolbox format, XCTest, smoke, release-build, bundle-resource, and structural codesign CI lane. |
| `2c1eb1d` | Removed `apps/diskora` and `apps/changeora` after later parity and migration work completed. |

### Verification evidence

The exact release workflow `32847772209` completed `success` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` and ran format lint, XCTest, all four smoke contracts, localization validation, universal build, and public release contracts. Repository-local evidence on `2026-08-25` separately records PASS for `./scripts/test_core.sh`, `./scripts/test_storage.sh`, `./scripts/test_changes.sh`, `./scripts/test_app.sh`, localization lint, and the universal/ad-hoc bundle checks. Command Line Tools alone could not run `swift test` because `XCTest` was unavailable there; the successful exact macOS Actions run is the XCTest evidence.

### Deferred and unproven boundaries

This record does not prove physical Intel execution, performance parity against v1, a clean-account launch, Developer ID signing, notarization, stapling, Homebrew distribution, beta participation, defects resolved, or adoption. The published DMG contains `arm64` and `x86_64` slices but is ad-hoc signed and not Apple-notarized. See [stable release evidence](../../release-evidence/toolbox-2.0.0.md); **Open Anyway** is the safe first-launch exception for this build.

## Tiếng Việt

### Objective và release identity

Record này thay plan foundation đã execute. Objective là tạo một SwiftPM package và một native Toolbox executable, đồng thời giữ behavior Diskora/Changeora đủ lâu để verify port. Work được implement ngày `2026-08-25` trong `2160541`, `1d480a6`, `f3a5108`, `4b623b7`, `e780df5`; evidence/recovery phase sau đó xóa legacy package trong `2c1eb1d`. Stable tag cuối là `v2.0.0` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

### Implemented file map

| Area | File/responsibility as built |
| --- | --- |
| Package | `apps/toolbox/Package.swift` định nghĩa `ToolboxCore`, `ToolboxStorage`, `ToolboxChanges`, `Toolbox`, `SmokeCore` và bốn XCTest target. |
| Core | `Sources/ToolboxCore/AppMetadata.swift`, `Localization.swift`, `SafetyModels.swift`, `EvidenceModels.swift` tạo application support, language/formatting, normalized-path safety và shared evidence type. |
| Storage | `Sources/ToolboxStorage/**`, `Tests/ToolboxStorageTests/**`, `Tests/SmokeStorage/main.swift`, `scripts/test_storage.sh` chứa storage/application/developer/cleanup/history/duplicate/photo/trend đã port. |
| Changes | `Sources/ToolboxChanges/**`, `Tests/ToolboxChangesTests/**`, `Tests/SmokeChanges/main.swift`, `scripts/test_changes.sh` chứa snapshot, FSEvents, diff, baseline, history và Change Timeline đã port. |
| App shell | `Sources/Toolbox/ToolboxApp.swift`, `ToolboxShellView.swift`, `HomeView.swift`, `Resources/**`, app test và `scripts/build_app.sh` tạo một app/một window. |
| CI/docs | `.github/workflows/ci.yml`, `README.md`, `docs/ARCHITECTURE.md` chuyển supported build/test contract sang Toolbox. |

### Contract và failure mode

Dependency là `ToolboxStorage -> ToolboxCore`, `ToolboxChanges -> ToolboxCore`, `Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges`; Storage/Changes không import nhau. Stable navigation identifier là Home, Storage, Projects, Applications, Change Timeline, Recovery. Bundle là `com.thang.toolbox`, version `2.0.0`, macOS 13+.

Path safety normalize/resolve candidate, reject root/home/out-of-boundary target và symlink escape, coi unknown target là review/protected thay vì safe. Scanner đã port hiển thị inaccessible location thành coverage error, không phải successful empty scan. Mutation vẫn cần review/confirmation; foundation không cho phép automatic deletion. Bundle ship English/Vietnamese resource; Japanese chỉ documentation.

### Execution record

| Commit | Kết quả ghi nhận |
| --- | --- |
| `2160541` | Tạo unified package, Core type, path-safety policy, metadata/localization primitive, Core test và `SmokeCore`. |
| `1d480a6` | Port Diskora vào `ToolboxStorage` cùng test/smoke cho storage, cleanup, applications, developer, duplicate, photo và history. |
| `f3a5108` | Port Changeora vào `ToolboxChanges` cùng snapshot, FSEvents, diff, baseline, session, view, test và smoke. |
| `4b623b7` | Thêm Toolbox executable, `NavigationSplitView` sáu destination, Home, resource, app bundle script và app-shell test. |
| `e780df5` | Thêm CI lane format, XCTest, smoke, release build, bundle resource và structural codesign. |
| `2c1eb1d` | Xóa `apps/diskora`/`apps/changeora` sau parity/migration phase. |

### Verification evidence

Exact release workflow `32847772209` completed `success` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`, chạy format lint, XCTest, bốn smoke contract, localization, universal build và public release contract. Repository-local evidence ngày `2026-08-25` ghi PASS riêng cho `./scripts/test_core.sh`, `./scripts/test_storage.sh`, `./scripts/test_changes.sh`, `./scripts/test_app.sh`, localization lint và universal/ad-hoc bundle check. Command Line Tools local không chạy được `swift test` vì thiếu `XCTest`; exact macOS Actions run là XCTest evidence.

### Boundary deferred/chưa prove

Record không prove physical Intel execution, performance parity với v1, clean-account launch, Developer ID, notarization, stapling, Homebrew, beta participation, defect resolved hay adoption. Published DMG có slice `arm64`/`x86_64` nhưng ký ad-hoc và chưa Apple-notarize. Xem [stable release evidence](../../release-evidence/toolbox-2.0.0.md); **Open Anyway** là first-launch exception an toàn cho build này.

## 日本語

### Objective と release identity

この record は実行済み foundation plan を置き換えます。Objective は一つの SwiftPM package/native Toolbox executable を構築し、port 検証まで Diskora/Changeora behavior を保持することでした。`2026-08-25` に `2160541`、`1d480a6`、`f3a5108`、`4b623b7`、`e780df5` で実装し、後続 evidence/recovery work の `2c1eb1d` で legacy package を削除しました。Final stable tag は `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` の `v2.0.0` です。

### Implemented file map

| Area | As-built file/responsibility |
| --- | --- |
| Package | `apps/toolbox/Package.swift` は `ToolboxCore`、`ToolboxStorage`、`ToolboxChanges`、`Toolbox`、`SmokeCore`、4 XCTest target を定義します。 |
| Core | `Sources/ToolboxCore/AppMetadata.swift`、`Localization.swift`、`SafetyModels.swift`、`EvidenceModels.swift` が application support、language/formatting、normalized-path safety、shared evidence type を実装します。 |
| Storage | `Sources/ToolboxStorage/**`、`Tests/ToolboxStorageTests/**`、`Tests/SmokeStorage/main.swift`、`scripts/test_storage.sh` が port 済み storage/application/developer/cleanup/history/duplicate/photo/trend を実装します。 |
| Changes | `Sources/ToolboxChanges/**`、`Tests/ToolboxChangesTests/**`、`Tests/SmokeChanges/main.swift`、`scripts/test_changes.sh` が port 済み snapshot、FSEvents、diff、baseline、history、Change Timeline を実装します。 |
| App shell | `Sources/Toolbox/ToolboxApp.swift`、`ToolboxShellView.swift`、`HomeView.swift`、`Resources/**`、app test、`scripts/build_app.sh` が one app/one window を作ります。 |
| CI/docs | `.github/workflows/ci.yml`、`README.md`、`docs/ARCHITECTURE.md` が supported build/test contract を Toolbox に変更しました。 |

### Contract と failure mode

Dependency は `ToolboxStorage -> ToolboxCore`、`ToolboxChanges -> ToolboxCore`、`Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges` で、Storage/Changes は相互 import しません。Stable navigation identifier は Home、Storage、Projects、Applications、Change Timeline、Recovery です。Bundle は `com.thang.toolbox`、version `2.0.0`、macOS 13+ です。

Path safety は candidate を normalize/resolve し、root/home/out-of-boundary target と symlink escape を reject し、unknown target を safe ではなく review/protected とします。Port 済み scanner は inaccessible location を successful empty scan ではなく coverage error にします。Mutation は review/confirmation 後だけで、automatic deletion はありません。English/Vietnamese resource を ship し、Japanese は documentation-only です。

### Execution record

| Commit | 記録結果 |
| --- | --- |
| `2160541` | Unified package、Core type、path-safety policy、metadata/localization primitive、Core test、`SmokeCore` を作成。 |
| `1d480a6` | Diskora を `ToolboxStorage` に port し、storage、cleanup、applications、developer、duplicate、photo、history の test/smoke を追加。 |
| `f3a5108` | Changeora を `ToolboxChanges` に port し、snapshot、FSEvents、diff、baseline、session、view、test/smoke を追加。 |
| `4b623b7` | Toolbox executable、6 destination の `NavigationSplitView`、Home、resource、app bundle script、app-shell test を追加。 |
| `e780df5` | Toolbox format、XCTest、smoke、release build、bundle resource、structural codesign CI lane を追加。 |
| `2c1eb1d` | Parity/migration phase 後に `apps/diskora`/`apps/changeora` を削除。 |

### Verification evidence

Exact release workflow `32847772209` は `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` で completed `success` となり、format lint、XCTest、4 smoke contract、localization、universal build、public release contract を実行しました。`2026-08-25` repository-local evidence は `./scripts/test_core.sh`、`./scripts/test_storage.sh`、`./scripts/test_changes.sh`、`./scripts/test_app.sh`、localization lint、universal/ad-hoc bundle check の PASS を記録します。Local Command Line Tools は `XCTest` 不在で `swift test` を実行できず、exact macOS Actions run が XCTest evidence です。

### Deferred/unproven boundary

Physical Intel execution、v1 performance parity、clean-account launch、Developer ID、notarization、stapling、Homebrew、beta participation、resolved defect、adoption は prove していません。Published DMG は `arm64`/`x86_64` slice を含みますが ad-hoc signed で Apple-notarize されていません。[Stable release evidence](../../release-evidence/toolbox-2.0.0.md) を参照し、この build の安全な first-launch exception は **Open Anyway** です。
