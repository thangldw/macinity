# Orven for macOS

## English

### Orven 3.0

Orven brings live Mac monitoring, hardware observations, Wi-Fi/LAN diagnostics and recoverable storage management into one native macOS app. It is the renamed successor to Toolbox, with a new ring icon and interface. English, Vietnamese, Japanese and Simplified Chinese are available.

### Install and release status

Orven 3.0.0 is being prepared for production. Use the [release page](https://github.com/thangldw/toolbox/releases) for published assets; a local build is not a published download. The release is ad-hoc signed and **not notarized**. macOS may require **System Settings → Privacy & Security → Open Anyway** after the first blocked launch. Do not disable Gatekeeper or remove quarantine. Requirements: macOS 13+, ARM64 or x86_64; physical Intel/macOS13 verification remains incomplete. Homebrew installation is unavailable.

Download the DMG and matching SHA-256 file, verify the checksum, open the disk image, read the first-launch guide and drag Orven.app into Applications. Retain your data when upgrading: bundle ID `com.thang.toolbox` and `~/Library/Application Support/Toolbox` intentionally remain unchanged.

### What you can do

- Live monitoring: process identities and trends, CPU/memory, disk/network rates, battery/thermal and optional menu-bar status.
- Hardware: machine profile, available mapped CPU/GPU temperatures, fan RPM, battery temperature and observed system power, with freshness and missing readings.
- Wi-Fi/LAN: interface/IP/gateway/DNS/media/carrier observations, Wi-Fi signal/channel/link rate and explicit nearby scans.
- Network measurements: destination DNS/TCP443 checks and 20-probe ICMP latency/loss/jitter by button; cancel and retained timestamps.
- Health: default-off bounded local history, median baselines, session sensor charts/JSON/CSV and opt-in in-app alerts.
- Network changes: opt-in session connection/path observations; no packet capture or firewall.
- Storage/projects: folder allocation, duplicate candidates, selected-root rebuildable artifacts, developer workspace and growth checkpoints.
- Applications: dossiers and evidence-linked leftovers; evidence is not deletion permission. CPU priority changes require explicit review.
- Changes/recovery: installer evidence, comparisons, reviewed eligible moves to Trash and recovery to an unoccupied original path.

### Privacy and limits

No account, telemetry, analytics, automatic deletion or cloud sync. Explicit network probes contact the destinations you enter; update checking contacts GitHub. History is optional and bounded. Permissions expand coverage, never authorize deletion. Physical sensor mappings are model dependent; link rate is not Internet speed, snapshots do not establish exclusive bytes, and connection observations are not a firewall. See [Privacy](PRIVACY.md), [Security](SECURITY.md) and [release readiness](docs/production/RELEASE-READINESS.md) for executed checks and remaining limits.

### Build, contribute and documentation

Build with Swift 6 and full Xcode. From `apps/toolbox`, run `swift test`, `./scripts/test_monitoring.sh`, `./scripts/lint_localizations.swift`, `./scripts/build_universal.sh` and `./scripts/build_dmg.sh`. The resulting app is `dist/Orven.app`; the internal executable/module names remain Toolbox for compatibility. Verify with `./scripts/verify_release.sh --allow-adhoc`; this checks structural integrity, not Apple notarization.

Read [User guide](docs/USER-GUIDE.md), [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md), [Release operations](docs/OPERATIONS-RELEASE.md), [Contributing](CONTRIBUTING.md) and [Changelog](CHANGELOG.md). Website: [Orven](https://thangldw.github.io/toolbox/). Previous Toolbox releases remain in GitHub's immutable tag/release history. [MIT license](LICENSE).

## Tiếng Việt

### Orven 3.0

Orven hợp nhất giám sát Mac, quan sát phần cứng, chẩn đoán Wi-Fi/LAN và quản lý dung lượng có khôi phục trong app macOS native. Đây là tên mới của Toolbox, với ring icon và giao diện mới. Hỗ trợ Anh, Việt, Nhật và Trung giản thể.

### Cài đặt và trạng thái release

Orven 3.0.0 đang được chuẩn bị cho production. Tải artifact đã công bố từ [release page](https://github.com/thangldw/toolbox/releases); local build không phải download đã phát hành. Release ký ad-hoc và **chưa notarize**. Khi lần mở đầu bị chặn, macOS có thể yêu cầu **System Settings → Privacy & Security → Open Anyway**. Không tắt Gatekeeper/xóa quarantine. Yêu cầu macOS 13+, ARM64/x86_64; kiểm chứng Intel/macOS13 vật lý còn thiếu. Chưa có Homebrew.

Tải DMG và SHA-256 cùng phiên bản, xác minh checksum, mở disk image, đọc hướng dẫn và kéo Orven.app vào Applications. Khi nâng cấp giữ dữ liệu: bundle ID `com.thang.toolbox` và `~/Library/Application Support/Toolbox` được giữ nguyên có chủ đích.

### Chức năng

- Giám sát: identity/trend process, CPU/memory, tốc độ disk/network, battery/thermal, menu-bar tùy chọn.
- Phần cứng: profile máy, nhiệt độ CPU/GPU mapped khả dụng, RPM quạt, nhiệt pin/công suất hệ thống quan sát; freshness/missing rõ ràng.
- Wi-Fi/LAN: interface/IP/gateway/DNS/media/carrier, signal/channel/link rate và nearby scan theo nút.
- Phép đo mạng: DNS/TCP443 tới đích nhập và20probe ICMP latency/loss/jitter; cancel và timestamp kết quả cũ.
- Health: history local bounded mặc định tắt, baseline median, sensor chart phiên/JSON/CSV, in-app alert opt-in.
- Thay đổi mạng: connection/path observations trong RAM phiên opt-in; không packet capture/firewall.
- Storage/projects: allocation thư mục, duplicate candidates, artifact rebuildable trong root đã chọn, developer workspace/growth checkpoints.
- Applications: dossier/leftover có evidence; evidence không phải quyền xóa. Đổi priority CPU cần review rõ ràng.
- Changes/recovery: evidence installer/comparison, duyệt trước khi chuyển file đủ điều kiện vào Trash, restore khi path gốc trống.

### Privacy và giới hạn

Không account/telemetry/analytics/tự xóa/cloudsync. Probe explicit kết nối đích bạn nhập; checkupdate kết nối GitHub. History tùy chọn/bounded. Quyền mở coverage không cấp quyền xóa. Mapping sensor theo model; linkrate không Internet speed, snapshot không proofexclusivebytes, quan sát connection không firewall. [Privacy](PRIVACY.md), [Security](SECURITY.md), [release readiness](docs/production/RELEASE-READINESS.md) ghi checks đã chạy và giới hạn.

### Build, đóng góp và tài liệu

Build bằng Swift 6 và bộ Xcode đầy đủ. Từ `apps/toolbox`, chạy `swift test`, `./scripts/test_monitoring.sh`, `./scripts/lint_localizations.swift`, `./scripts/build_universal.sh`, `./scripts/build_dmg.sh`. App là `dist/Orven.app`; tên executable/module Toolbox giữ để tương thích. `./scripts/verify_release.sh --allow-adhoc` kiểm tra tính toàn vẹn của bộ cài, không chứng minh notarization.

Xem [User guide](docs/USER-GUIDE.md), [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md), [Release operations](docs/OPERATIONS-RELEASE.md), [Contributing](CONTRIBUTING.md), [Changelog](CHANGELOG.md), [website Orven](https://thangldw.github.io/toolbox/). Release Toolbox trước đó giữ trong tag/release history trên GitHub. [MIT](LICENSE).

## 日本語

### Orven 3.0

OrvenはMacのライブ監視、ハードウェア観測、Wi-Fi/LAN診断、復元可能なストレージ管理を統合したnative macOS appです。Toolboxの後継で、名前・ring icon・画面を刷新。英語、ベトナム語、日本語、簡体字中国語に対応します。

### インストールとrelease状況

Orven3.0.0はproduction向け準備中です。[Release page](https://github.com/thangldw/toolbox/releases)に公開されたartifactを使用してください。Localbuildは公開downloadではありません。Ad-hoc署名で**notarize されていません**。初回起動がblockedの場合、**System Settings → Privacy & Security → Open Anyway**が必要なことがあります。Gatekeeper無効化/quarantine削除はしません。macOS 13+/ARM64/x86_64、physicalIntel/macOS13検証は未完。Homebrewなし。

同versionのDMG/SHA-256をdownloadしてchecksum確認、diskimage内guideを読みOrven.appをApplicationsへ。Upgrade時のデータを保持するためbundleID `com.thang.toolbox`と`~/Library/Application Support/Toolbox`を意図的に維持します。

### 機能

- ライブ監視：processidentity/trend、CPU/memory、disk/networkrate、battery/thermal、optionalmenu-bar。
- Hardware：machineprofile、利用可能なmappedCPU/GPUtemp、fanRPM、batterytemp/観測systempower、freshness/missing表示。
- Wi-Fi/LAN：interface/IP/gateway/DNS/media/carrier、signal/channel/linkrate、明示nearby scan。
- Network測定：入力destinationのDNS/TCP443と20ICMPprobe latency/loss/jitter、cancel/以前のtimestamp保持。
- Health：初期offのboundedlocalhistory、medianbaseline、sessionchart/JSON/CSV、opt-inin-appalert。
- Networkchanges：opt-insessionconnection/path観測、packetcapture/firewallなし。
- Storage/projects：folderallocation/duplicatecandidate、選択root内rebuildableartifact、developerworkspace/growthcheckpoint。
- Applications：dossier/evidence-linkedleftover。Evidenceは削除許可ではなく、CPUpriority変更は明示reviewが必要。
- Changes/recovery：installerevidence/comparison、review後のeligibleTrash移動、元pathが空の場合のrestore。

### Privacyと制限

Account/telemetry/analytics/自動削除/cloudsyncなし。明示probeは入力先へ、updatecheckはGitHubへ接続。Historyはoptional/bounded。権限はcoverageを広げますが削除許可ではありません。Sensorはmodel依存、linkrateはInternet速度ではなくsnapshotのexclusivebytesやfirewallを証明しません。[Privacy](PRIVACY.md)、[Security](SECURITY.md)、[release readiness](docs/production/RELEASE-READINESS.md)に検証と制限を記載。

### Build・貢献・資料

Swift 6 và bộ Xcode đầy đủでbuild。`apps/toolbox`から`swift test`、`./scripts/test_monitoring.sh`、`./scripts/lint_localizations.swift`、`./scripts/build_universal.sh`、`./scripts/build_dmg.sh`。Appは`dist/Orven.app`、internalexecutable/moduleは互換性のためToolboxを維持。`./scripts/verify_release.sh --allow-adhoc`はstructuralintegrityでApple notarization証明ではありません。

[User guide](docs/USER-GUIDE.md)、[Architecture](docs/ARCHITECTURE.md)、[Operations](docs/OPERATIONS.md)、[Release operations](docs/OPERATIONS-RELEASE.md)、[Contributing](CONTRIBUTING.md)、[Changelog](CHANGELOG.md)、[website](https://thangldw.github.io/toolbox/)を参照。以前のToolboxreleaseはGitHubtag/releasehistoryで保持。[MIT](LICENSE)。
