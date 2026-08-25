# Toolbox Operations

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Workstation and toolchain

Toolbox is a dependency-free SwiftPM package with `swift-tools-version: 6.0` and a macOS 13 deployment target. Development, application bundling, FSEvents, LaunchAgent, signing, DMG, and Gatekeeper checks require macOS. GitHub CI uses `macos-15` and prints the selected Swift version; the repository does not promise a specific local Xcode build beyond what the manifest and tests prove.

Start from the repository root and inspect the active developer directory before validation:

```bash
xcode-select -p
cd apps/toolbox
swift --version
```

Use a full Xcode developer directory when running XCTest. Do not change application source, release scripts, or workflow policy merely to accommodate a Command Line Tools-only host.

### Development validation

Run the source and bundle gates from `apps/toolbox`:

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
test -x dist/Toolbox.app/Contents/MacOS/Toolbox
test -f dist/Toolbox.app/Contents/Resources/en.lproj/Localizable.strings
test -f dist/Toolbox.app/Contents/Resources/vi.lproj/Localizable.strings
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
```

`build_app.sh` assembles a local single-architecture app and applies an ad-hoc signature. A successful build and `codesign --verify` prove bundle structure and signature consistency only; they do not prove a universal binary, Developer ID identity, notarization, stapling, Gatekeeper acceptance, or launch on physical Intel hardware.

Run documentation and workflow checks from the repository root when those contracts change:

```bash
python3 tests/check_docs.py docs/ARCHITECTURE.md docs/OPERATIONS.md docs/OPERATIONS-RELEASE.md
bash tests/unsigned_stable_release_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
```

The explicit exception for `v2.0.0` is historical. Its reproducible structural checks, immutable evidence, and the notarized default for later releases are defined in [Release operations](OPERATIONS-RELEASE.md).

### XCTest boundary

If `xcode-select -p` points to Command Line Tools and `swift test` fails with `no such module 'XCTest'`, report XCTest as blocked on that host. The four smoke scripts remain useful executable evidence for Core, selected Storage and Changes paths, and the update checker, but they compile curated source lists and do not replace the SwiftPM XCTest targets.

A merge or release claim requires `swift test` under full Xcode or the exact-commit GitHub Actions XCTest job to succeed. Do not convert smoke success into an XCTest, signing, notarization, launch, or production claim.

### Scheduled-scan lifecycle

The user enables a schedule from the packaged Toolbox GUI and must grant Notification permission. The interval must be 1 through 168 hours. Toolbox atomically writes `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`, asks `launchctl` to boot out any currently loaded Toolbox label on a best-effort basis, then bootstraps the new plist. If bootstrap fails, Toolbox removes the new plist, does not store the interval, and surfaces the exact `launchctl` error.

The LaunchAgent runs `/usr/bin/open -gj <Toolbox.app> --args --scheduled-scan`. The app switches to accessory mode, scans only default targets classified `safe`, posts a local summary notification, stores last-run metadata in `UserDefaults`, and exits. It never selects, trashes, or deletes scan results.

Settings detects `~/Library/LaunchAgents/com.thang.diskora.scheduled-scan.plist` and requires confirmation before replacement. Replacement order is: install and successfully bootstrap the Toolbox job, best-effort boot out `com.thang.diskora.scheduled-scan`, then remove the legacy plist. A Toolbox bootstrap failure removes the Toolbox plist and preserves the legacy plist. The current implementation does not fail replacement when booting out the already-loaded legacy label fails; removing its plist prevents the legacy job from loading at a later login, but an operator should inspect the current `launchctl` session if both jobs appear active.

Disable removes the Toolbox plist and schedule metadata after a best-effort bootout. If a job still runs after disable, inspect `launchctl print gui/$(id -u)/com.thang.toolbox.scheduled-scan`; do not delete unrelated LaunchAgents.

### Update checks

Toolbox performs no automatic update polling. Clicking **Check for Updates** is the only in-process trigger and is rejected while `ScanActivityRegistry` reports an active scan or snapshot. The request is:

```text
GET https://api.github.com/repos/thangldw/toolbox/releases/latest
Accept: application/vnd.github+json
User-Agent: Toolbox/<version>
```

There is no request body and no scan path, evidence, result, or device payload. A non-2xx response is shown as an error. The returned tag is parsed as semantic `major.minor.patch`, ignoring a leading `v` and prerelease suffix for comparison; malformed tags yield no parsed latest version. Toolbox reports availability but does not download or install an update.

### Local data, backup, and recovery

Before manual data maintenance, quit Toolbox and copy `~/Library/Application Support/Toolbox` to protected local storage. If a schedule is installed, also preserve `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`. These files may contain user paths, timestamps, application attribution, cleanup history, and Trash locations; treat the backup as private.

For `evidence-v1.json` or `activity-v1.json`, a decode failure automatically moves the file to a sibling `*.corrupt-<UTC timestamp>-<UUID>.json` path and reports an error. Preserve the quarantined file for diagnosis. An unsupported schema is not quarantined. `history.json`, `storage-checkpoints.json`, `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, and `trusted-baseline.json` use older fail-soft loaders: corrupt or unreadable content may appear as empty or missing state. Do not infer that the underlying data never existed; restore a known-good local backup or move the affected file aside while Toolbox is closed before recreating state.

