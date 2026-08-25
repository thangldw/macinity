# Toolbox 2.0 Super-App As-Built Design Record

Date: 2026-08-24
Status: completed
Owner: thangldw
Release: `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Record boundary and outcome

This completed record describes the design implemented between `6a177e2` and the stable `v2.0.0` tag. Source and executable tests define application behavior; the exact workflow and published artifact define release state. The stable evidence ledger is [docs/release-evidence/toolbox-2.0.0.md](../../release-evidence/toolbox-2.0.0.md).

Toolbox replaced the separate Diskora and Changeora binaries with one native, GUI-only macOS application for developer and power-user hygiene. Its two jobs are to explain developer storage and reclaim only reviewed targets, and to record installer-related changes so that later cleanup can use that evidence. The product promise remained **See what changed. Reclaim space safely.**

### Goals, non-goals, and target user

The implemented goals were one coherent path from change observation to evidence-based cleanup; six user-facing destinations; local-only processing; review before mutation; Trash-backed recovery where eligible; read-only observation; and opt-in, copy-then-verify migration that leaves legacy data untouched.

The target user is a macOS developer or power user who installs developer tools, uses multiple package managers or runtimes, and accumulates rebuildable caches or project artifacts. The application does not require terminal use. Optional Full Disk Access improves coverage, while refusal produces explicit reduced coverage.

The 2.0 boundary excludes a CLI, privileged helper, Endpoint Security extension, automatic blocking, malware verdicts, automatic uninstall or deletion, default permanent deletion, restore overwrite, cloud accounts, file-content upload, in-app telemetry, advertising, subscriptions, Windows/Linux builds, AI-model inventory, environment-drift inventory, and reproducibility bundles. The last three remain uncommitted product candidates rather than release promises.

### As-built product and code structure

`Toolbox` uses bundle identifier `com.thang.toolbox`, targets macOS 13 or later, and ships as version `2.0.0`. The single window exposes Home, Storage, Projects, Applications, Change Timeline, and Recovery. Home summarizes recoverable bytes and important changes and offers Start Install Trace; Settings owns language, scheduled scans, migration controls, and the user-initiated update check.

`apps/toolbox/Package.swift` defines `ToolboxCore`, `ToolboxStorage`, `ToolboxChanges`, the `Toolbox` executable, and the non-shipping `SmokeCore` executable. Dependencies are `ToolboxStorage -> ToolboxCore`, `ToolboxChanges -> ToolboxCore`, and `Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges`. Storage and Changes do not import one another; cross-module routing stays in `ToolboxCoordinator`. The legacy `apps/diskora` and `apps/changeora` packages were removed after parity checks in `2c1eb1d`; their historical releases and user data were not deleted.

### Evidence and durable data

New shared data lives under `~/Library/Application Support/Toolbox`. `ToolboxCore` owns schema-versioned `evidence-v1.json` and `activity-v1.json`, deterministic ordering, normalized paths, atomic per-file writes, corrupt-file quarantine, and explicit unsupported-schema errors. Atomic replacement is not a transaction across stores. Storage history, storage checkpoints, Change Timeline sessions, active trace state, and trusted baseline retain their feature-owned formats and fail-soft behavior; they do not inherit the Core quarantine guarantee.

Evidence records describe the normalized path, kind, safety, observation time, and reasons. Activity entries record cleanup, approved command, restore, trace, migration, or export results. Change Timeline can route a path to Storage for review, but routing neither selects nor mutates it.

### Reclaim Space as built

Scans start only from the relevant GUI surfaces. Project scanning is limited to user-selected roots and recognizes explicit generated-artifact rules for Swift/SwiftPM, Node.js, Python, Rust, Gradle/Android, Flutter, and CocoaPods. Source, manifests, lockfiles, `.git`, secrets, virtual-machine disks, Docker volumes, unknown directories, root, and the home root are not safe cleanup candidates.

The review path shows the candidate path, bytes, evidence, reasons, action, and recoverability. Immediately before mutation, services resolve symlinks and validate the exact existing target against approved roots. Eligible items move through `FileManager.trashItem`; fixed-path developer commands use enumerated arguments and are labeled nonrecoverable. The ledger records actual results and Trash paths. Scheduled work is scan-and-notify only and cannot invoke mutation.

### Install Trace as built

Install Trace accepts only `.dmg`, `.pkg`, and `.app`. It records metadata, writes the before snapshot, starts bounded FSEvents observation, and passes the selected item to normal macOS opening through `NSWorkspace`. Toolbox does not mount, execute, install, authorize, or bypass Gatekeeper itself.

Finish captures the after snapshot, merges snapshot and event evidence, records coverage gaps, persists the session, and writes shared evidence/activity records. An interrupted trace may be resumed or finished with an explicit reduced-coverage interval, or cancelled; it is never presented as complete coverage. Reports redact the home prefix to `~`, omit file contents, and do not make malware claims.

### Safety, privacy, errors, and recovery

Unknown or ambiguous targets fail closed as `protected` or `review`. Mutation requires explicit foreground selection and confirmation. Symlink escapes, paths outside approved roots, and dangerous or evidence-only targets are rejected. Restore revalidates source and destination and never overwrites. Partial Trash moves are recorded individually; nonrecoverable commands are separate from Trash-backed activity.

Scanner and permission failures remain attached to their root or category while independent scans continue. Cancellation preserves incomplete read-only results. Core store corruption is quarantined; unsupported Core schema versions are reported without quarantine. Legacy feature stores may return empty or `nil` on unreadable data, so this narrower behavior is documented rather than overstated.

All scans, snapshots, evidence, history, and reports remain local. The only in-process network request is a user-initiated Settings GET to public GitHub release metadata; it sends no scan paths, evidence, results, or device payload. Toolbox has no account or telemetry.

### Migration, localization, and accessibility

Onboarding inspects legacy Diskora, MacCleaner, and Changeora records. Migration decodes all present sources, derives stable domain-scoped IDs, merges missing records, atomically writes and decodes destinations, records one migration activity, and writes `migration-v1.json` last. Repeated migration is idempotent. Legacy files are never modified or deleted, and a corrupt source or marker leaves the operation retryable without a false completion marker.

The old Diskora scheduled LaunchAgent is changed only after explicit confirmation. Full Disk Access must be granted again to Toolbox and remains optional.

The shipped application has English and Vietnamese resources; Japanese is documentation-only for 2.0. Primary actions have keyboard access and labels, status meaning does not rely on color alone, and paths remain selectable where presented.

### Verification and release evidence

Commits `2160541` through `2c1eb1d` established the package, ported both products, added the shell, evidence stores, Projects, Install Trace, migration, unified recovery/routing, and retired legacy packages. Repository-local evidence dated `2026-08-25` records passing format, core, storage/recovery, changes, app/update, localization, universal-bundle, and ad-hoc DMG structural checks. Recovery evidence includes five byte-for-byte restores and one no-overwrite conflict. The exact release workflow `32847772209` and Pages workflow `32847688077` completed `success` at the tagged source commit.

The published artifact is `Toolbox-2.0.0.dmg`, `6055290` bytes, SHA-256 `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba`. It contains `arm64` and `x86_64` slices, but no physical Intel execution is proven. It is ad-hoc signed and not Apple-notarized or stapled. Direct Gatekeeper rejection is expected; **System Settings → Privacy & Security → Open Anyway** is the safe first-launch path for this build. Homebrew is unavailable. Product Hunt was scheduled, not launched, at the time-bounded `2026-08-26 02:07 JST` observation. No beta-cohort, performance-comparison, defect-count, unique-user, download, vote, follower, or adoption result is claimed.

## Tiếng Việt

### Ranh giới record và kết quả

Record hoàn tất này mô tả design đã implement từ `6a177e2` đến stable tag `v2.0.0`. Source và executable test định nghĩa behavior; exact workflow và published artifact định nghĩa release state. Stable evidence ledger là [docs/release-evidence/toolbox-2.0.0.md](../../release-evidence/toolbox-2.0.0.md).

Toolbox thay hai binary Diskora/Changeora bằng một ứng dụng macOS native, GUI-only cho developer và power user. Hai nhiệm vụ là giải thích storage rồi chỉ reclaim target đã review, và ghi thay đổi liên quan installer để cleanup sau dùng được evidence đó. Product promise vẫn là **See what changed. Reclaim space safely.**

### Goal, non-goal và target user

Goal đã implement là một luồng thống nhất từ quan sát thay đổi đến cleanup dựa trên evidence; sáu destination; xử lý local; review trước mutation; recovery qua Trash khi đủ điều kiện; quan sát read-only; và migration opt-in, copy-then-verify không sửa legacy data.

Target user là developer/power user macOS thường cài developer tool, dùng nhiều package manager/runtime và tích lũy cache hoặc project artifact có thể rebuild. Ứng dụng không yêu cầu terminal. Full Disk Access là tùy chọn; nếu từ chối, ứng dụng hiển thị reduced coverage.

Ranh giới 2.0 loại trừ CLI, privileged helper, Endpoint Security extension, automatic blocking, malware verdict, automatic uninstall/delete, permanent deletion mặc định, restore overwrite, cloud account, upload file content, in-app telemetry, quảng cáo, subscription, Windows/Linux, AI-model inventory, environment-drift inventory và reproducibility bundle. Ba ý cuối chỉ là candidate chưa cam kết.

### Product và code structure as built

`Toolbox` dùng bundle identifier `com.thang.toolbox`, target macOS 13+ và ship version `2.0.0`. Một window có Home, Storage, Projects, Applications, Change Timeline và Recovery. Home tóm tắt recoverable byte/important change và có Start Install Trace; Settings quản lý language, scheduled scan, migration control và update check do user khởi tạo.

`apps/toolbox/Package.swift` định nghĩa `ToolboxCore`, `ToolboxStorage`, `ToolboxChanges`, executable `Toolbox` và executable không ship `SmokeCore`. Dependency là `ToolboxStorage -> ToolboxCore`, `ToolboxChanges -> ToolboxCore`, `Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges`. Storage/Changes không import nhau; `ToolboxCoordinator` giữ cross-module routing. Hai package legacy bị xóa khỏi source trong `2c1eb1d` sau parity check; release history và user data không bị xóa.

### Evidence và durable data

Shared data mới nằm dưới `~/Library/Application Support/Toolbox`. `ToolboxCore` sở hữu `evidence-v1.json`, `activity-v1.json`, ordering deterministic, normalized path, atomic write cho từng file, corrupt-file quarantine và unsupported-schema error explicit. Atomic replacement không phải transaction giữa nhiều store. Storage history/checkpoint, Change Timeline session, active trace và trusted baseline giữ format/fail-soft behavior riêng; không có Core quarantine guarantee.

Evidence record lưu normalized path, kind, safety, observation time và reason. Activity entry lưu kết quả cleanup, approved command, restore, trace, migration hoặc export. Change Timeline có thể route path sang Storage để review nhưng không select hay mutate.

### Reclaim Space as built

Scan chỉ bắt đầu từ GUI phù hợp. Project scan giới hạn trong root do user chọn và dùng rule explicit cho Swift/SwiftPM, Node.js, Python, Rust, Gradle/Android, Flutter và CocoaPods. Source, manifest, lockfile, `.git`, secret, virtual-machine disk, Docker volume, unknown directory, root và home root không phải safe cleanup candidate.

Review hiển thị path, byte, evidence, reason, action và recoverability. Ngay trước mutation, service resolve symlink và validate exact existing target trong approved root. Item đủ điều kiện đi qua `FileManager.trashItem`; developer command dùng fixed path/argument enum và được ghi rõ nonrecoverable. Ledger ghi actual result/Trash path. Scheduled work chỉ scan-and-notify, không mutate.

### Install Trace as built

Install Trace chỉ nhận `.dmg`, `.pkg`, `.app`; ghi metadata/before snapshot, bắt đầu FSEvents có giới hạn và giao item cho luồng mở macOS bình thường qua `NSWorkspace`. Toolbox không tự mount, execute, install, authorize hay bypass Gatekeeper.

Finish chụp after snapshot, merge snapshot/event evidence, ghi coverage gap, persist session và shared evidence/activity. Trace bị interrupt có thể resume, finish với reduced-coverage interval explicit hoặc cancel; không được coi là complete coverage. Report đổi home prefix thành `~`, bỏ file content và không malware verdict.

### Safety, privacy, error và recovery

Target unknown/ambiguous fail closed thành `protected` hoặc `review`. Mutation cần selection/confirmation foreground explicit. Symlink escape, target ngoài approved root, dangerous/evidence-only target bị reject. Restore revalidate source/destination và không overwrite. Partial Trash move được ghi riêng; nonrecoverable command tách khỏi Trash-backed activity.

Scanner/permission error gắn với exact root/category trong khi scan độc lập tiếp tục. Cancel giữ incomplete read-only result. Core store corrupt được quarantine; unsupported Core schema chỉ report. Legacy feature store có thể trả empty/`nil` khi data unreadable, nên record không mở rộng guarantee.

Scan, snapshot, evidence, history và report đều local. Network request duy nhất trong app là Settings GET do user khởi tạo tới public GitHub release metadata; không gửi scan path, evidence, result hay device payload. Toolbox không có account hoặc telemetry.

### Migration, localization và accessibility

Onboarding kiểm tra record Diskora, MacCleaner và Changeora. Migration decode mọi source hiện diện, tạo stable domain-scoped ID, merge record thiếu, atomic-write/decode destination, ghi một migration activity rồi ghi `migration-v1.json` cuối cùng. Chạy lại là idempotent. Legacy file không bị sửa/xóa; corrupt source/marker để trạng thái retryable, không tạo completion marker sai.

Legacy Diskora scheduled LaunchAgent chỉ đổi sau confirmation explicit. Full Disk Access phải cấp lại cho Toolbox và vẫn optional.

Ứng dụng ship resource English/Vietnamese; Japanese chỉ có trong documentation của 2.0. Primary action có keyboard access/label, status không chỉ dựa vào color, và path có thể select khi hiển thị.

### Verification và release evidence

Các commit `2160541` đến `2c1eb1d` tạo package, port hai product, thêm shell, evidence store, Projects, Install Trace, migration, unified recovery/routing và xóa package legacy. Repository-local evidence ngày `2026-08-25` ghi PASS cho format, core, storage/recovery, changes, app/update, localization, universal bundle và ad-hoc DMG structural check. Recovery gồm năm restore byte-for-byte và một conflict không overwrite. Release workflow `32847772209` và Pages workflow `32847688077` completed `success` tại tagged source commit.

Published artifact là `Toolbox-2.0.0.dmg`, `6055290` byte, SHA-256 `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba`. Artifact có slice `arm64`/`x86_64`, nhưng không có proof chạy trên Intel vật lý. Build ký ad-hoc, chưa Apple-notarize/staple. Gatekeeper dự kiến từ chối; **System Settings → Privacy & Security → Open Anyway** là first-launch path an toàn cho build này. Homebrew không available. Product Hunt đã schedule, chưa launch tại observation `2026-08-26 02:07 JST`. Không claim beta cohort, performance comparison, defect count, unique user, download, vote, follower hay adoption result.

## 日本語

### Record boundary と outcome

この completed record は `6a177e2` から stable tag `v2.0.0` までに実装された design を記述します。Source/executable test が behavior を定義し、exact workflow/published artifact が release state を定義します。Stable evidence ledger は [docs/release-evidence/toolbox-2.0.0.md](../../release-evidence/toolbox-2.0.0.md) です。

Toolbox は Diskora/Changeora の別 binary を、developer/power user hygiene 用の native GUI-only macOS application 一つに置き換えました。Developer storage を説明して review 済み target だけを reclaim すること、installer 関連 change を記録して後の cleanup に evidence を使うことが二つの job です。Product promise は **See what changed. Reclaim space safely.** のままです。

### Goal、non-goal、target user

実装した goal は change observation から evidence-based cleanup までの一貫した workflow、6 destination、local processing、mutation 前 review、eligible な Trash-backed recovery、read-only observation、legacy data を変更しない opt-in copy-then-verify migration です。

Target user は developer tool を導入し、複数 package manager/runtime を使い、rebuildable cache/project artifact を蓄積する macOS developer/power user です。Terminal は不要です。Full Disk Access は optional で、拒否時は reduced coverage を明示します。

2.0 は CLI、privileged helper、Endpoint Security extension、automatic blocking、malware verdict、automatic uninstall/delete、default permanent deletion、restore overwrite、cloud account、file-content upload、in-app telemetry、広告、subscription、Windows/Linux、AI-model inventory、environment-drift inventory、reproducibility bundle を含みません。最後の三つは未確約 candidate です。

### As-built product と code structure

`Toolbox` は bundle identifier `com.thang.toolbox`、macOS 13+、version `2.0.0` です。一つの window に Home、Storage、Projects、Applications、Change Timeline、Recovery があります。Home は recoverable byte/important change を要約して Start Install Trace を提供し、Settings は language、scheduled scan、migration control、user-initiated update check を所有します。

`apps/toolbox/Package.swift` は `ToolboxCore`、`ToolboxStorage`、`ToolboxChanges`、`Toolbox` executable、non-shipping `SmokeCore` executable を定義します。Dependency は `ToolboxStorage -> ToolboxCore`、`ToolboxChanges -> ToolboxCore`、`Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges` です。Storage/Changes は相互 import せず、`ToolboxCoordinator` が cross-module routing を行います。Legacy package は parity check 後の `2c1eb1d` で source から削除しましたが、release history/user data は削除していません。

### Evidence と durable data

新しい shared data は `~/Library/Application Support/Toolbox` にあります。`ToolboxCore` は `evidence-v1.json`、`activity-v1.json`、deterministic ordering、normalized path、file ごとの atomic write、corrupt-file quarantine、明示的 unsupported-schema error を所有します。Atomic replacement は store 間 transaction ではありません。Storage history/checkpoint、Change Timeline session、active trace、trusted baseline は feature-owned format/fail-soft behavior のままで、Core quarantine guarantee はありません。

Evidence record は normalized path、kind、safety、observation time、reason を保持します。Activity entry は cleanup、approved command、restore、trace、migration、export の result を保持します。Change Timeline は review のため Storage に path を route できますが、select/mutate はしません。

### Reclaim Space as built

Scan は該当 GUI からのみ開始します。Project scan は user-selected root 内に限定し、Swift/SwiftPM、Node.js、Python、Rust、Gradle/Android、Flutter、CocoaPods の明示 rule を使います。Source、manifest、lockfile、`.git`、secret、virtual-machine disk、Docker volume、unknown directory、root、home root は safe cleanup candidate ではありません。

Review は path、byte、evidence、reason、action、recoverability を表示します。Mutation 直前に service が symlink を resolve し、approved root 内の exact existing target を validate します。Eligible item は `FileManager.trashItem` を通し、developer command は fixed path/列挙 argument を使い nonrecoverable と表示します。Ledger は actual result/Trash path を記録します。Scheduled work は scan-and-notify のみで mutate しません。

### Install Trace as built

Install Trace は `.dmg`、`.pkg`、`.app` のみ受け付けます。Metadata/before snapshot を保存し、bounded FSEvents observation を開始し、`NSWorkspace` で通常の macOS open flow に渡します。Toolbox 自身は mount、execute、install、authorize、Gatekeeper bypass を行いません。

Finish は after snapshot を取得し、snapshot/event evidence を merge し、coverage gap、session、shared evidence/activity を保存します。Interrupted trace は resume、明示的 reduced-coverage interval 付き finish、cancel が可能で、complete coverage と表示しません。Report は home prefix を `~` に置換し、file content と malware claim を含みません。

### Safety、privacy、error、recovery

Unknown/ambiguous target は `protected` または `review` として fail closed します。Mutation は foreground の explicit selection/confirmation を必要とします。Symlink escape、approved root 外、dangerous/evidence-only target は reject します。Restore は source/destination を再検証し overwrite しません。Partial Trash move は個別に記録し、nonrecoverable command を Trash-backed activity と分離します。

Scanner/permission error は exact root/category に付け、独立 scan は継続します。Cancel は incomplete read-only result を保持します。Core store corruption は quarantine し、unsupported Core schema は report のみです。Legacy feature store は unreadable data で empty/`nil` を返す場合があるため、より広い guarantee は claim しません。

Scan、snapshot、evidence、history、report は local です。App 内の唯一の network request は user-initiated Settings GET による public GitHub release metadata 取得で、scan path、evidence、result、device payload は送信しません。Account/telemetry はありません。

### Migration、localization、accessibility

Onboarding は Diskora、MacCleaner、Changeora record を検査します。Migration は全 present source を decode し、stable domain-scoped ID を生成し、missing record を merge し、destination を atomic-write/decode し、一件の migration activity 後に `migration-v1.json` を最後に書きます。Repeat は idempotent です。Legacy file は変更/削除せず、corrupt source/marker では false completion marker を書かず retryable にします。

Legacy Diskora scheduled LaunchAgent は explicit confirmation 後だけ変更します。Full Disk Access は Toolbox に再付与が必要で optional です。

Application resource は English/Vietnamese を ship し、Japanese は 2.0 documentation-only です。Primary action は keyboard access/label を持ち、status は color のみに依存せず、表示 path は select 可能です。

### Verification と release evidence

`2160541` から `2c1eb1d` は package、両 product port、shell、evidence store、Projects、Install Trace、migration、unified recovery/routing、legacy package retirement を実装しました。`2026-08-25` repository-local evidence は format、core、storage/recovery、changes、app/update、localization、universal bundle、ad-hoc DMG structural check の PASS を記録しています。Recovery は 5 件の byte-for-byte restore と 1 件の no-overwrite conflict を含みます。Exact release workflow `32847772209` と Pages workflow `32847688077` は tagged source commit で completed `success` でした。

Published artifact は `Toolbox-2.0.0.dmg`、`6055290` byte、SHA-256 `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` です。`arm64`/`x86_64` slice を含みますが physical Intel execution proof はありません。Ad-hoc signed で Apple-notarize/staple されていません。Gatekeeper rejection が expected で、この build の安全な first-launch path は **System Settings → Privacy & Security → Open Anyway** です。Homebrew は unavailable です。Product Hunt は `2026-08-26 02:07 JST` の観測時に scheduled で未 launch でした。Beta cohort、performance comparison、defect count、unique user、download、vote、follower、adoption result は claim しません。
