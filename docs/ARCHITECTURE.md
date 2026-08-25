# Toolbox Architecture

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Scope and dependency direction

Toolbox 2.0 is a SwiftPM package under `apps/toolbox`, targets macOS 13 or later, and ships one SwiftUI/AppKit GUI executable. `Package.swift` defines five products: three library modules, the Toolbox executable, and the non-shipping `SmokeCore` executable. The four application modules are:

- `ToolboxCore` owns shared safety types, evidence and activity models, versioned-store recovery, localization, scan coordination, application metadata, and legacy-data migration.
- `ToolboxStorage` owns storage analysis, duplicate and similar-photo detection, project and application discovery, reviewed cleanup, developer-tool actions, scheduled scans, cleanup history, and recovery.
- `ToolboxChanges` owns system snapshots, bounded FSEvents observation, diff and risk attribution, Install Trace, trusted baselines, session history, and redacted Change Timeline reports.
- `Toolbox` owns the application lifecycle, one-window shell, onboarding, Settings, update checks, summaries, and routing between the feature modules.

Dependency direction is `ToolboxStorage -> ToolboxCore`, `ToolboxChanges -> ToolboxCore`, and `Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges`. Storage and Changes do not import one another. This keeps shared evidence and safety contracts below both feature modules and leaves cross-module coordination in the executable.

See the [architecture and safety-boundary diagram](../docs/diagrams/toolbox-architecture.html) for the static component and trust-path view.

### Application coordination

The shell exposes Home, Storage, Projects, Applications, Change Timeline, and Recovery. `ToolboxCoordinator` persists the selected section and derives Home summaries from the Core ledgers. A Change Timeline action can route a standardized evidence path to Storage; the receiving view displays the path and opens Finder only on request. Routing does not select or mutate the item.

`ScanActivityRegistry` is the process-wide coordination boundary for scans and snapshots. Scanners increment the registry while work is active, and Settings refuses to start an update request during that interval. It is an in-memory counter, not a durable job queue or cross-process lock.

Install Trace accepts only `.dmg`, `.pkg`, and `.app` paths. It saves a before snapshot, starts FSEvents for the defined monitored roots, then hands the selected item to normal macOS opening through `NSWorkspace`. Toolbox does not mount, execute, install, or bypass Gatekeeper itself. Finishing captures the after snapshot, compares snapshot and FSEvents evidence, persists the session, and adds Core evidence/activity records. An interrupted trace may be resumed, but the UI marks the interval while Toolbox was not running as reduced coverage.

### Durable data

Active JSON data is stored under `~/Library/Application Support/Toolbox`:

