# Orven capability matrix

## English

### Scope

Live metrics use the existing Darwin process/CPU/memory/network owners and one MonitoringCoordinator. Hardware uses sysctl/SystemConfiguration/system profile reads and read-only AppleSMC mapped sensors where available. Network tools use getifaddrs, global SystemConfiguration DNS/gateways, CoreWLAN and visible-page NWPathMonitor. Explicit helper probes use fixed direct arguments with bounded output/cancellation, not a shell.

### Coverage and limits

Observation coverage depends on model, permissions, cadence, process visibility and successful reads. Main-window active or menu-bar demand controls sampling. Missing/stale/paused data is explicit. There is no calibrated per-core identity, SPD/voltage/liveclock/SMART/stress benchmark, traffic interception, fan control or firewall capability.

### Verification

CLI/unit evidence and historical engine soak do not establish current GUI performance or physical Intel/macOS13/Ethernet coverage.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## Tiếng Việt

### Scope

Live metrics dùng các provider Darwin và một MonitoringCoordinator. Hardware dùng sysctl, SystemConfiguration, profile hệ thống và AppleSMC chỉ đọc khi khả dụng. Network dùng getifaddrs, cấu hình DNS/gateway toàn cục, CoreWLAN và NWPathMonitor trong page. Probe dùng direct arguments cố định, bounded output và cancellation; không shell.

### Coverage and limits

Coverage phụ thuộc model, quyền, cadence, process visibility và kết quả đọc. Sampling chỉ theo active main window hoặc menu-bar opt-in. Missing/stale/paused hiển thị rõ. Không calibrated per-core identity, SPD/voltage/live clock/SMART/stress benchmark, interception, fan control hay firewall.

### Verification

CLI/unit và soak engine lịch sử không chứng minh performance GUI hiện tại hoặc Intel/macOS13/Ethernet vật lý.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## 日本語

### Scope

ライブ指標はDarwin providerと一つのMonitoringCoordinatorを利用します。機器情報はsysctl・SystemConfiguration・system profile、センサーは取得可能な場合のread-only AppleSMCです。Networkはgetifaddrs、globalDNS/gateway、CoreWLAN、表示pageのNWPathMonitorを使用。Probeは固定directarguments、boundedoutput/cancelでshell評価なし。

### Coverage and limits

取得範囲は機種・権限・cadence・process visibility・読み取り結果によります。Active main windowまたは任意menu-barのみsampling。Missing/stale/paused明示。Calibrated per-core identity、SPD/voltage/liveclock/SMART/stress、interception/fancontrol/firewallは対象外。

### Verification

CLI/unitと以前のengine soakはcurrent GUI performanceやphysical Intel/macOS13/Ethernetの証明ではありません。

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)
