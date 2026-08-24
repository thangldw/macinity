# Toolbox Privacy

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

Toolbox has no account, telemetry, advertising SDK, analytics endpoint, or built-in cloud synchronization. Scans, snapshots, file hashes, photo features, evidence, activity, and recovery manifests are processed on the Mac and stored under `~/Library/Application Support/Toolbox`.

Depending on the workflow and granted permissions, Toolbox may read filesystem metadata, allocated sizes, image features/metadata, project markers, application bundle metadata, code-signing identifiers, package receipts, system registration data, and FSEvents. It does not upload file contents or declare software malicious. Full Disk Access is optional; inaccessible paths are shown as reduced coverage.

Mutations occur only after foreground review. Recoverable file operations use Trash and record original/Trash paths. Project roots and export destinations are user-selected. Redacted exports replace the current home prefix with `~`; review reports before sharing.

First launch may inspect legacy `Diskora`, `MacCleaner`, and `Changeora` Application Support JSON. Import is opt-in, copy-then-verify, and does not modify or delete legacy files. Settings may replace a legacy scheduled-scan plist only after confirmation and successful Toolbox bootstrap.

The app makes no automatic update request. When the user clicks **Check for Updates**, Toolbox sends a GET request to `https://api.github.com/repos/thangldw/toolbox/releases/latest` with standard HTTP headers. It sends no paths, scan results, evidence, file metadata, or device fields, and the action is blocked during a scan.

## Tiếng Việt

Toolbox không có tài khoản, telemetry, SDK quảng cáo, analytics endpoint hoặc cloud sync tích hợp. Scan, snapshot, hash, đặc trưng ảnh, evidence, activity và recovery manifest được xử lý trên máy Mac và lưu tại `~/Library/Application Support/Toolbox`.

Tùy workflow/quyền, Toolbox có thể đọc metadata filesystem, dung lượng, đặc trưng/metadata ảnh, project marker, bundle/signing metadata, package receipt, system registration và FSEvents. App không upload nội dung file hoặc kết luận malware. Full Disk Access là tùy chọn; path không đọc được hiển thị là coverage giảm.

Mutation chỉ xảy ra sau review foreground. Thao tác có thể khôi phục dùng Trash. Migration dữ liệu Diskora/MacCleaner/Changeora là opt-in, copy-then-verify và không sửa/xóa file cũ. Thay lịch quét cũ cần xác nhận và chỉ gỡ plist cũ sau khi Toolbox bootstrap thành công.

App không tự check update. Khi người dùng bấm nút, Toolbox chỉ GET endpoint GitHub công khai nêu ở phần English, không gửi path, kết quả scan, evidence, metadata file hoặc field thiết bị, và bị chặn trong lúc scan.

## 日本語

Toolbox には account、telemetry、広告 SDK、analytics endpoint、内蔵 cloud sync がありません。Scan、snapshot、hash、photo feature、evidence、activity、recovery manifest は Mac 上で処理され、`~/Library/Application Support/Toolbox` に保存されます。

Workflow と permission に応じて filesystem metadata、size、image metadata/feature、project marker、bundle/signing metadata、package receipt、system registration、FSEvents を読み取ります。File content を upload せず、malware 判定を行いません。Full Disk Access は任意で、読めない path は reduced coverage として表示します。

Mutation は foreground review 後だけです。Legacy migration は opt-in の copy-then-verify で旧 file を変更・削除しません。Update request は自動実行せず、user が button を押した場合だけ English セクションの public GitHub endpoint に GET し、scan/path/evidence/device data を送りません。
