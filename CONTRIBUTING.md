# Contributing to Toolbox

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

Keep changes focused on a concrete user outcome. Toolbox is local-first: mutations require explicit review, exact canonical targets, and Trash-backed recovery whenever macOS permits. Do not broaden deletion with globs, unresolved variables, name-only matching, or inferred project artifacts. Network features require an explicit privacy design and must never carry scan data.

Before review, run from `apps/toolbox`:

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
```

Add a failing regression before implementation when practical. Document user behavior, safety impact, test evidence, and UI screenshots. Update documentation English first, Vietnamese second, Japanese third. New GUI copy must work in both in-app languages and new icon-only controls need VoiceOver labels.

Use short imperative commits such as `feat: add conflict-safe restore`. Never commit build output, personal reports, credentials, signing identities, or notarization secrets.

## Tiếng Việt

Giữ thay đổi tập trung vào kết quả người dùng cụ thể. Toolbox chạy local: mutation cần duyệt rõ ràng, canonical target chính xác và dùng Trash khi macOS cho phép. Không mở rộng phạm vi xóa bằng glob, biến chưa resolve, name-only matching hoặc suy đoán artifact project. Tính năng mạng phải có thiết kế privacy rõ ràng và không được gửi dữ liệu scan.

Trước review, chạy toàn bộ command phần English trong `apps/toolbox`, thêm regression đỏ trước implementation khi phù hợp, ghi rõ hành vi/safety/test/screenshot và cập nhật tài liệu theo thứ tự English → Tiếng Việt → 日本語. GUI copy mới phải đủ hai ngôn ngữ trong app; control chỉ có icon cần VoiceOver label.

Không commit build output, báo cáo cá nhân, credential, signing identity hoặc notarization secret.

## 日本語

具体的な user outcome に scope を限定します。Toolbox は local-first で、mutation には明示的 review、exact canonical target、可能な場合は Trash recovery が必要です。Glob、未解決変数、名前だけの一致、推測した project artifact で削除範囲を広げません。Network feature は明示的 privacy design を持ち、scan data を送信してはいけません。

Review 前に `apps/toolbox` で English セクションの全 command を実行し、可能なら failing regression を先に追加します。Documentation は English → Vietnamese → Japanese の順で更新し、GUI copy は app 内 2 言語、icon-only control は VoiceOver label を必須にします。Build output、credential、signing identity、notarization secret を commit しません。
