# Toolbox operations / Vận hành / 運用

## English

Run `swift format lint --recursive --parallel Sources Tests Package.swift`, `./scripts/test_core.sh` and `swift build` inside each application directory. Build unsigned local packages only after tests pass. The consolidated release tag is `v1.0.0`; GitHub-hosted build workflows are intentionally removed.

## Tiếng Việt

Trong từng thư mục app, chạy `swift format lint --recursive --parallel Sources Tests Package.swift`, `./scripts/test_core.sh` và `swift build`. Chỉ build package local unsigned sau khi test đạt. Tag hợp nhất là `v1.0.0`; workflow build hosted đã được xóa.

## 日本語

各アプリで `swift format lint --recursive --parallel Sources Tests Package.swift`、`./scripts/test_core.sh`、`swift build` を実行します。テスト成功後のみ未署名ローカルパッケージを作成します。統合タグは `v1.0.0` で、hosted build workflow は削除済みです。
