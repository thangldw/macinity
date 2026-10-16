---
version: alpha
name: Macinity
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
# Macinity native design context

## English

Battery Health additionally reads macOS System Information on page entry or explicit refresh through a bounded, cancellable process. It reports system condition and maximum capacity independently of the raw full/design ratio, without retaining serial numbers or scheduled power events. Battery level and charging/power-source flags share the existing one-minute local Health History store and retention. The battery chart offers 1-hour, 24-hour and 7-day ranges; the latest 20 observed charging/discharging/external-power intervals break at missing, stale, paused, sleep or restarted sampling. No historical macOS battery records are imported and observation times are not exact plug/unplug times.

Battery & Thermal adds source, Low Power Mode, OS health, cycle count, reported design/full capacity, calculated capacity ratio, battery voltage, adapter watts and valid remaining-time estimates. Existing slow sampling owns the reads. AppleSmartBattery fields are model-dependent; absent fields stay unavailable. No serials or raw registry payloads are retained. Capacity ratio is not the macOS health percentage; adapter rating is not live charging power. Stale observations are labeled, and stale voltage, adapter and time estimates are suppressed.

Developer expansion: Software now includes the bounded, read-only Developer Tools path inventory. It shares the existing route search, theme and locale owner. Package/version resolution remains future scope. See the [expansion decisions and staged acceptance](../../docs/product/SUPER-APP-EXPANSION.md).

### Unified workspace — October 15, 2026

Brand update on October 16: Macinity replaces the display identity; the clean linked-M logo, native icon family and compatibility boundaries are documented in [Macinity integration](../../docs/brand/macinity/INTEGRATION.md). Internal MacinityTheme/MacinityNavigation names remain stable.

The current Macinity Cobalt Link identity uses graphite canvas #151A23, surface #172335, sidebar #131F30, ink #EAF0FA, secondary #ABBBD1 and border #2B3C54. Light/System remain first-class modes; existing preferences are not reset. Appearance and language choices live in Settings, not the sidebar, and remain directly selectable. The sidebar exposes all 22 stable page routes under six group headings. The sidebar search box and duplicate workspace page grid are removed. The route list scrolls at small heights while Settings and About stay anchored below. Brand, route and footer rows share consistent insets and fixed icon columns; navigation uses no dropdowns. Storage tools and network tools use the available width; refresh actions have their own row. Choice search appears only for more than eight options or an active query, with a clear button. Disk Activity belongs to Files and owns APFS capacity, snapshots and disk I/O. Network Activity belongs to Network and owns connections, connection changes and interface throughput. The legacy diskNetwork route restores Network Activity. Hardware profile and sensor panels are separate destinations. The thermal page leads with CPU/GPU hottest mapped readings, then five direct group buttons. Only the selected group renders a four-column sensor table and its selected sensor chart. Raw keys remain traceable; unrelated CPU/memory/I/O ranges are excluded. Charts reuse existing observations; gap/generation semantics remain owned by MonitoringChart. Applications automatically starts its read-only scan on first appearance for each screen model, retains completed results during that model lifetime, and keeps manual rescan. Concurrent scans are rejected; loading and empty results have distinct states. Applications uses its existing AppDossierView as a 340-point inspector above 900 points of available width, with the existing sheet at narrower sizes. The Overview uses real OS/memory/processor facts; no mock metrics or health score. Existing module detail/confirmation owners remain in place. Utility extensions now add startup inspection, temporary Keep Awake, external drives, file operations, package adapters, device snapshots and workspace presets; exact capability and verification boundaries are tracked in docs/product/SUPER-APP-EXPANSION.md.

| Previous rule | Decision | Runtime owner |
| --- | --- | --- |
| Area-only sidebar | Twenty-one direct routes under six headings | MacinityNavigation / ToolboxCoordinator |
| Hardware profile and sensors in one page | Separate My Mac and Thermals destinations | HardwareInspectorView.Mode |
| Blue-grey dark canvas | Approved graphite observatory palette | MacinityTheme → sync_brand_tokens.py → website adapter |
| Native controls and one sampler | Retained | UX-CONTRACT / MonitoringCoordinator |