| Owner | Files | Contract |
| --- | --- | --- |
| `ToolboxCore` | `evidence-v1.json`, `activity-v1.json` | Schema-versioned envelopes, normalized evidence paths, deterministic ordering, and atomic writes. A decode failure moves the corrupt file to a sibling `*.corrupt-<UTC timestamp>-<UUID>.json` file and reports the quarantine path. An unsupported schema is reported without quarantine. |
| `ToolboxStorage` | `history.json` | Normal cleanup-history writes retain the newest 500 entries, including Trash move manifests and restore state; migration merges existing and imported history without truncation, so a valid migrated store may contain more than 500. Writes are atomic. The current loader returns an empty history when the file is absent or undecodable, so this legacy-format store does not provide Core-style quarantine. |
| `ToolboxStorage` | `storage-checkpoints.json` | Up to 50 storage checkpoints used for local trend comparison; written atomically. Read/decode/write errors currently fail soft. |
| `ToolboxChanges` | `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, `trusted-baseline.json` | Sessions, interrupted-work state, installer metadata, and the user-created baseline; written atomically. Normal Change Timeline and Install Trace writes retain the newest 100 sessions, but migration merges existing and imported sessions without truncation, so a valid migrated store may contain more than 100. Loaders currently return empty or `nil` for unreadable legacy-format data rather than quarantining it. |
| `ToolboxCore` migration | `migration-v1.json` | Verified completion report written only after imported destinations and the migration activity entry are written. |

`UserDefaults` holds UI language, onboarding completion, selected section, scheduled-scan interval, and the last scheduled-scan time and byte estimate. These preferences are not evidence ledgers.

Atomic replacement protects each individual JSON write; it is not a transaction across multiple stores. The Core quarantine guarantee applies only to `evidence-v1.json` and `activity-v1.json`. Operators must preserve that distinction during recovery.

### macOS integrations and trust boundaries

- `FileManager.trashItem` provides recoverable mutation for eligible cleanup actions. Recovery moves an item from an allowed Trash root to an allowed destination only when the Trash source exists and the destination does not; it never overwrites.
- FSEvents is a bounded, in-process observation stream. A session starts at `kFSEventStreamEventIdSinceNow`, uses file-level events with a 0.25-second latency, and retains at most 20,000 events. Snapshots remain the before/after source of comparison; FSEvents does not provide a complete historical audit log.
- `NSWorkspace` opens Finder, installers, the Full Disk Access settings pane, and external links only after a user action. Full Disk Access is optional; unreadable Mail or Safari sentinel folders produce reduced coverage rather than a permission bypass.
- `launchctl` manages `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`; UserNotifications reports completed scan-only work. The scheduled process opens the packaged app with `--scheduled-scan`, scans safe targets, notifies, and exits without mutation.
- Developer cleanup uses fixed executable paths and exact argument allowlists. `sfltool dumpbtm` is a bounded read-only evidence query; login-item databases and package receipts are displayed as protected evidence and are not automatically removed.

All scans, snapshots, evidence, history, and reports are local. The only in-process application network request is the user-initiated Settings GET to `https://api.github.com/repos/thangldw/toolbox/releases/latest`. It sends `Accept: application/vnd.github+json` and `User-Agent: Toolbox/<version>` and no scan paths, evidence, results, or device payload. Links opened in the system browser are outside this request path.

### Mutation safety

Mutation remains separate from discovery and evidence. The GUI requires the user to choose reviewed items and uses confirmation UI for destructive cleanup flows. Mutation services resolve symlinks and validate the exact existing target against explicit roots immediately before acting. Root, the home root, paths outside an approved root, unknown project folders, protected project files, referenced runtimes, dangerous application leftovers, package receipts, login-item databases, Docker volumes, and other non-approved targets fail closed or remain evidence-only.

Eligible cleanup moves items to Trash and records the original and resulting Trash paths. Cleaning Trash itself and allowlisted developer commands are explicitly non-recoverable. Restore revalidates both paths and reports missing Trash items, destination conflicts, and filesystem failures instead of overwriting. Local evidence is advisory: a `safe`, `review`, or `protected` classification is not authorization to mutate without the corresponding feature's checks and user action.

### Legacy migration

Onboarding inspects legacy `Diskora/history.json`, `MacCleaner/history.json`, and Changeora `sessions.json`, `active-snapshot.json`, and `trusted-baseline.json`. Import is opt-in. The service decodes every present source before destination writes, derives domain-scoped stable IDs, merges only missing records, and copies active snapshots or baselines only when the Toolbox destination does not exist.

Each written destination is decoded and verified, then one migration activity entry is recorded and `migration-v1.json` is written and verified last. Existing Toolbox records are retained, repeat import is idempotent, and original legacy files are never modified or deleted. A corrupt source or completion marker is reported; a failed import does not write a completion marker. Migration of the legacy scheduled LaunchAgent is a separate, explicit Settings operation described in `docs/OPERATIONS.md`.

## Tiếng Việt

### Phạm vi và hướng dependency

Toolbox 2.0 là SwiftPM package trong `apps/toolbox`, target macOS 13 trở lên và ship một GUI executable SwiftUI/AppKit. `Package.swift` định nghĩa năm product: ba library module, executable Toolbox và executable `SmokeCore` không ship. Bốn application module là:

