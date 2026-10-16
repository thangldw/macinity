# Macinity Privacy

## English

### Local processing and stored data

Macinity has no account, telemetry, advertising SDK, analytics or cloud sync. Filesystem metadata/hashes, image features, installer FSEvents, package receipts, application registrations, processes, hardware and network observations are read only within OS permissions and selected workflow coverage. Dropped installers are identified, never mounted or executed by Macinity.

State remains under the existing Application Support directory for upgrade compatibility: cleanup/recovery history, change sessions/snapshots/evidence, storage checkpoints and migration state. Opt-in `health-history-v1.json` holds system CPU/memory/pressure/thermal and available mapped sensors, with availability/source/unit/timestamps; it excludes process names, paths and network endpoints. Retention is24h/7d, at most10080 records/36fields/24MiB. File budget can omit older observations sooner. Expired observations are removed on a successful later write; an app that does not run does not actively erase them. Corrupt/unknown/oversized files are preserved and block writes.

Sensor sessions contain at most360 points in memory until Quit. Alerts contain at most100 in-app events. Socket-change and network-path timelines are opt-in bounded session data, not disk identity history. Stop preserves a recording session; starting a new session replaces it. Existing management history stays until explicitly managed.

### Network activity

Check for Updates explicitly requests `https://api.github.com/repos/thangldw/macinity/releases/latest`; no scan report is attached. Wi-Fi/LAN tools run only explicit refresh/scan/probe operations. DNS resolution queries the system resolver; ICMP latency uses up to20 probes, and connection checks use optional gateway ICMP3 and TCP443 without application payload. Destinations/resolvers can observe ordinary connection metadata, source IP and queried hostnames. Numeric-IP diagnostics skip DNS. Nearby Wi-Fi uses CoreWLAN, with identities possibly redacted by macOS. No background bandwidth test, packet capture, firewall, network configuration change or automatic upload is provided.

### Permissions and exports

Optional Full Disk Access expands filesystem coverage. Location permission is requested by a dedicated button for Wi-Fi identity coverage; Local Network permission may be requested by macOS during probes. Notifications require explicit permission. None of these grants authorizes file deletion. Macinity does not read Wi-Fi passwords or bypass protected locations.

JSON/CSV/Markdown export shows a frozen preview and saves to the destination you choose. Health reports retain raw measurement units, missing values and timestamps. Diagnostic reports may contain process/application names, paths and numeric endpoints; replacing the home prefix is not full anonymization. Review the exact report before sharing. Macinity does not transmit it automatically.

### Controls and release trust

History, alerts, menu-bar monitoring and connection tracking default off. Turning history on does not enable background sampling; inactivity/sleep/missing observations create gaps. Cleanup requires foreground review and immediate path revalidation; eligible file moves use Trash. Recovery refuses to overwrite an occupied path. Scheduled management scans never delete automatically.

Macinity 3.1.0 uses an explicitly authorized ad-hoc-signed, unnotarized release channel. This is not Apple trust approval. The [Security policy](SECURITY.md) and [user guide](docs/USER-GUIDE.md) explain installation and known limits. Website links and external support destinations have their own privacy policies.

## Tiếng Việt

### Xử lý local và dữ liệu lưu

Macinity không có account/telemetry/advertising/analytics/cloud sync. Đọc metadata/hash filesystem, image features, FSEventsinstaller, receipt/registration, process/hardware/network trong quyền OS và coverage workflow. Installer thả vào chỉ được định danh, không mount/execute.

Dữ liệu giữ trong thư mục Application Support hiện có để tương thích nâng cấp: cleanup/recovery, change sessions/snapshots/evidence, storagecheckpoint/migration. `health-history-v1.json` opt-in lưu systemCPU/memory/pressure/thermal/sensor khả dụng, availability/source/unit/timestamp; không tênprocess/path/endpoint. Retention24h/7d, tối đa10080record/36field/24MiB; budget có thể bỏ record sớm. Expired bị loại trong write thành công sau đó; app không chạy không tự xóa. File corrupt/unknown/oversized giữ nguyên và chặn write.

Sensor session tối đa360point RAM tới Quit, alert tối đa100event. Socket-change/networkpath opt-in bounded/RAM, không identityhistorydisk. Stop giữ session; Start thay session cũ. History quản lý vẫn giữ tới khi được quản lý rõ ràng.

### Hoạt động mạng

Check for Updates theo nút GET `https://api.github.com/repos/thangldw/macinity/releases/latest`, không đính kèm scan report. Wi-Fi/LAN chỉ refresh/scan/probe explicit. DNS dùng system resolver; latency tối đa20ICMP; connectioncheck gatewayICMP3 tùy chọn/TCP443 không application payload. Đích/resolver có thể thấy metadata kết nối, source IP/hostname query. NumericIP bỏ DNS. Nearby dùngCoreWLAN, identity có thể bị OSẩn. Không backgroundspeedtest/packet capture/firewall/đổicấuhình/tựupload.

### Quyền và export

FullDiskAccess tùy chọn mở filesystemcoverage. Location qua nút riêng để đọc Wi-Fiidentity; macOS có thể xin LocalNetwork khi probe. Notification cần quyền riêng. Không quyền nào cấp quyền xóa file. Không đọc mật khẩu Wi-Fi/vượt protectedlocations.

Export JSON/CSV/Markdown preview chốt trước và lưu vào đích chọn. Health giữunit/missing/timestamp. Diagnostics có thể chứaprocess/app name/path/numeric endpoint; thayhome prefix không anonymize đầy đủ. Reviewreport trước chia sẻ; app không tự truyền.