### Wi-Fi and LAN

Wi-Fi/LAN uses the existing Macinity theme, native controls, locale provider, MonitoringChart and rate sampler. A page-owned explicit read/probe service has one operation, cancellation and timestamped results; NWPathMonitor is a visible-page event observer. No configuration changes or persisted identities. See [network contract](../../docs/monitoring/NETWORK-TOOLS.md).


### Health workflows

The user authorized local Health History/Baseline, opt-in Smart Alerts, Sensor Charts/Recording and session-only Network Connection Changes. This scoped change supersedes earlier no-persistence/no-alert wording below. Existing sampler, MonitoringChart, MacinityTheme, L10n, native controls and DiagnosticsExportView remain owners. Persistence is bounded/default-off; notification permission is explicit; endpoints stay in session memory. See [health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md).


### Physical sensors

Physical Sensor Panel reuses the existing hardware cadence, Macinity surface, native disclosure/Grid and shared export. Mapped identity, stale current, missing values and limited coverage are explicit; no fan mutation. See [physical sensor scope](../../docs/monitoring/PHYSICAL-SENSORS.md).

### Hardware Inspector

Hardware Inspector reuses Macinity surfaces, native Grid, explicit refresh and the shared diagnostics preview/save sheet. Range reset preserves engine history; missing/current-stale fields remain explicit. See [hardware scope](../../docs/monitoring/HARDWARE-TOOLS.md).

### Feature expansion

New diagnostics reuse MacinityTheme, native controls and existing sampling. Explicit helper refresh owns loading/error/cancellation states. The approved CPU priority action has its own native confirmation and same-user PID/start guard; monitoring does not change process scheduling automatically. Scope and prerequisites are defined in [feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md).

#

### Sleep Inspector

Sleep Inspector extends Battery & Thermal using the existing surface, native refresh button and process route. It is an explicit snapshot, with wall time, partial-data and unverified-owner states; it never polls in the background or changes power settings. Public assertion type/name strings are OS-provided source evidence, not localized app instructions.

## Overview

The user approved the Macinity observation-ring identity and the light diagnostics workspace, then authorized native implementation. The October 15 redesign combines the approved dark sensor concept, spacious Overview and list/detail software composition. The bundled Cobalt Link icon remains canonical. This is native SwiftUI with real monitoring snapshots, not a browser shell or synthetic data. GUI locales are English, Vietnamese, Japanese and Simplified Chinese, as explicitly requested. L10n owns language selection; dates and numbers follow the selected locale while source timestamps and paths retain their meaning.

### Colors

ToolboxCore/MacinityTheme.swift owns native adaptive tokens. Light values mirror this frontmatter. Dark canvas/surface/ink/secondary/border are #0F1928/#172335/#EAF0FA/#ABBBD1/#2B3C54. Chart/icon accent brightens to #73A8FF; primary actions keep #2464DF. System/light/dark is an app-local preference, default system, toolbox.appearance. Native selection, focus, pickers, tables and scrollbar rendering remain system owned. Status always includes text.

### Typography

System sans and monospaced digits. Page title 36 points, section title2, metric values title2 with the Overview CPU at32 points, caption for source freshness. Full names are available in tooltips; process status text wraps rather than silently becoming zero. Native font coverage supports both GUI locales.

### Layout

Default1320×900, minimum960×640, sidebar220–280 with ideal240, main inset28 and section gaps18–20. Overview has the CPU chart and attached summary, a top-process list and startup storage strip; document scrolling preserves access on smaller screens. All navigation raw values are stable. Processes uses a native internally scrolling Table; verified details occupy a300-point inspector at main widths900 or more, otherwise a440×520 native sheet. Management modules retain their mutation owners inside a common surface.

### Elevation & Depth

Grouped flat adaptive surfaces with1-point borders. No ornamental shadows/gradients or entrance animations. macOS owns sheet/menu depth and focus. Charts retain generation/missing-sample gaps and linear interpolation; a subtle area fill is data context.

### Shapes

