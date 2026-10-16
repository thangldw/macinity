# Macinity native interaction contract

## English

Direct-choice policy: application selectors do not use dropdowns. Short choices use native radio groups, segments or visible adaptive buttons. Long sensor/metric/session choices use a searchable 144-point scrolling grid. Selection uses the existing binding and disabled state; no sampling, scanning or mutation is added. Native macOS menu bars and system file dialogs remain platform-owned.

The split-view detail column has a 600-point minimum width before SwiftUI measures wrapped copy. Without this boundary, a 96-point fitting proposal made the Developer Tools column demand more than 2,300 points of height and pushed the shell outside its 900-point window. The root minimum remains 960×640. The hosting-view regression test must fit within that minimum; lists remain scrollable. No clipping modifier or fixed window height hides overflow.

### Unified navigation

MacinityArea groups every persisted MacinitySection exactly once. MacinityCoordinator remains the route owner and remembers the last page per area in session memory. Cross-feature routes select the corresponding area without changing mutation selections or process identity validation. Six native sidebar rows replace the previous flat route inventory. MacinityChoicePicker keeps peer page choices visible in an adaptive button grid; long labels wrap and narrow windows never switch to a menu. Each destination keeps its own ScrollView/Table and operation lifecycle. The localized window title remains the selected page title.

MacinityToolSearch owns a bounded, local route catalog. Command-K and the sidebar button open a native sheet. A labeled native TextField filters by localized page/area words; no query persistence, filesystem scan, remote search or default Enter execution is introduced. Clear restores input focus, Escape/Close dismiss, native buttons open results. Files/app-content search is explicitly excluded in the UI. Four locales use the same key set. Native AX/keyboard, narrow geometry, themes and locale checks are recorded separately from build/static checks.


### Wi-Fi and LAN

Wi-Fi/LAN uses the existing Macinity theme, native controls, locale provider, MonitoringChart and rate sampler. A page-owned explicit read/probe service has one operation, cancellation and timestamped results; NWPathMonitor is a visible-page event observer. No configuration changes or persisted identities. See [network contract](../../docs/monitoring/NETWORK-TOOLS.md).


### Health workflows

The user authorized local Health History/Baseline, opt-in Smart Alerts, Sensor Charts/Recording and session-only Network Connection Changes. This scoped change supersedes earlier no-persistence/no-alert wording below. Existing sampler, MonitoringChart, MacinityTheme, L10n, native controls and DiagnosticsExportView remain owners. Persistence is bounded/default-off; notification permission is explicit; endpoints stay in session memory. See [health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md).


### Physical sensors

Physical Sensor Panel reuses the existing hardware cadence, Macinity surface, native disclosure/Grid and shared export. Mapped identity, stale current, missing values and limited coverage are explicit; no fan mutation. See [physical sensor scope](../../docs/monitoring/PHYSICAL-SENSORS.md).

### Hardware Inspector

Hardware Inspector reuses Macinity surfaces, native Grid, explicit refresh and the shared diagnostics preview/save sheet. Range reset preserves engine history; missing/current-stale fields remain explicit. See [hardware scope](../../docs/monitoring/HARDWARE-TOOLS.md).

Coverage and privacy explanations in bounded sheets must wrap vertically, remain readable in full, and allow scrolling to related actions. App Activity Timeline explicitly fixes vertical text sizing; a clipped or ellipsized warning is not a completed narrow-window gate. Native screenshots and AX evidence remain separate from static audits.

### Feature expansion

New diagnostics reuse MacinityTheme, native controls and existing sampling. Explicit helper refresh owns loading/error/cancellation states. The approved CPU priority action has its own native confirmation and same-user PID/start guard; monitoring does not change process scheduling automatically. Scope and prerequisites are defined in [feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md).

Native redesign approved: shared MacinityTheme and surfaces replace the old material/gradient headers. Overview reads the existing monitoring snapshot and routes Inspect process with a full PID/start identity; no storage selection is made. Process details use a persistent inspector at wide sizes and an OS-owned modal sheet at smaller sizes. System/light/dark is app-local with toolbox.appearance defaulting to system. Table, picker, focus and scroll ownership stay native. No runtime schema or data directory changes.

### Sources and ownership

