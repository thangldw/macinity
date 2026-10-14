---
version: alpha
name: Orven
description: Native macOS resource and storage workspace
colors:
  primary: "#2464DF"
  background: "#F5F7FA"
  surface: "#FFFFFF"
  text: "#17263C"
  secondary: "#586D8A"
  accent: "#2464DF"
typography:
  sans:
    fontFamily: system-ui
  numeric:
    fontFamily: system-ui
rounded:
  surface: 16px
  compact: 9px
spacing:
  page: 28px
  section: 20px
omitted:
  - section: components
    reason: Native component ownership is defined in UX-CONTRACT.md.
---
# Orven native design context

## English

### Wi-Fi and LAN

Wi-Fi/LAN uses the existing Orven theme, native controls, locale provider, MonitoringChart and rate sampler. A page-owned explicit read/probe service has one operation, cancellation and timestamped results; NWPathMonitor is a visible-page event observer. No configuration changes or persisted identities. See [network contract](../../docs/monitoring/NETWORK-TOOLS.md).


### Health workflows

The user authorized local Health History/Baseline, opt-in Smart Alerts, Sensor Charts/Recording and session-only Network Connection Changes. This scoped change supersedes earlier no-persistence/no-alert wording below. Existing sampler, MonitoringChart, OrvenTheme, L10n, native controls and DiagnosticsExportView remain owners. Persistence is bounded/default-off; notification permission is explicit; endpoints stay in session memory. See [health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md).


### Physical sensors

Physical Sensor Panel reuses the existing hardware cadence, Orven surface, native disclosure/Grid and shared export. Mapped identity, stale current, missing values and limited coverage are explicit; no fan mutation. See [physical sensor scope](../../docs/monitoring/PHYSICAL-SENSORS.md).

### Hardware Inspector

Hardware Inspector reuses Orven surfaces, native Grid, explicit refresh and the shared diagnostics preview/save sheet. Range reset preserves engine history; missing/current-stale fields remain explicit. See [hardware scope](../../docs/monitoring/HARDWARE-TOOLS.md).

### Feature expansion

New diagnostics reuse OrvenTheme, native controls and existing sampling. Explicit helper refresh owns loading/error/cancellation states. The approved CPU priority action has its own native confirmation and same-user PID/start guard; monitoring does not change process scheduling automatically. Scope and prerequisites are defined in [feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md).

#

### Sleep Inspector

Sleep Inspector extends Battery & Thermal using the existing surface, native refresh button and process route. It is an explicit snapshot, with wall time, partial-data and unverified-owner states; it never polls in the background or changes power settings. Public assertion type/name strings are OS-provided source evidence, not localized app instructions.

## Overview

The user approved the Orven observation-ring identity and the light diagnostics workspace, then authorized native implementation. Layout reference: prototypes/toolbox-next/visual-target.png; identity reference: prototypes/toolbox-next/orven-brand-target.png. This is native SwiftUI with real monitoring snapshots, not a browser shell or synthetic data. GUI locales are English, Vietnamese, Japanese and Simplified Chinese, as explicitly requested. L10n owns language selection; dates and numbers follow the selected locale while source timestamps and paths retain their meaning.

### Colors

ToolboxCore/OrvenTheme.swift owns native adaptive tokens. Light values mirror this frontmatter. Dark canvas/surface/ink/secondary/border are #14283B/#1C3247/#E5EDF7/#B0C0D6/#375069. Chart/icon accent brightens to #73A8FF; primary actions keep #2464DF. System/light/dark is an app-local preference, default system, toolbox.appearance. Native selection, focus, pickers, tables and scrollbar rendering remain system owned. Status always includes text.

### Typography

System sans and monospaced digits. Page title 36 points, section title2, metric values title2 with the Overview CPU at32 points, caption for source freshness. Full names are available in tooltips; process status text wraps rather than silently becoming zero. Native font coverage supports both GUI locales.

### Layout

