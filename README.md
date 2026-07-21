# Thang Toolbox

Một monorepo dành cho những ứng dụng và tiện ích nhỏ, tập trung vào tính hữu ích, minh bạch và an toàn.

## Applications

| App | Mô tả | Phiên bản | Nền tảng |
| --- | --- | --- | --- |
| [Diskora](apps/diskora) | Phân tích và quản lý dung lượng — *See where your space goes.* | 1.0.0 | macOS 13+ |
| [Changeora](apps/changeora) | Theo dõi thay đổi sau khi cài app — *See what changed on your Mac.* | 1.0.0 | macOS 13+ |

<p>
  <img src="apps/diskora/Resources/AppIcon-1024.png" alt="Diskora icon" width="180">
  <img src="apps/changeora/Resources/AppIcon-1024.png" alt="Changeora icon" width="180">
</p>

## Cài đặt

Mỗi ứng dụng có hướng dẫn build và cài đặt riêng trong thư mục của nó. Các release miễn phí không được Apple notarize sẽ bao gồm:

- Mã nguồn tại Git tag tương ứng.
- Unsigned/ad-hoc signed ZIP.
- SHA-256 checksum để kiểm tra file tải về.

## Nguyên tắc

- Không telemetry hoặc gửi dữ liệu ra ngoài nếu chưa có sự đồng ý rõ ràng.
- Mọi thao tác xóa phải có xem trước và xác nhận.
- Ưu tiên Trash để có thể khôi phục.
- Công khai mã nguồn và quy trình build.
- Báo cáo lỗ hổng theo [SECURITY.md](SECURITY.md), không đăng dữ liệu nhạy cảm lên issue công khai.

## License

Mã nguồn được phát hành theo [MIT License](LICENSE), trừ khi một thư mục ứng dụng ghi rõ điều khác.

## Tài liệu

- [Kiến trúc monorepo, Diskora và Changeora](docs/ARCHITECTURE.md)
- [Quy trình phát hành](docs/RELEASING.md)
- [Đóng góp](CONTRIBUTING.md)
- [Bảo mật](SECURITY.md)
- [Quyền riêng tư](PRIVACY.md)
