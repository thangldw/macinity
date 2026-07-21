# Phát hành ứng dụng

## Diskora

### Chuẩn bị

1. Cập nhật version trong `AppMetadata.swift`, `Info.plist`, README và CHANGELOG.
2. Chạy `swift format lint`, smoke test và debug build.
3. Tạo release artifact local để kiểm tra.

```bash
cd apps/diskora
./scripts/test_core.sh
DISKORA_UNIVERSAL=1 ./scripts/build_release.sh
```

### Kiểm tra artifact

```bash
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
unzip -l release/Diskora-1.0.0-macos-*-unsigned.zip
```

### Phát hành

```bash
git tag diskora-v1.0.0
git push origin diskora-v1.0.0
```

Workflow `Release Diskora` xác minh tag trùng với `Info.plist`, chạy test, build và đính kèm ZIP cùng checksum vào GitHub Release.

Workflow không chạy cho commit hoặc push thông thường. Chỉ tạo tag khi thực sự muốn phát hành; dùng `workflow_dispatch` cho lần kiểm tra thủ công có chủ đích.

## Giới hạn của release miễn phí

Artifact được ad-hoc signed với Hardened Runtime nhưng không có Developer ID và không được Apple notarize. GitHub Actions có full Xcode nên tạo bản universal; máy chỉ có Command Line Tools sẽ tạo bản native và ghi kiến trúc trong tên file. Người dùng tải binary phải xác minh SHA-256 và dùng **Privacy & Security → Open Anyway**, hoặc tự build từ source.

## Changeora

### Kiểm tra và build local

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

### Phát hành

```bash
git tag changeora-v1.0.0
git push origin changeora-v1.0.0
```

Workflow Changeora chỉ chạy khi tạo tag `changeora-v*` hoặc được kích hoạt thủ công. Push thông thường vào `main` không sử dụng runner macOS.
