# Privacy

Toolbox is designed for local inspection and local control. This policy describes the repository's current behavior; it is not a promise about third-party tools that users choose to run.

## English

### Data processing

Toolbox has no telemetry, advertising SDK, user account, analytics endpoint, or built-in cloud synchronization. Diskora and Changeora process data on the Mac where they run.

Diskora may read:

- filesystem paths, sizes, dates, file type, and other metadata needed for cleanup previews;
- partial or complete file content while calculating local SHA-256 hashes;
- local image features and metadata used to group similar photos;
- application identifiers, receipts, launch items, background-item evidence, and containers;
- output from explicitly selected, allowlisted local maintenance commands.

Diskora stores cleanup history and restore locations under `~/Library/Application Support/Diskora`. Scheduled scanning stores user preferences and a LaunchAgent configuration. It scans and notifies only; it does not delete automatically.

Changeora may read filesystem metadata, property-list metadata, code-signing identifiers, package receipts, system registration data, and FSEvents needed to compare a Mac before and after an install, update, or uninstall. It stores sessions and an optional trusted baseline under `~/Library/Application Support/Changeora`.

### Data sharing

The applications do not send scanned paths, hashes, photos, reports, or usage data to the developer or another service. Export occurs only when the user chooses a destination. Changeora support exports replace the current home-directory prefix with `~`; users should still review a report before sharing it.

Official developer-cleanup commands can invoke locally installed third-party tools. Those tools remain governed by their own configuration and privacy behavior.

### Retention and deletion

History is retained locally until the user removes it or deletes the application's support directory. Items moved to Trash follow macOS Trash retention and user actions. Removing an application's support directory removes its saved history or baseline but cannot restore files already deleted from Trash.

### Permissions

macOS may request notification, filesystem, or Full Disk Access permissions depending on the selected scope. Denying permission limits coverage; Toolbox does not bypass system protections.

Privacy questions may be opened as a GitHub discussion or issue. Security-sensitive reports should follow [SECURITY.md](SECURITY.md).

## Tiếng Việt

### Xử lý dữ liệu

Toolbox không có telemetry, SDK quảng cáo, tài khoản người dùng, endpoint analytics hoặc đồng bộ cloud tích hợp. Diskora và Changeora xử lý dữ liệu ngay trên máy Mac đang chạy.

Diskora có thể đọc:

- đường dẫn, kích thước, ngày, loại file và metadata cần cho màn hình xem trước;
- một phần hoặc toàn bộ nội dung file khi tính SHA-256 cục bộ;
- đặc trưng và metadata ảnh cục bộ để gom nhóm ảnh tương tự;
- định danh ứng dụng, receipt, launch item, bằng chứng background item và container;
- output của lệnh bảo trì local nằm trong allowlist và do người dùng chọn rõ ràng.

Diskora lưu lịch sử cleanup và vị trí khôi phục tại `~/Library/Application Support/Diskora`. Quét theo lịch lưu tùy chọn người dùng và cấu hình LaunchAgent. Tính năng này chỉ quét và thông báo, không tự xóa.

Changeora có thể đọc metadata filesystem, property list, định danh chữ ký, package receipt, dữ liệu đăng ký hệ thống và FSEvents để so sánh máy Mac trước/sau cài đặt, cập nhật hoặc gỡ ứng dụng. Phiên theo dõi và baseline tùy chọn được lưu tại `~/Library/Application Support/Changeora`.

### Chia sẻ dữ liệu

Ứng dụng không gửi đường dẫn, hash, ảnh, báo cáo hoặc dữ liệu sử dụng cho nhà phát triển hay dịch vụ khác. Chỉ export khi người dùng chọn đích lưu. Báo cáo hỗ trợ của Changeora thay prefix thư mục home hiện tại bằng `~`; người dùng vẫn cần xem lại trước khi chia sẻ.

Lệnh developer cleanup chính thức có thể gọi công cụ bên thứ ba đã cài local. Các công cụ đó tuân theo cấu hình và chính sách riêng của chúng.

### Lưu trữ và xóa

Lịch sử được giữ local cho đến khi người dùng xóa hoặc xóa thư mục support của ứng dụng. File chuyển vào Trash tuân theo cơ chế Trash của macOS. Xóa thư mục support sẽ xóa lịch sử hoặc baseline nhưng không thể khôi phục file đã bị xóa khỏi Trash.

### Quyền truy cập

macOS có thể yêu cầu quyền notification, filesystem hoặc Full Disk Access tùy phạm vi quét. Từ chối quyền sẽ làm giảm độ bao phủ; Toolbox không vượt qua cơ chế bảo vệ hệ thống.

Câu hỏi quyền riêng tư có thể gửi qua GitHub discussion hoặc issue. Báo cáo nhạy cảm về bảo mật cần theo [SECURITY.md](SECURITY.md).

## 日本語

### データ処理

Toolbox には telemetry、広告 SDK、user account、analytics endpoint、内蔵 cloud sync がありません。Diskora と Changeora は実行中の Mac 上でデータを処理します。

Diskora は次のデータを読み取る場合があります。

- Cleanup preview に必要な path、size、date、file type などの metadata
- Local SHA-256 計算中の file 内容の一部または全部
- 類似写真 grouping に使う local image feature と metadata
- Application identifier、receipt、launch item、background-item evidence、container
- User が明示的に選んだ allowlist 内の local maintenance command 出力

Diskora は cleanup history と restore location を `~/Library/Application Support/Diskora` に保存します。定期 scan は user preference と LaunchAgent 設定を保存しますが、scan と通知だけを行い自動削除しません。

Changeora は install、update、uninstall 前後を比較するため、filesystem metadata、property-list metadata、code-signing identifier、package receipt、system registration data、FSEvents を読み取る場合があります。Session と任意の trusted baseline は `~/Library/Application Support/Changeora` に保存します。

### データ共有

アプリは scan した path、hash、photo、report、usage data を developer や外部 service に送信しません。Export は user が保存先を選んだ場合だけ行います。Changeora support export は現在の home-directory prefix を `~` に置換しますが、共有前に内容を確認してください。

公式 developer-cleanup command は local に導入された third-party tool を呼び出す場合があります。それらの tool には独自の設定と privacy behavior が適用されます。

### 保持と削除

History は user が削除するか application support directory を削除するまで local に残ります。Trash に移動した item は macOS Trash の保持と user 操作に従います。Support directory を削除すると history/baseline は消えますが、Trash から削除済みの file は復元できません。

### 権限

選択範囲に応じて macOS が notification、filesystem、Full Disk Access を要求する場合があります。拒否すると監視範囲が制限されます。Toolbox は system protection を迂回しません。

Privacy に関する質問は GitHub discussion または issue を利用できます。Security-sensitive な報告は [SECURITY.md](SECURITY.md) に従ってください。
