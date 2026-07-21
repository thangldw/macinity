# Contributing

Cảm ơn bạn muốn đóng góp cho Thang Toolbox.

1. Tạo issue mô tả lỗi hoặc đề xuất trước những thay đổi lớn.
2. Tạo branch ngắn gọn từ `main`.
3. Không đưa dữ liệu cá nhân, cache thật hoặc thông tin máy người dùng vào test fixture.
4. Chạy test của ứng dụng bị thay đổi trước khi mở pull request.
5. Giải thích rõ mọi thao tác filesystem, quyền truy cập và khả năng khôi phục.

Với Diskora:

```bash
cd apps/diskora
./scripts/test_core.sh
swift build
```

Với Changeora:

```bash
cd apps/changeora
./scripts/test_core.sh
swift build
```

Pull request liên quan đến xóa dữ liệu phải có test cho giới hạn đường dẫn và trường hợp lỗi quyền truy cập.

## Sử dụng GitHub Actions tiết kiệm

- CI không tự chạy khi push trực tiếp vào `main`.
- CI chỉ chạy cho Pull Request có thay đổi Diskora, hoặc khi được kích hoạt thủ công.
- Commit mới trong cùng Pull Request sẽ hủy lượt CI cũ đang chạy.
- Hãy chạy smoke test và `swift build` local trước khi mở Pull Request.