Surface radius16, compact control radius9; native controls retain OS geometry. The observation-Cobalt Link icon comes from AppIcon.icns, the supplied MacinityLogo.png is bundled and displayed on a white contrast plate in Help. Existing file/driver identities are not inferred from branding.

### Components

MacinityTheme/orvenSurface are shared across app/Core/Storage. MacinityPageHeader, MacinitySamplingStatus, MetricReadout and MonitoringChart are shared display owners. ToolboxCoordinator owns section routing and transient PID/start inspection focus; MonitoringViewModel remains the sole snapshot/render-demand owner. Source/provider values and availability are retained. Only the approved HealthHistoryStore persists bounded opt-in metrics. No additional polling engine, telemetry, privileges, process termination or automatic cleanup.

### Do's and Don'ts

Display live timestamps, CPU normalization, occupied-memory cache semantics, capacity versus rates, unsupported and stale states. Only processes with measured CPU values are ranked in Overview; explicit sample coverage leads to the complete process view, where restricted processes remain visible. Never interpret app correlation as deletion permission. Native cleanup/recovery confirmations and exact target checks remain unchanged. Keep com.thang.toolbox, the Toolbox data directory, executable/module names and existing preference keys stable.

## Tiếng Việt

Sức khỏe pin đọc Thông tin hệ thống macOS khi mở trang hoặc bấm làm mới, qua tiến trình có giới hạn và có thể hủy. Tình trạng và dung lượng tối đa tách biệt với tỷ lệ dung lượng thô; không lưu số sê-ri hoặc lịch bật/tắt máy. Mức pin và trạng thái sạc/nguồn điện dùng kho Health History hiện có, ghi mỗi phút theo thời hạn lưu chung. Biểu đồ có khoảng 1 giờ, 24 giờ và 7 ngày; 20 khoảng sạc/xả/cắm nguồn gần nhất ngắt khi thiếu mẫu, dữ liệu cũ, tạm dừng, ngủ hoặc khởi động lại. Không nhập lịch sử pin cũ của macOS; thời gian quan sát không phải thời điểm cắm/rút sạc chính xác.

Pin & Nhiệt độ bổ sung nguồn điện, chế độ nguồn thấp, sức khỏe do OS báo cáo, chu kỳ, dung lượng thiết kế/sạc đầy, tỷ lệ dung lượng, điện áp, công suất bộ sạc và thời gian ước tính hợp lệ. Dùng nhịp lấy mẫu chậm hiện có; dữ liệu thiếu hiển thị không khả dụng. Không giữ serial hay dữ liệu registry thô. Tỷ lệ dung lượng không phải phần trăm sức khỏe macOS; công suất bộ sạc không phải công suất sạc tức thời. Dữ liệu cũ có nhãn; ẩn điện áp, công suất và ước tính thời gian khi cũ.

Mở rộng cho lập trình viên: Software có trang Công cụ lập trình kiểm kê đường dẫn giới hạn, chỉ đọc. Dùng chung tìm trang, theme và locale. Giải phiên bản/package vẫn là phạm vi tiếp theo. Xem [quyết định và nghiệm thu từng đợt](../../docs/product/SUPER-APP-EXPANSION.md).

### Workspace thống nhất — 15/10/2026

