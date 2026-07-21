# Releasing / Phát hành / リリース

[Tiếng Việt](#vi) · [English](#en) · [日本語](#ja)

<a id="vi"></a>

## Tiếng Việt

### Chuẩn bị chung

1. Cập nhật version trong `AppMetadata.swift`, `Info.plist`, README và CHANGELOG của ứng dụng.
2. Chạy Swift format, smoke test và debug build.
3. Tạo artifact local và xác minh checksum.
4. Chỉ tạo tag sau khi working tree sạch và `main` đã được push.

### Diskora

```bash
cd apps/diskora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
```

Phát hành:

```bash
git tag -a diskora-v1.0.0 -m "Diskora 1.0.0"
git push origin diskora-v1.0.0
```

### Changeora

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

Phát hành:

```bash
git tag -a changeora-v1.0.0 -m "Changeora 1.0.0"
git push origin changeora-v1.0.0
```

### GitHub Actions và giới hạn miễn phí

- CI chỉ chạy cho Pull Request có thay đổi ứng dụng tương ứng hoặc khi kích hoạt thủ công.
- Push thông thường vào `main` không sử dụng runner macOS.
- Release workflow chỉ chạy khi tạo tag của ứng dụng hoặc kích hoạt thủ công.
- GitHub runner có full Xcode và tạo universal binary; máy chỉ có Command Line Tools tạo native binary.

Artifact được ad-hoc signed với Hardened Runtime nhưng không có Developer ID và không được Apple notarize. Người dùng phải xác minh SHA-256 và có thể cần dùng **Privacy & Security → Open Anyway**, hoặc tự build từ source.

---

<a id="en"></a>

## English

### Common preparation

1. Update the version in the application's `AppMetadata.swift`, `Info.plist`, README, and CHANGELOG.
2. Run Swift format, smoke tests, and a debug build.
3. Create a local artifact and verify its checksum.
4. Create a tag only after the working tree is clean and `main` has been pushed.

### Diskora

```bash
cd apps/diskora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
```

Release:

```bash
git tag -a diskora-v1.0.0 -m "Diskora 1.0.0"
git push origin diskora-v1.0.0
```

### Changeora

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

Release:

```bash
git tag -a changeora-v1.0.0 -m "Changeora 1.0.0"
git push origin changeora-v1.0.0
```

### GitHub Actions and free-tier limits

- CI runs only for Pull Requests that affect the corresponding application, or when manually dispatched.
- Ordinary pushes to `main` do not consume a macOS runner.
- A release workflow runs only for an application tag or manual dispatch.
- The GitHub runner has full Xcode and produces a universal binary; a machine with Command Line Tools only produces a native binary.

Artifacts are ad-hoc signed with Hardened Runtime but have no Developer ID signature and are not notarized by Apple. Users should verify SHA-256 and may need **Privacy & Security → Open Anyway**, or build from source.

---

<a id="ja"></a>

## 日本語

### 共通の準備

1. 対象アプリケーションの `AppMetadata.swift`、`Info.plist`、README、CHANGELOG の version を更新します。
2. Swift format、smoke test、debug build を実行します。
3. ローカル artifact を作成し、checksum を検証します。
4. working tree が clean で、`main` が push 済みであることを確認してから tag を作成します。

### Diskora

```bash
cd apps/diskora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Diskora-1.0.0-macos-*-unsigned.zip.sha256)
```

リリース:

```bash
git tag -a diskora-v1.0.0 -m "Diskora 1.0.0"
git push origin diskora-v1.0.0
```

### Changeora

```bash
cd apps/changeora
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
swift build
./scripts/build_release.sh
(cd release && shasum -a 256 -c Changeora-1.0.0-macos-*-unsigned.zip.sha256)
```

リリース:

```bash
git tag -a changeora-v1.0.0 -m "Changeora 1.0.0"
git push origin changeora-v1.0.0
```

### GitHub Actions と無料利用の制限

- 対象アプリケーションに変更がある Pull Request、または手動実行時のみ CI が動作します。
- `main` への通常の push では macOS runner を使用しません。
- Release workflow はアプリケーション用の tag、または手動実行時のみ動作します。
- GitHub runner は full Xcode を備え universal binary を生成します。Command Line Tools のみの端末では native binary を生成します。

Artifact は Hardened Runtime を有効にした ad-hoc 署名ですが、Developer ID 署名および Apple notarization はありません。SHA-256 を検証し、必要に応じて **プライバシーとセキュリティ → このまま開く** を使用するか、ソースからビルドしてください。
