# Toolbox for macOS

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

Toolbox is a local-first macOS GUI for understanding installer changes and reclaiming storage through reviewed, recoverable actions. It combines the former Diskora and Changeora workflows in one application. It is not a malware scanner, package manager, automatic cleaner, cloud service, or privileged system repair tool.

### Install `v2.0.0`

Requirements: macOS 13 or later. The published DMG contains `arm64` and `x86_64` slices; the release record does not claim a physical Intel launch test.

1. Download [`Toolbox-2.0.0.dmg`](https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg) and [`Toolbox-2.0.0.dmg.sha256`](https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg.sha256) into the same folder.
2. Verify the download:

   ```bash
   shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
   ```

3. Open the DMG, read `Open Toolbox - First Launch.html`, and drag Toolbox to Applications.
4. Try to open Toolbox once. If macOS blocks it, open **System Settings → Privacy & Security**, find the Toolbox message, choose **Open Anyway**, and authenticate.

`v2.0.0` is the stable product release, but it is ad-hoc signed and **not notarized** by Apple. Stable identifies the release channel; it is not Apple trust approval. Gatekeeper rejection before the manual approval is expected. Do not disable Gatekeeper or remove quarantine attributes. Homebrew installation is unavailable because this release is not Developer ID-signed and notarized.

### Core workflows

- **Install Trace:** accept a `.dmg`, `.pkg`, or `.app`, capture a before snapshot, observe bounded FSEvents while the user runs the normal macOS install, update, or uninstall flow, then compare and persist the after evidence. Toolbox does not mount or execute the dropped installer.
- **Storage:** inspect folder allocation, duplicate candidates verified by hashing, similar-photo candidates, developer storage, and safe cleanup categories.
- **Projects:** find only recognized rebuildable artifacts such as `.build`, `node_modules`, `.venv`, `target`, Gradle/Flutter output, and `Pods` inside a root selected by the user.
- **Applications:** inspect installed applications and evidence-linked leftovers; package receipts and registration metadata are evidence, not permission to delete.
- **Change Timeline:** compare saved sessions and baselines, explain attribution and risk, and export redacted Markdown or JSON reports.
- **Recovery:** retain original and Trash paths for eligible reviewed mutations; restore fails rather than overwrite an existing destination.

### Safety and privacy boundary

Scans, snapshots, hashes, evidence, activity, migration state, and recovery manifests stay on the Mac under `~/Library/Application Support/Toolbox`. Toolbox has no account, telemetry, advertising SDK, analytics endpoint, content upload, privileged helper, automatic deletion, or malware verdict. Full Disk Access is optional and only expands readable coverage; inaccessible protected locations remain reduced coverage.

Every mutation requires foreground review and immediate canonical-path revalidation. Eligible file mutations use macOS Trash. Scheduled runs scan and notify only; they never delete. The only built-in network path is a GET to `https://api.github.com/repos/thangldw/toolbox/releases/latest` after the user chooses **Check for Updates**; it sends no scan results, paths, evidence, file metadata, or device fields.

See [Privacy](PRIVACY.md) and [Security](SECURITY.md) for the complete policy.

### Build and validation