Use Recovery only for cleanup history entries that retain Trash move manifests. Restore requires the recorded Trash source to exist, the original destination to be absent, and both paths to pass the allowlisted-root checks. It creates only the destination parent and never overwrites a conflict. Cleaning Trash, developer-tool commands, entries without a Trash manifest, and already-restored items are not recoverable through Toolbox. Preserve partial-failure details and resolve each conflict instead of repeating the whole mutation blindly.

Full Disk Access is optional. Toolbox probes `~/Library/Mail` and `~/Library/Safari`: if neither sentinel exists, it reports both paths as reduced coverage; otherwise only an unreadable existing sentinel reduces coverage. Grant Full Disk Access only when the desired scan requires it, then use Settings **Check again**. Reduced coverage is an evidence limitation, not permission to bypass macOS protections.

### Redacted export

Change Timeline can save one selected session as Markdown or JSON through `NSSavePanel`. Export is local and atomic. The redaction is deliberately narrow: the exact home-directory prefix becomes `~`. Filenames, remaining path components, timestamps, change/risk/category fields, attribution, reasons, and event counts can remain in the report, and paths outside the home directory are not redacted.

Review the generated file before sharing it. Move it only through a user-chosen channel; Toolbox does not upload exports. If stronger anonymization is required, remove names, non-home paths, project identifiers, timestamps, and attribution outside Toolbox before transmission.

### Failure and escalation

- For a scan or mutation error, preserve the displayed per-path errors and local ledgers, stop retrying destructive work, and verify the target and Trash state in Finder.
- For migration failure, preserve the original Diskora, MacCleaner, and Changeora files. Fix the unreadable source or completion marker before retrying; absence of `migration-v1.json` means completion was not recorded.
- For schedule failure, preserve both plist files and the exact `launchctl` stderr, then inspect only the two Toolbox/Diskora labels described above.
- For evidence-store quarantine or unexpected empty legacy-format state, preserve the affected and quarantined files before recovery. Do not hand-edit live JSON while Toolbox is running.
- For a suspected vulnerability or unsafe path acceptance, stop the affected workflow and follow `SECURITY.md`. For artifact, signing, notarization, checksum, or published-release issues, follow `docs/OPERATIONS-RELEASE.md`.

## Tiếng Việt

### Workstation và toolchain

Toolbox là SwiftPM package không có dependency ngoài, dùng `swift-tools-version: 6.0` và deployment target macOS 13. Development, application bundling, FSEvents, LaunchAgent, signing, DMG và Gatekeeper check cần macOS. GitHub CI dùng `macos-15` và in Swift version đã chọn; repository không hứa một local Xcode build cụ thể ngoài những gì manifest và test chứng minh.

Bắt đầu từ repository root và kiểm tra active developer directory trước khi validation:

```bash
xcode-select -p
cd apps/toolbox
swift --version
```