The approved 3.0 specification, [architecture](../../docs/ARCHITECTURE.md), [privacy](../../PRIVACY.md), [security](../../SECURITY.md), and [release readiness](../../docs/production/RELEASE-READINESS.md) define the native product boundary. The root DESIGN.md belongs to the marketing site; [native DESIGN.md](DESIGN.md) preserves the existing SwiftUI identity. English/Vietnamese/Japanese/Simplified Chinese GUI is owned by L10n and the shell locale. Every packaged locale merges the module tables into Localizable for native controls.

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
| --- | --- | --- | --- | --- |
| Table Selection | SwiftUI Table with ProcessRowID | DESIGN.md; approved 3.0 spec; metric contracts | One read-only row; verified PID/start identity, no cleanup selection. | ProcessTests; native keyboard check |
| Select/Listbox | Native SwiftUI Picker | DESIGN.md; approved 3.0 spec; metric contracts | OS popup geometry and keyboard behavior are accepted. | native keyboard and popup check |
| Form | SwiftUI Form / SettingsView | DESIGN.md; approved 3.0 spec; metric contracts | Stable preferences; menu bar default off, one sampler, no privilege requests. | MonitoringPreferencesTests; Settings GUI |
| Scrollbar | Native macOS ScrollView/Table | DESIGN.md; approved 3.0 spec; metric contracts | System scrollbar preferences remain unchanged; table owns its scroll. | native window scroll check |
| Search | ProcessesView local TextField | DESIGN.md; approved 3.0 spec; metric contracts | Clear is immediate and returns focus; no remote request or query persistence. | ProcessTests; clear/no-results GUI |
| App Dossier and discovery | ApplicationsView / AppDossierView / ApplicationScanner | Market enhancements; DESIGN.md | Explicit inspection; scan-time size/evidence; app/Bundle ID search; no extra scan or cleanup | Universal/unit/locale checks; native UI pending unlock |
| Sleep inspection | SleepInspectorView / MonitoringCoordinator | DESIGN.md; approved feature exploration | Explicit refresh; timestamped snapshot; unknown ownership; no mutation or polling. | live provider smoke; PID reuse/parser fixtures; Light/Dark, EN/VI, explicit refresh and verified navigation observed; full VoiceOver unverified |
| Charts | MonitoringChart | DESIGN.md; approved 3.0 spec; metric contracts | Labeled axes, missing-sample gaps, VoiceOver numeric summary and previous/next buttons. | gap and numeric summary GUI; keyboard samples |
| Navigation | MacinityCoordinator / MacinityShellView | DESIGN.md; approved 3.0 spec; metric contracts | Existing raw values persist; cross-feature actions navigate without selecting mutations. | MacinityAppTests; deep-link GUI |
| Feedback | MetricReadout / MetricSample | DESIGN.md; approved 3.0 spec; metric contracts | Availability, unit and timestamp remain visible; missing data never becomes zero. | SamplingTests; live/stale GUI |

### Workflow and lifecycle

One app-owned runtime owns routing and monitoring across the main, fallback and menu bar surfaces. Window markers identify visible main windows; inactive/closed windows pause polling unless menu bar is explicitly enabled. Enabled background sampling uses 5 s cadence; sleep pauses, wake warms up and Quit joins/cancels work. Closing a window leaves the existing Dock app available to reopen. Scheduled-scan invocation bypasses monitoring.

Process details revalidate identity before and after counters; Applications navigation additionally checks live bundle mapping and launch date. Parent PID is advisory; a verified ancestry tree is deferred because parent start identity is not supplied in that field. Read-only views have loading, stale, error, permission, unsupported and no-results states. Serious alerts, process kill and automatic cleanup are excluded. Automatic alerts remain unavailable until separately authorized diagnostic rules exist.

Existing foreground confirmation, canonical validation, Trash/recovery and legacy import remain with their feature owners. No monitoring data is persisted. Search/selection are transient to avoid storing process names; section and menu preferences persist. Accessibility, locale, light/dark, small supported window and actual lifecycle checks must be recorded separately from compilation.

## Tiếng Việt

