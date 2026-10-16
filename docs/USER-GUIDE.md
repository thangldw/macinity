# Macinity user guide

## English

Macinity 3.1.0 introduces the Cobalt Link identity and expands Orven into a native Mac workspace. Developed by [thangldw](https://thangldw.github.io/) & Codex.

- Action Center collects favorites and recent workflows; Smart Diagnostics explains observed CPU, memory, storage and network conditions. Work Profiles preview selected workspace, audio and Keep Awake actions.
- Utilities cover startup/background inventory, Keep Awake, external drives/file locks, ports, batch rename with preview/undo, SHA-256, folder comparison, package/runtime inspection and device/workspace management.
- Battery details and charge/discharge history, clearer sensor groups, independent Disk and Network screens, automatic application inventory and Wi-Fi access tools extend monitoring.
- English, Vietnamese, Japanese and Simplified Chinese; language and appearance live in Settings.

### Install and upgrade

Download Macinity-3.1.0.dmg and its SHA-256 file from the same published GitHub release. Run `shasum -a 256 -c Macinity-3.1.0.dmg.sha256`, open the DMG, read the included guide and drag Macinity.app into Applications. Ad-hoc signed, not notarized: if first launch is blocked, use System Settings → Privacy & Security → Open Anyway. Do not disable Gatekeeper. The old data namespace and bundle ID remain compatible; no data migration to a new Macinity folder is required.

### Observe your Mac

Overview and monitoring pages show observed CPU/memory, processes, disk/network rates and battery/thermal. Live requires an active main window; otherwise sampling pauses unless optional menu-bar monitoring is enabled. Hardware Inspector shows the machine profile and available mapped sensors. Missing readings and stale timestamps are meaningful; do not interpret them as zero. Sleep Inspector presents observed sleep-prevention assertions, not permission to kill a process.

### Wi-Fi and LAN

Choose Wi-Fi & LAN in the sidebar, select a tool and refresh explicitly. Overview/Ethernet show addresses, gateway/global DNS, media and carrier; UP/RUNNING flags are distinct from physical link detection. Wi-Fi shows signal/noise/SNR/channel/band/width and link rate when available. Identity may require Location permission. Nearby scans are explicit; channel counts/RSSI are not interference measurements.

For Connection Diagnostics or Latency & Stability, enter one hostname or numeric IP, then run the measurement. No URL, port, command options or credentials. DNS/TCP443/gateway stages report independent outcomes; numeric IPs skip DNS. ICMP20 reports loss/received mean/jitter with missing-sequence gaps. Stop cancels the owned operation and preserves earlier results. Connection/path timelines are opt-in session observations, not packet history or exact disconnect times.

### History, baseline and recording

Enable local health history deliberately; it defaults off and does not enable background monitoring. Retain24h/7d within record/byte budgets. After30–60 real observations, Capture Baseline stores reference medians; at least10 newer valid observations per metric are needed for comparison. Different workloads can explain differences.

Select15/30/60 minutes for a sensor recording, then Start. Stop preserves the session; Start replaces it, and Quit discards it. Sleep/inactivity create gaps or extend elapsed wall time. JSON/CSV export previews exactly what will be saved. Smart Alerts are opt-in; OS notification delivery depends on permission and a working OS service and remains unverified in current QA.

### Storage, projects and applications

Choose roots before scanning. Review allocated sizes, duplicate candidates, growth and rebuildable project artifacts. App Dossier links observations and leftovers; receipts and registrations do not authorize deletion. Eligible file cleanup requires review and Trash/recovery checks. Developer-tool cleanup commands are a separate explicit operation and may not use Trash or support Undo; review the exact command before confirming. Manual CPU priority lowering is not an automatic CPU cap.

### Changes, recovery and reports

Install Trace records bounded observations while you run the normal installation/update/uninstall flow. It never runs a dropped installer automatically. Compare snapshots/timeline evidence, review partial coverage, and export locally. Restore only when the original destination is unoccupied. Reports may include names, paths or endpoints; review before sharing.

### Limits and support

Mapped temperature labels vary by model; link rate is not Internet throughput. Hidden-space/snapshot explanations do not establish exclusive snapshot bytes. No firewall, fan control or privileged repair is included. Current foreground resources, physical Intel/macOS13/Ethernet, full VoiceOver, Japanese critical-copy review and native notification delivery remain unverified. See [release readiness](production/RELEASE-READINESS.md), [Privacy](../PRIVACY.md), [Security](../SECURITY.md) and [GitHub issues](https://github.com/thangldw/toolbox/issues).

## Tiếng Việt

Macinity 3.1.0 giới thiệu nhận diện Cobalt Link và mở rộng Orven thành không gian quản lý Mac native. Phát triển bởi [thangldw](https://thangldw.github.io/) & Codex.

- Action Center gom mục yêu thích và thao tác gần đây; Smart Diagnostics giải thích trạng thái CPU, bộ nhớ, dung lượng và mạng quan sát được. Work Profiles cho xem trước thao tác workspace, âm thanh và Keep Awake.
- Tiện ích gồm startup/background, Keep Awake, ổ ngoài/file đang mở, cổng, đổi tên hàng loạt có preview/hoàn tác, SHA-256, so sánh thư mục, package/runtime và quản lý thiết bị/workspace.
- Bổ sung thông tin pin/lịch sử sạc xả, nhóm cảm biến dễ đọc, tách Disk/Network, tự quét ứng dụng và tiện ích Wi-Fi.
- Hỗ trợ Anh, Việt, Nhật và Trung giản thể; ngôn ngữ/giao diện nằm trong Settings.

### Cài đặt và nâng cấp

Tải Macinity-3.1.0.dmg và SHA-256 từ cùng một release GitHub đã công bố. Chạy `shasum -a 256 -c Macinity-3.1.0.dmg.sha256`, mở DMG, đọc hướng dẫn và kéo Macinity.app vào Applications. App ký ad-hoc, chưa notarized. Nếu lần mở đầu bị chặn, dùng System Settings → Privacy & Security → Open Anyway; không tắt Gatekeeper. Bundle ID và thư mục dữ liệu cũ được giữ tương thích, không cần chuyển sang thư mục Macinity mới.

### Quan sát Mac

Overview và các trang giám sát hiển thị CPU, bộ nhớ, process, tốc độ disk/network, pin và thermal. Live cần cửa sổ chính đang hoạt động; nếu không, sampling tạm dừng trừ khi đã bật giám sát menu bar. Hardware Inspector hiển thị profile và cảm biến mapped khả dụng. Mẫu thiếu hoặc timestamp cũ không có nghĩa là giá trị bằng không. Sleep Inspector hiển thị các yêu cầu giữ máy thức, không phải quyền kill process.

### Wi-Fi và LAN

Chọn Wi-Fi & LAN trong sidebar, chọn công cụ rồi làm mới. Overview/Ethernet hiển thị địa chỉ, gateway, DNS toàn cục, media và carrier; UP/RUNNING khác với phát hiện kết nối vật lý. Wi-Fi hiển thị signal, noise, SNR, channel, band, width và link rate khi có dữ liệu. Tên mạng có thể cần quyền Location. Nearby scan chạy theo nút; số lượng mạng và RSSI không phải phép đo nhiễu.

Trong Connection Diagnostics hoặc Latency & Stability, nhập một hostname hoặc IP, không kèm URL, port, options hay credentials. DNS, TCP 443 và gateway có kết quả độc lập; IP số bỏ qua DNS. Phiên 20 phép đo ICMP hiển thị loss, mean, jitter và khoảng trống mẫu thiếu. Stop chỉ hủy tác vụ của Macinity, giữ kết quả trước đó. Timeline tùy chọn giữ quan sát trong RAM của phiên, không phải packet history hoặc thời điểm mất kết nối chính xác.

### History, baseline và recording

History cục bộ mặc định tắt. Bật tính năng này không bật sampling nền. Chọn giữ 24 giờ hoặc 7 ngày trong giới hạn dung lượng. Sau 30–60 quan sát thực, chọn Capture Baseline; so sánh trung vị cần ít nhất 10 quan sát mới hợp lệ cho mỗi metric. Workload khác nhau có thể giải thích chênh lệch.

Chọn 15/30/60 phút rồi Start. Stop giữ phiên, Start thay phiên, Quit bỏ phiên khỏi RAM. Sleep/inactive tạo khoảng trống và có thể kéo dài thời gian thực. Preview JSON/CSV đúng nội dung sẽ lưu. Smart Alerts tùy chọn; thông báo OS cần quyền và service thực tế, việc gửi đến người dùng chưa được xác minh.

### Storage, projects và applications

Chọn thư mục gốc trước khi quét. Duyệt allocation, duplicates, growth và artifacts có thể tạo lại. App Dossier liên kết quan sát và leftovers; receipt hoặc registration không cấp quyền xóa. Cleanup đủ điều kiện cần review, Trash và kiểm tra recovery. Developer cleanup commands là thao tác riêng có xác nhận; có thể không dùng Trash hoặc Undo, nên hãy đọc đúng command trước khi chạy. Giảm CPU priority thủ công không phải tự động giới hạn CPU.

### Changes, recovery và reports

Install Trace ghi quan sát có giới hạn khi bạn thực hiện install/update/uninstall bình thường; không tự chạy installer được thả vào app. So sánh snapshots/timeline, kiểm tra coverage và export cục bộ. Chỉ restore khi đích gốc đang trống. Report có thể chứa tên, path và endpoint; duyệt trước khi chia sẻ.

### Giới hạn và support

Tên cảm biến phụ thuộc model; link rate không phải tốc độ Internet. Giải thích dung lượng ẩn/snapshots không chứng minh exclusive snapshot bytes. App không có firewall, điều khiển quạt hoặc sửa hệ thống với đặc quyền. Foreground resources, Intel/macOS 13/Ethernet vật lý, full VoiceOver, câu chữ quan trọng tiếng Nhật và thông báo native chưa được xác minh. Xem [readiness](production/RELEASE-READINESS.md), [Privacy](../PRIVACY.md), [Security](../SECURITY.md), [issues](https://github.com/thangldw/toolbox/issues).

## 日本語

Macinity 3.1.0はCobalt Linkのブランドを導入し、OrvenをMac管理用のnative workspaceへ拡張します。[thangldw](https://thangldw.github.io/) & Codexが開発しました。

- Action Centerはお気に入りと最近の操作、Smart DiagnosticsはCPU・メモリ・容量・ネットワークの観測結果を表示します。Work Profilesはworkspace・音声・Keep Awake操作を事前確認します。
- 起動項目、Keep Awake、外部ドライブとファイルロック、ポート、一括名称変更と取り消し、SHA-256、フォルダ比較、package/runtime、デバイスとworkspace管理を追加しました。
- バッテリー詳細と充放電履歴、整理したセンサー、独立したDisk/Network画面、アプリの自動一覧、Wi-Fiツールを提供します。
- 英語・ベトナム語・日本語・簡体字に対応し、言語と外観はSettingsで変更できます。

### インストールと更新

同じ公開済みGitHub releaseからMacinity-3.1.0.dmgとSHA-256を取得し、`shasum -a 256 -c Macinity-3.1.0.dmg.sha256`で確認します。DMG内の案内を読んでMacinity.appをApplicationsへ移動します。Ad-hoc署名でApple notarizationは受けていません。初回起動が拒否された場合はSystem Settings → Privacy & Security → Open Anywayを使い、Gatekeeperを無効化しないでください。旧bundle IDとdata namespaceを維持するため、新しいMacinity folderへの移行は不要です。

### Macを観測する

Overviewと監視画面でCPU、memory、process、disk/network rate、battery/thermalを確認します。任意のmenu-bar監視を有効にしていない場合、Liveにはactive main windowが必要で、それ以外はsamplingを停止します。Hardware Inspectorはprofileと取得可能なmapped sensorsを表示します。Missingや古いtimestampはゼロを意味しません。Sleep Inspectorはsleepを防ぐassertionsの観測であり、process終了の許可ではありません。

### Wi-FiとLAN

SidebarのWi-Fi & LANでtoolを選んでrefreshします。Overview/Ethernetはaddresses、gateway、global DNS、media、carrierを表示します。UP/RUNNINGとphysical linkの検出は別です。Wi-Fiは取得可能なsignal/noise/SNR/channel/band/width/link rateを表示します。IdentityにはLocation permissionが必要な場合があります。Nearby scanは明示操作のみで、network countやRSSIはinterference測定ではありません。

Connection DiagnosticsまたはLatency & Stabilityに単一のhostname/IPを入力します。URL、port、options、credentialsは含めません。DNS、TCP 443、gatewayは独立した結果で、numeric IPはDNSを省略します。20回のICMPでloss、mean、jitterとmissing gapsを確認します。StopはMacinity所有のoperationのみcancelし、以前の結果を保持します。任意timelineはsession RAM内の観測で、packet historyや正確なdisconnect時刻ではありません。

### History、baseline、recording

Local historyは初期状態でoffです。有効にしてもbackground samplingを開始しません。24時間または7日を容量上限内で保持します。30–60回の実観測後にCapture Baselineを実行し、median比較にはmetricごとに10個の新しいvalid observationsが必要です。Workloadの違いが差の理由となる場合があります。

15/30/60分を選んでStartします。Stopはsessionを保持、Startは置換、QuitはRAM内sessionを破棄します。Sleep/inactiveはgapを作り、実時間を延ばす場合があります。JSON/CSV previewは保存内容と同一です。Smart Alertsは任意設定です。OS通知にはpermissionと実serviceが必要で、通知到達は未検証です。

### Storage、projects、applications

Rootを選択してscanし、allocation、duplicates、growth、再生成可能なartifactsをreviewします。App Dossierは観測とleftoversを関連づけますが、receipt/registrationは削除許可ではありません。対象cleanupにはreview、Trashとrecovery検証が必要です。Developer cleanup commandsは別の明示操作で、Trash/Undoを使えない場合があります。実行前に正確なcommandを確認します。手動のCPU priority低下は自動CPU capではありません。

### Changes、recovery、reports

Install Traceは通常のinstall/update/uninstallを人が行う間に限定された観測を記録し、dropされたinstallerを自動実行しません。Snapshots/timelineとcoverageをreviewしてlocal exportします。Restoreは元のdestinationが空の場合のみです。Reportに名前、path、endpointを含む場合があるため、共有前に確認します。

### 制限とサポート

Mapped sensor labelsは機種に依存し、link rateはInternet throughputではありません。Hidden space/snapshotの説明はexclusive snapshot bytesの証明ではありません。Firewall、fan control、privileged repairは含みません。Current foreground resources、実機Intel/macOS 13/Ethernet、完全なVoiceOver、重要な日本語表現review、native通知到達は未検証です。[Readiness](production/RELEASE-READINESS.md)、[Privacy](../PRIVACY.md)、[Security](../SECURITY.md)、[issues](https://github.com/thangldw/toolbox/issues)を参照してください。