Default1320×900, minimum960×640, sidebar220–280 with ideal240, main inset28 and section gaps18–20. Overview has the CPU chart and attached summary, a top-process list and startup storage strip; document scrolling preserves access on smaller screens. All navigation raw values are stable. Processes uses a native internally scrolling Table; verified details occupy a300-point inspector at main widths900 or more, otherwise a440×520 native sheet. Management modules retain their mutation owners inside a common surface.

### Elevation & Depth

Grouped flat adaptive surfaces with1-point borders. No ornamental shadows/gradients or entrance animations. macOS owns sheet/menu depth and focus. Charts retain generation/missing-sample gaps and linear interpolation; a subtle area fill is data context.

### Shapes

Surface radius16, compact control radius9; native controls retain OS geometry. The observation-ring icon comes from AppIcon.icns, the supplied OrvenLogo.png is bundled and displayed on a white contrast plate in Help. Existing file/driver identities are not inferred from branding.

### Components

OrvenTheme/orvenSurface are shared across app/Core/Storage. OrvenPageHeader, OrvenSamplingStatus, MetricReadout and MonitoringChart are shared display owners. ToolboxCoordinator owns section routing and transient PID/start inspection focus; MonitoringViewModel remains the sole snapshot/render-demand owner. Source/provider values and availability are retained. Only the approved HealthHistoryStore persists bounded opt-in metrics. No additional polling engine, telemetry, privileges, process termination or automatic cleanup.

### Do's and Don'ts

Display live timestamps, CPU normalization, occupied-memory cache semantics, capacity versus rates, unsupported and stale states. Only processes with measured CPU values are ranked in Overview; explicit sample coverage leads to the complete process view, where restricted processes remain visible. Never interpret app correlation as deletion permission. Native cleanup/recovery confirmations and exact target checks remain unchanged. Keep com.thang.toolbox, the Toolbox data directory, executable/module names and existing preference keys stable.

## Tiếng Việt

### Wi-Fi and LAN

Wi-Fi/LAN dùng theme/control/locale/chart/sampler cũ; owner riêng cho read/probe theo yêu cầu, một operation/cancel/timestamp. NWPathMonitor quan sát event khi trang mở. Không đổi cấu hình hoặc lưu identity. Xem [network contract](../../docs/monitoring/NETWORK-TOOLS.md).


### Health workflows

Người dùng cho phép Health History/Baseline trên máy, Smart Alerts opt-in, Sensor Charts/Recording và Network Connection Changes chỉ trong phiên. Scope này thay thế các hạn chế persistence/alert cũ bên dưới. Sampler, MonitoringChart, OrvenTheme, L10n, native controls và DiagnosticsExportView hiện có tiếp tục sở hữu chức năng. Persistence có giới hạn và mặc định tắt; quyền notification qua nút riêng; endpoint chỉ giữ trong RAM phiên. Xem [health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md).

### Physical sensors

Physical Sensor Panel dùng cadence phần cứng cũ, surface Orven, disclosure/Grid native và export chung. Ghi rõ mapped identity, current stale, missing/limited coverage; không đổi quạt. Xem [scope sensor](../../docs/monitoring/PHYSICAL-SENSORS.md).

### Hardware Inspector

Hardware Inspector dùng lại surface Orven, Grid native, refresh theo yêu cầu và sheet preview/save diagnostics chung. Reset range giữ history engine; field thiếu/current-stale được ghi rõ. Xem [scope phần cứng](../../docs/monitoring/HARDWARE-TOOLS.md).

### Feature expansion

Diagnostics mới dùng lại OrvenTheme, control native và sampling cũ. Refresh helper theo yêu cầu có loading/error/cancellation. CPU priority đã được cho phép có xác nhận native riêng và guard cùng user/PID/start; monitoring không tự đổi scheduling. Scope/prerequisite ở [feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md).

#

### Sleep Inspector

Sleep Inspector mở rộng Battery & Thermal bằng surface, nút refresh native và route process hiện có. Đây là snapshot theo yêu cầu, có wall time, partial data và owner chưa verify; không polling nền hay đổi power settings. Type/name assertion từ OS là evidence gốc, không phải chỉ thị của app.