Quy tắc chọn trực tiếp: bộ chọn trong ứng dụng không dùng dropdown. Nhóm ngắn dùng radio, segmented hoặc nút luôn hiện và tự xuống hàng. Danh sách sensor/chỉ số/phiên dài dùng lưới cuộn cao 144 điểm có tìm kiếm. Giữ binding và trạng thái disabled cũ; không thêm sampling, scan hay mutation. Menu bar macOS và hộp thoại tệp hệ thống vẫn do nền tảng quản lý.

Cột nội dung split view có chiều rộng tối thiểu 600 điểm trước khi SwiftUI đo văn bản xuống dòng. Khi thiếu giới hạn này, phép đo ở 96 điểm khiến trang Công cụ lập trình đòi hơn 2.300 điểm chiều cao và đẩy khung giao diện khỏi cửa sổ cao 900 điểm. Kích thước tối thiểu toàn cửa sổ vẫn là 960×640. Regression test của hosting view phải nằm trong giới hạn đó; danh sách vẫn cuộn được. Không dùng clipping hoặc chiều cao cửa sổ cố định để che lỗi tràn.

### Điều hướng thống nhất

MacinityArea gom mỗi MacinitySection đúng một lần. Coordinator giữ route, nhớ trang cuối trong từng khu vực ở RAM và giữ nguyên kiểm tra định danh/selection mutation. Sáu hàng sidebar native; nút chọn trang xuống hàng khi hẹp/nhãn dài, không dùng dropdown. Mỗi trang giữ ScrollView/Table và lifecycle riêng; title theo trang và locale. Search qua nút hoặc Command-K, sheet native lọc catalog công cụ/trang theo từ đã dịch; không lưu query/quét tệp/request mạng/Enter tự chạy. Clear trả focus, Escape/Close đóng, button native mở kết quả. UI ghi rõ không tìm nội dung tệp/app. Bốn locale cùng key; runtime QA riêng với build/static.


### Wi-Fi and LAN

Wi-Fi/LAN dùng theme/control/locale/chart/sampler cũ; owner riêng cho read/probe theo yêu cầu, một operation/cancel/timestamp. NWPathMonitor quan sát event khi trang mở. Không đổi cấu hình hoặc lưu identity. Xem [network contract](../../docs/monitoring/NETWORK-TOOLS.md).


### Health workflows

Người dùng cho phép Health History/Baseline trên máy, Smart Alerts opt-in, Sensor Charts/Recording và Network Connection Changes chỉ trong phiên. Scope này thay thế các hạn chế persistence/alert cũ bên dưới. Sampler, MonitoringChart, MacinityTheme, L10n, native controls và DiagnosticsExportView hiện có tiếp tục sở hữu chức năng. Persistence có giới hạn và mặc định tắt; quyền notification qua nút riêng; endpoint chỉ giữ trong RAM phiên. Xem [health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md).

### Physical sensors

Physical Sensor Panel dùng cadence phần cứng cũ, surface Macinity, disclosure/Grid native và export chung. Ghi rõ mapped identity, current stale, missing/limited coverage; không đổi quạt. Xem [scope sensor](../../docs/monitoring/PHYSICAL-SENSORS.md).

### Hardware Inspector

Hardware Inspector dùng lại surface Macinity, Grid native, refresh theo yêu cầu và sheet preview/save diagnostics chung. Reset range giữ history engine; field thiếu/current-stale được ghi rõ. Xem [scope phần cứng](../../docs/monitoring/HARDWARE-TOOLS.md).

Giải thích coverage/privacy trong sheet có kích thước giới hạn phải wrap theo chiều dọc, đọc được đầy đủ và cuộn tới action liên quan. App Activity Timeline cố định vertical text sizing; cảnh báo bị cắt hoặc rút gọn không đạt gate cửa sổ nhỏ. Screenshot/AX native được ghi riêng với static audit.

### Feature expansion

Diagnostics mới dùng lại MacinityTheme, control native và sampling cũ. Refresh helper theo yêu cầu có loading/error/cancellation. CPU priority đã được cho phép có xác nhận native riêng và guard cùng user/PID/start; monitoring không tự đổi scheduling. Scope/prerequisite ở [feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md).

