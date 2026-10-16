# Macinity capability matrix

## English

### Scope

Live metrics use the existing Darwin process/CPU/memory/network owners and one MonitoringCoordinator. Hardware uses sysctl/SystemConfiguration/system profile reads and read-only AppleSMC mapped sensors where available. Network tools use getifaddrs, global SystemConfiguration DNS/gateways, CoreWLAN and visible-page NWPathMonitor. Explicit helper probes use fixed direct arguments with bounded output/cancellation, not a shell.

| Metric | API / owner | Platform target | Permission | Meaning / unit | Read cadence / cost | Limits | Verification | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| System CPU | host_statistics / HOST_CPU_LOAD_INFO | macOS 13+, both architectures | OS read access | Delta host ticks, percent | Existing coordinator demand | First/reset samples are gaps | Sampling unit and smoke tests | Missing sample |
| Process CPU / memory | libproc and process identity | macOS 13+, both architectures | Process visibility | Counter deltas / bytes | Bounded coordinator enumeration | PID reuse, exits, protected processes | Identity and rate tests | Reduced coverage |
| Memory / swap / pressure | host_statistics64, vm.swapusage, Dispatch pressure events | macOS 13+, both architectures | OS read access | Bytes; pressure category | Existing coordinator; pressure callback | Pressure is not an exact free-memory value | Memory and lifecycle tests | Explicit unavailable |
| Disk / interface rate | IOKit counters; NET_RT_IFLIST2 | macOS 13+, both architectures | Driver / OS visibility | Counter deltas, bytes per second | Shared rate sampler | Reset/wrap/identity gaps; interface observations differ from app traffic | Counter and gap tests | Missing rate |
| Battery / thermal | IOPS; ProcessInfo thermalState | macOS 13+, both architectures | OS read access | Capacity/charging; thermal category | Slow fields cached; thermal sampled | Desktop battery may be unsupported; category is not degrees | Provider and sample tests | Unsupported or missing |
| CPU/GPU temperature, fan, system power | Read-only mapped AppleSMC | Model-dependent | Driver access | Celsius, RPM, watts | Bounded read; no writes | Community labels; no calibrated per-core/package-power claim | Mapping, decode and missing tests; historical engine observations | Unavailable with source/time |
| Sleep requests | IOPM assertion inspection | macOS 13+, both architectures | OS visibility | Observed power assertions | Explicit refresh | Not every sleep/wake cause; no process kill | Parsing and smoke tests | Reduced coverage |
| Wi-Fi / LAN | CoreWLAN, getifaddrs, SystemConfiguration, ifconfig | macOS 13+, both architectures | Location identities; OS / driver visibility | RSSI/noise, channel/link rate, address/media/carrier | Explicit refresh / nearby scan | Link rate is not throughput; global DNS may differ from scoped VPN DNS | Parsing/unit and historical native checks | Redacted / unknown |
| Connection diagnostics | Direct DNS, ICMP and TCP helper arguments | macOS 13+, both architectures | Local Network may be requested by OS | Latency/loss/jitter; independent stage outcomes | User button, fixed budgets and cancellation | Cached DNS, blocked ICMP; not HTTP/TLS/bandwidth verification | Validation, parse and cancellation contracts | Explicit stage failure |

### Coverage and limits

Observation coverage depends on model, permissions, cadence, process visibility and successful reads. Main-window active or menu-bar demand controls sampling. Missing/stale/paused data is explicit. There is no calibrated per-core identity, SPD/voltage/liveclock/SMART/stress benchmark, traffic interception, fan control or firewall capability.

### Verification

CLI/unit evidence and historical engine soak do not establish current GUI performance or physical Intel/macOS13/Ethernet coverage.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## Tiếng Việt

### Scope

Live metrics dùng các provider Darwin và một MonitoringCoordinator. Hardware dùng sysctl, SystemConfiguration, profile hệ thống và AppleSMC chỉ đọc khi khả dụng. Network dùng getifaddrs, cấu hình DNS/gateway toàn cục, CoreWLAN và NWPathMonitor trong page. Probe dùng direct arguments cố định, bounded output và cancellation; không shell.