## Overview

Người dùng chốt identity Orven vòng quan sát và workspace diagnostics sáng, rồi cho phép triển khai native. Layout reference: prototypes/toolbox-next/visual-target.png; identity reference: prototypes/toolbox-next/orven-brand-target.png. SwiftUI dùng snapshot thật; không browser shell hoặc dữ liệu mẫu. GUI English/Tiếng Việt/日本語/简体中文 theo yêu cầu rõ ràng. L10n sở hữu language; date/number theo locale, timestamp nguồn/path giữ nguyên ý nghĩa.

### Colors

ToolboxCore/OrvenTheme.swift sở hữu token adaptive. Giá trị sáng theo frontmatter. Dark canvas/surface/ink/secondary/border: #14283B/#1C3247/#E5EDF7/#B0C0D6/#375069. Chart/icon accent #73A8FF; primary action #2464DF. Theme riêng app với key toolbox.appearance, mặc định system. macOS sở hữu selection/focus/picker/table/scrollbar. Trạng thái luôn có chữ.

### Typography

System sans và monospaced digit. Page36 point, section title2, metric title2, CPU Overview32 point, freshness caption. Tooltip giữ tên đầy đủ; status wrap và không biến missing thành zero. Font native hỗ trợ hai locale.

### Layout

Mặc định1320×900, minimum960×640, sidebar220–280/ideal240, main inset28/gap18–20. Overview gồm CPU chart-summary, danh sách tiến trình và strip dung lượng; cuộn tài liệu giữ truy cập khi cửa sổ nhỏ. Raw route giữ nguyên. Processes dùng Table tự cuộn; inspector300 point khi main width>=900, còn lại sheet440×520. Module quản lý giữ owner mutation trong surface chung.

### Elevation & Depth

Surface adaptive phẳng, viền1 point; không shadow/gradient trang trí hoặc entrance animation. macOS sở hữu depth/focus sheet/menu. Chart giữ gap theo missing/generation, interpolation linear và area fill nhẹ có ý nghĩa dữ liệu.

### Shapes

Surface16, control compact9; geometry control native. Icon từ AppIcon.icns; OrvenLogo.png được bundle và đặt trên nền trắng tương phản ở Help. Không suy diễn file/driver identity từ branding.

### Components

OrvenTheme/orvenSurface dùng chung app/Core/Storage. Header/status/MetricReadout/MonitoringChart là display owner. Coordinator sở hữu route/focus PID-start tạm; MonitoringViewModel vẫn sở hữu snapshot/render demand. Giữ source/availability; chỉ HealthHistoryStore được lưu metric local opt-in có giới hạn; không thêm sampler/telemetry/privilege/kill/auto-cleanup.

### Do's and Don'ts

Ghi timestamp, CPU normalization, memory gồm cache, capacity khác rate, unsupported/stale. Overview chỉ xếp hạng CPU đã đo và hiển thị coverage; màn hình đầy đủ vẫn giữ process bị hạn chế quyền. App correlation không phải quyền xóa. Giữ confirmation/target checks cleanup-recovery, com.thang.toolbox, thư mục dữ liệu Toolbox, executable/module và preference keys cũ.

## 日本語

### Wi-Fi and LAN

Wi-Fi/LANは既存theme/control/locale/chart/samplerを再利用。Page-owned明示read/probeはsingleoperation/cancel/timestamp、NWPathMonitorは表示pageのeventobserver。設定変更/identity保存なし。[Network contract](../../docs/monitoring/NETWORK-TOOLS.md)参照。


### Health workflows

ユーザーはlocal Health History/Baseline、opt-in Smart Alerts、Sensor Charts/Recording、session-only Network Connection Changesを承認しました。このscopeでは下記の従来persistence/alert制限を置き換えます。既存sampler、MonitoringChart、OrvenTheme、L10n、native controls、DiagnosticsExportViewを引き続き使用します。Persistenceは上限付きで初期off、notification権限は明示button、endpointはsession memoryのみ。[Health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md)を参照。