- `ToolboxCore` sở hữu shared safety type, evidence/activity model, phục hồi versioned store, localization, điều phối scan, application metadata và migration dữ liệu legacy.
- `ToolboxStorage` sở hữu phân tích storage, phát hiện duplicate/similar photo, khám phá project/application, cleanup có review, developer-tool action, scheduled scan, cleanup history và recovery.
- `ToolboxChanges` sở hữu system snapshot, quan sát FSEvents có giới hạn, diff/risk attribution, Install Trace, trusted baseline, session history và báo cáo Change Timeline đã redact.
- `Toolbox` sở hữu application lifecycle, one-window shell, onboarding, Settings, update check, summary và routing giữa các feature module.

Hướng dependency là `ToolboxStorage -> ToolboxCore`, `ToolboxChanges -> ToolboxCore` và `Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges`. Storage và Changes không import nhau. Cấu trúc này đặt shared evidence/safety contract bên dưới cả hai feature module và giữ điều phối cross-module trong executable.

Xem [sơ đồ architecture và safety boundary](../docs/diagrams/toolbox-architecture.html) để có component/trust-path view dạng static.

### Điều phối ứng dụng

Shell cung cấp Home, Storage, Projects, Applications, Change Timeline và Recovery. `ToolboxCoordinator` lưu section đang chọn và tạo summary ở Home từ các Core ledger. Một action trong Change Timeline có thể route standardized evidence path sang Storage; view nhận chỉ hiển thị path và mở Finder khi người dùng yêu cầu. Routing không chọn hoặc mutate item.

`ScanActivityRegistry` là ranh giới điều phối toàn process cho scan và snapshot. Scanner tăng counter khi công việc đang chạy, và Settings từ chối bắt đầu update request trong khoảng đó. Đây là counter trong memory, không phải durable job queue hay cross-process lock.

Install Trace chỉ nhận path `.dmg`, `.pkg` và `.app`. Nó lưu before snapshot, bắt đầu FSEvents cho các monitored root đã định nghĩa, rồi giao item đã chọn cho luồng mở bình thường của macOS qua `NSWorkspace`. Toolbox không tự mount, execute, install hoặc bypass Gatekeeper. Khi hoàn tất, hệ thống chụp after snapshot, so sánh evidence từ snapshot và FSEvents, lưu session, rồi thêm Core evidence/activity record. Có thể resume trace bị gián đoạn, nhưng UI đánh dấu thời gian Toolbox không chạy là reduced coverage.

### Dữ liệu bền vững

Dữ liệu JSON active được lưu dưới `~/Library/Application Support/Toolbox`:

| Owner | File | Contract |
| --- | --- | --- |
| `ToolboxCore` | `evidence-v1.json`, `activity-v1.json` | Envelope có schema version, evidence path được normalize, ordering deterministic và ghi atomic. Decode failure chuyển file lỗi thành file sibling `*.corrupt-<UTC timestamp>-<UUID>.json` rồi báo quarantine path. Schema không được support được báo lỗi nhưng không quarantine. |
| `ToolboxStorage` | `history.json` | Lần ghi cleanup history bình thường giữ 500 entry mới nhất, gồm Trash move manifest và restore state; migration merge history hiện có với history import mà không truncate, nên migrated store hợp lệ có thể có hơn 500 entry. Việc ghi là atomic. Loader hiện tại trả history rỗng nếu file không tồn tại hoặc không decode được, nên legacy-format store này không có quarantine như Core. |
| `ToolboxStorage` | `storage-checkpoints.json` | Tối đa 50 storage checkpoint dùng cho so sánh trend local; được ghi atomic. Lỗi read/decode/write hiện fail soft. |
| `ToolboxChanges` | `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, `trusted-baseline.json` | Session, interrupted-work state, installer metadata và baseline do người dùng tạo; được ghi atomic. Lần ghi bình thường của Change Timeline và Install Trace giữ 100 session mới nhất, nhưng migration merge session hiện có với session import mà không truncate, nên migrated store hợp lệ có thể có hơn 100. Loader hiện trả rỗng hoặc `nil` cho legacy-format data không đọc được thay vì quarantine. |
| Migration của `ToolboxCore` | `migration-v1.json` | Báo cáo hoàn tất đã verify, chỉ được ghi sau khi destination import và migration activity entry đã được ghi. |

`UserDefaults` giữ UI language, trạng thái hoàn tất onboarding, section đang chọn, scheduled-scan interval, thời gian và byte estimate của scheduled scan gần nhất. Các preference này không phải evidence ledger.

Atomic replacement bảo vệ từng lần ghi JSON riêng lẻ; nó không phải transaction qua nhiều store. Quarantine guarantee của Core chỉ áp dụng cho `evidence-v1.json` và `activity-v1.json`. Operator phải giữ đúng khác biệt này khi recovery.

### Tích hợp macOS và trust boundary

- `FileManager.trashItem` cung cấp mutation có thể recovery cho cleanup action đủ điều kiện. Recovery chỉ chuyển item từ Trash root được phép đến destination được phép khi source trong Trash còn tồn tại và destination chưa có; không bao giờ overwrite.
- FSEvents là observation stream có giới hạn, chạy trong process. Session bắt đầu tại `kFSEventStreamEventIdSinceNow`, dùng file-level event với latency 0,25 giây và giữ tối đa 20.000 event. Snapshot vẫn là nguồn before/after để so sánh; FSEvents không cung cấp historical audit log hoàn chỉnh.
- `NSWorkspace` chỉ mở Finder, installer, pane Full Disk Access và external link sau user action. Full Disk Access là tùy chọn; sentinel folder Mail hoặc Safari không đọc được sẽ tạo reduced coverage, không dẫn đến bypass permission.
- `launchctl` quản lý `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`; UserNotifications báo công việc scan-only đã hoàn tất. Scheduled process mở packaged app với `--scheduled-scan`, scan safe target, gửi notification rồi thoát mà không mutation.
- Developer cleanup dùng executable path cố định và allowlist argument chính xác. `sfltool dumpbtm` là read-only evidence query có giới hạn; login-item database và package receipt được hiển thị như protected evidence và không bị tự động xóa.

Mọi scan, snapshot, evidence, history và report đều local. Network request duy nhất trong process của ứng dụng là GET do người dùng khởi tạo trong Settings đến `https://api.github.com/repos/thangldw/toolbox/releases/latest`. Request gửi `Accept: application/vnd.github+json` và `User-Agent: Toolbox/<version>`, không gửi scan path, evidence, result hoặc device payload. Link mở trong system browser nằm ngoài request path này.

### An toàn mutation

Mutation được tách khỏi discovery và evidence. GUI yêu cầu người dùng chọn item đã review và dùng confirmation UI cho destructive cleanup flow. Mutation service resolve symlink và validate exact existing target với root rõ ràng ngay trước khi hành động. Root, home root, path ngoài approved root, project folder không biết, protected project file, runtime đang được tham chiếu, dangerous application leftover, package receipt, login-item database, Docker volume và target không được phê duyệt khác sẽ fail closed hoặc chỉ còn evidence.

Cleanup đủ điều kiện chuyển item vào Trash và ghi original path cùng Trash path kết quả. Dọn chính Trash và allowlisted developer command là thao tác non-recoverable được ghi rõ. Restore revalidate cả hai path và báo item trong Trash bị thiếu, destination conflict hoặc filesystem failure thay vì overwrite. Local evidence chỉ mang tính advisory: classification `safe`, `review` hoặc `protected` không phải authorization để mutation khi chưa qua check của feature tương ứng và user action.

### Migration legacy

Onboarding kiểm tra legacy `Diskora/history.json`, `MacCleaner/history.json`, cùng Changeora `sessions.json`, `active-snapshot.json` và `trusted-baseline.json`. Import là opt-in. Service decode mọi source hiện có trước khi ghi destination, tạo stable ID theo domain, chỉ merge record còn thiếu và chỉ copy active snapshot hoặc baseline khi destination của Toolbox chưa tồn tại.

Mỗi destination đã ghi được decode và verify; sau đó một migration activity entry được ghi, còn `migration-v1.json` được ghi và verify cuối cùng. Record Toolbox hiện có được giữ lại, import lặp lại có tính idempotent, và file legacy gốc không bao giờ bị sửa hoặc xóa. Source hoặc completion marker lỗi được báo; import thất bại không ghi completion marker. Migration legacy scheduled LaunchAgent là operation rõ ràng, riêng biệt trong Settings, được mô tả tại `docs/OPERATIONS.md`.