Dùng full Xcode developer directory khi chạy XCTest. Không thay application source, release script hoặc workflow policy chỉ để phù hợp host chỉ có Command Line Tools.

### Validation khi development

Chạy source và bundle gate từ `apps/toolbox`:

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
test -x dist/Toolbox.app/Contents/MacOS/Toolbox
test -f dist/Toolbox.app/Contents/Resources/en.lproj/Localizable.strings
test -f dist/Toolbox.app/Contents/Resources/vi.lproj/Localizable.strings
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
```

`build_app.sh` assemble app single-architecture local và áp dụng ad-hoc signature. Build thành công cùng `codesign --verify` chỉ chứng minh bundle structure và signature consistency; chúng không chứng minh universal binary, Developer ID identity, notarization, stapling, Gatekeeper acceptance hoặc launch trên physical Intel hardware.

Chạy documentation và workflow check từ repository root khi các contract đó thay đổi:

```bash
python3 tests/check_docs.py docs/ARCHITECTURE.md docs/OPERATIONS.md docs/OPERATIONS-RELEASE.md
bash tests/unsigned_stable_release_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
```

Exception explicit cho `v2.0.0` là historical. Structural check có thể reproduce, immutable evidence và default notarized cho release sau được định nghĩa trong [Release operations](OPERATIONS-RELEASE.md).

### Ranh giới XCTest

Nếu `xcode-select -p` trỏ đến Command Line Tools và `swift test` fail với `no such module 'XCTest'`, báo XCTest bị block trên host đó. Bốn smoke script vẫn là executable evidence hữu ích cho Core, các path Storage/Changes được chọn và update checker, nhưng chúng compile curated source list và không thay thế SwiftPM XCTest target.

Claim merge hoặc release cần `swift test` dưới full Xcode hoặc job XCTest của GitHub Actions trên exact commit thành công. Không nâng smoke success thành claim về XCTest, signing, notarization, launch hoặc production.

### Vòng đời scheduled scan

Người dùng bật schedule từ packaged Toolbox GUI và phải cấp Notification permission. Interval phải từ 1 đến 168 giờ. Toolbox ghi atomic `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`, yêu cầu `launchctl` boot out Toolbox label đang load theo best effort, rồi bootstrap plist mới. Nếu bootstrap fail, Toolbox xóa plist mới, không lưu interval và hiển thị exact `launchctl` error.

LaunchAgent chạy `/usr/bin/open -gj <Toolbox.app> --args --scheduled-scan`. App chuyển sang accessory mode, chỉ scan default target được phân loại `safe`, gửi local summary notification, lưu last-run metadata trong `UserDefaults` rồi thoát. Nó không bao giờ chọn, chuyển Trash hoặc xóa scan result.

Settings phát hiện `~/Library/LaunchAgents/com.thang.diskora.scheduled-scan.plist` và yêu cầu confirmation trước khi replace. Thứ tự replacement là: install và bootstrap thành công job Toolbox, best-effort boot out `com.thang.diskora.scheduled-scan`, rồi xóa legacy plist. Nếu bootstrap Toolbox fail, Toolbox plist bị xóa và legacy plist được giữ. Implementation hiện tại không làm replacement fail khi bootout legacy label đang load thất bại; xóa plist sẽ ngăn legacy job load ở lần login sau, nhưng operator nên kiểm tra session `launchctl` hiện tại nếu cả hai job có vẻ active.

Disable xóa Toolbox plist và schedule metadata sau best-effort bootout. Nếu job vẫn chạy sau disable, kiểm tra `launchctl print gui/$(id -u)/com.thang.toolbox.scheduled-scan`; không xóa LaunchAgent không liên quan.

### Update check

Toolbox không tự động poll update. Click **Check for Updates** là trigger duy nhất trong process và bị từ chối khi `ScanActivityRegistry` báo scan hoặc snapshot active. Request là:

```text
GET https://api.github.com/repos/thangldw/toolbox/releases/latest
Accept: application/vnd.github+json
User-Agent: Toolbox/<version>
```

Không có request body và không có scan path, evidence, result hoặc device payload. Response không phải 2xx được hiển thị như error. Tag trả về được parse thành semantic `major.minor.patch`, bỏ leading `v` và prerelease suffix khi so sánh; tag sai format không tạo latest version đã parse. Toolbox chỉ báo availability, không download hoặc install update.

### Local data, backup và recovery

Trước khi bảo trì data thủ công, quit Toolbox và copy `~/Library/Application Support/Toolbox` vào local storage được bảo vệ. Nếu schedule đã install, cũng giữ `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`. Các file này có thể chứa user path, timestamp, application attribution, cleanup history và Trash location; coi backup là private.

Với `evidence-v1.json` hoặc `activity-v1.json`, decode failure tự động chuyển file thành sibling path `*.corrupt-<UTC timestamp>-<UUID>.json` và báo error. Giữ quarantined file để diagnose. Unsupported schema không bị quarantine. `history.json`, `storage-checkpoints.json`, `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json` và `trusted-baseline.json` dùng loader fail-soft cũ: nội dung corrupt hoặc unreadable có thể xuất hiện như state rỗng hoặc missing. Không suy luận rằng data gốc chưa từng tồn tại; restore local backup đã biết tốt hoặc move affected file sang chỗ khác khi Toolbox đã đóng trước khi tạo lại state.

Chỉ dùng Recovery cho cleanup history entry còn Trash move manifest. Restore yêu cầu source đã ghi trong Trash còn tồn tại, original destination chưa tồn tại và cả hai path qua allowlisted-root check. Nó chỉ tạo destination parent và không bao giờ overwrite conflict. Dọn Trash, developer-tool command, entry không có Trash manifest và item đã restore không thể recovery qua Toolbox. Giữ chi tiết partial failure và xử lý từng conflict thay vì lặp lại toàn bộ mutation một cách mù quáng.

Full Disk Access là tùy chọn. Toolbox probe `~/Library/Mail` và `~/Library/Safari`: nếu cả hai sentinel đều không tồn tại, app báo reduced coverage cho cả hai path; nếu có sentinel tồn tại, chỉ sentinel đó không đọc được mới giảm coverage. Chỉ cấp Full Disk Access khi scan mong muốn cần nó, rồi dùng **Check again** trong Settings. Reduced coverage là giới hạn evidence, không phải quyền bypass bảo vệ macOS.

### Export đã redact

Change Timeline có thể lưu một session đã chọn dưới dạng Markdown hoặc JSON qua `NSSavePanel`. Export là local và atomic. Redaction cố ý hẹp: exact home-directory prefix được thay bằng `~`. Filename, path component còn lại, timestamp, change/risk/category field, attribution, reason và event count có thể vẫn nằm trong report; path ngoài home directory không được redact.

Review file đã tạo trước khi share. Chỉ move file qua channel do người dùng chọn; Toolbox không upload export. Nếu cần anonymization mạnh hơn, xóa name, non-home path, project identifier, timestamp và attribution bên ngoài Toolbox trước khi transmission.

### Failure và escalation

- Với scan hoặc mutation error, giữ per-path error hiển thị và local ledger, ngừng retry destructive work, rồi verify target và Trash state trong Finder.
- Với migration failure, giữ file Diskora, MacCleaner và Changeora gốc. Sửa source hoặc completion marker không đọc được trước khi retry; không có `migration-v1.json` nghĩa là completion chưa được ghi.
- Với schedule failure, giữ cả hai plist và exact `launchctl` stderr, rồi chỉ kiểm tra hai label Toolbox/Diskora mô tả ở trên.
- Với evidence-store quarantine hoặc legacy-format state rỗng bất ngờ, giữ affected/quarantined file trước khi recovery. Không hand-edit live JSON khi Toolbox đang chạy.
- Với suspected vulnerability hoặc unsafe path acceptance, dừng workflow bị ảnh hưởng và theo `SECURITY.md`. Với artifact, signing, notarization, checksum hoặc published-release issue, theo `docs/OPERATIONS-RELEASE.md`.

## 日本語

### Workstation と toolchain

Toolbox は外部 dependency のない SwiftPM package で、`swift-tools-version: 6.0` と macOS 13 deployment target を使用します。Development、application bundling、FSEvents、LaunchAgent、signing、DMG、Gatekeeper check には macOS が必要です。GitHub CI は `macos-15` を使い、選択された Swift version を表示します。Repository は manifest と test が証明する範囲を超えて特定 local Xcode build を保証しません。

Repository root から開始し、validation 前に active developer directory を確認します。

```bash
xcode-select -p
cd apps/toolbox
swift --version
```

XCTest 実行時は full Xcode developer directory を使います。Command Line Tools-only host に合わせるためだけに application source、release script、workflow policy を変更しません。

### Development validation

`apps/toolbox` で source/bundle gate を実行します。

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
test -x dist/Toolbox.app/Contents/MacOS/Toolbox
test -f dist/Toolbox.app/Contents/Resources/en.lproj/Localizable.strings
test -f dist/Toolbox.app/Contents/Resources/vi.lproj/Localizable.strings
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
```