Dùng hướng quan sát tối đã duyệt: canvas #0F1928, surface #172335, sidebar #131F30, chữ #EAF0FA, chữ phụ #ABBBD1, viền #2B3C54. Giữ Light/System và lựa chọn hiện tại. Lựa chọn giao diện và ngôn ngữ nằm trong Settings, không nằm ở sidebar, và vẫn chọn trực tiếp. Sidebar hiển thị trực tiếp 21 trang trong sáu nhóm. Bỏ ô tìm kiếm sidebar và hàng chọn trang trùng lặp. Danh sách cuộn khi cửa sổ thấp, Settings và Giới thiệu cố định phía dưới. Logo, mục điều hướng và footer dùng lề thống nhất cùng cột icon cố định; không dùng dropdown. Công cụ lưu trữ và mạng dùng toàn bộ chiều rộng; nút làm mới nằm trên hàng riêng. Ô tìm lựa chọn chỉ hiện khi có hơn tám mục hoặc đang lọc, kèm nút xóa nhanh. Hoạt động ổ đĩa nằm trong Tệp, gồm APFS, snapshots và I/O; Hoạt động mạng nằm trong Mạng, gồm kết nối, thay đổi kết nối và lưu lượng. Route cũ diskNetwork mở Hoạt động mạng. Tách hồ sơ phần cứng khỏi cảm biến. Trang nhiệt độ đưa số đo CPU/GPU cao nhất lên đầu, tiếp theo là năm nút nhóm trực tiếp; chỉ nhóm đang chọn có bảng bốn cột và biểu đồ cảm biến. Giữ mã tra cứu; bỏ bảng CPU/RAM/I/O không liên quan. Biểu đồ dùng mẫu cũ, giữ gap/generation của MonitoringChart. Ứng dụng tự quét chỉ đọc khi mở lần đầu cho mỗi model màn hình, giữ kết quả trong vòng đời model và có nút quét lại. Không chạy nhiều lượt đồng thời; phân biệt đang tải và kết quả rỗng. Ứng dụng dùng AppDossierView ở inspector340 point khi có ít nhất900 point; cửa sổ hẹp vẫn dùng sheet. Tổng quan dùng thông tin OS/RAM/CPU thật. Phạm vi tiện ích và giới hạn kiểm chứng hiện tại được ghi tại docs/product/SUPER-APP-EXPANSION.md. Theme vẫn có một owner, adapter website được sinh lại; control và sampler cũ được giữ.

| Quy tắc trước | Quyết định | Runtime owner |
| --- | --- | --- |
| Sidebar chỉ có nhóm | Mười sáu trang trực tiếp trong sáu nhóm | MacinityNavigation / ToolboxCoordinator |
| Hồ sơ và cảm biến chung trang | Tách Máy Mac và Nhiệt độ | HardwareInspectorView.Mode |
| Canvas tối xanh xám | Palette graphite đã duyệt | MacinityTheme → sync_brand_tokens.py → website adapter |
| Control native và một sampler | Giữ nguyên | UX-CONTRACT / MonitoringCoordinator |


### Wi-Fi and LAN

Wi-Fi/LAN dùng theme/control/locale/chart/sampler cũ; owner riêng cho read/probe theo yêu cầu, một operation/cancel/timestamp. NWPathMonitor quan sát event khi trang mở. Không đổi cấu hình hoặc lưu identity. Xem [network contract](../../docs/monitoring/NETWORK-TOOLS.md).


### Health workflows

Người dùng cho phép Health History/Baseline trên máy, Smart Alerts opt-in, Sensor Charts/Recording và Network Connection Changes chỉ trong phiên. Scope này thay thế các hạn chế persistence/alert cũ bên dưới. Sampler, MonitoringChart, MacinityTheme, L10n, native controls và DiagnosticsExportView hiện có tiếp tục sở hữu chức năng. Persistence có giới hạn và mặc định tắt; quyền notification qua nút riêng; endpoint chỉ giữ trong RAM phiên. Xem [health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md).

### Physical sensors

Physical Sensor Panel dùng cadence phần cứng cũ, surface Macinity, disclosure/Grid native và export chung. Ghi rõ mapped identity, current stale, missing/limited coverage; không đổi quạt. Xem [scope sensor](../../docs/monitoring/PHYSICAL-SENSORS.md).

### Hardware Inspector

Hardware Inspector dùng lại surface Macinity, Grid native, refresh theo yêu cầu và sheet preview/save diagnostics chung. Reset range giữ history engine; field thiếu/current-stale được ghi rõ. Xem [scope phần cứng](../../docs/monitoring/HARDWARE-TOOLS.md).

### Feature expansion

Diagnostics mới dùng lại MacinityTheme, control native và sampling cũ. Refresh helper theo yêu cầu có loading/error/cancellation. CPU priority đã được cho phép có xác nhận native riêng và guard cùng user/PID/start; monitoring không tự đổi scheduling. Scope/prerequisite ở [feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md).

