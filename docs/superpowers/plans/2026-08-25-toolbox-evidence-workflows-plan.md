# Toolbox 2.0 Evidence Workflows As-Built Record

Date: 2026-08-25
Status: completed
Release: `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Objective and release identity

This record replaces the executed evidence-workflow plan. The objective was to connect storage discovery, installer-change observation, mutation safety, migration, activity history, and recovery through shared local evidence without letting evidence itself authorize deletion. Implementation landed on `2026-08-25` in `58c9082`, `8e1acd2`, `f656198`, `74b2f90`, `12dbdd0`, and `2c1eb1d`. The resulting source shipped in stable `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

### Implemented file map

| Workflow | As-built files and contract |
| --- | --- |
| Shared stores | `ToolboxCore/EvidenceStore.swift`, `ActivityLedger.swift`, `StoreRecovery.swift`, and `EvidenceModels.swift` own versioned envelopes, normalized evidence paths, deterministic ordering, atomic per-file writes, append/upsert behavior, and corrupt Core-store quarantine. |
| Projects | `ToolboxStorage/Features/Projects/**` and `ToolboxStorage/Views/ProjectsView.swift` scan explicit generated-artifact rules inside user-selected roots and hand reviewed candidates to the existing cleanup boundary. |
| Install Trace | `ToolboxChanges/Features/Trace/InstallerMetadata.swift`, `InstallTraceCoordinator.swift`, `InstallTraceDropView.swift`, and related snapshot/store files accept `.dmg`, `.pkg`, and `.app`, persist before/active state, observe bounded FSEvents, and finish with snapshot/diff evidence. |
| Migration | `ToolboxCore/LegacyModels.swift`, `MigrationService.swift`, fixtures/tests, and `Toolbox/OnboardingView.swift` implement opt-in Diskora, MacCleaner, and Changeora import. |
| Safety/recovery/routing | `UnifiedRecoveryAdapter.swift`, mutation-safety tests, `ToolboxCoordinator.swift`, `ReleaseUpdateChecker.swift`, `SettingsView.swift`, and the module view models connect review routes, preflight validation, activity summaries, restore, scheduling, and update checks. |
| Retirement | `2c1eb1d` removed `apps/diskora/**` and `apps/changeora/**` and updated CI and canonical docs after the Toolbox gates passed. |

### Data and workflow contracts

`EvidenceStore` and `ActivityLedger` persist `evidence-v1.json` and `activity-v1.json` under `~/Library/Application Support/Toolbox`. Each write is atomic; multiple store writes are not one transaction. Decode corruption moves a Core file to a sibling `*.corrupt-<UTC timestamp>-<UUID>.json` path and reports it. An unsupported Core schema is reported without quarantine. Feature-owned history/session/checkpoint stores retain their narrower fail-soft loaders and are not represented as having Core-style quarantine.

Project scanning is opt-in by root. Rules recognize generated outputs for Swift/SwiftPM, Node.js, Python, Rust, Gradle/Android, Flutter, and CocoaPods. Unknown directories, source, manifests, lockfiles, `.git`, secrets, virtual-machine disks, Docker volumes, referenced runtimes, and paths outside the selected root do not become safe candidates.

Install Trace saves a before snapshot before asking `NSWorkspace` to open the selected installer item. Toolbox does not install or bypass macOS controls. Finish combines after-snapshot and bounded FSEvents evidence. Restarted traces expose the interval without observation as reduced coverage. Change Timeline can send a normalized path to Storage for review, but the route does not select or mutate it.

Migration decodes all present sources before destination writes, derives stable domain-scoped IDs, merges only missing records, verifies written destinations, records one migration activity, and writes `migration-v1.json` last. Repeat import is idempotent. Existing Toolbox data and every legacy file remain unchanged. A corrupt source or marker reports an error and does not produce a false completion marker.