## 日本語

### Scope と dependency direction

Toolbox 2.0 は `apps/toolbox` の SwiftPM package で、macOS 13 以降を target とし、一つの SwiftUI/AppKit GUI executable を出荷します。`Package.swift` は五つの product、すなわち三 library module、Toolbox executable、出荷しない `SmokeCore` executable を定義します。四つの application module は次のとおりです。

- `ToolboxCore` は shared safety type、evidence/activity model、versioned-store recovery、localization、scan coordination、application metadata、legacy-data migration を所有します。
- `ToolboxStorage` は storage analysis、duplicate/similar-photo detection、project/application discovery、review 済み cleanup、developer-tool action、scheduled scan、cleanup history、recovery を所有します。
- `ToolboxChanges` は system snapshot、bounded FSEvents observation、diff/risk attribution、Install Trace、trusted baseline、session history、redacted Change Timeline report を所有します。
- `Toolbox` は application lifecycle、one-window shell、onboarding、Settings、update check、summary、feature module 間 routing を所有します。

Dependency direction は `ToolboxStorage -> ToolboxCore`、`ToolboxChanges -> ToolboxCore`、`Toolbox -> ToolboxCore + ToolboxStorage + ToolboxChanges` です。Storage と Changes は相互に import しません。Shared evidence/safety contract を両 feature module の下に置き、cross-module coordination を executable に保持します。

Static な component/trust-path view は [architecture と safety-boundary diagram](../docs/diagrams/toolbox-architecture.html) を参照してください。

### Application coordination

Shell は Home、Storage、Projects、Applications、Change Timeline、Recovery を提供します。`ToolboxCoordinator` は選択 section を保存し、Core ledger から Home summary を計算します。Change Timeline action は standardized evidence path を Storage へ route できますが、受信 view は path を表示し、要求時だけ Finder を開きます。Routing は item を選択せず mutation もしません。

`ScanActivityRegistry` は scan と snapshot の process-wide coordination boundary です。Scanner は実行中に counter を増やし、その間 Settings は update request の開始を拒否します。これは in-memory counter であり、durable job queue や cross-process lock ではありません。

Install Trace は `.dmg`、`.pkg`、`.app` path だけを受け入れます。Before snapshot を保存し、定義済み monitored root で FSEvents を開始した後、選択 item を `NSWorkspace` による通常の macOS open flow へ渡します。Toolbox 自体は mount、execute、install、Gatekeeper bypass を行いません。完了時に after snapshot を取得し、snapshot/FSEvents evidence を比較し、session を保存して Core evidence/activity record を追加します。中断 trace は resume できますが、Toolbox が停止していた区間は UI で reduced coverage と表示されます。

### Durable data

Active JSON data は `~/Library/Application Support/Toolbox` に保存されます。