#

### Sleep Inspector

Sleep Inspector mở rộng Battery & Thermal bằng surface, nút refresh native và route process hiện có. Đây là snapshot theo yêu cầu, có wall time, partial data và owner chưa verify; không polling nền hay đổi power settings. Type/name assertion từ OS là evidence gốc, không phải chỉ thị của app.

## Overview

Người dùng chốt identity Macinity vòng quan sát và workspace diagnostics sáng, rồi cho phép triển khai native. The October 15 redesign combines the approved dark sensor concept, spacious Overview and list/detail software composition. The bundled Cobalt Link icon remains canonical. SwiftUI dùng snapshot thật; không browser shell hoặc dữ liệu mẫu. GUI English/Tiếng Việt/日本語/简体中文 theo yêu cầu rõ ràng. L10n sở hữu language; date/number theo locale, timestamp nguồn/path giữ nguyên ý nghĩa.

### Colors

ToolboxCore/MacinityTheme.swift sở hữu token adaptive. Giá trị sáng theo frontmatter. Dark canvas/surface/ink/secondary/border: #0F1928/#172335/#EAF0FA/#ABBBD1/#2B3C54. Chart/icon accent #73A8FF; primary action #2464DF. Theme riêng app với key toolbox.appearance, mặc định system. macOS sở hữu selection/focus/picker/table/scrollbar. Trạng thái luôn có chữ.

### Typography

System sans và monospaced digit. Page36 point, section title2, metric title2, CPU Overview32 point, freshness caption. Tooltip giữ tên đầy đủ; status wrap và không biến missing thành zero. Font native hỗ trợ hai locale.

### Layout

Mặc định1320×900, minimum960×640, sidebar220–280/ideal240, main inset28/gap18–20. Overview gồm CPU chart-summary, danh sách tiến trình và strip dung lượng; cuộn tài liệu giữ truy cập khi cửa sổ nhỏ. Raw route giữ nguyên. Processes dùng Table tự cuộn; inspector300 point khi main width>=900, còn lại sheet440×520. Module quản lý giữ owner mutation trong surface chung.

### Elevation & Depth

Surface adaptive phẳng, viền1 point; không shadow/gradient trang trí hoặc entrance animation. macOS sở hữu depth/focus sheet/menu. Chart giữ gap theo missing/generation, interpolation linear và area fill nhẹ có ý nghĩa dữ liệu.

### Shapes

Surface16, control compact9; geometry control native. Icon từ AppIcon.icns; MacinityLogo.png được bundle và đặt trên nền trắng tương phản ở Help. Không suy diễn file/driver identity từ branding.

### Components

MacinityTheme/orvenSurface dùng chung app/Core/Storage. Header/status/MetricReadout/MonitoringChart là display owner. Coordinator sở hữu route/focus PID-start tạm; MonitoringViewModel vẫn sở hữu snapshot/render demand. Giữ source/availability; chỉ HealthHistoryStore được lưu metric local opt-in có giới hạn; không thêm sampler/telemetry/privilege/kill/auto-cleanup.

### Do's and Don'ts

Ghi timestamp, CPU normalization, memory gồm cache, capacity khác rate, unsupported/stale. Overview chỉ xếp hạng CPU đã đo và hiển thị coverage; màn hình đầy đủ vẫn giữ process bị hạn chế quyền. App correlation không phải quyền xóa. Giữ confirmation/target checks cleanup-recovery, com.thang.toolbox, thư mục dữ liệu Toolbox, executable/module và preference keys cũ.

## 日本語

バッテリー状態はページ表示時または手動更新時に、時間制限とキャンセル対応のプロセスでmacOSのシステム情報から取得します。状態と最大容量は生の容量比と分け、シリアル番号や電源イベントは保存しません。残量と充電・電源状態は既存のヘルス履歴に毎分記録し、共通の保存期間を使用します。グラフは1時間・24時間・7日間に対応し、直近20件の充電・放電・外部電源の観測区間は欠測、古い値、一時停止、スリープ、再起動で区切ります。過去のmacOS履歴は取り込まず、観測時刻を正確な接続・切断時刻とは扱いません。