| Metric | API / owner | Platform target | Permission | Meaning / unit | Read cadence / cost | Limits | Verification | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| System CPU | host_statistics / HOST_CPU_LOAD_INFO | macOS 13+, both architectures | OS read access | Delta host ticks, percent | Existing coordinator demand | First/reset samples are gaps | Sampling unit and smoke tests | Missing sample |
| Process CPU / memory | libproc and process identity | macOS 13+, both architectures | Process visibility | Counter deltas / bytes | Bounded coordinator enumeration | PID reuse, exits, protected processes | Identity and rate tests | Reduced coverage |
| Memory / swap / pressure | host_statistics64, vm.swapusage, Dispatch pressure events | macOS 13+, both architectures | OS read access | Bytes; pressure category | Existing coordinator; pressure callback | Pressure is not an exact free-memory value | Memory and lifecycle tests | Explicit unavailable |
| Disk / interface rate | IOKit counters; NET_RT_IFLIST2 | macOS 13+, both architectures | Driver / OS visibility | Counter deltas, bytes per second | Shared rate sampler | Reset/wrap/identity gaps; interface observations differ from app traffic | Counter and gap tests | Missing rate |
| Battery / thermal | IOPS; ProcessInfo thermalState | macOS 13+, both architectures | OS read access | Capacity/charging; thermal category | Slow fields cached; thermal sampled | Desktop battery may be unsupported; category is not degrees | Provider and sample tests | Unsupported or missing |
| CPU/GPU temperature, fan, system power | Read-only mapped AppleSMC | Model-dependent | Driver access | Celsius, RPM, watts | Bounded read; no writes | Community labels; no calibrated per-core/package-power claim | Mapping, decode and missing tests; historical engine observations | Unavailable with source/time |
| Sleep requests | IOPM assertion inspection | macOS 13+, both architectures | OS visibility | Observed power assertions | Explicit refresh | Not every sleep/wake cause; no process kill | Parsing and smoke tests | Reduced coverage |
| Wi-Fi / LAN | CoreWLAN, getifaddrs, SystemConfiguration, ifconfig | macOS 13+, both architectures | Location identities; OS / driver visibility | RSSI/noise, channel/link rate, address/media/carrier | Explicit refresh / nearby scan | Link rate is not throughput; global DNS may differ from scoped VPN DNS | Parsing/unit and historical native checks | Redacted / unknown |
| Connection diagnostics | Direct DNS, ICMP and TCP helper arguments | macOS 13+, both architectures | Local Network may be requested by OS | Latency/loss/jitter; independent stage outcomes | User button, fixed budgets and cancellation | Cached DNS, blocked ICMP; not HTTP/TLS/bandwidth verification | Validation, parse and cancellation contracts | Explicit stage failure |

### Coverage and limits

Coverage phụ thuộc model, quyền, cadence, process visibility và kết quả đọc. Sampling chỉ theo active main window hoặc menu-bar opt-in. Missing/stale/paused hiển thị rõ. Không calibrated per-core identity, SPD/voltage/live clock/SMART/stress benchmark, interception, fan control hay firewall.

### Verification

CLI/unit và soak engine lịch sử không chứng minh performance GUI hiện tại hoặc Intel/macOS13/Ethernet vật lý.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## 日本語

### Scope

ライブ指標はDarwin providerと一つのMonitoringCoordinatorを利用します。機器情報はsysctl・SystemConfiguration・system profile、センサーは取得可能な場合のread-only AppleSMCです。Networkはgetifaddrs、globalDNS/gateway、CoreWLAN、表示pageのNWPathMonitorを使用。Probeは固定directarguments、boundedoutput/cancelでshell評価なし。

| Metric | API / owner | Platform target | Permission | Meaning / unit | Read cadence / cost | Limits | Verification | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| System CPU | host_statistics / HOST_CPU_LOAD_INFO | macOS 13+, both architectures | OS read access | Delta host ticks, percent | Existing coordinator demand | First/reset samples are gaps | Sampling unit and smoke tests | Missing sample |
| Process CPU / memory | libproc and process identity | macOS 13+, both architectures | Process visibility | Counter deltas / bytes | Bounded coordinator enumeration | PID reuse, exits, protected processes | Identity and rate tests | Reduced coverage |
| Memory / swap / pressure | host_statistics64, vm.swapusage, Dispatch pressure events | macOS 13+, both architectures | OS read access | Bytes; pressure category | Existing coordinator; pressure callback | Pressure is not an exact free-memory value | Memory and lifecycle tests | Explicit unavailable |
| Disk / interface rate | IOKit counters; NET_RT_IFLIST2 | macOS 13+, both architectures | Driver / OS visibility | Counter deltas, bytes per second | Shared rate sampler | Reset/wrap/identity gaps; interface observations differ from app traffic | Counter and gap tests | Missing rate |
| Battery / thermal | IOPS; ProcessInfo thermalState | macOS 13+, both architectures | OS read access | Capacity/charging; thermal category | Slow fields cached; thermal sampled | Desktop battery may be unsupported; category is not degrees | Provider and sample tests | Unsupported or missing |
| CPU/GPU temperature, fan, system power | Read-only mapped AppleSMC | Model-dependent | Driver access | Celsius, RPM, watts | Bounded read; no writes | Community labels; no calibrated per-core/package-power claim | Mapping, decode and missing tests; historical engine observations | Unavailable with source/time |
| Sleep requests | IOPM assertion inspection | macOS 13+, both architectures | OS visibility | Observed power assertions | Explicit refresh | Not every sleep/wake cause; no process kill | Parsing and smoke tests | Reduced coverage |
| Wi-Fi / LAN | CoreWLAN, getifaddrs, SystemConfiguration, ifconfig | macOS 13+, both architectures | Location identities; OS / driver visibility | RSSI/noise, channel/link rate, address/media/carrier | Explicit refresh / nearby scan | Link rate is not throughput; global DNS may differ from scoped VPN DNS | Parsing/unit and historical native checks | Redacted / unknown |
| Connection diagnostics | Direct DNS, ICMP and TCP helper arguments | macOS 13+, both architectures | Local Network may be requested by OS | Latency/loss/jitter; independent stage outcomes | User button, fixed budgets and cancellation | Cached DNS, blocked ICMP; not HTTP/TLS/bandwidth verification | Validation, parse and cancellation contracts | Explicit stage failure |

### Coverage and limits

取得範囲は機種・権限・cadence・process visibility・読み取り結果によります。Active main windowまたは任意menu-barのみsampling。Missing/stale/paused明示。Calibrated per-core identity、SPD/voltage/liveclock/SMART/stress、interception/fancontrol/firewallは対象外。

### Verification

CLI/unitと以前のengine soakはcurrent GUI performanceやphysical Intel/macOS13/Ethernetの証明ではありません。

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)
