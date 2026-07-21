# Changeora

**See what changed on your Mac.**

[Tiếng Việt](#vi) · [English](#en) · [日本語](#ja)

<a id="vi"></a>

## Tiếng Việt

Ứng dụng macOS native tạo snapshot trước và sau khi cài hoặc cập nhật phần mềm, sau đó giải thích những thay đổi có thể quan sát. Changeora tập trung vào bằng chứng kỹ thuật; không tự động xóa, tắt service hoặc kết luận một ứng dụng là độc hại.

| Thông tin | Chi tiết |
| --- | --- |
| Tác giả | Thang |
| Phiên bản | 1.0.0 (Build 1) |
| Bản quyền | Copyright © 2026 Thang — MIT License. |

Xem [COPYRIGHT.md](COPYRIGHT.md) và [MIT License](../../LICENSE).

### Chức năng

- Chụp snapshot trước và sau một lần cài đặt hoặc cập nhật.
- Theo dõi ứng dụng, LaunchAgent, LaunchDaemon, privileged helper và system extension.
- Quan sát metadata cấp cao trong Application Support, Cache, Preferences và app containers.
- Phân loại thay đổi thành Thông tin, Nên xem và Quan trọng.
- Đối chiếu Bundle ID, Team ID, version, code-signing status và label để gợi ý chủ sở hữu.
- Lưu tối đa 100 phiên local và khôi phục phiên đang theo dõi sau khi mở lại app.
- Compact lịch sử để chỉ lưu các mục thực sự thay đổi.
- Tìm kiếm theo tên, đường dẫn hoặc chủ sở hữu; mở kết quả trong Finder.
- Export báo cáo Markdown để review hoặc đính kèm issue.

### Luồng sử dụng

1. Chọn **Chụp trạng thái ban đầu**.
2. Cài hoặc cập nhật ứng dụng như bình thường.
3. Quay lại Changeora và chọn **Hoàn tất và so sánh**.
4. Xem thay đổi theo mức rủi ro và export báo cáo nếu cần.

![Changeora snapshot flow](../../docs/diagrams/changeora-snapshot-flow.svg)

### Phát triển và kiểm thử

Yêu cầu macOS 13+, Swift 6 và Xcode Command Line Tools.

```bash
cd apps/changeora
swift run
```

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

Smoke test tạo filesystem fixture tạm và xác minh scan, diff, risk classification, attribution, compact history cùng persistence. Test không đọc hoặc sửa cấu hình thật của máy.

### Build và release

```bash
cd apps/changeora
./scripts/build_app.sh
open dist/Changeora.app
```

```bash
cd apps/changeora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

Artifact được ad-hoc signed với Hardened Runtime nhưng không có Developer ID và không được Apple notarize. Người nhận có thể cần dùng **Privacy & Security → Open Anyway**, hoặc tự build từ source.

### Dữ liệu và quyền riêng tư

Changeora lưu dữ liệu tại `~/Library/Application Support/Changeora`:

- `active-snapshot.json`: snapshot đầy đủ của phiên đang theo dõi.
- `sessions.json`: tối đa 100 báo cáo compact đã hoàn tất.

App không có telemetry, tài khoản, quảng cáo hoặc network client. Changeora đọc metadata đường dẫn, timestamp, kích thước, bundle metadata và chữ ký; không đọc nội dung tài liệu cá nhân. Một số vị trí được macOS bảo vệ có thể không quan sát đầy đủ nếu chưa cấp Full Disk Access.

### Giới hạn 1.0.0

- Không phải antivirus hoặc malware scanner.
- Không tự động rollback, xóa file hoặc vô hiệu hóa background service.
- Snapshot không phải ảnh toàn bộ filesystem; chỉ bao phủ các vị trí có giá trị cho attribution.
- Ứng dụng có thể thay đổi dữ liệu ngoài phạm vi hoặc sau khi phiên kết thúc.
- Cache và preference có thể thay đổi do hoạt động bình thường của ứng dụng khác.
- Code-signing hợp lệ xác nhận tính toàn vẹn/chủ thể ký, không chứng minh phần mềm an toàn.

### Tạo lại icon

Icon đã được commit sẵn. `scripts/make_icon.py` chỉ cần khi thay artwork nguồn và yêu cầu Python với Pillow; build app thông thường không phụ thuộc Python.

---

<a id="en"></a>

## English

A native macOS application that captures snapshots before and after software installation or update, then explains observable changes. Changeora focuses on technical evidence; it does not automatically delete files, disable services, or declare an application malicious.

| Information | Details |
| --- | --- |
| Author | Thang |
| Version | 1.0.0 (Build 1) |
| Copyright | Copyright © 2026 Thang — MIT License. |

See [COPYRIGHT.md](COPYRIGHT.md) and the [MIT License](../../LICENSE).

### Features

- Capture before-and-after snapshots for an installation or update session.
- Observe applications, LaunchAgents, LaunchDaemons, privileged helpers, and system extensions.
- Observe high-level metadata in Application Support, Cache, Preferences, and app containers.
- Classify changes as Informational, Review, or Important.
- Use Bundle ID, Team ID, version, code-signing status, and labels to suggest ownership.
- Store up to 100 local sessions and recover an active session after relaunch.
- Compact history so only genuinely changed items remain in completed reports.
- Search by name, path, or owner and reveal results in Finder.
- Export Markdown reports for review or issue attachments.

### Workflow

1. Choose **Capture initial state**.
2. Install or update an application normally.
3. Return to Changeora and choose **Finish and compare**.
4. Review changes by risk level and export a report when needed.

![Changeora snapshot flow](../../docs/diagrams/changeora-snapshot-flow.svg)

### Development and testing

Requires macOS 13+, Swift 6, and Xcode Command Line Tools.

```bash
cd apps/changeora
swift run
```

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

The smoke test creates a temporary filesystem fixture and verifies scanning, diffing, risk classification, attribution, compact history, and persistence. It never reads or modifies the machine's real configuration.

### Build and release

```bash
cd apps/changeora
./scripts/build_app.sh
open dist/Changeora.app
```

```bash
cd apps/changeora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

The artifact is ad-hoc signed with Hardened Runtime but has no Developer ID signature and is not notarized by Apple. Recipients may need **Privacy & Security → Open Anyway**, or may build from source.

### Data and privacy

Changeora stores data in `~/Library/Application Support/Changeora`:

- `active-snapshot.json`: the full snapshot for an active watch session.
- `sessions.json`: up to 100 compact completed reports.

The app has no telemetry, account, advertising, or network client. Changeora reads path, timestamp, size, bundle, and signature metadata; it does not read personal document contents. Some macOS-protected locations may not be fully observable without Full Disk Access.

### Version 1.0.0 limitations

- Changeora is not an antivirus or malware scanner.
- It does not automatically roll back changes, delete files, or disable background services.
- A snapshot is not a full filesystem image; it covers locations useful for attribution.
- An application may change data outside the observed scope or after a session ends.
- Caches and preferences may change because of normal activity from unrelated applications.
- A valid code signature confirms integrity and signing identity, not software safety.

### Regenerating the icon

The icon is already committed. `scripts/make_icon.py` is needed only when replacing the source artwork and requires Python with Pillow; ordinary app builds do not depend on Python.

---

<a id="ja"></a>

## 日本語

ソフトウェアのインストールまたは更新前後に snapshot を取得し、観測できた変更を説明する native macOS アプリケーションです。Changeora は技術的証拠を重視し、ファイルの自動削除、service の無効化、アプリケーションのマルウェア判定を行いません。

| 情報 | 内容 |
| --- | --- |
| 作者 | Thang |
| バージョン | 1.0.0 (Build 1) |
| 著作権 | Copyright © 2026 Thang — MIT License. |

[COPYRIGHT.md](COPYRIGHT.md) および [MIT License](../../LICENSE) を参照してください。

### 機能

- インストールまたは更新セッションの前後で snapshot を取得。
- アプリケーション、LaunchAgent、LaunchDaemon、privileged helper、system extension を監視。
- Application Support、Cache、Preferences、app container の高レベル metadata を監視。
- 変更を「情報」「要確認」「重要」の 3 段階に分類。
- Bundle ID、Team ID、version、code-signing status、label から所有元を推定。
- 最大 100 件のローカルセッションを保存し、再起動後も監視中セッションを復元。
- 完了レポートには実際に変更された項目だけを compact 保存。
- 名前、パス、所有元で検索し、Finder で結果を表示。
- レビューや Issue 添付用に Markdown レポートを export。

### 使用フロー

1. **初期状態を取得** を選択します。
2. 通常どおりアプリケーションをインストールまたは更新します。
3. Changeora に戻り、**完了して比較** を選択します。
4. リスクレベル別に変更を確認し、必要に応じてレポートを export します。

![Changeora snapshot flow](../../docs/diagrams/changeora-snapshot-flow.svg)

### 開発とテスト

macOS 13+、Swift 6、Xcode Command Line Tools が必要です。

```bash
cd apps/changeora
swift run
```

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

Smoke test は一時 filesystem fixture を作成し、scan、diff、risk classification、attribution、compact history、persistence を検証します。実際の端末設定を読み取り・変更しません。

### Build とリリース

```bash
cd apps/changeora
./scripts/build_app.sh
open dist/Changeora.app
```

```bash
cd apps/changeora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

Artifact は Hardened Runtime を有効にした ad-hoc 署名ですが、Developer ID 署名と Apple notarization はありません。必要に応じて **プライバシーとセキュリティ → このまま開く** を使用するか、ソースから build してください。

### データとプライバシー

Changeora は `~/Library/Application Support/Changeora` にデータを保存します。

- `active-snapshot.json`: 監視中セッションの完全な snapshot。
- `sessions.json`: 最大 100 件の compact 済み完了レポート。

アプリには telemetry、account、広告、network client がありません。Changeora はパス、timestamp、サイズ、bundle、署名 metadata を読み取りますが、個人文書の内容は読み取りません。macOS に保護された一部ロケーションは、フルディスクアクセスがない場合に完全には観測できません。

### Version 1.0.0 の制限

- Antivirus または malware scanner ではありません。
- 変更の自動 rollback、ファイル削除、background service の無効化を行いません。
- Snapshot は filesystem 全体の image ではなく、attribution に役立つロケーションだけを対象にします。
- アプリケーションが監視範囲外、またはセッション終了後にデータを変更する場合があります。
- 他のアプリケーションの通常動作により cache や preference が変化する場合があります。
- 有効な code signature は整合性と署名者を示しますが、ソフトウェアの安全性を保証しません。

### Icon の再生成

Icon は commit 済みです。`scripts/make_icon.py` は source artwork を変更する場合のみ必要で、Python と Pillow を使用します。通常の app build は Python に依存しません。