| Owner | File | Contract |
| --- | --- | --- |
| `ToolboxCore` | `evidence-v1.json`, `activity-v1.json` | Schema-versioned envelope、normalized evidence path、deterministic ordering、atomic write。Decode failure は破損 file を sibling の `*.corrupt-<UTC timestamp>-<UUID>.json` へ移し、quarantine path を報告します。Unsupported schema は quarantine せず報告します。 |
| `ToolboxStorage` | `history.json` | 通常の cleanup-history write は Trash move manifest と restore state を含む最新 500 entry を保持します。Migration は既存/import history を truncate せず merge するため、有効な migrated store が 500 entry を超える場合があります。Write は atomic です。現在の loader は file 不在または decode 不可で空 history を返すため、この legacy-format store には Core と同じ quarantine はありません。 |
| `ToolboxStorage` | `storage-checkpoints.json` | Local trend 比較用の最大 50 storage checkpoint。Atomic write です。Read/decode/write error は現在 fail soft です。 |
| `ToolboxChanges` | `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, `trusted-baseline.json` | Session、interrupted-work state、installer metadata、user-created baseline。Atomic write です。通常の Change Timeline/Install Trace write は最新 100 session を保持しますが、migration は既存/import session を truncate せず merge するため、有効な migrated store が 100 session を超える場合があります。Loader は unreadable な legacy-format data を quarantine せず、空または `nil` を返します。 |
| `ToolboxCore` migration | `migration-v1.json` | Imported destination と migration activity entry の書き込み後だけ保存される、verified completion report。 |

`UserDefaults` は UI language、onboarding completion、selected section、scheduled-scan interval、最後の scheduled-scan time と byte estimate を保持します。これらの preference は evidence ledger ではありません。

Atomic replacement は個別 JSON write を保護しますが、複数 store にまたがる transaction ではありません。Core の quarantine guarantee は `evidence-v1.json` と `activity-v1.json` だけに適用されます。Recovery 時にはこの差を維持する必要があります。

### macOS integration と trust boundary

- `FileManager.trashItem` は対象 cleanup action に recoverable mutation を提供します。Recovery は Trash source が存在し destination が存在しない場合だけ、allowed Trash root から allowed destination へ item を移し、overwrite しません。
- FSEvents は bounded in-process observation stream です。Session は `kFSEventStreamEventIdSinceNow` から開始し、0.25 秒 latency の file-level event を使い、最大 20,000 event を保持します。Snapshot が before/after 比較元であり、FSEvents は完全な historical audit log ではありません。
- `NSWorkspace` は user action 後だけ Finder、installer、Full Disk Access settings pane、external link を開きます。Full Disk Access は optional です。Mail/Safari sentinel folder を読めない場合は reduced coverage となり、permission を bypass しません。
- `launchctl` は `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist` を管理し、UserNotifications は完了した scan-only work を通知します。Scheduled process は packaged app を `--scheduled-scan` で開き、safe target を scan し、通知して mutation せず終了します。
- Developer cleanup は固定 executable path と exact argument allowlist を使います。`sfltool dumpbtm` は bounded read-only evidence query です。Login-item database と package receipt は protected evidence として表示され、自動削除されません。

Scan、snapshot、evidence、history、report はすべて local です。Application process 内の唯一の network request は、Settings で user が開始する `https://api.github.com/repos/thangldw/toolbox/releases/latest` への GET です。`Accept: application/vnd.github+json` と `User-Agent: Toolbox/<version>` を送りますが、scan path、evidence、result、device payload は送りません。System browser で開く link はこの request path の外部です。

### Mutation safety

Mutation は discovery/evidence から分離されます。GUI は review 済み item の user selection を要求し、destructive cleanup flow に confirmation UI を使います。Mutation service は action 直前に symlink を解決し、exact existing target を明示的 root に対して検証します。Root、home root、approved root 外、未知の project folder、protected project file、参照中 runtime、dangerous application leftover、package receipt、login-item database、Docker volume、その他未承認 target は fail closed または evidence-only です。

対象 cleanup は item を Trash へ移し、original path と結果の Trash path を記録します。Trash 自体の cleanup と allowlisted developer command は明示的に non-recoverable です。Restore は両 path を再検証し、missing Trash item、destination conflict、filesystem failure を報告して overwrite しません。Local evidence は advisory です。`safe`、`review`、`protected` classification は、対応 feature check と user action なしの mutation authorization ではありません。

### Legacy migration

Onboarding は legacy `Diskora/history.json`、`MacCleaner/history.json`、Changeora の `sessions.json`、`active-snapshot.json`、`trusted-baseline.json` を検査します。Import は opt-in です。Service は destination write 前に存在する全 source を decode し、domain-scoped stable ID を生成し、missing record だけを merge します。Active snapshot/baseline は Toolbox destination が存在しない場合だけ copy します。

書き込んだ各 destination を decode/verify し、その後一つの migration activity entry を記録し、最後に `migration-v1.json` を書いて verify します。既存 Toolbox record は保持され、repeat import は idempotent で、元の legacy file は変更・削除されません。破損 source または completion marker は報告され、failed import は completion marker を書きません。Legacy scheduled LaunchAgent の migration は別の明示的 Settings operation で、`docs/OPERATIONS.md` に記載します。
