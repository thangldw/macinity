# Macinity operations

## English

### Build and verify

Use full Xcode with a per-command DEVELOPER_DIR, Swift6 and macOS13deployment. Run all XCTest and smoke contracts, strict formatting and locale lint, then build_universal.sh/build_dmg.sh/verify_release.sh --allow-adhoc. Artifacts are Macinity.app and Macinity-3.1.0.dmg. The explicit exception for Macinity3.1.0 is ad-hoc/unnotarized; no Gatekeeper bypass command is permitted.

### Local data and cleanup

Keep bundle/data namespace stable. Do not reset corrupt stores automatically or silently seed history. Preserve skipped/missing/permission-reduced coverage. Scheduled scans do not delete; eligible cleanup and irreversible developer commands have distinct reviewed flows. [Installation trace](diagrams/install-trace-sequence.html) and [recovery](diagrams/review-recovery-state.html).

### Support and limitations

Report actual version, architecture, permission scope and fresh timestamps. Do not publish raw private diagnostic reports. See [user guide](USER-GUIDE.md), [readiness](production/RELEASE-READINESS.md), [privacy](../PRIVACY.md) and [release operations](OPERATIONS-RELEASE.md).

## Tiếng Việt

### Build and verify

Dùng Xcode đầy đủ, `DEVELOPER_DIR` theo từng command, Swift 6 và deployment target macOS 13. Chạy XCTest, năm smoke contracts, strict format và locale lint; sau đó chạy `build_universal.sh`, `build_dmg.sh`, `verify_release.sh --allow-adhoc` trong apps/toolbox/scripts. Artifact là Macinity.app và Macinity-3.1.0.dmg. Macinity 3.1.0 được phép ký ad-hoc và ghi rõ chưa notarized; không dùng command bỏ qua Gatekeeper.

### Local data and cleanup

Giữ bundle ID và namespace dữ liệu. Không tự reset store bị hỏng hoặc tự tạo history giả. Hiển thị mẫu thiếu, mục bỏ qua và giới hạn quyền. Scheduled scans không xóa dữ liệu. Cleanup đủ điều kiện và developer commands không thể khôi phục phải có luồng duyệt riêng. Xem [Install Trace](diagrams/install-trace-sequence.html) và [recovery](diagrams/review-recovery-state.html).

### Support and limitations

Báo version, architecture, phạm vi quyền và timestamp thực. Không công bố báo cáo chẩn đoán riêng tư chưa duyệt. Xem [guide](USER-GUIDE.md), [readiness](production/RELEASE-READINESS.md), [privacy](../PRIVACY.md), [release operations](OPERATIONS-RELEASE.md).

## 日本語

### Build and verify

完全なXcode、commandごとの`DEVELOPER_DIR`、Swift 6、macOS 13 deployment targetを使用します。XCTest、五つのsmoke contracts、strict format、locale lintの後、apps/toolbox/scriptsの`build_universal.sh`、`build_dmg.sh`、`verify_release.sh --allow-adhoc`を実行します。ArtifactはMacinity.appとMacinity-3.1.0.dmgです。Macinity 3.1.0はad-hoc署名と未notarizedの明示を承認済みで、Gatekeeperを回避するcommandは使いません。

### Local data and cleanup

Bundle IDとdata namespaceを維持します。壊れたstoreの自動resetや架空historyの生成を行いません。Missing、skipped、permissionによるcoverage制限を保持します。Scheduled scansは削除しません。対象となるcleanupと不可逆なdeveloper commandsには、それぞれ明示reviewが必要です。[Install Trace](diagrams/install-trace-sequence.html)と[recovery](diagrams/review-recovery-state.html)を参照してください。

### Support and limitations

実際のversion、architecture、permission scopeとtimestampを報告します。未reviewのprivate diagnostic reportsを公開しません。[Guide](USER-GUIDE.md)、[readiness](production/RELEASE-READINESS.md)、[privacy](../PRIVACY.md)、[release operations](OPERATIONS-RELEASE.md)を参照してください。
