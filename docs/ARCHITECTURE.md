# Kiến trúc Thang Toolbox

## Mục tiêu

Monorepo chứa các tiện ích nhỏ nhưng mỗi ứng dụng vẫn độc lập về mã nguồn, test, release và quyền truy cập. Phần dùng chung chỉ được trích xuất khi có ít nhất hai ứng dụng thực sự cần nó.

## Cấu trúc

```text
thang-toolbox/
├── apps/
│   ├── diskora/
│   │   ├── Sources/Diskora/
│   │   │   ├── App/
│   │   │   ├── Core/
│   │   │   ├── Features/
│   │   │   └── Views/
│   │   ├── Tests/
│   │   ├── Resources/
│   │   └── scripts/
│   └── changeora/
│       ├── Sources/Changeora/
│       │   ├── App/
│       │   ├── Core/
│       │   ├── Features/
│       │   └── Views/
│       ├── Tests/
│       ├── Resources/
│       └── scripts/
├── docs/
├── .github/workflows/
└── LICENSE
```

## Diskora

Diskora dùng kiến trúc MVVM nhẹ:

![Diskora architecture](diagrams/diskora-architecture.svg)

Các nguyên tắc bắt buộc:

- View không thực hiện filesystem I/O.
- ViewModel quản lý trạng thái và điều phối tác vụ nền.
- Service không phụ thuộc SwiftUI.
- Đường dẫn destructive phải được chuẩn hóa và kiểm tra phạm vi.
- Nhóm nguy hiểm không được chọn tự động.
- Mọi thao tác có thể phục hồi phải ưu tiên Trash.

## Release flow

![Diskora free release flow](diagrams/diskora-release-flow.svg)

Hai sơ đồ sử dụng phong cách whiteboard: card pastel, connector cong và ghi chú như sticky note, nhưng được lưu trực tiếp trong Git để review và version-control.

## Changeora

Changeora dùng cùng nguyên tắc MVVM nhẹ nhưng toàn bộ pipeline là read-only:

![Changeora snapshot flow](diagrams/changeora-snapshot-flow.svg)

- `SystemSnapshotScanner` thu thập metadata trong một danh sách vị trí hữu hạn.
- `SnapshotDiffEngine` là hàm thuần, không truy cập filesystem.
- `ChangeoraViewModel` chạy scan ngoài main actor và chỉ cập nhật UI trên main actor.
- `SnapshotStore` ghi JSON nguyên tử vào Application Support.
- View không quét filesystem và không tự thực hiện hành động hệ thống.
- Risk classification là mức ưu tiên review, không phải đánh giá malware.
- Không có chức năng destructive hoặc network client trong phiên bản 1.0.0.
