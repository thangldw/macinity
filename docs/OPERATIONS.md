# Toolbox operations / Vận hành / 運用

## English

Run `swift format lint --recursive --parallel Sources Tests Package.swift`, `swift test`, `./scripts/test_core.sh` and `swift build` inside each application directory. Build unsigned local packages only after tests pass. GitHub Actions repeats these checks for pushes and pull requests. Release assets contain only application archives and checksums; never upload separate source ZIP/TAR files. GitHub's automatic “Source code” links are managed by the platform and cannot be removed from a tag-based release.

## Tiếng Việt

Trong từng thư mục app, chạy `swift format lint --recursive --parallel Sources Tests Package.swift`, `swift test`, `./scripts/test_core.sh` và `swift build`. Chỉ build package local unsigned sau khi test đạt. GitHub Actions lặp lại các kiểm tra này cho push và pull request. Asset của release chỉ gồm gói ứng dụng và checksum; không upload riêng ZIP/TAR mã nguồn. Các liên kết “Source code” tự động do GitHub quản lý và không thể xóa khỏi release gắn tag.

## 日本語

各アプリで `swift format lint --recursive --parallel Sources Tests Package.swift`、`swift test`、`./scripts/test_core.sh`、`swift build` を実行します。テスト成功後のみ未署名ローカルパッケージを作成します。GitHub Actions でも push と pull request ごとに同じ検証を行います。リリース asset はアプリ本体と checksum のみにし、ソース ZIP/TAR は別途アップロードしません。GitHub が自動生成する「Source code」リンクは tag 付き release から削除できません。