Mutation services re-resolve symlinks and validate the exact existing target immediately before action. Eligible paths move to Trash; allowed developer commands use fixed executables and enumerated arguments and are explicitly nonrecoverable. Restore accepts only allowed Trash roots and allowed destinations, requires the source to exist, and refuses destination overwrite. Scheduled scans are scan-and-notify only. The legacy scheduled LaunchAgent changes only after confirmation. The update checker is user initiated and refuses a request while `ScanActivityRegistry` reports an active scan.

### Failure modes recorded as built

Permission/read failures produce visible coverage deficits. Independent scans may continue when one root fails. Cancellation leaves already streamed read-only results marked incomplete. Interrupted Install Trace never claims complete coverage. A preflight failure removes or rejects that target without broadening the allowed root. Partial Trash moves remain individually recoverable; missing Trash sources, destination conflicts, and filesystem errors are reported without overwrite. Evidence classifications remain advisory and never bypass feature-specific checks or confirmation.

### Execution record

| Commit | Recorded outcome |
| --- | --- |
| `58c9082` | Added shared evidence/activity stores, version envelopes, atomic writes, recovery/quarantine handling, and Core tests/smoke. |
| `8e1acd2` | Added project recognition, project scan reports, Projects UI, explicit cleanup review, tests, smoke fixtures, and localization resources. |
| `f656198` | Added installer metadata validation, GUI drop surface, trace lifecycle, interrupted-session support, and Changes tests/smoke. |
| `74b2f90` | Added legacy models, fixtures, opt-in onboarding migration, stable IDs, copy-verify behavior, idempotency tests, and completion reporting. |
| `12dbdd0` | Applied shared mutation preflight, unified Recovery, cross-module review routing, Home summaries, scan coordination, scheduled-scan migration, update checks, localization, and behavioral tests. |
| `2c1eb1d` | Removed the two legacy shipping packages and their CI matrix after the complete Toolbox gate. |

### Verification evidence

Repository-local results dated `2026-08-25` record PASS for Core, Storage/Recovery, Changes, and App/update smoke scripts plus localization lint. Migration smoke covered Diskora cleanup history, completed and interrupted Changeora sessions, an idempotent second run, and corrupt legacy input without partial markers or destructive writes. Recovery smoke completed five independent byte-for-byte restores and one no-overwrite conflict. The exact release workflow `32847772209` later ran XCTest and the same smoke/localization contracts at the tagged source commit and completed `success`.

### Deferred and unproven boundaries

The evidence does not establish performance comparisons, full coverage for every macOS path, a beta cohort, production-user behavior, unique users, downloads, defect counts, or physical Intel execution. It does not change the `v2.0.0` trust boundary: the published universal DMG is ad-hoc signed, not Apple-notarized or stapled, and requires the documented **Open Anyway** path after expected Gatekeeper rejection. See [stable release evidence](../../release-evidence/toolbox-2.0.0.md).

## Tiếng Việt

### Objective và release identity

Record này thay evidence-workflow plan đã execute. Objective là nối storage discovery, installer-change observation, mutation safety, migration, activity history và recovery qua shared local evidence mà không để evidence tự authorize deletion. Implementation vào `2026-08-25` trong `58c9082`, `8e1acd2`, `f656198`, `74b2f90`, `12dbdd0`, `2c1eb1d`; source đó ship trong stable `v2.0.0` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

### Implemented file map