Native redesign approved: shared MacinityTheme and surfaces replace the old material/gradient headers. Overview reads the existing monitoring snapshot and routes Inspect process with a full PID/start identity; no storage selection is made. Process details use a persistent inspector at wide sizes and an OS-owned modal sheet at smaller sizes. System/light/dark is app-local with toolbox.appearance defaulting to system. Table, picker, focus and scroll ownership stay native. No runtime schema or data directory changes.

### Nguồn và ownership

Đặc tả 3.0 đã chấp thuận, [architecture](../../docs/ARCHITECTURE.md), [privacy](../../PRIVACY.md), [security](../../SECURITY.md), [release readiness](../../docs/production/RELEASE-READINESS.md) quy định native boundary. DESIGN.md ở root thuộc marketing; [DESIGN.md native](DESIGN.md) giữ identity SwiftUI hiện có. L10n/shell locale sở hữu GUI English/Vietnamese/Japanese/Simplified Chinese. Mỗi locale được đóng gói merge table module vào Localizable cho native control.

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
| --- | --- | --- | --- | --- |
| Table Selection | SwiftUI Table / ProcessRowID | DESIGN.md; approved 3.0 spec; metric contracts | Một row read-only, PID/start identity verify, không chọn cleanup. | ProcessTests; native keyboard check |
| Select/Listbox | SwiftUI Picker native | DESIGN.md; approved 3.0 spec; metric contracts | Chấp nhận geometry popup/keyboard OS. | native keyboard and popup check |
| Form | SwiftUI Form / SettingsView | DESIGN.md; approved 3.0 spec; metric contracts | Preference ổn định, menu bar default-off, một sampler, không xin privilege. | MonitoringPreferencesTests; Settings GUI |
| Scrollbar | ScrollView/Table native macOS | DESIGN.md; approved 3.0 spec; metric contracts | Không đổi scrollbar preference system; table sở hữu scroll. | native window scroll check |
| Search | TextField local ở ProcessesView | DESIGN.md; approved 3.0 spec; metric contracts | Clear ngay/khôi phục focus, không request remote/persist query. | ProcessTests; clear/no-results GUI |
| App Dossier and discovery | ApplicationsView / AppDossierView / ApplicationScanner | Market enhancements; DESIGN.md | Explicit inspection; scan-time size/evidence; app/Bundle ID search; no extra scan or cleanup | Universal/unit/locale checks; native UI pending unlock |
| Sleep inspection | SleepInspectorView / MonitoringCoordinator | DESIGN.md; approved feature exploration | Explicit refresh; timestamped snapshot; unknown ownership; no mutation or polling. | live provider smoke; PID reuse/parser fixtures; Light/Dark, EN/VI, explicit refresh and verified navigation observed; full VoiceOver unverified |
| Charts | MonitoringChart | DESIGN.md; approved 3.0 spec; metric contracts | Axis có label, gap mẫu thiếu, numeric summary VoiceOver, nút trước/sau. | gap and numeric summary GUI; keyboard samples |
| Navigation | MacinityCoordinator / MacinityShellView | DESIGN.md; approved 3.0 spec; metric contracts | Giữ raw value cũ, cross-feature chỉ navigation không chọn mutation. | MacinityAppTests; deep-link GUI |
| Feedback | MetricReadout / MetricSample | DESIGN.md; approved 3.0 spec; metric contracts | Availability/unit/timestamp rõ; missing không thành zero. | SamplingTests; live/stale GUI |

### Workflow và lifecycle

Một runtime app sở hữu route/monitoring cho main/fallback/menu bar. Window marker nhận diện main visible/key; inactive/closed pause trừ khi menu bar opt-in. Background bật thì cadence 5 s; sleep pause, wake warm-up, Quit join/cancel. Đóng window vẫn giữ app trong Dock để mở lại. Scheduled scan bỏ qua monitoring.

Detail revalidate identity trước/sau counter; navigation Applications còn kiểm tra bundle mapping live/launch date. Parent PID advisory; hoãn verified ancestry tree vì field không cung cấp parent start identity. View read-only có loading/stale/error/permission/unsupported/no-results. Không serious alert, kill, automatic cleanup. Alert tự động chưa có tới khi rule diagnostics được cho phép riêng.

