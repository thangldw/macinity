# Toolbox for macOS

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

Toolbox is a local-first macOS GUI that explains what changed and reclaims storage without automatic deletion.

### Why Toolbox

- **Install Trace:** drop a `.dmg`, `.pkg`, or `.app`, save a before snapshot, install normally through macOS, then review the after diff and FSEvents evidence.
- **Project cleanup:** find recognized rebuildable artifacts such as `.build`, `node_modules`, `.venv`, `target`, Gradle/Flutter build output, and `Pods` only inside roots you select.
- **Storage and applications:** analyze folders, duplicates, similar photos, developer data, applications, and evidence-linked leftovers.
- **Recovery:** every Trash-backed move records its original and Trash paths; restore refuses to overwrite an existing destination.
- **Local trust model:** no account, telemetry, content upload, privileged helper, automatic cleanup, or malware verdict.

Toolbox 2.0 replaces the standalone Diskora and Changeora packages. Releases through `v1.4.0` retain their historical source and binaries. First launch can copy and verify their Application Support history; the original files remain untouched.

### Requirements

- macOS 13 or later
- Swift 6.0 or later to build from source
- Full Xcode for XCTest, universal archives, Developer ID signing, and notarization
- Optional Full Disk Access for broader protected-folder coverage

### Install the public beta

[`v2.0.0-beta.1`](https://github.com/thangldw/toolbox/releases/tag/v2.0.0-beta.1) is ad-hoc signed and **not notarized** by Apple. Download the DMG and its SHA-256 file, then verify them in the same folder:

```bash
shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
```

Open the DMG and drag Toolbox to Applications. On first launch, try to open Toolbox once, then go to **System Settings → Privacy & Security → Open Anyway** and authenticate. Do not disable Gatekeeper or strip quarantine attributes. Homebrew installation remains unavailable until a Developer ID-signed and notarized stable release exists.

### Build and verify

```bash
cd apps/toolbox
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

Command Line Tools can run the smoke gates and release build. This repository's XCTest targets require the XCTest module from full Xcode.

### Repository layout

```text
toolbox/
├── apps/toolbox/          # ToolboxCore, ToolboxStorage, ToolboxChanges, GUI executable
├── docs/                  # Architecture, operations, plans, and release evidence
├── site/                  # Product landing page
├── .github/workflows/     # CI, Pages, and release workflows
├── PRIVACY.md
├── SECURITY.md
└── CONTRIBUTING.md
```

See [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md), [Privacy](PRIVACY.md), [Security](SECURITY.md), and [Contributing](CONTRIBUTING.md).

## Tiếng Việt

Toolbox là ứng dụng macOS GUI chạy local, giúp giải thích thay đổi trên máy và giải phóng dung lượng mà không tự động xóa.

### Giá trị chính

- **Install Trace:** thả `.dmg`, `.pkg` hoặc `.app`, lưu snapshot trước, cài qua luồng macOS bình thường rồi xem diff sau cài đặt và bằng chứng FSEvents.
- **Dọn project:** chỉ tìm artifact có thể tạo lại đã biết như `.build`, `node_modules`, `.venv`, `target`, output Gradle/Flutter và `Pods` trong root do bạn chọn.
- **Dung lượng và ứng dụng:** phân tích folder, file trùng, ảnh tương tự, dữ liệu developer, ứng dụng và leftover có bằng chứng.
- **Khôi phục:** thao tác qua Trash lưu vị trí gốc/vị trí Trash; restore không ghi đè destination đang tồn tại.
- **Ranh giới tin cậy:** không tài khoản, telemetry, upload nội dung, privileged helper, tự động dọn hoặc kết luận malware.

Toolbox 2.0 thay hai package độc lập Diskora và Changeora. Các release đến `v1.4.0` vẫn giữ source và binary lịch sử. Lần chạy đầu có thể sao chép và xác minh Application Support cũ; file gốc không bị sửa.

### Yêu cầu và build

- macOS 13 trở lên; Swift 6.0 trở lên khi build source.
- Full Xcode để chạy XCTest, build universal, ký Developer ID và notarize.
- Full Disk Access là tùy chọn để tăng phạm vi đọc thư mục được bảo vệ.

Dùng các lệnh trong phần English để chạy format, XCTest, bốn smoke gate, localization gate, release build và xác minh bundle. Command Line Tools chạy được smoke/release build; XCTest cần module từ full Xcode.

`apps/toolbox` là package duy nhất được ship. `ToolboxCore` giữ contract/persistence/safety, `ToolboxStorage` giữ workflow dung lượng, `ToolboxChanges` giữ Install Trace, và target `Toolbox` giữ GUI/onboarding/settings/routing.

Xem [Kiến trúc](docs/ARCHITECTURE.md), [Vận hành](docs/OPERATIONS.md), [Quyền riêng tư](PRIVACY.md), [Bảo mật](SECURITY.md) và [Đóng góp](CONTRIBUTING.md).

[`v2.0.0-beta.1`](https://github.com/thangldw/toolbox/releases/tag/v2.0.0-beta.1) là beta ký ad-hoc và **chưa notarize** bởi Apple. Tải DMG cùng file SHA-256, chạy lệnh kiểm tra trong phần English, kéo Toolbox vào Applications rồi thử mở một lần. Sau đó vào **System Settings → Privacy & Security → Open Anyway** và xác thực. Không tắt Gatekeeper hoặc xóa quarantine attribute. Homebrew chỉ được mở sau khi có stable release ký Developer ID và notarize.

## 日本語

Toolbox は、変更内容を説明し、自動削除せずにストレージを安全に整理するローカル優先の macOS GUI です。

### 主な価値

- **Install Trace:** `.dmg`、`.pkg`、`.app` をドロップし、前後 snapshot と FSEvents evidence を比較します。
- **Project cleanup:** user が選択した root 内だけで、既知の再生成可能 artifact を検出します。
- **Storage / Applications:** folder、duplicate、類似写真、developer data、application leftover を evidence と共に確認します。
- **Recovery:** Trash 移動を記録し、既存 destination を上書きしません。
- **Trust boundary:** account、telemetry、content upload、privileged helper、自動 cleanup、malware 判定はありません。

Toolbox 2.0 は standalone Diskora / Changeora package を置き換えます。`v1.4.0` までの release には過去の source と binary が残ります。初回起動時の migration は旧 Application Support data を copy・verify し、元 file を変更しません。

macOS 13 以降と Swift 6.0 以降が必要です。XCTest、universal archive、Developer ID signing、notarization には full Xcode を使用してください。検証 command は English セクションを参照してください。

[Architecture](docs/ARCHITECTURE.md)、[Operations](docs/OPERATIONS.md)、[Privacy](PRIVACY.md)、[Security](SECURITY.md)、[Contributing](CONTRIBUTING.md) を参照してください。

[`v2.0.0-beta.1`](https://github.com/thangldw/toolbox/releases/tag/v2.0.0-beta.1) は ad-hoc 署名の beta で、Apple により **notarize されていません**。DMG と SHA-256 file を download し、English section の command で検証してから Applications に移動します。初回は一度起動を試し、**System Settings → Privacy & Security → Open Anyway** で許可してください。Gatekeeper の無効化や quarantine attribute の削除は行わないでください。Homebrew は Developer ID 署名・notarize 済み stable release まで提供しません。

## License

[MIT](LICENSE)