| Workflow | File/contract as built |
| --- | --- |
| Shared store | `ToolboxCore/EvidenceStore.swift`, `ActivityLedger.swift`, `StoreRecovery.swift`, `EvidenceModels.swift` sở hữu versioned envelope, normalized path, deterministic ordering, atomic write, append/upsert và corrupt Core-store quarantine. |
| Projects | `ToolboxStorage/Features/Projects/**` và `ProjectsView.swift` scan rule generated-artifact explicit trong user-selected root rồi đưa candidate đã review tới cleanup boundary. |
| Install Trace | `ToolboxChanges/Features/Trace/InstallerMetadata.swift`, `InstallTraceCoordinator.swift`, `InstallTraceDropView.swift` và snapshot/store liên quan nhận `.dmg`, `.pkg`, `.app`, persist before/active state, quan sát bounded FSEvents và finish bằng snapshot/diff evidence. |
| Migration | `ToolboxCore/LegacyModels.swift`, `MigrationService.swift`, fixture/test và `Toolbox/OnboardingView.swift` implement opt-in import Diskora, MacCleaner, Changeora. |
| Safety/recovery/routing | `UnifiedRecoveryAdapter.swift`, mutation-safety test, `ToolboxCoordinator.swift`, `ReleaseUpdateChecker.swift`, `SettingsView.swift` và view model nối review route, preflight validation, summary, restore, scheduling, update check. |
| Retirement | `2c1eb1d` xóa `apps/diskora/**`, `apps/changeora/**` và update CI/canonical docs sau khi Toolbox gate pass. |

### Data/workflow contract

`EvidenceStore` và `ActivityLedger` persist `evidence-v1.json`, `activity-v1.json` dưới `~/Library/Application Support/Toolbox`. Mỗi write atomic; nhiều store không tạo một transaction. Decode corruption đổi tên Core file thành sibling `*.corrupt-<UTC timestamp>-<UUID>.json` và report. Unsupported Core schema được report mà không quarantine. Feature-owned history/session/checkpoint store giữ fail-soft loader hẹp hơn, không có Core quarantine guarantee.

Project scan là opt-in theo root, nhận generated output cho Swift/SwiftPM, Node.js, Python, Rust, Gradle/Android, Flutter, CocoaPods. Unknown directory, source, manifest, lockfile, `.git`, secret, virtual-machine disk, Docker volume, referenced runtime và path ngoài root không thành safe candidate.

Install Trace lưu before snapshot trước khi nhờ `NSWorkspace` mở installer item. Toolbox không install hay bypass macOS control. Finish merge after-snapshot/bounded FSEvents evidence. Trace qua restart đánh dấu interval không quan sát là reduced coverage. Change Timeline có thể gửi normalized path sang Storage để review, nhưng không select/mutate.

Migration decode mọi present source trước destination write, tạo stable domain-scoped ID, chỉ merge missing record, verify destination, ghi một migration activity và ghi `migration-v1.json` cuối. Repeat import idempotent. Existing Toolbox data và legacy file không đổi. Corrupt source/marker report error, không false completion marker.

Mutation service re-resolve symlink và validate exact existing target ngay trước action. Eligible path đi Trash; allowed developer command dùng fixed executable/argument enum và được ghi nonrecoverable. Restore chỉ nhận allowed Trash root/destination, yêu cầu source tồn tại và không overwrite. Scheduled scan chỉ scan-and-notify. Legacy scheduled LaunchAgent chỉ đổi sau confirmation. Update checker do user khởi tạo và từ chối request khi `ScanActivityRegistry` báo active scan.

### Failure mode as built

Permission/read failure tạo coverage deficit visible. Scan độc lập có thể tiếp tục khi một root fail. Cancel giữ streamed read-only result và đánh dấu incomplete. Interrupted Install Trace không claim complete coverage. Preflight failure reject target mà không mở rộng allowed root. Partial Trash move vẫn recover riêng; missing Trash source, destination conflict và filesystem error được report, không overwrite. Evidence classification chỉ advisory, không bypass feature check/confirmation.

### Execution record

| Commit | Kết quả ghi nhận |
| --- | --- |
| `58c9082` | Thêm shared store, version envelope, atomic write, recovery/quarantine handling, Core test/smoke. |
| `8e1acd2` | Thêm project recognition/report/UI, cleanup review, test/smoke fixture và localization. |
| `f656198` | Thêm metadata validation, GUI drop, trace lifecycle, interrupted-session support và Changes test/smoke. |
| `74b2f90` | Thêm legacy model/fixture, onboarding migration opt-in, stable ID, copy-verify, idempotency test và completion report. |
| `12dbdd0` | Thêm shared mutation preflight, unified Recovery, review routing, Home summary, scan coordination, scheduled migration, update check, localization và behavioral test. |
| `2c1eb1d` | Xóa hai legacy shipping package/CI matrix sau full Toolbox gate. |