`build_app.sh` は local single-architecture app を assemble し、ad-hoc signature を適用します。Build 成功と `codesign --verify` が証明するのは bundle structure と signature consistency だけです。Universal binary、Developer ID identity、notarization、stapling、Gatekeeper acceptance、physical Intel hardware での launch は証明しません。

Documentation/workflow contract を変更した場合は repository root で次を実行します。

```bash
python3 tests/check_docs.py docs/ARCHITECTURE.md docs/OPERATIONS.md docs/OPERATIONS-RELEASE.md
bash tests/unsigned_stable_release_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
```

`v2.0.0` の明示的 exception は historical です。再現可能な structural check、immutable evidence、後続 release の notarized default は [Release operations](OPERATIONS-RELEASE.md) で定義します。

### XCTest boundary

`xcode-select -p` が Command Line Tools を指し、`swift test` が `no such module 'XCTest'` で失敗する場合、その host では XCTest blocked と報告します。四つの smoke script は Core、選択された Storage/Changes path、update checker の有用な executable evidence ですが、curated source list を compile するため SwiftPM XCTest target の代替ではありません。

Merge/release claim には full Xcode 下の `swift test` または exact-commit GitHub Actions XCTest job の成功が必要です。Smoke success を XCTest、signing、notarization、launch、production claim に昇格させません。