Swift 6.0 or later is required to build from source. From `apps/toolbox`:

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
codesign --verify --deep --strict dist/Toolbox.app
```

Command Line Tools can run the smoke gates and release build. The XCTest targets require the XCTest module from full Xcode. Local build and `codesign` success prove structural integrity only; they do not prove Developer ID signing, notarization, stapling, Gatekeeper acceptance, or a published release.

### Documentation and repository layout

```text
toolbox/
├── apps/toolbox/          # ToolboxCore, ToolboxStorage, ToolboxChanges, GUI executable
├── docs/                  # Architecture, operations, launch, and release evidence
├── site/                  # Product landing page
├── .github/workflows/     # CI, Pages, and release workflows
├── PRIVACY.md
├── SECURITY.md
└── CONTRIBUTING.md
```

Start with [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md), and [Release operations](docs/OPERATIONS-RELEASE.md). Historical release details are in [Changelog](CHANGELOG.md) and the [`v2.0.0` release note](docs/launch/toolbox-2.0.0.md). Engineering changes follow [Contributing](CONTRIBUTING.md).

### Version 1 history

Tags through `v1.4.0` retain the standalone Diskora and Changeora source and binaries as historical artifacts; they are not active support branches. On first launch, Toolbox 2 can inspect supported legacy Application Support JSON and, only with user approval, copy, merge, and verify it into the Toolbox store. Original legacy files remain unchanged.

### License

[MIT](LICENSE)

## Tiếng Việt

Toolbox là GUI macOS ưu tiên xử lý local để hiểu thay đổi do installer tạo ra và giải phóng dung lượng bằng thao tác được duyệt, có thể khôi phục. Ứng dụng hợp nhất workflow Diskora và Changeora trước đây. Toolbox không phải malware scanner, package manager, trình dọn tự động, cloud service hay công cụ sửa hệ thống có quyền đặc biệt.

### Cài đặt `v2.0.0`

Yêu cầu: macOS 13 trở lên. DMG đã phát hành chứa slice `arm64` và `x86_64`; release record không claim đã launch trực tiếp trên máy Intel vật lý.

1. Tải [`Toolbox-2.0.0.dmg`](https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg) và [`Toolbox-2.0.0.dmg.sha256`](https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg.sha256) vào cùng folder.
2. Xác minh file tải về:

   ```bash
   shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
   ```

3. Mở DMG, đọc `Open Toolbox - First Launch.html`, rồi kéo Toolbox vào Applications.
4. Thử mở Toolbox một lần. Nếu macOS chặn, mở **System Settings → Privacy & Security**, tìm thông báo về Toolbox, chọn **Open Anyway** rồi xác thực.

`v2.0.0` là stable product release nhưng được ký ad-hoc và **chưa notarize** bởi Apple. Stable chỉ kênh phát hành, không phải Apple trust approval. Gatekeeper từ chối trước bước phê duyệt thủ công là kết quả dự kiến. Không tắt Gatekeeper hoặc xóa quarantine attribute. Chưa có Homebrew vì release này chưa được ký Developer ID và notarize.

### Workflow chính

- **Install Trace:** nhận `.dmg`, `.pkg` hoặc `.app`, chụp snapshot trước, quan sát FSEvents có giới hạn trong khi người dùng chạy luồng cài đặt, cập nhật hoặc uninstall bình thường của macOS, sau đó so sánh và lưu evidence sau thao tác. Toolbox không mount hoặc execute installer được thả vào.
- **Storage:** kiểm tra dung lượng folder, candidate file trùng được xác minh bằng hash, candidate ảnh tương tự, developer storage và các nhóm cleanup an toàn.
- **Projects:** chỉ tìm artifact có thể build lại đã được nhận diện như `.build`, `node_modules`, `.venv`, `target`, output Gradle/Flutter và `Pods` bên trong root do người dùng chọn.
- **Applications:** kiểm tra ứng dụng đã cài và leftover gắn với evidence; package receipt và registration metadata chỉ là evidence, không phải quyền xóa.
- **Change Timeline:** so sánh session và baseline đã lưu, giải thích attribution/risk, đồng thời export report Markdown hoặc JSON đã redaction.
- **Recovery:** giữ vị trí gốc và vị trí Trash cho mutation đủ điều kiện đã được duyệt; restore sẽ fail thay vì ghi đè destination đang tồn tại.

### Ranh giới an toàn và quyền riêng tư

Scan, snapshot, hash, evidence, activity, trạng thái migration và recovery manifest ở lại trên máy Mac trong `~/Library/Application Support/Toolbox`. Toolbox không có account, telemetry, advertising SDK, analytics endpoint, content upload, privileged helper, tự động xóa hoặc malware verdict. Full Disk Access là tùy chọn và chỉ mở rộng coverage có thể đọc; vị trí được bảo vệ không truy cập được vẫn được hiển thị là reduced coverage.

Mọi mutation cần foreground review và revalidation canonical path ngay trước thao tác. File mutation đủ điều kiện dùng macOS Trash. Lịch chạy chỉ scan và notify, tuyệt đối không xóa. Network path tích hợp duy nhất là GET tới `https://api.github.com/repos/thangldw/toolbox/releases/latest` sau khi người dùng chọn **Check for Updates**; request không gửi kết quả scan, path, evidence, file metadata hoặc device field.

Xem [Quyền riêng tư](PRIVACY.md) và [Bảo mật](SECURITY.md) để đọc policy đầy đủ.

### Build và validation