Foreground confirmation/canonical validation/Trash-recovery/legacy import giữ owner feature. Monitoring data chỉ lưu theo contract HealthHistoryStore opt-in có giới hạn. Search/selection tạm thời để tránh lưu tên process; section/menu preference persistent. Ghi riêng accessibility/locale/light-dark/window hẹp/lifecycle, không suy luận từ compile.

## 日本語

直接選択方針：アプリ内selectorにdropdownを使いません。少数の選択肢はnative radio、segment、常時表示のadaptive buttonを使用。長いsensor/metric/session一覧は検索可能な高さ144ポイントのscroll gridを使用。既存bindingとdisabled状態を維持し、sampling、scan、mutationは追加しません。macOS menu barとsystem file dialogはOS管理のままです。

split viewの詳細列は、SwiftUIが折り返しテキストを測定する前に最小幅600ポイントを持ちます。この境界がない場合、幅96ポイントでの測定により開発ツールが2,300ポイント以上の高さを要求し、高さ900ポイントのウィンドウ外へシェルがはみ出しました。ルートの最小サイズは960×640のままです。hosting viewの回帰テストはその範囲内に収まり、一覧はスクロール可能でなければなりません。clippingや固定ウィンドウ高さで問題を隠しません。

### 統合ナビゲーション

MacinityAreaは各MacinitySectionを一度だけ分類。Coordinatorはrouteとエリア別の直近ページを管理し、mutation selectionとidentity検証を維持。六つのnative sidebar項目、常時表示の選択ボタンを使い、幅不足時は折り返します。各ページのscroll ownerとlifecycle、ローカライズ済みtitleを保持。Command-K/ボタンでnative検索sheetを開き、ツール/ページの翻訳名を検索。Query保存、file scan、network request、Enterによる自動実行なし。Clearでfocusを戻しEscape/Closeで閉じ、native buttonで移動。四言語で同じkey。Runtime QAとbuild/static evidenceを区別。


### Wi-Fi and LAN

Wi-Fi/LANは既存theme/control/locale/chart/samplerを再利用。Page-owned明示read/probeはsingleoperation/cancel/timestamp、NWPathMonitorは表示pageのeventobserver。設定変更/identity保存なし。[Network contract](../../docs/monitoring/NETWORK-TOOLS.md)参照。


### Health workflows

ユーザーはlocal Health History/Baseline、opt-in Smart Alerts、Sensor Charts/Recording、session-only Network Connection Changesを承認しました。このscopeでは下記の従来persistence/alert制限を置き換えます。既存sampler、MonitoringChart、MacinityTheme、L10n、native controls、DiagnosticsExportViewを引き続き使用します。Persistenceは上限付きで初期off、notification権限は明示button、endpointはsession memoryのみ。[Health workflow contract](../../docs/monitoring/HEALTH-WORKFLOWS.md)を参照。

### Physical sensors

Physical Sensor Panelは既存hardware cadence、Macinity surface、native disclosure/Grid、共通exportを再利用。Mapped identity/stale current/missing/limited coverageを明示し、fanを変更しません。[Scope](../../docs/monitoring/PHYSICAL-SENSORS.md)参照。

### Hardware Inspector

Hardware InspectorはMacinity surface、native Grid、明示refresh、共通diagnostics preview/save sheetを再利用。Range resetはengine historyを保持し、欠測/current-staleを明示します。[Hardware scope](../../docs/monitoring/HARDWARE-TOOLS.md)参照。

サイズ制限付きsheetのcoverage/privacy説明は縦方向に折り返し、全文を読めて関連actionへscrollできること。App Activity Timelineはvertical text sizingを明示固定。警告の切れ/省略表示はnarrow-window gate未完了です。Native screenshot/AX evidenceとstatic auditを区別します。

### Feature expansion

新diagnosticsはMacinityTheme/native control/既存samplingを再利用。明示helper refreshはloading/error/cancellationを所有。承認済みCPU priority actionはnative確認とsame-user PID/start guardを持ちmonitoringは自動変更しません。Scope/prerequisiteは[feature expansion](../../docs/monitoring/FEATURE-EXPANSION.md)。