バッテリー画面に電源、低電力モード、OSの状態、充放電回数、設計・満充電容量、容量比率、電圧、アダプタ電力、有効な残り時間を追加。既存の低頻度サンプリングを利用し、欠測値は取得不可と表示。シリアル番号や生のregistryデータは保持しない。容量比率はmacOSの健康度ではなく、アダプタ電力は現在の充電電力ではない。古い観測値を明示し、古い電圧・アダプタ電力・残り時間は表示しない。

開発者向け拡張：Softwareに限定的・読み取り専用の開発ツールパス一覧を追加。既存のページ検索、theme、localeを共有します。バージョン・package解決は今後の範囲です。[決定と段階別受け入れ](../../docs/product/SUPER-APP-EXPANSION.md)を参照。

### 統合ワークスペース — 2026年10月15日

承認済み暗色デザインを採用。Canvas #0F1928、surface #172335、sidebar #131F30、text #EAF0FA、secondary #ABBBD1、border #2B3C54。Light/Systemと既存設定を維持。外観と言語の選択はサイドバーから設定画面へ移し、直接選択できる形式を維持。サイドバーに六つの見出しの下で21ページを直接表示。検索欄と重複するページ選択行を削除。小さいウィンドウでは一覧をスクロールし、設定と情報は下部に固定。ロゴ・項目・フッターの余白とアイコン列を統一し、ドロップダウンは使用しません。ストレージとネットワークの選択は利用可能な幅を使い、更新操作は別の行に配置。検索欄は選択肢が8件を超える場合または検索中に表示し、クリアボタンを備えます。ディスクはFilesに配置しAPFS・スナップショット・I/Oを表示。ネットワークはNetworkに配置し接続・接続変更・通信量を表示。旧diskNetworkルートはNetwork Activityへ復元。構成情報とセンサーを分離。温度画面はCPU/GPUの最高観測値を先頭に配置し、五つのグループボタン、選択グループの四列テーブルとセンサーグラフを表示。生のキーは保持し、CPU使用率・メモリ・I/Oの表は除外。既存観測値を使いgap/generationを維持。Applicationsは画面モデルの初回表示時に読み取り専用スキャンを実行し、モデルの存続中は結果を保持。手動再スキャンを維持し、同時実行を防止。読み込み中と空の結果を区別。幅900pt以上で340ptのAppDossier inspector、それ以外は既存sheetを使用。Overviewは実際のOS/RAM/CPU情報を使用。追加ツールの範囲と制限はdocs/product/SUPER-APP-EXPANSION.mdに記載。Theme ownerと既存control/samplerを維持。

| 従来の規則 | 決定 | Runtime owner |
| --- | --- | --- |
| エリアだけのサイドバー | 六つの見出しに21ページを直接表示 | MacinityNavigation / ToolboxCoordinator |
| 構成情報とセンサーが同じページ | My MacとThermalsに分離 | HardwareInspectorView.Mode |
| 青灰色の暗色canvas | 承認済みgraphite palette | MacinityTheme → sync_brand_tokens.py → website adapter |
| Native controlと一つのsampler | 維持 | UX-CONTRACT / MonitoringCoordinator |


### Wi-Fi and LAN

Wi-Fi/LANは既存theme/control/locale/chart/samplerを再利用。Page-owned明示read/probeはsingleoperation/cancel/timestamp、NWPathMonitorは表示pageのeventobserver。設定変更/identity保存なし。[Network contract](../../docs/monitoring/NETWORK-TOOLS.md)参照。


### Health workflows

ユーザーはlocal Health History/Baseline、opt-in Smart Alerts、Sensor Charts/Recording、session-only Network Connection Changesを承認しました。このscopeでは下記の従来persistence/alert制限を置き換えます。既存sampler、MonitoringChart、MacinityTheme、L10n、native controls、DiagnosticsExportViewを引き続き使用します。Persistenceは上限付きで初期off、notification権限は明示button、endpointはsession memoryのみ。[Health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md)を参照。

### Physical sensors

