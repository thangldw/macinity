# Security policy

## English

### Supported versions

Security fixes target the latest public versions: Diskora 1.3.x and Changeora 1.4.x. Older releases may not receive patches.

### Reporting a vulnerability

Use the repository's private GitHub Security Advisory reporting flow. Do not open a public issue before a fix is available. Include:

- affected application, version, macOS version, and architecture;
- expected and observed behavior;
- minimal reproduction steps or a proof of concept;
- realistic impact and any prerequisites;
- relevant logs with credentials, tokens, usernames, and personal filesystem paths removed.

Maintainers will validate the report, determine severity and scope, prepare a fix, and coordinate disclosure. Avoid accessing data that is not yours, persistence, service disruption, or destructive testing.

### Security boundaries

- Diskora previews targets before cleanup and uses Trash for recoverable file operations.
- Undo Center restores only recorded paths and never overwrites an existing destination.
- Dangerous or read-only evidence is excluded from ordinary application cleanup.
- Developer cleanup uses fixed executable paths and allowlisted arguments; it does not evaluate shell input.
- Scheduled cleanup only scans and notifies. Deletion requires an interactive confirmation.
- Changeora observes and reports system changes; it does not remove detected artifacts.
- Exported support reports redact the current home-directory prefix, but users must review exports before sharing.

These controls reduce risk but do not replace backups. Keep a current backup before large cleanup operations.

### Dependency and release integrity

The repository has no runtime package dependencies outside Apple's SDKs. Release archives are generated from a tagged commit and accompanied by SHA-256 checksum files. Verify a download before opening an unsigned build:

```bash
shasum -a 256 -c Diskora-1.3.0-macos-arm64-unsigned.zip.sha256
shasum -a 256 -c Changeora-1.4.0-macos-arm64-unsigned.zip.sha256
```

## Tiếng Việt

### Phiên bản được hỗ trợ

Bản vá bảo mật tập trung vào phiên bản public mới nhất: Diskora 1.3.x và Changeora 1.4.x. Phiên bản cũ có thể không được vá.

### Báo cáo lỗ hổng

Dùng luồng báo cáo riêng tư GitHub Security Advisory của repository. Không mở public issue trước khi có bản sửa. Báo cáo nên gồm:

- ứng dụng, version, macOS version và kiến trúc bị ảnh hưởng;
- hành vi mong đợi và thực tế;
- bước tái hiện tối thiểu hoặc proof of concept;
- ảnh hưởng thực tế và điều kiện cần;
- log liên quan đã xóa credential, token, username và đường dẫn filesystem cá nhân.

Maintainer sẽ xác minh, xác định mức độ và phạm vi, chuẩn bị bản sửa và phối hợp công bố. Không truy cập dữ liệu không thuộc quyền sở hữu, tạo persistence, làm gián đoạn dịch vụ hoặc thử nghiệm phá hủy.

### Ranh giới bảo mật

- Diskora xem trước target và dùng Trash cho thao tác có thể phục hồi.
- Undo Center chỉ khôi phục đường dẫn đã ghi và không ghi đè destination có sẵn.
- Evidence nguy hiểm hoặc chỉ đọc không được đưa vào cleanup ứng dụng thông thường.
- Developer cleanup dùng đường dẫn executable cố định và argument trong allowlist; không thực thi shell input.
- Lịch cleanup chỉ quét và thông báo; xóa luôn cần xác nhận tương tác.
- Changeora chỉ quan sát và báo cáo, không xóa artifact.
- Báo cáo hỗ trợ ẩn prefix thư mục home hiện tại, nhưng người dùng vẫn phải kiểm tra trước khi chia sẻ.

Các lớp bảo vệ này giảm rủi ro nhưng không thay thế backup. Hãy giữ backup mới trước khi cleanup lớn.

### Toàn vẹn dependency và release

Repository không có runtime package dependency ngoài SDK của Apple. Archive release được tạo từ commit đã tag và có file checksum SHA-256. Dùng các lệnh trong phần English để xác minh bản unsigned trước khi mở.

## 日本語

### Supported version

Security fix は最新 public version の Diskora 1.3.x と Changeora 1.4.x を対象にします。古い release は patch 対象外になる場合があります。

### 脆弱性の報告

Repository の private GitHub Security Advisory reporting flow を使用し、fix 公開前に public issue を作成しないでください。次を含めてください。

- 影響を受ける application、version、macOS version、architecture
- 期待する動作と実際の動作
- 最小限の再現手順または proof of concept
- 現実的な impact と前提条件
- Credential、token、username、個人 filesystem path を除いた log

Maintainer は report を検証し、severity/scope の判定、fix、coordinated disclosure を進めます。自分のものではない data へのアクセス、persistence、service disruption、破壊的 test は避けてください。

### Security boundary

- Diskora は cleanup 前に target を preview し、復元可能な file 操作に Trash を使います。
- Undo Center は記録済み path だけを復元し、既存 destination を上書きしません。
- Dangerous または read-only evidence は通常の application cleanup から除外されます。
- Developer cleanup は固定 executable path と allowlist argument を使い、shell input を評価しません。
- 定期 cleanup は scan と通知だけを行い、削除には対話的確認が必要です。
- Changeora は system change を観測・報告するだけで artifact を削除しません。
- Support report は現在の home-directory prefix を秘匿しますが、共有前に user が確認する必要があります。

これらの control は risk を軽減しますが backup の代わりにはなりません。大規模 cleanup 前に最新 backup を用意してください。

### Dependency と release integrity

Repository は Apple SDK 以外の runtime package dependency を持ちません。Release archive は tag commit から生成し、SHA-256 checksum file を添付します。Unsigned build を開く前に English セクションのコマンドで検証してください。
