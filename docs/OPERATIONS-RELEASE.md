# Macinity release operations

## English

### Current release contract

Macinity3.1.0/v3.1.0 is the current stable target. The user explicitly authorized ad-hoc signing and not-notarized disclosure. release.json and Info.plist must agree; ZIP/DMG names, first-launch guide, website and release notes must identify the same product/version. Historical Toolbox tags remain immutable on GitHub.

### Validation and packaging

Complete source tests/smokes/format/locales/docs/site, universal bundle and ad-hoc structural checks. Mount the DMG read-only to verify Macinity.app, Applications link and first-launch guide; verify checksum after final DMG bytes. Record known unverified native/hardware/resource limits without substituting old candidates. No signing identity or credentials are required for the authorized ad-hoc channel.

### Publication and update

Publish from an exact reviewed source commit/tag and immutable assets/checksum. The release workflow only supports v3.1.0 and runs checks before publication; Pages publishes the maintained site from main. Check GitHub latest release and Pages rendered content after completion. If an upload outcome is uncertain, inspect existing release assets before retrying. [Release notes](launch/macinity-3.1.0.md), [readiness](production/RELEASE-READINESS.md).

## Tiếng Việt

### Current release contract

Macinity 3.1.0/v3.1.0 là stable target hiện tại. Người dùng đã chọn ký ad-hoc và ghi rõ chưa notarized. release.json, Info.plist, tên artifact, first-launch guide, website và release notes phải cùng product/version. Giữ nguyên các tag Toolbox trước đây trên GitHub.

### Validation and packaging

Hoàn tất tests, smokes, format, locale, docs, site, universal build và kiểm tra chữ ký ad-hoc. Mount DMG read-only để kiểm tra Macinity.app, link Applications và first-launch guide; xác minh checksum của byte DMG cuối cùng. Ghi rõ gate native/hardware/resource chưa xác minh; không thay bằng kết quả candidate cũ. Kênh ad-hoc đã chọn không yêu cầu signing identity hoặc credentials.

### Publication and update

Phát hành từ commit/tag đã review, với artifact và checksum cố định. Workflow hỗ trợ v3.1.0 và chạy kiểm tra trước khi publish; Pages phát hành site từ main. Sau khi hoàn tất, kiểm tra GitHub latest release và nội dung Pages thực tế. Nếu chưa rõ upload thành công hay không, đọc danh sách asset trước khi retry. Xem [release notes](launch/macinity-3.1.0.md) và [readiness](production/RELEASE-READINESS.md).

## 日本語

### Current release contract

現在のstable targetはMacinity 3.1.0/v3.1.0です。ユーザーはad-hoc署名と未notarizedの明示を選択しました。release.json、Info.plist、artifact名、first-launch guide、website、release notesのproduct/versionを一致させます。以前のToolbox tagsはGitHubで変更しません。

### Validation and packaging

Tests、smokes、format、locale、docs、site、universal buildとad-hoc検証を完了します。DMGをread-onlyでmountし、Macinity.app、Applications linkとfirst-launch guideを確認して、最終DMG bytesのchecksumを検証します。未確認のnative/hardware/resource gatesを明示し、以前のcandidateの結果で代用しません。選択されたad-hoc channelにsigning identityやcredentialsは不要です。

### Publication and update

Review済みcommit/tagから変更しないartifact/checksumを公開します。Workflowはv3.1.0に対応し、publish前に検証します。Pagesはmainからsiteを公開します。完了後、GitHub latest releaseと実際に描画されたPagesを確認します。Upload結果が不明な場合は、retry前に既存assetを確認します。[Release notes](launch/macinity-3.1.0.md)と[readiness](production/RELEASE-READINESS.md)を参照してください。