Physical Sensor Panelは既存hardware cadence、Macinity surface、native disclosure/Grid、共通exportを再利用。Mapped identity/stale current/missing/limited coverageを明示し、fanを変更しません。[Scope](../../docs/monitoring/PHYSICAL-SENSORS.md)参照。

### Hardware Inspector

Hardware InspectorはMacinity surface、native Grid、明示refresh、共通diagnostics preview/save sheetを再利用。Range resetはengine historyを保持し、欠測/current-staleを明示します。[Hardware scope](../../docs/monitoring/HARDWARE-TOOLS.md)参照。

### Feature expansion

新diagnosticsはMacinityTheme/native control/既存samplingを再利用。明示helper refreshはloading/error/cancellationを所有。承認済みCPU priority actionはnative確認とsame-user PID/start guardを持ちmonitoringは自動変更しません。Scope/prerequisiteは[feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md)。

#

### Sleep Inspector

Sleep Inspectorは既存surface/native refresh/process routeでBattery & Thermalを拡張。明示的snapshot、wall time、partial data、unverified ownerを示し、background polling/power設定変更なし。OS assertion type/nameはsource evidenceでapp instructionではない。

## Overview

利用者がMacinity observation-ring identityとlight diagnostics workspaceを承認しnative実装を依頼。10月15日承認の暗色センサー画面、Overview、一覧と詳細の構成を統合。Ring iconは維持。Native SwiftUIと実snapshotを使い、browser shell/demo dataではありません。明示依頼によりGUIはEnglish/Vietnamese/日本語/简体中文。LanguageはL10nが所有しdate/numberは選択localeを使用。Source timestamp/pathの意味は保持。

### Colors

ToolboxCore/MacinityTheme.swiftがadaptive tokenを所有。Lightはfrontmatter、darkは#0F1928/#172335/#EAF0FA/#ABBBD1/#2B3C54。Chart/icon accentは#73A8FF、actionは#2464DF。App-local toolbox.appearanceはsystem default。Native selection/focus/picker/table/scrollbarはOS管理、statusは文字付き。

### Typography

System sans/monospaced digits。Page36pt、section/metric title2、Overview CPU32pt、freshness caption。名前tooltip/status wrap、missingをzeroに変換しません。二GUI localeのnative font。

### Layout

Default1320×900/min960×640、sidebar220–280/ideal240、main inset28/gap18–20。OverviewはCPU instrument/summary、process list、storage strip。小windowでdocument scroll。Raw routeは安定。Process Tableは内部scroll、main width>=900で300pt inspector、他は440×520 sheet。Management mutation ownerは保持。

### Elevation & Depth

Flat adaptive surface/1pt border、装飾shadow/gradient/entrance animationなし。Sheet/menu depth/focusはOS。Chartはgeneration/missing gapとlinear interpolation、控えめなdata area fill。

### Shapes

Surface16/control9、native control geometry。AppIcon.icnsとbundled MacinityLogo.pngを使用し、Helpはwhite contrast plate。Brandからfile/driver identityを推測しません。

### Components

MacinityTheme/orvenSurfaceはapp/Core/Storage共有。Header/status/readout/chartがdisplay owner。Coordinatorがrouteとtransient PID/start focus、MonitoringViewModelが唯一のsnapshot/render demand owner。Source/availability保持、承認済みHealthHistoryStoreのみopt-in metricを制限付きで保存。追加sampler/telemetry/privilege/kill/auto-cleanupなし。

### Do's and Don'ts

Timestamp/CPU normalization/cache/capacity-rate/unsupported-staleを明記。Overviewは実CPU sampleのみrankしcoverageを表示、完全viewはrestricted processを保持。Correlationは削除許可ではありません。Confirmation/target checksとcom.thang.toolbox/Toolbox data directory/executable/module/preference keyを保持。

Action Center now owns the home presentation, with bounded favorites and summaries from existing state owners. Smart Diagnostics adds a read-only route. Work Profiles extends the existing workspace preset schema with optional audio and Keep Awake settings. Capability and verification boundaries: `docs/product/ACTION-WORKFLOWS.md`.
