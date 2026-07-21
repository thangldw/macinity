# Diskora

**See where your space goes.**

[Tiếng Việt](#vi) · [English](#en) · [日本語](#ja)

<a id="vi"></a>

## Tiếng Việt

Ứng dụng quản lý dung lượng macOS native, phát triển từ script `mac_cleaner.py` ban đầu. Diskora có dọn nhanh an toàn, phân tích thư mục hoặc ổ đĩa, tìm tệp lớn, duplicate, ảnh tương tự và dữ liệu môi trường developer.

| Thông tin | Chi tiết |
| --- | --- |
| Tác giả | Thang |
| Phiên bản | 1.0.0 (Build 1) |
| Bản quyền | Copyright © 2026 Thang — MIT License. |

Xem [COPYRIGHT.md](COPYRIGHT.md) và [MIT License](../../LICENSE).

### Chức năng

- **Dọn nhanh:** cache, log, Thùng rác, dữ liệu build Xcode và cache package manager.
- **Phân tích dung lượng:** quét thư mục hoặc ổ đĩa, thống kê loại dữ liệu, thư mục lớn nhất và tệp trên 100 MB.
- **Tệp trùng lặp:** nhóm theo kích thước rồi xác minh SHA-256 theo block; cảnh báo tên gần giống nhưng nội dung khác và tên khác nhưng nội dung giống hệt.
- **Developer:** nhận diện Xcode Simulator, Device Support, Docker, nvm, pyenv, asdf, Conda, Android SDK, Gradle, CocoaPods và backup iPhone/iPad.
- **Ảnh tương tự:** dùng Apple Vision để nhóm ảnh gần nhau, đề xuất bản chất lượng cao hơn và cho duyệt trước khi chuyển vào Trash.
- **Dọn chuyên sâu:** phân loại An toàn, Cần xem lại và Không xóa tự động.
- **Gỡ ứng dụng:** đối chiếu Bundle ID để tìm Application Support, Cache, Preferences, Logs và Containers còn sót.
- **Treemap, xu hướng và lịch sử:** trực quan hóa thư mục lớn, so sánh lần quét và lưu thao tác có thể khôi phục.
- Mở kết quả trong Finder và ghi báo cáo tại `~/Library/Application Support/Diskora/Reports`.

Màn hình Developer hiện chỉ thống kê và cảnh báo rủi ro. App không tự động xóa SDK/runtime khi chưa thể xác định phiên bản đang được dự án sử dụng.

### Phát triển và kiểm thử

Yêu cầu macOS 13+ và Xcode Command Line Tools.

```bash
cd apps/diskora
swift run Diskora
```

```bash
cd apps/diskora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

Smoke test sử dụng thư mục tạm, không chạm vào dữ liệu thật và không yêu cầu XCTest.

### Build và cài đặt

```bash
cd apps/diskora
./scripts/build_app.sh
open dist/Diskora.app
```

Release miễn phí không có Developer ID hoặc Apple notarization. Sau khi tải ZIP:

1. Xác minh SHA-256 bằng file `.sha256` đi kèm.
2. Giải nén và kéo `Diskora.app` vào Applications.
3. Thử mở app một lần.
4. Nếu bị chặn, chọn **System Settings → Privacy & Security → Open Anyway**.

Không tắt Gatekeeper toàn hệ thống và không xóa quarantine cho file từ nguồn không tin cậy.

Tạo release local:

```bash
cd apps/diskora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
```

### Quyền truy cập và an toàn

macOS có thể bảo vệ Thùng rác và một số thư mục. Nếu app báo lỗi quyền, vào **System Settings → Privacy & Security → Full Disk Access**, thêm `Diskora.app`, rồi mở lại app. Chỉ cấp quyền nếu bạn tự build hoặc tin tưởng binary.

- Chỉ thao tác trong thư mục người dùng hiện tại.
- Chặn đường dẫn cố thoát ra ngoài phạm vi cho phép.
- Chỉ xóa nội dung của hạng mục, không xóa thư mục gốc.
- Xcode Archives và Thùng rác không được chọn mặc định.
- Hiển thị lỗi thay vì bỏ qua im lặng.
- Ưu tiên Trash để có thể khôi phục.

### Tài liệu

- [Kiến trúc](../../docs/ARCHITECTURE.md)
- [Quy trình release](../../docs/RELEASING.md)
- [Changelog](CHANGELOG.md)
- [Security policy](../../SECURITY.md)
- [Privacy](../../PRIVACY.md)

---

<a id="en"></a>

## English

A native macOS storage-management application developed from the original `mac_cleaner.py` script. Diskora provides safe quick cleanup, folder or disk analysis, large-file discovery, duplicate detection, similar-photo grouping, and developer-environment analysis.

| Information | Details |
| --- | --- |
| Author | Thang |
| Version | 1.0.0 (Build 1) |
| Copyright | Copyright © 2026 Thang — MIT License. |

See [COPYRIGHT.md](COPYRIGHT.md) and the [MIT License](../../LICENSE).

### Features

- **Quick cleanup:** caches, logs, Trash, Xcode build data, and package-manager caches.
- **Storage analysis:** scan a folder or disk and report data types, largest directories, and files over 100 MB.
- **Duplicate files:** group by size and verify block-by-block with SHA-256; warn about similar names with different content and different names with identical content.
- **Developer data:** detect Xcode Simulator, Device Support, Docker, nvm, pyenv, asdf, Conda, Android SDK, Gradle, CocoaPods, and iPhone/iPad backups.
- **Similar photos:** use Apple Vision to group similar images, recommend the higher-quality copy, and require review before moving anything to Trash.
- **Deep cleanup:** classify candidates as Safe, Review Required, or Never Delete Automatically.
- **Application removal:** use Bundle IDs to find related Application Support, Cache, Preferences, Logs, and Containers.
- **Treemap, trends, and history:** visualize large directories, compare scans, and record recoverable operations.
- Reveal results in Finder and write reports to `~/Library/Application Support/Diskora/Reports`.

The Developer screen currently reports data and risk only. Diskora does not automatically remove an SDK or runtime when it cannot determine whether a project still uses that version.

### Development and testing

Requires macOS 13+ and Xcode Command Line Tools.

```bash
cd apps/diskora
swift run Diskora
```

```bash
cd apps/diskora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

Smoke tests use temporary directories, never touch real user data, and do not require XCTest.

### Build and installation

```bash
cd apps/diskora
./scripts/build_app.sh
open dist/Diskora.app
```

Free releases have no Developer ID signature or Apple notarization. After downloading the ZIP:

1. Verify SHA-256 using the accompanying `.sha256` file.
2. Extract and move `Diskora.app` to Applications.
3. Attempt to open the app once.
4. If macOS blocks it, choose **System Settings → Privacy & Security → Open Anyway**.

Do not disable Gatekeeper system-wide or clear quarantine for a file from an untrusted source.

Create a local release:

```bash
cd apps/diskora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
```

### Permissions and safety

macOS may protect Trash and other folders. If Diskora reports a permission error, open **System Settings → Privacy & Security → Full Disk Access**, add `Diskora.app`, and relaunch it. Grant this access only to a build you created or trust.

- Operate only inside the current user's home directory.
- Reject paths that escape an allowed scope.
- Remove the contents of a cleanup category, not its root directory.
- Never select Xcode Archives or Trash by default.
- Surface errors instead of silently ignoring them.
- Prefer Trash so items remain recoverable.

### Documentation

- [Architecture](../../docs/ARCHITECTURE.md)
- [Release process](../../docs/RELEASING.md)
- [Changelog](CHANGELOG.md)
- [Security policy](../../SECURITY.md)
- [Privacy](../../PRIVACY.md)

---

<a id="ja"></a>

## 日本語

元の `mac_cleaner.py` script を基に開発した native macOS ストレージ管理アプリケーションです。安全なクイッククリーンアップ、フォルダ／ディスク分析、大容量ファイル検索、重複検出、類似写真のグループ化、developer 環境分析を提供します。

| 情報 | 内容 |
| --- | --- |
| 作者 | Thang |
| バージョン | 1.0.0 (Build 1) |
| 著作権 | Copyright © 2026 Thang — MIT License. |

[COPYRIGHT.md](COPYRIGHT.md) および [MIT License](../../LICENSE) を参照してください。

### 機能

- **クイッククリーンアップ:** cache、log、ゴミ箱、Xcode build data、package manager cache。
- **ストレージ分析:** フォルダまたはディスクを scan し、データ種別、大きなディレクトリ、100 MB を超えるファイルを表示。
- **重複ファイル:** サイズでグループ化し SHA-256 で block 単位に検証。似た名前で内容が異なる場合、または名前が異なり内容が同一の場合に警告。
- **Developer データ:** Xcode Simulator、Device Support、Docker、nvm、pyenv、asdf、Conda、Android SDK、Gradle、CocoaPods、iPhone／iPad backup を検出。
- **類似写真:** Apple Vision で類似画像をグループ化し、高品質な候補を提案。ゴミ箱へ移動する前に確認が必要。
- **詳細クリーンアップ:** 安全、要確認、自動削除禁止のカテゴリに分類。
- **アプリケーション削除:** Bundle ID を使い、関連する Application Support、Cache、Preferences、Logs、Containers を検出。
- **Treemap、傾向、履歴:** 大きなディレクトリの可視化、scan 比較、復元可能な操作の記録。
- Finder で結果を表示し、`~/Library/Application Support/Diskora/Reports` にレポートを保存。

Developer 画面は現在、データとリスクの表示のみ行います。プロジェクトが使用中か判断できない SDK／runtime を自動削除しません。

### 開発とテスト

macOS 13+ と Xcode Command Line Tools が必要です。

```bash
cd apps/diskora
swift run Diskora
```

```bash
cd apps/diskora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

Smoke test は一時ディレクトリを使用し、実際のユーザーデータには触れず、XCTest も必要ありません。

### Build とインストール

```bash
cd apps/diskora
./scripts/build_app.sh
open dist/Diskora.app
```

無料リリースには Developer ID 署名と Apple notarization がありません。ZIP をダウンロードした後:

1. 同梱の `.sha256` ファイルで SHA-256 を検証します。
2. 解凍して `Diskora.app` を Applications に移動します。
3. 一度アプリを開きます。
4. macOS にブロックされた場合は **システム設定 → プライバシーとセキュリティ → このまま開く** を選択します。

Gatekeeper をシステム全体で無効にしたり、信頼できないファイルの quarantine を解除したりしないでください。

ローカル release の作成:

```bash
cd apps/diskora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
```

### 権限と安全性

macOS はゴミ箱などのフォルダを保護する場合があります。権限エラーが表示された場合は **システム設定 → プライバシーとセキュリティ → フルディスクアクセス** で `Diskora.app` を追加し、アプリを再起動してください。自分で build した、または信頼できる binary にのみ許可してください。

- 現在のユーザーの home directory 内だけを操作します。
- 許可された範囲から外れるパスを拒否します。
- クリーンアップ対象の内容のみを削除し、root directory は削除しません。
- Xcode Archives とゴミ箱をデフォルト選択しません。
- エラーを黙って無視せず表示します。
- 復元できるようゴミ箱を優先します。

### ドキュメント

- [アーキテクチャ](../../docs/ARCHITECTURE.md)
- [リリース手順](../../docs/RELEASING.md)
- [変更履歴](CHANGELOG.md)
- [セキュリティポリシー](../../SECURITY.md)
- [プライバシー](../../PRIVACY.md)