### Điều khiển và trust release

History/alerts/menu-bar/connectiontracking mặc định off. Bật history không bật sampler nền; inactive/sleep/missing tạo gap. Cleanup cần foreground review/path revalidation; eligiblefile dùngTrash. Recovery không overwritepathoccupied. Scheduledscan không tự delete.

Macinity 3.1.0 kýad-hoc/chưa notarized theo lựa chọn rõ ràng, không Appletrustapproval. Xem [Security](SECURITY.md)/[userguide](docs/USER-GUIDE.md). Linkwebsite/external support có policy riêng.

## 日本語

### Local処理と保存データ

Account/telemetry/広告/analytics/cloud syncなし。OS権限とworkflowcoverage内でfilesystem metadata/hash、image features、installer FSEvents、receipt/registration、process/hardware/networkを読みます。Droppedinstallerをidentifyしますがmount/executeしません。

Upgrade互換のため既存Application Supportディレクトリにcleanup/recovery、changesession/snapshot/evidence、storagecheckpoint/migrationを保存。Opt-in`health-history-v1.json`はsystemCPU/memory/pressure/thermal/availablesensorとavailability/source/unit/timestampのみ、process name/path/endpointなし。Retention24h/7d、最大10080record/36field/24MiB。Budgetで早期省略可能、期限切れは後の成功writeで削除、非実行appは能動削除しません。Corrupt/unknown/oversizedfile保持・write停止。

Sensor session最大360pointはQuitまでRAM、alert最大100event。Socket-change/networkpathはopt-inbounded/sessionRAMでdiskidentityhistoryなし。Stopは保持、Startは以前sessionを置換。Managementhistoryは明示管理まで保持。

### Network動作

明示Check for Updatesは`https://api.github.com/repos/thangldw/macinity/releases/latest`へGET、scan report添付なし。Wi-Fi/LANは明示refresh/scan/probeのみ。DNSはsystem resolver、latency最大20ICMP、connectioncheckはoptionalgatewayICMP3/TCP443・application payloadなし。Destination/resolverに通常connectionmetadata/source IP/hostname queryが見える場合があります。NumericIPはDNS省略。NearbyはCoreWLAN、identityはOSredaction可能。Backgroundspeedtest/packet capture/firewall/設定変更/自動uploadなし。

### 権限とexport

OptionalFullDiskAccessはfilesystemcoverage拡大。Locationは専用buttonでWi-Fiidentity用、probe中にOSがLocalNetwork権限を要求する場合があります。Notificationは明示権限。権限は削除許可ではなくWi-Fipassword/protectedlocation回避なし。

JSON/CSV/Markdownは凍結preview後、選択先へ保存。Healthはunit/missing/timestamp保持。Diagnosticsはprocess/app name/path/numeric endpointを含む場合がありhome prefix置換は完全匿名化ではありません。共有前にreportをreview、自動送信なし。

### Controlとrelease trust

History/alerts/menu-bar/connectiontracking初期off。Historyを有効にしても背景samplingは開始せずinactive/sleep/missingはgap。Cleanupはforeground review/path revalidation、eligiblefileをTrashへ。Recoveryはoccupiedpathをoverwriteしません。Scheduledscanは自動deleteなし。

Macinity 3.1.0は明示承認されたad-hoc署名/unnotarizedでAppletrustapprovalではありません。[Security](SECURITY.md)/[userguide](docs/USER-GUIDE.md)参照。外部support/linkには別privacy policyがあります。

## Local development increment: action workflows

**English:** The unreleased Action Center / Smart Diagnostics / Work Profiles increment stores up to eight favorites in local preferences. Work Profiles extend the existing local preset file with selected audio device UIDs/names and optional Keep Awake duration. Audio enumeration does not record sound. Diagnostic reports (including selected process identities/names) and the latest 20 profile-run results stay in memory until Quit. Network diagnostics retain numeric configuration/signal observations, not SSIDs, addresses or DNS identities. Audio and window changes require an explicit reviewed profile run. See [scope and verification](docs/product/ACTION-WORKFLOWS.md).

**Tiếng Việt:** Đợt phát triển chưa phát hành lưu tối đa tám mục yêu thích trong tùy chọn cục bộ. Hồ sơ làm việc bổ sung UID/tên thiết bị âm thanh và thời gian giữ máy thức vào file preset hiện có. Liệt kê âm thanh không ghi âm. Báo cáo chẩn đoán (gồm tên/định danh tiến trình được chọn) và 20 kết quả chạy gần nhất chỉ giữ trong bộ nhớ đến khi thoát. Chẩn đoán mạng giữ số liệu cấu hình/tín hiệu, không giữ SSID, địa chỉ hay định danh DNS. Đổi âm thanh/bố cục chỉ xảy ra khi người dùng xác nhận chạy hồ sơ đã xem trước.

**日本語:** 未公開の開発更新では最大8件のお気に入りをローカル設定に保存します。既存presetに選択した音声機器のUID・名前とスリープ防止時間を追加します。音声一覧の取得は録音を伴いません。診断レポート（選択したプロセス名・識別情報を含む）と直近20件の実行結果は終了までメモリ内のみ保持します。ネットワーク診断は数値化した設定・信号のみ保持し、SSID・アドレス・DNS識別情報を保持しません。音声・配置変更は内容確認後の明示実行時のみ行います。