Cần Swift 6.0 trở lên để build source. Chạy từ `apps/toolbox`:

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
codesign --verify --deep --strict dist/Toolbox.app
```

Command Line Tools chạy được smoke gate và release build. XCTest target cần module XCTest từ full Xcode. Local build và `codesign` pass chỉ chứng minh structural integrity; không chứng minh Developer ID signing, notarization, stapling, Gatekeeper acceptance hoặc release đã publish.

### Tài liệu và layout repository

```text
toolbox/
├── apps/toolbox/          # ToolboxCore, ToolboxStorage, ToolboxChanges, GUI executable
├── docs/                  # Architecture, operations, launch, and release evidence
├── site/                  # Product landing page
├── .github/workflows/     # CI, Pages, and release workflows
├── PRIVACY.md
├── SECURITY.md
└── CONTRIBUTING.md
```

Bắt đầu với [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md) và [Release operations](docs/OPERATIONS-RELEASE.md). Chi tiết release lịch sử nằm trong [Changelog](CHANGELOG.md) và [release note `v2.0.0`](docs/launch/toolbox-2.0.0.md). Thay đổi kỹ thuật tuân theo [Contributing](CONTRIBUTING.md).

### Lịch sử Version 1

Các tag đến `v1.4.0` giữ source và binary độc lập của Diskora/Changeora dưới dạng artifact lịch sử; đây không phải active support branch. Ở lần chạy đầu, Toolbox 2 có thể inspect Application Support JSON cũ được hỗ trợ và chỉ khi người dùng đồng ý mới copy, merge, verify vào Toolbox store. File legacy gốc không thay đổi.

### Giấy phép

[MIT](LICENSE)

## 日本語

Toolbox は、installer による変更を理解し、review 済みで復元可能な操作によって storage を整理する local-first macOS GUI です。旧 Diskora と Changeora の workflow を一つの application に統合しています。Malware scanner、package manager、自動 cleaner、cloud service、privileged system repair tool ではありません。

### `v2.0.0` のインストール

要件は macOS 13 以降です。公開 DMG は `arm64` と `x86_64` slice を含みますが、release record は物理 Intel Mac での launch test を claim していません。

1. [`Toolbox-2.0.0.dmg`](https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg) と [`Toolbox-2.0.0.dmg.sha256`](https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg.sha256) を同じ folder に download します。
2. Download を検証します。

   ```bash
   shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
   ```

3. DMG を開き、`Open Toolbox - First Launch.html` を読んで Toolbox を Applications に移動します。
4. Toolbox を一度開きます。macOS に block された場合は **System Settings → Privacy & Security** を開き、Toolbox の message から **Open Anyway** を選び、認証します。

`v2.0.0` は stable product release ですが、ad-hoc 署名で Apple により **notarize されていません**。Stable は release channel を示すだけで、Apple trust approval ではありません。手動承認前の Gatekeeper rejection は expected result です。Gatekeeper を無効化したり quarantine attribute を削除したりしないでください。この release は Developer ID 署名・notarize 済みではないため、Homebrew install は提供しません。

### Core workflow

- **Install Trace:** `.dmg`、`.pkg`、`.app` を受け取り、before snapshot を取得し、user が通常の macOS install/update/uninstall flow を実行している間だけ bounded FSEvents を観測して、after evidence を比較・保存します。Toolbox は drop された installer を mount または execute しません。
- **Storage:** folder allocation、hash で検証した duplicate candidate、similar-photo candidate、developer storage、安全な cleanup category を確認します。
- **Projects:** user が選択した root 内だけで、`.build`、`node_modules`、`.venv`、`target`、Gradle/Flutter output、`Pods` など既知の再生成可能 artifact を検出します。
- **Applications:** install 済み application と evidence-linked leftover を確認します。Package receipt と registration metadata は evidence であり、削除許可ではありません。
- **Change Timeline:** 保存済み session と baseline を比較し、attribution/risk を説明し、redaction 済み Markdown または JSON report を export します。
- **Recovery:** 対象となる review 済み mutation の original path と Trash path を保持します。既存 destination を上書きせず restore を fail させます。

### Safety と privacy の境界

Scan、snapshot、hash、evidence、activity、migration state、recovery manifest は Mac 内の `~/Library/Application Support/Toolbox` に保持されます。Account、telemetry、advertising SDK、analytics endpoint、content upload、privileged helper、自動削除、malware verdict はありません。Full Disk Access は任意で、読み取り可能範囲を広げるだけです。Access できない protected location は reduced coverage として表示されます。

すべての mutation は foreground review と action 直前の canonical-path revalidation を必要とします。対象 file mutation は macOS Trash を使います。Scheduled run は scan と notification のみで、削除しません。内蔵 network path は、user が **Check for Updates** を選択した後の `https://api.github.com/repos/thangldw/toolbox/releases/latest` への GET だけです。Scan result、path、evidence、file metadata、device field は送信しません。

完全な policy は [Privacy](PRIVACY.md) と [Security](SECURITY.md) を参照してください。

### Build と validation

Source build には Swift 6.0 以降が必要です。`apps/toolbox` から実行します。

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
codesign --verify --deep --strict dist/Toolbox.app
```

Command Line Tools では smoke gate と release build を実行できます。XCTest target には full Xcode の XCTest module が必要です。Local build と `codesign` pass は structural integrity の evidence に限られ、Developer ID signing、notarization、stapling、Gatekeeper acceptance、公開 release の evidence ではありません。

### Documentation と repository layout

```text
toolbox/
├── apps/toolbox/          # ToolboxCore, ToolboxStorage, ToolboxChanges, GUI executable
├── docs/                  # Architecture, operations, launch, and release evidence
├── site/                  # Product landing page
├── .github/workflows/     # CI, Pages, and release workflows
├── PRIVACY.md
├── SECURITY.md
└── CONTRIBUTING.md
```

[Architecture](docs/ARCHITECTURE.md)、[Operations](docs/OPERATIONS.md)、[Release operations](docs/OPERATIONS-RELEASE.md) から参照してください。Historical release detail は [Changelog](CHANGELOG.md) と [`v2.0.0` release note](docs/launch/toolbox-2.0.0.md) にあります。Engineering change は [Contributing](CONTRIBUTING.md) に従います。

### Version 1 の履歴

`v1.4.0` までの tag は、standalone Diskora/Changeora の source と binary を historical artifact として保持しています。Active support branch ではありません。初回起動時、Toolbox 2 は supported legacy Application Support JSON を inspect でき、user が承認した場合だけ Toolbox store に copy、merge、verify します。元の legacy file は変更しません。

### License

[MIT](LICENSE)