### Physical sensors

Physical Sensor Panelは既存hardware cadence、Orven surface、native disclosure/Grid、共通exportを再利用。Mapped identity/stale current/missing/limited coverageを明示し、fanを変更しません。[Scope](../../docs/monitoring/PHYSICAL-SENSORS.md)参照。

### Hardware Inspector

Hardware InspectorはOrven surface、native Grid、明示refresh、共通diagnostics preview/save sheetを再利用。Range resetはengine historyを保持し、欠測/current-staleを明示します。[Hardware scope](../../docs/monitoring/HARDWARE-TOOLS.md)参照。

### Feature expansion

新diagnosticsはOrvenTheme/native control/既存samplingを再利用。明示helper refreshはloading/error/cancellationを所有。承認済みCPU priority actionはnative確認とsame-user PID/start guardを持ちmonitoringは自動変更しません。Scope/prerequisiteは[feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md)。

#

### Sleep Inspector

Sleep Inspectorは既存surface/native refresh/process routeでBattery & Thermalを拡張。明示的snapshot、wall time、partial data、unverified ownerを示し、background polling/power設定変更なし。OS assertion type/nameはsource evidenceでapp instructionではない。

## Overview

利用者がOrven observation-ring identityとlight diagnostics workspaceを承認しnative実装を依頼。Layout sourceはprototypes/toolbox-next/visual-target.png、identity sourceはorven-brand-target.png。Native SwiftUIと実snapshotを使い、browser shell/demo dataではありません。明示依頼によりGUIはEnglish/Vietnamese/日本語/简体中文。LanguageはL10nが所有しdate/numberは選択localeを使用。Source timestamp/pathの意味は保持。

### Colors

ToolboxCore/OrvenTheme.swiftがadaptive tokenを所有。Lightはfrontmatter、darkは#14283B/#1C3247/#E5EDF7/#B0C0D6/#375069。Chart/icon accentは#73A8FF、actionは#2464DF。App-local toolbox.appearanceはsystem default。Native selection/focus/picker/table/scrollbarはOS管理、statusは文字付き。

### Typography

System sans/monospaced digits。Page36pt、section/metric title2、Overview CPU32pt、freshness caption。名前tooltip/status wrap、missingをzeroに変換しません。二GUI localeのnative font。

### Layout

Default1320×900/min960×640、sidebar220–280/ideal240、main inset28/gap18–20。OverviewはCPU instrument/summary、process list、storage strip。小windowでdocument scroll。Raw routeは安定。Process Tableは内部scroll、main width>=900で300pt inspector、他は440×520 sheet。Management mutation ownerは保持。

### Elevation & Depth

Flat adaptive surface/1pt border、装飾shadow/gradient/entrance animationなし。Sheet/menu depth/focusはOS。Chartはgeneration/missing gapとlinear interpolation、控えめなdata area fill。

### Shapes

Surface16/control9、native control geometry。AppIcon.icnsとbundled OrvenLogo.pngを使用し、Helpはwhite contrast plate。Brandからfile/driver identityを推測しません。

### Components

OrvenTheme/orvenSurfaceはapp/Core/Storage共有。Header/status/readout/chartがdisplay owner。Coordinatorがrouteとtransient PID/start focus、MonitoringViewModelが唯一のsnapshot/render demand owner。Source/availability保持、承認済みHealthHistoryStoreのみopt-in metricを制限付きで保存。追加sampler/telemetry/privilege/kill/auto-cleanupなし。

### Do's and Don'ts

Timestamp/CPU normalization/cache/capacity-rate/unsupported-staleを明記。Overviewは実CPU sampleのみrankしcoverageを表示、完全viewはrestricted processを保持。Correlationは削除許可ではありません。Confirmation/target checksとcom.thang.toolbox/Toolbox data directory/executable/module/preference keyを保持。