Native redesign approved: shared MacinityTheme and surfaces replace the old material/gradient headers. Overview reads the existing monitoring snapshot and routes Inspect process with a full PID/start identity; no storage selection is made. Process details use a persistent inspector at wide sizes and an OS-owned modal sheet at smaller sizes. System/light/dark is app-local with toolbox.appearance defaulting to system. Table, picker, focus and scroll ownership stay native. No runtime schema or data directory changes.

### Source と ownership

承認済み 3.0 spec、[architecture](../../docs/ARCHITECTURE.md)、[privacy](../../PRIVACY.md)、[security](../../SECURITY.md)、[release readiness](../../docs/production/RELEASE-READINESS.md) が native boundary。Root DESIGN.md は marketing、[native DESIGN.md](DESIGN.md) は既存 SwiftUI identity。English/Vietnamese/Japanese/Simplified Chinese GUIはL10n/shell localeが所有。各packaged localeはmodule tableをLocalizableへmergeしnative controlに適用。

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
| --- | --- | --- | --- | --- |
| Table Selection | SwiftUI Table / ProcessRowID | DESIGN.md; approved 3.0 spec; metric contracts | Read-only one row、verified PID/start identity、cleanup selection なし。 | ProcessTests; native keyboard check |
| Select/Listbox | Native SwiftUI Picker | DESIGN.md; approved 3.0 spec; metric contracts | OS popup geometry/keyboard behavior を受容。 | native keyboard and popup check |
| Form | SwiftUI Form / SettingsView | DESIGN.md; approved 3.0 spec; metric contracts | Stable preference、menu bar default-off、single sampler、privilege request なし。 | MonitoringPreferencesTests; Settings GUI |
| Scrollbar | Native macOS ScrollView/Table | DESIGN.md; approved 3.0 spec; metric contracts | System scrollbar preference 未変更、table が scroll を所有。 | native window scroll check |
| Search | ProcessesView local TextField | DESIGN.md; approved 3.0 spec; metric contracts | Immediate clear/focus restore、remote request/query persistence なし。 | ProcessTests; clear/no-results GUI |
| App Dossier and discovery | ApplicationsView / AppDossierView / ApplicationScanner | Market enhancements; DESIGN.md | Explicit inspection; scan-time size/evidence; app/Bundle ID search; no extra scan or cleanup | Universal/unit/locale checks; native UI pending unlock |
| Sleep inspection | SleepInspectorView / MonitoringCoordinator | DESIGN.md; approved feature exploration | Explicit refresh; timestamped snapshot; unknown ownership; no mutation or polling. | live provider smoke; PID reuse/parser fixtures; Light/Dark, EN/VI, explicit refresh and verified navigation observed; full VoiceOver unverified |
| Charts | MonitoringChart | DESIGN.md; approved 3.0 spec; metric contracts | Axis label、missing gap、VoiceOver numeric summary、previous/next button。 | gap and numeric summary GUI; keyboard samples |
| Navigation | MacinityCoordinator / MacinityShellView | DESIGN.md; approved 3.0 spec; metric contracts | Legacy raw value 保持、cross-feature は navigation のみで mutation を選択しません。 | MacinityAppTests; deep-link GUI |
| Feedback | MetricReadout / MetricSample | DESIGN.md; approved 3.0 spec; metric contracts | Availability/unit/timestamp 表示、missing を zero にしません。 | SamplingTests; live/stale GUI |

### Workflow と lifecycle

App-owned runtime が main/fallback/menu bar の routing/monitoring を所有。Window marker で visible main を識別、inactive/closed は menu bar opt-in 以外 pause。Background は 5 s cadence、sleep pause、wake warm-up、Quit join/cancel。Close 後も既存 Dock app を reopen 可能。Scheduled scan は monitoring を bypass。

Detail は counter 前後で identity を revalidate、Applications は live bundle mapping/launch date も確認。Parent PID は advisory、parent start identity が field にないため verified ancestry tree は deferred。Read-only view は loading/stale/error/permission/unsupported/no-results。Serious alert/kill/automatic cleanup なし。別途承認した diagnostic rule まで automatic alert は unavailable。

Foreground confirmation/canonical validation/Trash-recovery/legacy import は feature owner を維持。Monitoring data persistence なし。Process name を保存しないため search/selection は transient、section/menu preference は persistent。Accessibility/locale/light-dark/narrow window/lifecycle は compilation と別に記録。