### Scheduled-scan lifecycle

User は packaged Toolbox GUI から schedule を有効化し、Notification permission を許可する必要があります。Interval は 1～168 時間です。Toolbox は `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist` を atomic write し、現在 load 済みの Toolbox label を best-effort で boot out してから、新しい plist を bootstrap します。Bootstrap failure 時は新しい plist を削除し、interval を保存せず、exact `launchctl` error を表示します。

LaunchAgent は `/usr/bin/open -gj <Toolbox.app> --args --scheduled-scan` を実行します。App は accessory mode に切り替わり、`safe` と分類された default target だけを scan し、local summary notification を送り、last-run metadata を `UserDefaults` に保存して終了します。Scan result の選択、Trash 移動、削除は行いません。

Settings は `~/Library/LaunchAgents/com.thang.diskora.scheduled-scan.plist` を検出し、replacement 前に confirmation を要求します。順序は Toolbox job の install と bootstrap 成功、`com.thang.diskora.scheduled-scan` の best-effort bootout、legacy plist 削除です。Toolbox bootstrap failure では Toolbox plist を削除し legacy plist を保持します。現在の implementation は load 済み legacy label の bootout failure で replacement を失敗させません。Plist 削除により次回 login での legacy job load は防ぎますが、両 job が active に見える場合、operator は現在の `launchctl` session を調べる必要があります。

Disable は best-effort bootout 後に Toolbox plist と schedule metadata を削除します。Disable 後も job が動く場合は `launchctl print gui/$(id -u)/com.thang.toolbox.scheduled-scan` を調べ、無関係な LaunchAgent は削除しません。

### Update check

