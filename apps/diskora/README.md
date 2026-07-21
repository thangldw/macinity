# Diskora

**See where your space goes.**

Ứng dụng quản lý dung lượng macOS native, phát triển từ script `mac_cleaner.py` ban đầu. App có dọn nhanh an toàn, phân tích thư mục hoặc ổ đĩa, tìm tệp lớn và thống kê dữ liệu môi trường developer.

| Thông tin | Chi tiết |
| --- | --- |
| Tác giả | Thang |
| Phiên bản | 1.0.0 (Build 1) |
| Bản quyền | Copyright © 2026 Thang — MIT License. |

Xem [COPYRIGHT.md](COPYRIGHT.md) và [MIT License](../../LICENSE).

## Chức năng

- **Dọn nhanh:** cache, log, Thùng rác, dữ liệu build Xcode và cache package manager.
- **Phân tích dung lượng:** quét một thư mục hoặc ổ đĩa, thống kê loại dữ liệu, thư mục lớn nhất và tệp trên 100 MB.
- **Tệp trùng lặp:** nhóm theo kích thước rồi xác minh SHA-256 theo block, giữ lại bản mới nhất và chuyển bản được chọn vào Trash.
- Cảnh báo riêng trường hợp tên gần giống nhưng nội dung khác, và tên khác nhưng nội dung SHA-256 giống hệt.
- **Developer:** nhận diện Xcode Simulator, Device Support, Docker, nvm, pyenv, asdf, Conda, Android SDK, Gradle, CocoaPods và backup iPhone/iPad.
- **Ảnh tương tự:** dùng Apple Vision để nhóm ảnh chụp gần nhau, đề xuất bản chất lượng cao hơn và cho duyệt trước khi chuyển vào Trash.
- **Dọn chuyên sâu:** phân loại An toàn, Cần xem lại và Không xóa tự động.
- **Gỡ ứng dụng:** đối chiếu Bundle ID để tìm Application Support, Cache, Preferences, Logs và Containers còn sót.
- **Treemap và xu hướng:** trực quan hóa thư mục lớn và so sánh thay đổi giữa các lần quét.
- **Lịch sử:** lưu thao tác, dung lượng, đường dẫn gốc và trạng thái có thể khôi phục.
- Mở trực tiếp mọi kết quả trong Finder để kiểm tra trước khi xử lý.
- Ghi báo cáo đường dẫn bản giữ lại và bản chuyển vào Trash tại `~/Library/Application Support/Diskora/Reports`.

Màn hình Developer hiện chỉ thống kê và cảnh báo rủi ro. App không tự động xóa SDK/runtime cho đến khi có thể xác định phiên bản đang được dự án sử dụng.

## Chạy khi phát triển

Yêu cầu macOS 13 trở lên và Xcode Command Line Tools:

```bash
swift run Diskora
```

## Tạo ứng dụng `.app`

```bash
./scripts/build_app.sh
open "dist/Diskora.app"
```

File tạo ra nằm tại `dist/Diskora.app`. Script build ký ad-hoc để chạy trên máy local.

## Cài đặt miễn phí từ GitHub Release

Release miễn phí không có Apple Developer ID hoặc notarization. Sau khi tải `Diskora-1.0.0-macos-universal-unsigned.zip` hoặc bản ghi rõ kiến trúc máy:

1. So sánh SHA-256 với file `.sha256` đi kèm.
2. Giải nén và kéo `Diskora.app` vào Applications.
3. Thử mở app một lần.
4. Nếu macOS chặn, vào **System Settings → Privacy & Security → Open Anyway**.

Không tắt Gatekeeper toàn hệ thống và không chạy lệnh xóa quarantine từ nguồn không tin cậy. Cách minh bạch nhất là tự build từ source bằng các lệnh ở trên.

## Tạo gói release

```bash
./scripts/build_release.sh
```

Kết quả gồm unsigned ZIP và SHA-256 trong thư mục `release/`.

## Quyền truy cập macOS

macOS có thể chặn một số thư mục như Thùng rác. Nếu app báo lỗi quyền truy cập, vào **System Settings → Privacy & Security → Full Disk Access**, thêm `Diskora.app`, rồi mở lại app. Chỉ cấp quyền này nếu bạn tự build hoặc tin tưởng bản app đang dùng.

## Nguyên tắc an toàn

- Chỉ thao tác trong thư mục người dùng hiện tại.
- Chặn đường dẫn cố thoát ra ngoài thư mục người dùng.
- Chỉ xóa nội dung bên trong hạng mục, không xóa chính thư mục gốc.
- Xcode Archives và Thùng rác không được chọn mặc định.
- Hiện lỗi thay vì bỏ qua im lặng.

## Kiểm thử

```bash
./scripts/test_core.sh
```

Test sử dụng thư mục tạm, không chạm vào dữ liệu thật của người dùng và không yêu cầu cài XCTest.

## Kiến trúc và đóng góp

- [Kiến trúc](../../docs/ARCHITECTURE.md)
- [Quy trình release](../../docs/RELEASING.md)
- [Changelog](CHANGELOG.md)
- [Security policy](../../SECURITY.md)
- [Privacy](../../PRIVACY.md)