### Verification evidence

Repository-local result ngày `2026-08-25` ghi PASS cho Core, Storage/Recovery, Changes, App/update smoke và localization lint. Migration smoke bao phủ Diskora cleanup history, Changeora session complete/interrupted, second run idempotent và corrupt input không partial marker/destructive write. Recovery smoke hoàn tất năm restore byte-for-byte và một no-overwrite conflict. Exact release workflow `32847772209` sau đó chạy XCTest cùng smoke/localization contract tại tagged source commit và completed `success`.

### Boundary deferred/chưa prove

Evidence không prove performance comparison, full coverage mọi macOS path, beta cohort, production-user behavior, unique user, download, defect count hay physical Intel execution. Nó không đổi trust boundary `v2.0.0`: published universal DMG ký ad-hoc, chưa Apple-notarize/staple và cần **Open Anyway** sau expected Gatekeeper rejection. Xem [stable release evidence](../../release-evidence/toolbox-2.0.0.md).

## 日本語

### Objective と release identity

この record は実行済み evidence-workflow plan を置き換えます。Objective は storage discovery、installer-change observation、mutation safety、migration、activity history、recovery を shared local evidence で接続し、evidence 自体には deletion authorization を与えないことでした。`2026-08-25` に `58c9082`、`8e1acd2`、`f656198`、`74b2f90`、`12dbdd0`、`2c1eb1d` で実装し、`c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` の stable `v2.0.0` に含まれました。

### Implemented file map

| Workflow | As-built file/contract |
| --- | --- |
| Shared store | `ToolboxCore/EvidenceStore.swift`、`ActivityLedger.swift`、`StoreRecovery.swift`、`EvidenceModels.swift` が versioned envelope、normalized path、deterministic ordering、atomic write、append/upsert、corrupt Core-store quarantine を所有します。 |
| Projects | `ToolboxStorage/Features/Projects/**` と `ProjectsView.swift` が user-selected root 内の明示 generated-artifact rule を scan し、review 済み candidate を cleanup boundary に渡します。 |
| Install Trace | `ToolboxChanges/Features/Trace/InstallerMetadata.swift`、`InstallTraceCoordinator.swift`、`InstallTraceDropView.swift` と関連 snapshot/store が `.dmg`、`.pkg`、`.app`、before/active persistence、bounded FSEvents、snapshot/diff finish を実装します。 |
| Migration | `ToolboxCore/LegacyModels.swift`、`MigrationService.swift`、fixture/test、`Toolbox/OnboardingView.swift` が Diskora、MacCleaner、Changeora の opt-in import を実装します。 |
| Safety/recovery/routing | `UnifiedRecoveryAdapter.swift`、mutation-safety test、`ToolboxCoordinator.swift`、`ReleaseUpdateChecker.swift`、`SettingsView.swift`、view model が review route、preflight、summary、restore、scheduling、update check を接続します。 |
| Retirement | `2c1eb1d` は Toolbox gate 後に `apps/diskora/**`、`apps/changeora/**` を削除し CI/canonical docs を更新しました。 |

### Data/workflow contract

`EvidenceStore` と `ActivityLedger` は `~/Library/Application Support/Toolbox` の `evidence-v1.json`、`activity-v1.json` を persist します。各 write は atomic ですが store 間 transaction ではありません。Decode corruption は Core file を sibling `*.corrupt-<UTC timestamp>-<UUID>.json` に移し report します。Unsupported Core schema は quarantine せず report します。Feature-owned history/session/checkpoint store は narrower fail-soft loader のままで Core quarantine guarantee はありません。

