# Toolbox Architecture

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

Toolbox 2.0 ships one macOS GUI from `apps/toolbox`:

```text
Toolbox executable
├── ToolboxStorage ──┐
├── ToolboxChanges ──┼──> ToolboxCore
└── shell/settings ──┘
```

- `ToolboxCore` owns safety policy, evidence/activity stores, localization, scan state, migration, and shared metadata.
- `ToolboxStorage` owns storage/project/application scanning, reviewed mutations, scheduled scan-only work, and conflict-safe Recovery.
- `ToolboxChanges` owns snapshots, bounded FSEvents, diff/risk attribution, Install Trace, baselines, and redacted exports.
- `Toolbox` owns the six-destination shell, onboarding, settings, update checks, summaries, and cross-module routing.

Dependencies flow only toward `ToolboxCore`; Storage and Changes do not import one another. `Review in Storage` passes only a canonical path to the app coordinator. Routing never selects or mutates the target.

### Durable data

All active data lives under `~/Library/Application Support/Toolbox` and uses atomic writes:

- `evidence-v1.json`: path, producer kind, safety level, reasons, observation time
- `activity-v1.json`: cleanup, command, restore, trace, migration, and export outcomes
- `history.json`: Trash move manifests and restore state
- `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, `trusted-baseline.json`
- `migration-v1.json`: verified completion marker

Corrupt versioned stores are quarantined instead of overwritten. Migration decodes all legacy sources before writing, derives stable domain-scoped IDs, verifies destination records, writes the marker last, and never changes the original Diskora/Changeora directories.

### Safety invariants

- Every mutation re-resolves symlinks and validates the exact target immediately before action.
- Root, home root, paths outside approved roots, unknown project folders, source, manifests, lockfiles, secrets, VM disks, and Docker volumes fail closed.
- Recoverable operations use `FileManager.trashItem`; restore validates Trash/destination roots and never overwrites.
- Developer commands require exact executable paths and enumerated arguments.
- Scheduled work scans and notifies only. The legacy agent is removed only after the Toolbox agent bootstraps successfully and the user confirms replacement.
- The update checker is user-initiated, calls one public GitHub endpoint, sends no scan/device fields, and is blocked while a scanner is active.

The stable destinations are Home, Storage, Projects, Applications, Change Timeline, and Recovery. English is the default; Vietnamese is first-class. Historical standalone code is available through tags up to `v1.4.0`, not in the 2.0 source tree.

## Tiếng Việt

Toolbox 2.0 chỉ ship một GUI từ `apps/toolbox`. `ToolboxCore` giữ contract, safety, persistence, migration và trạng thái scan; `ToolboxStorage` giữ scan/mutation/Recovery; `ToolboxChanges` giữ snapshot, FSEvents, diff và Install Trace; target `Toolbox` giữ shell, onboarding, Settings và routing.

Dependency chỉ đi về `ToolboxCore`; Storage và Changes không import nhau. Route `Review in Storage` chỉ truyền canonical path, không tự chọn hoặc dọn mục.

Dữ liệu active nằm trong `~/Library/Application Support/Toolbox` và được ghi atomic. Store lỗi bị quarantine. Migration decode nguồn trước, tạo ID ổn định theo domain, verify file đích, ghi marker cuối và không sửa thư mục Diskora/Changeora.

Mọi mutation resolve symlink và revalidate target ngay trước hành động. Path rộng/ngoài root, artifact không biết, source/manifest/lockfile/secret/VM disk/Docker volume bị chặn. Restore không ghi đè. Developer command chỉ nhận executable path và arguments cố định. Scheduled scan không xóa; update check chỉ chạy theo nút và bị khóa khi scanner đang hoạt động.

Sáu destination ổn định là Home, Storage, Projects, Applications, Change Timeline và Recovery. Source standalone lịch sử nằm trong tag đến `v1.4.0`, không nằm trong cây source 2.0.

## 日本語

Toolbox 2.0 は `apps/toolbox` から一つの GUI のみを出荷します。`ToolboxCore` は contract、安全性、永続化、migration、scan state、`ToolboxStorage` は storage/project/application と mutation/Recovery、`ToolboxChanges` は snapshot、FSEvents、diff、Install Trace、`Toolbox` target は shell、onboarding、Settings、routing を担当します。

依存方向は `ToolboxCore` のみです。`Review in Storage` は canonical path だけを渡し、自動選択・mutation を行いません。Active data は `~/Library/Application Support/Toolbox` に atomic write され、破損 store は quarantine されます。Migration は source を先に decode し、stable ID と destination を検証し、marker を最後に書き、旧 directory を変更しません。

Mutation 前には symlink を解決して exact target を再検証します。Restore は上書きせず、developer command は固定 path/argument のみ、scheduled task は scan/notification のみです。Update check は user 操作時だけ一つの public GitHub endpoint を使用し、scan 中は実行されません。

Standalone source は `v1.4.0` までの tag に保存されています。