Toolbox は automatic update polling を行いません。**Check for Updates** の click が唯一の in-process trigger で、`ScanActivityRegistry` が active scan/snapshot を示す間は拒否されます。Request は次のとおりです。

```text
GET https://api.github.com/repos/thangldw/toolbox/releases/latest
Accept: application/vnd.github+json
User-Agent: Toolbox/<version>
```

Request body はなく、scan path、evidence、result、device payload を送りません。Non-2xx response は error として表示します。Returned tag は leading `v` と比較時の prerelease suffix を除いて semantic `major.minor.patch` として parse されます。Malformed tag は parsed latest version を生成しません。Toolbox は availability を報告するだけで update を download/install しません。

### Local data、backup、recovery

Manual data maintenance 前に Toolbox を終了し、`~/Library/Application Support/Toolbox` を保護された local storage へ copy します。Schedule を install 済みなら `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist` も保存します。これらの file は user path、timestamp、application attribution、cleanup history、Trash location を含む可能性があるため、backup を private data として扱います。

`evidence-v1.json` または `activity-v1.json` の decode failure では、file が sibling の `*.corrupt-<UTC timestamp>-<UUID>.json` path へ自動的に移され、error が報告されます。診断用に quarantined file を保持します。Unsupported schema は quarantine されません。`history.json`、`storage-checkpoints.json`、`sessions.json`、`active-snapshot.json`、`active-trace-metadata.json`、`trusted-baseline.json` は古い fail-soft loader を使うため、corrupt/unreadable content が empty/missing state に見えることがあります。元 data が存在しなかったと推測せず、Toolbox 終了中に known-good local backup を restore するか affected file を別の場所へ move してから state を再作成します。

Recovery は Trash move manifest を保持する cleanup history entry にだけ使います。Restore には記録済み Trash source の存在、original destination の不在、両 path の allowlisted-root check 通過が必要です。Destination parent だけを作成し、conflict を overwrite しません。Trash cleanup、developer-tool command、Trash manifest のない entry、already-restored item は Toolbox から recovery できません。Partial-failure detail を保持し、mutation 全体を盲目的に繰り返さず conflict ごとに解決します。

Full Disk Access は optional です。Toolbox は `~/Library/Mail` と `~/Library/Safari` を probe します。両 sentinel が存在しなければ両 path を reduced coverage として報告し、いずれかが存在する場合は unreadable な既存 sentinel だけが coverage を低下させます。必要な scan のためだけに Full Disk Access を許可し、Settings の **Check again** を使います。Reduced coverage は evidence limitation であり macOS protection を bypass する権限ではありません。

### Redacted export

Change Timeline は選択した一つの session を `NSSavePanel` 経由で Markdown または JSON に保存できます。Export は local かつ atomic です。Redaction は意図的に限定され、exact home-directory prefix だけを `~` に置換します。Filename、残りの path component、timestamp、change/risk/category field、attribution、reason、event count は report に残る可能性があり、home directory 外の path は redact されません。

共有前に生成 file を review します。User が選択した channel だけで移動し、Toolbox は export を upload しません。より強い anonymization が必要なら、送信前に Toolbox 外で name、non-home path、project identifier、timestamp、attribution を削除します。

### Failure と escalation

- Scan/mutation error では表示された per-path error と local ledger を保持し、destructive retry を止め、Finder で target/Trash state を verify します。
- Migration failure では元の Diskora、MacCleaner、Changeora file を保持します。Unreadable source または completion marker を直してから retry します。`migration-v1.json` がなければ completion は記録されていません。
- Schedule failure では両 plist と exact `launchctl` stderr を保持し、上記の Toolbox/Diskora label 二つだけを調べます。
- Evidence-store quarantine または予期しない empty legacy-format state では、recovery 前に affected/quarantined file を保持します。Toolbox 実行中に live JSON を hand-edit しません。
- Suspected vulnerability または unsafe path acceptance では対象 workflow を停止し `SECURITY.md` に従います。Artifact、signing、notarization、checksum、published-release issue では `docs/OPERATIONS-RELEASE.md` に従います。