Project scan は root 単位の opt-in で、Swift/SwiftPM、Node.js、Python、Rust、Gradle/Android、Flutter、CocoaPods の generated output を認識します。Unknown directory、source、manifest、lockfile、`.git`、secret、virtual-machine disk、Docker volume、referenced runtime、root 外 path は safe candidate になりません。

Install Trace は `NSWorkspace` に installer item の open を依頼する前に before snapshot を保存します。Toolbox は install/macOS control bypass をしません。Finish は after-snapshot/bounded FSEvents evidence を merge します。Restart を跨いだ trace は未観測 interval を reduced coverage とします。Change Timeline は normalized path を Storage review に送れますが select/mutate はしません。

Migration は destination write 前に全 present source を decode し、stable domain-scoped ID を生成し、missing record のみ merge し、destination を verify し、一件の migration activity 後に `migration-v1.json` を最後に書きます。Repeat は idempotent です。Existing Toolbox data/legacy file は変更しません。Corrupt source/marker は error を report し false completion marker を作りません。

Mutation service は action 直前に symlink を再 resolve し exact existing target を validate します。Eligible path は Trash に移し、allowed developer command は fixed executable/列挙 argument を使って nonrecoverable と明示します。Restore は allowed Trash root/destination のみ、source existence 必須、overwrite 拒否です。Scheduled scan は scan-and-notify のみです。Legacy scheduled LaunchAgent は confirmation 後だけ変更します。Update checker は user initiated で、`ScanActivityRegistry` が active scan を示す間は request を拒否します。

### As-built failure mode

Permission/read failure は visible coverage deficit になります。一つの root が fail しても独立 scan は継続できます。Cancel は streamed read-only result を incomplete として保持します。Interrupted Install Trace は complete coverage を claim しません。Preflight failure は allowed root を拡張せず target を reject します。Partial Trash move は個別 recovery 可能で、missing source、destination conflict、filesystem error は overwrite せず report します。Evidence classification は advisory で feature check/confirmation を bypass しません。

### Execution record

| Commit | 記録結果 |
| --- | --- |
| `58c9082` | Shared store、version envelope、atomic write、recovery/quarantine handling、Core test/smoke を追加。 |
| `8e1acd2` | Project recognition/report/UI、cleanup review、test/smoke fixture、localization を追加。 |
| `f656198` | Metadata validation、GUI drop、trace lifecycle、interrupted-session support、Changes test/smoke を追加。 |
| `74b2f90` | Legacy model/fixture、opt-in onboarding migration、stable ID、copy-verify、idempotency test、completion report を追加。 |
| `12dbdd0` | Shared mutation preflight、unified Recovery、review routing、Home summary、scan coordination、scheduled migration、update check、localization、behavioral test を追加。 |
| `2c1eb1d` | Full Toolbox gate 後に二つの legacy shipping package/CI matrix を削除。 |

### Verification evidence

`2026-08-25` repository-local result は Core、Storage/Recovery、Changes、App/update smoke、localization lint の PASS を記録します。Migration smoke は Diskora cleanup history、completed/interrupted Changeora session、idempotent second run、partial marker/destructive write を作らない corrupt input を cover しました。Recovery smoke は 5 件の byte-for-byte restore と 1 件の no-overwrite conflict を完了しました。Exact release workflow `32847772209` は後に tagged source commit で XCTest と同じ smoke/localization contract を実行し completed `success` でした。

### Deferred/unproven boundary

Performance comparison、全 macOS path の complete coverage、beta cohort、production-user behavior、unique user、download、defect count、physical Intel execution は prove していません。`v2.0.0` trust boundary は変わらず、published universal DMG は ad-hoc signed、Apple-notarize/staple なしで、expected Gatekeeper rejection 後に **Open Anyway** が必要です。[Stable release evidence](../../release-evidence/toolbox-2.0.0.md) を参照してください。
