# Toolbox Operations

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Validation

From `apps/toolbox`:

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
```

If `xcode-select -p` points to Command Line Tools and `swift test` reports `no such module XCTest`, the smoke/release gates remain valid local evidence, but merge/release still requires the full GitHub Actions XCTest job.

### Scheduled scan

Toolbox creates `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist` only after explicit GUI confirmation and notification authorization. It opens Toolbox with the internal `--scheduled-scan` argument, scans safe targets, posts a local notification, and exits without mutation.

Settings detects `com.thang.diskora.scheduled-scan.plist`. Replacement order is: write Toolbox plist → bootstrap Toolbox label → boot out legacy label → remove legacy plist. A Toolbox bootstrap failure removes the new plist, retains the legacy plist, and reports the launchctl error.

### Update checks

Settings performs no automatic update request. The button sends a GET request only to:

```text
https://api.github.com/repos/thangldw/toolbox/releases/latest
```

It sends no paths, evidence, scan results, or device fields and refuses to start while a scanner is registered active.

### Release artifact

The public artifact is `Toolbox-2.0.0.dmg` plus `Toolbox-2.0.0.dmg.sha256`. The explicit exception for `v2.0.0` permits a universal (`arm64` + `x86_64`), ad-hoc-signed, unnotarized stable artifact with clear disclosure and safe **Open Anyway** guidance in the DMG, website, and onboarding. Gatekeeper rejection is expected and recorded for this version. Later public releases return to the default requirement: Developer ID signing, notarization, stapling, and Gatekeeper acceptance. Local `build_app.sh` is structural evidence only.

Required release checks:

```bash
lipo -info dist/Toolbox.app/Contents/MacOS/Toolbox
codesign --verify --deep --strict --verbose=2 dist/Toolbox.app
spctl --assess --type execute --verbose=4 dist/Toolbox.app
shasum -a 256 Toolbox-2.0.0.dmg
```

For `v2.0.0`, the `spctl` command above must reject the app; do not report that expected result as Gatekeeper acceptance. The complete exception, protected-keychain, notarization, local DMG, and post-publication procedures are in [OPERATIONS-RELEASE.md](OPERATIONS-RELEASE.md).

Do not publish or replace an asset until the exact artifact has passed CI, checksum verification after re-download, and DMG mount/launch smoke. The explicit `v2.0.0` exception additionally requires verification of its ad-hoc signature, universal slices, embedded first-launch guide, and expected Gatekeeper rejection. All later releases also require notarization/stapling. Credentials and Developer ID material remain protected release secrets.

Never replace a published binary silently. Mark a bad release unavailable, explain the impact, and publish a patch version. Use [SECURITY.md](../SECURITY.md) for vulnerabilities. Historical Diskora/Changeora source and assets remain in tags through `v1.4.0`; Toolbox 2.0 does not rebuild or mutate them.

## Tiếng Việt

Chạy toàn bộ command phần English trong `apps/toolbox`. Nếu Command Line Tools thiếu XCTest, smoke/release build là evidence local nhưng merge/release vẫn phải chờ job XCTest trên GitHub Actions.

Lịch quét chỉ được tạo sau xác nhận GUI và cấp Notification. Label mới là `com.thang.toolbox.scheduled-scan`; job chỉ scan, gửi notification và thoát. Khi thay lịch Diskora, Toolbox bootstrap label mới trước rồi mới bootout/xóa plist cũ. Bootstrap thất bại phải giữ nguyên plist cũ và hiển thị lỗi thật.

Update check không tự chạy, chỉ GET endpoint GitHub công khai ghi ở phần English, không gửi path/evidence/kết quả scan/thông tin thiết bị và bị chặn khi có scanner active.

Artifact public là `Toolbox-2.0.0.dmg` và checksum SHA-256. Ngoại lệ riêng cho `v2.0.0` cho phép bản stable universal ký ad-hoc, chưa notarize, có công bố rõ và hướng dẫn **Open Anyway** an toàn; Gatekeeper rejection là kết quả dự kiến phải ghi nhận. Release sau `v2.0.0` quay lại yêu cầu Developer ID signing, notarization, stapling và Gatekeeper acceptance. Mọi release vẫn phải qua CI, re-download checksum và DMG launch smoke.

Không thay binary đã publish một cách im lặng. Gỡ khả dụng bản lỗi, mô tả ảnh hưởng và phát hành patch. Source/asset Diskora và Changeora lịch sử vẫn ở tag đến `v1.4.0`.

## 日本語

`apps/toolbox` で English セクションの全 validation command を実行します。Command Line Tools に XCTest がない場合、local smoke/release build は有効ですが、merge/release には GitHub Actions の XCTest 成功が必要です。

Scheduled scan は GUI confirmation と notification authorization 後だけ作成され、`com.thang.toolbox.scheduled-scan` で scan・通知のみを実行します。Legacy replacement は新 label の bootstrap 成功後に旧 label/plist を削除します。失敗時は旧 plist を保持して exact error を表示します。

Update check は自動実行せず、English セクションの public GitHub endpoint だけを GET します。Path、evidence、scan result、device field は送信せず、scan 中は開始しません。

Public artifact は `Toolbox-2.0.0.dmg` と SHA-256 です。`v2.0.0` だけは明示的な例外として universal、ad-hoc 署名、未 notarize の stable artifact を許可し、安全な **Open Anyway** 手順を同梱します。Gatekeeper rejection は記録すべき expected result です。以後の release は Developer ID signing、notarization、stapling、Gatekeeper acceptance を再び必須とします。公開後の binary を黙って差し替えず、問題時は patch release を作成します。
