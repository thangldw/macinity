# Changeora

**See what changed on your Mac.**

Ứng dụng macOS native tạo snapshot trước và sau khi cài hoặc cập nhật phần mềm, sau đó giải thích những thay đổi có thể quan sát được. Changeora tập trung vào bằng chứng kỹ thuật, không tự động xóa, tắt service hoặc kết luận một ứng dụng là độc hại.

| Thông tin | Chi tiết |
| --- | --- |
| Tác giả | Thang |
| Phiên bản | 1.0.0 (Build 1) |
| Bản quyền | Copyright © 2026 Thang — MIT License. |

Xem [COPYRIGHT.md](COPYRIGHT.md) và [MIT License](../../LICENSE).

## Chức năng

- Chụp snapshot trước và sau một lần cài đặt hoặc cập nhật.
- Theo dõi ứng dụng, LaunchAgent, LaunchDaemon, privileged helper và system extension.
- Quan sát metadata cấp cao trong Application Support, Cache, Preferences và app containers.
- Phân loại thay đổi thành Thông tin, Nên xem và Quan trọng.
- Đối chiếu Bundle ID, Team ID, version, code-signing status và label để gợi ý chủ sở hữu.
- Lưu tối đa 100 phiên tại máy và khôi phục phiên đang theo dõi sau khi mở lại app.
- Tìm kiếm theo tên, đường dẫn hoặc chủ sở hữu.
- Export báo cáo Markdown để review hoặc đính kèm issue.
- Mở kết quả trong Finder để người dùng tự kiểm tra.

## Luồng sử dụng

1. Mở Changeora và chọn **Chụp trạng thái ban đầu**.
2. Cài hoặc cập nhật ứng dụng như bình thường.
3. Quay lại Changeora, chọn **Hoàn tất và so sánh**.
4. Xem thay đổi theo mức rủi ro và export báo cáo nếu cần.

![Changeora snapshot flow](../../docs/diagrams/changeora-snapshot-flow.svg)

## Chạy khi phát triển

Yêu cầu macOS 13+, Swift 6 và Xcode Command Line Tools.

```bash
cd apps/changeora
swift run
```

## Kiểm tra

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
```

Smoke test tạo một filesystem fixture tạm và xác minh scan, diff, risk classification, attribution cùng persistence. Test không đọc hoặc sửa cấu hình thật của máy.

## Build ứng dụng

```bash
cd apps/changeora
./scripts/build_app.sh
open dist/Changeora.app
```

## Tạo release miễn phí

```bash
cd apps/changeora
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

Artifact được ad-hoc signed với Hardened Runtime nhưng không có Developer ID và không được Apple notarize. Người nhận có thể cần dùng **Privacy & Security → Open Anyway**, hoặc tự build từ source.

## Dữ liệu và quyền riêng tư

Changeora lưu dữ liệu tại `~/Library/Application Support/Changeora`:

- `active-snapshot.json`: snapshot của phiên đang theo dõi.
- `sessions.json`: tối đa 100 báo cáo đã hoàn tất.

App không có telemetry, tài khoản, quảng cáo hoặc network client. Changeora đọc metadata đường dẫn, timestamp, kích thước, bundle metadata và chữ ký; không đọc nội dung tài liệu cá nhân. Một số vị trí được macOS bảo vệ có thể không quan sát đầy đủ nếu chưa cấp Full Disk Access.

## Giới hạn 1.0.0

- Không phải antivirus hoặc malware scanner.
- Không tự động rollback, xóa file hoặc vô hiệu hóa background service.
- Snapshot không phải ảnh toàn bộ filesystem; chỉ bao phủ các vị trí có giá trị cho attribution.
- Một ứng dụng có thể thay đổi dữ liệu ngoài phạm vi hoặc sau khi phiên đã kết thúc.
- Timestamp của cache và preference có thể thay đổi do hoạt động bình thường của ứng dụng khác.
- Code-signing hợp lệ chỉ xác nhận tính toàn vẹn/chủ thể ký, không chứng minh phần mềm an toàn.

## Tạo lại icon

Icon đã được commit sẵn. Script `scripts/make_icon.py` chỉ cần khi thay artwork nguồn và yêu cầu Python với Pillow; quá trình build app thông thường không phụ thuộc Python.
