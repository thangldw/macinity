# Orven user guide

## English

### Install and upgrade

Download Orven-3.0.0.dmg and its SHA-256 file from the same published GitHub release. Run `shasum -a 256 -c Orven-3.0.0.dmg.sha256`, open the DMG, read the included guide and drag Orven.app into Applications. Ad-hoc signed, not notarized: if first launch is blocked, use System Settings → Privacy & Security → Open Anyway. Do not disable Gatekeeper. The old data namespace and bundle ID remain compatible; no data migration to a new Orven folder is required.

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

### Cài đặt và nâng cấp

Tải Orven-3.0.0.dmg/SHA-256 từ cùng releaseGitHub đã công bố. `shasum -a 256 -c Orven-3.0.0.dmg.sha256`, mở DMG/đọc guide/kéo Orven.app vào Applications. Kýad-hoc/chưa notarized: blockedfirstlaunch dùng System Settings → Privacy & Security → Open Anyway, không tắtGatekeeper. Namespace/bundleIDcũ tương thích, không cần move dữ liệu sangfolderOrven mới.

### Quan sát Mac

Overview/monitoring hiển thị CPU/memory/process/disk/network/battery/thermal quan sát. Mainwindowactive mớiLive; nếu không thìpause trừmenu-baropt-in. HardwareInspector có profile/sensor mapped khả dụng. Missing/stale không phải0. SleepInspector là sleep-preventionassertions quan sát, không permissionkillprocess.

### Wi-Fi và LAN

Chọn sidebarWi-Fi & LAN, chọntool/refresh. Overview/Ethernet cóaddress/gateway/globalDNS/media/carrier; UP/RUNNING khác physical link. Wi-Fi signal/noise/SNR/channel/band/width/linkrate khi khả dụng; identity có thể cầnLocation. Nearby scan theo nút; count/RSSI khônginterferencemeasurement.

ConnectionDiagnostics/Latency & Stability nhập một hostname/IP rồi chạy; không URL/port/options/credentials. DNS/TCP443/gatewayoutcomeđộc lập, numericIPbỏDNS.20ICMP loss/mean/jitter/missinggap; Stop chỉcancelownedoperation, giữ kếtquảcũ. Timelineopt-inRAM/observation, khôngpackethistory/exactdisconnect.

### History, baseline và recording

Historylocalmặcđịnhoff, chủđộngbật khôngsamplingnền. Retain24h/7d trongbudget.30–60quan sátthật mớiCaptureBaseline; ít nhất10newvalidobservations/metric mớicomparemedian. Workloadkhác có thểgiảithíchchênhlệch.

Chọn15/30/60phút rồiStart. Stopgiữsession, Startthaysession, QuitmấtRAM. Sleep/inactive tạo gap/kéo dàiwalltime. JSON/CSVpreviewđúng nội dung lưu. SmartAlertsopt-in; OSnotification cầnquyền/service thực, hiệnchưa proofdelivery.

### Storage, projects và applications

Chọnroottrướcscan. Reviewallocation/duplicate/growth/rebuildableartifacts. Dossierlinkobservations/leftovers; receipt/registrationkhôngquyềnxóa. Eligiblecleanup cầnreview/Trash/recovery. Commandcleanupdeveloperlàoperationriêngexplicit, có thểkhôngTrash/Undo; reviewđúngcommandtrướcconfirm. LowerCPUprioritymanualkhôngautocap.

### Changes, recovery và reports

InstallTracegiữboundedobservations khi bạnrun install/update/uninstallbìnhthường, khôngtựchạyinstallerdropped. Compareevidence/partialcoverage/exportlocal. Restorechỉpathgốctrống. Reportcóthểchứaname/path/endpoint, reviewtrướcshare.

### Giới hạn và support

Sensormodeldependent;linkratekhôngInternetthroughput. Hidden/snapshotexplanationkhôngexclusivebytes. Khôngfirewall/fancontrol/privilegedrepair. Foregroundresources/Intel/macOS13/Ethernetvật lý/fullVO/JAcopy/OSnotificationcònchưa proof. [Readiness](production/RELEASE-READINESS.md)/[Privacy](../PRIVACY.md)/[Security](../SECURITY.md)/[issues](https://github.com/thangldw/toolbox/issues).

## 日本語

### Installとupgrade

同publishedGitHubreleaseのOrven-3.0.0.dmg/SHA-256をdownload。`shasum -a 256 -c Orven-3.0.0.dmg.sha256`で確認しDMG内guideを読みOrven.appをApplicationsへ。Ad-hoc/unnotarized、firstlaunchblocked時System Settings → Privacy & Security → Open Anyway。Gatekeeper無効化なし。旧namespace/bundleID互換、Orvenfolderへの移行不要。

### Macの観測

Overview/monitoringはCPU/memory/process/disk/network/battery/thermal観測。MainwindowactiveでLive、それ以外はoptionalmenu-barなしでpause。HardwareInspectorはprofile/availablemappedsensor。Missing/staleは0ではありません。SleepInspectorのassertionは観測でprocesskill許可ではありません。

### Wi-FiとLAN

SidebarWi-Fi & LANでtool選択/明示refresh。Overview/Ethernetはaddress/gateway/globalDNS/media/carrier、UP/RUNNINGとphysical linkは別。Wi-Fiはsignal/noise/SNR/channel/band/width/linkrate、identityはLocationが必要な場合。Nearbyは明示scan、count/RSSIはinterference測定ではありません。

ConnectionDiagnostics/Latency & Stabilityに単一hostname/IP入力。URL/port/options/credentialsなし。DNS/TCP443/gatewayは独立結果、numericIPはDNS省略。20ICMPのloss/mean/jitter/missinggap、Stopはownedoperationcancel・以前結果保持。Opt-intimelineはsession観測でpackethistory/exactdisconnectなし。

### History・baseline・recording

Localhistoryは初期off、明示有効化しても背景samplingなし。24h/7dをbudget内保持。30–60実観測後CaptureBaseline、各metric10新valid観測でmediancompare。Workload差で変化する場合があります。

15/30/60分を選びStart。Stop保持、Start置換、QuitでRAM破棄。Sleep/inactiveはgap/walltime延長。JSON/CSVは保存内容preview。SmartAlertsはopt-in、OSnotificationには権限/実serviceが必要でdelivery未検証。

### Storage・projects・applications

Root選択後scan。Allocation/duplicate/growth/rebuildableartifactをreview。Dossierのreceipt/registrationは削除許可ではありません。Eligiblecleanupはreview/Trash/recovery。Developercommandcleanupは別明示operationでTrash/Undo不可の場合、実commandを確認。ManualCPUpriorityloweringはautocapではありません。

### Changes・recovery・reports

InstallTraceは人がnormalinstall/update/uninstall中のbounded観測、droppedinstallerを自動実行しません。Evidence/partialcoveragecompare/exportlocal。Restoreは元pathが空の場合のみ。Reportにname/path/endpointを含む場合、共有前に確認。

### 制限とsupport

Sensorはmodel依存、linkrateはInternetthroughputではありません。Hidden/snapshotはexclusivebytes証明なし。Firewall/fancontrol/privilegedrepairなし。Foregroundresources/physicalIntel/macOS13/Ethernet/fullVO/JAcopy/OSnotification未検証。[Readiness](production/RELEASE-READINESS.md)/[Privacy](../PRIVACY.md)/[Security](../SECURITY.md)/[issues](https://github.com/thangldw/toolbox/issues)参照。
