# Orven health workflows

## English

### Approved scope and ownership

The user authorized Health History & Baseline, Smart Alerts, Sensor Charts and Network Connection Changes on 2026-10-14. This supersedes earlier observation-only/no-persistence/no-alert restrictions for these scoped capabilities. Orven 3.0 production publication is authorized through the reviewed release workflow. No new sampler, driver, privileged helper, network interception, automatic cleanup, priority or fan mutation is added.

MonitoringViewModel consumes the existing coordinator stream. HealthHistoryViewModel owns recording demand and presentation; HealthHistoryStore serializes versioned local storage off the main actor. DiagnosticInsights remains the canonical evidence-rule owner. AlertGate adds re-arm/cooldown; SmartAlertsViewModel owns OS notification delivery and routing. NetworkInspection remains the explicit bounded read owner; NetworkChangeTracker compares those results. MonitoringChart remains the shared bounded Canvas owner, extended with time-window and gap limits. DiagnosticsExportView owns exact frozen preview/save for JSON and CSV. L10n, OrvenTheme and native controls remain canonical.

### Health History & Baseline

History is default-off, opt-in, and local to Application Support/Toolbox/health-history-v1.json. It records at most one point per 60 seconds using existing active or menu-bar demand. Enabling history does not enable background sampling. Retention is 24 hours or seven days, at most10080 records, at most36 fields per record and24MiB per file. The byte budget may discard older observations before the time retention limit, with an explicit omitted-record count; seven days is an upper bound, not guaranteed complete coverage. Atomic writes occur only when a record or explicit retention/baseline update is saved. Load validates schema, count, field limits, finite values, IDs and chronological order. Corrupt/unknown/oversized files block writes and remain preserved; no automatic reset is performed.

Only system CPU, occupied-memory percentage, pressure/thermal states and mapped read-only physical sensors are stored. No process names, PID list, paths, serial, hostname or network endpoints are included. Each field retains availability, source, unit and its actual observation wall timestamp. Missing/stale fields have no value. A new segment is used after pause, generation change, uptime discontinuity or wall/uptime disagreement. Charts do not bridge missing values or segments. Pressure and thermal history are categorical observations, not inferred temperatures or health diagnoses. History stops at Quit. Expired records are omitted on read and removed on the next successful write; an app that never runs and writes does not actively erase expired on-disk data.

Capture Baseline freezes the latest30–60 records. Comparisons use the median of available finite fields with the same key/unit, deduplicated by actual field timestamp, and at least ten observations on each side. Recent values are up to60 records strictly newer than capture. Differences are descriptive, not causal, workload-normalized or proof of regression. The baseline expires with retention.

### Smart Alerts

Alerts default off and only evaluate fresh foreground-active evidence. The existing rules are sustained system CPU >=85% for30 seconds with continuous same-generation samples, non-normal memory pressure, startup capacity below10% available, and serious/critical thermal state. Paused/stale/missing data does not establish a finding. Re-arm requires30 seconds of continuously observed recovery: CPU below70%, normal pressure, available capacity >=15%, or nominal/fair thermal. Missing evidence and gaps over15 seconds reset recovery timing. Repeat delivery is at least15 minutes apart; Snooze suppresses new events for one hour. Disabling clears the gate. No action mutates the Mac.

In-app events are capped at100, in memory. OS notification permission is requested only by the explicit button. Notification services initialize only within the Orven bundle, avoiding unsupported command-line/XCTest hosts. If permission is denied or delivery fails, evidence remains in-app. Clicking a delivered notification navigates through ToolboxCoordinator to its evidence section. Delivery requires a functioning OS notification service and user permission; rule tests are not OS delivery proof.

### Sensor Charts and Recording

A recording uses the existing stream every ten seconds for15,30 or60 minutes, at most360 records, held in memory until Quit. Sleep extends wall-clock duration because the monitoring uptime clock excludes sleep. Inactivity without opt-in menu-bar monitoring creates gaps; no samples are backfilled. Stop preserves the completed session. Start replaces the previous in-memory session. CPU/memory and individual mapped CPU/GPU temperature, fan RPM, battery temperature and system-power metrics are selectable when observed. Units and sources remain explicit. Cached physical timestamps are deduplicated in charts and baseline statistics.

Charts use linear bounded Canvas segments, keyboard Previous/Next sample controls, time labels and numeric accessibility summaries. Export previews the exact frozen JSON or CSV saved through NSSavePanel; missing values stay blank/null with availability, and CSV uses quoted fields plus locale-independent numeric data. No export/upload is automatic. A session is not a stress test or benchmark, fan controller, CPU-package power measurement or calibrated per-core temperature claim.

### Network Connection Changes

Tracking is default-off and session-memory only. Explicit Refresh reuses the bounded lsof snapshot and verified PID/start identities. Stable comparison keys are process identity, transport and numeric endpoint; descriptor/order changes alone do not create events. Duplicate descriptors coalesce; conflicting states become Unknown. Events are Newly observed, No longer observed and State changed, not inferred open/close timestamps. Only observable verified sockets are compared. The first successful full-cap snapshot establishes a baseline; failed/cancelled/truncated reads, route departure and intervals over ten minutes reset it. No historical disappearance is inferred across those boundaries.

Retention is200 events; display shows the latest50 and discloses that limit. Unverified sockets and omitted old events are counted. Clear resets events and baseline; disabling clears session state. Process names/endpoints remain only in memory, with no persistence, DNS lookups, packet capture, firewall, traffic totals or periodic polling. Restricted processes and short-lived connections remain outside coverage. PID reuse produces separate identities.

### Verification

Owner tests protect persistence/cadence/retention/real reload, corruption preservation, baseline deduplication, connection identity/state/coverage/event bounds, alert hysteresis/cooldown/gaps/snooze and CSV escaping/missing states. The original notification-host XCTest abort and corrected-run evidence are preserved in evidence/health-expansion. Current unit/build/format/localization/static/native/resource results must be recorded with the new candidate hash; historical sensor engine soak and prior GUI profile do not verify these new workflows.

External gates remain physical Intel/macOS13, full VoiceOver, critical Japanese native copy review and native notification delivery. Native notification delivery is unverified until permission and actual delivery/action are observed. No publication is implied by local implementation or an ad-hoc contract.

## Tiếng Việt

### Scope và ownership

Người dùng cho phép Health History/Baseline, Smart Alerts, Sensor Charts và Network Connection Changes ngày2026-10-14, thay thế giới hạn persistence/alert cũ trong scope này. Người dùng đã cho phép phát hành Orven 3.0 qua workflow đã kiểm chứng. Không thêm sampler, driver, helper đặc quyền, interception, cleanup tự động, đổi priority/quạt.

MonitoringViewModel nhận stream coordinator hiện có; HealthHistoryViewModel quản lý ghi/presentation, HealthHistoryStore tuần tự hóa storage versioned ngoài main actor. DiagnosticInsights sở hữu rule evidence; AlertGate quản lý recovery/cooldown, SmartAlertsViewModel quản lý notification/routing. NetworkInspection đọc bounded rõ ràng, NetworkChangeTracker so sánh snapshot. MonitoringChart dùng Canvas bounded/window/gap. DiagnosticsExportView preview/lưu JSON/CSV chốt chính xác; L10n/OrvenTheme/native controls giữ ownership.

### Health History & Baseline

History mặc định off, opt-in, file Application Support/Toolbox/health-history-v1.json. Tối đa một record/60giây với demand active/menu-bar hiện có; bật history không bật nền. Retention24giờ/7ngày,10080record,36field/record,24MiB/file. Budget bytes có thể bỏ record trước thời hạn và báo số bỏ;7ngày là giới hạn trên. Atomic write chỉ khi thêm record/đổi retention/baseline. Load kiểm tra schema/count/field/finite/ID/thứ tự; file hỏng/unknown/quá lớn được giữ nguyên và chặn write, không reset tự động.

Chỉ lưu CPU hệ thống, phần trăm bộ nhớ chiếm dụng, pressure/thermal và sensor vật lý chỉ đọc. Không tên process/PIDlist/path/serial/hostname/endpoint. Field giữ availability/source/unit/timestamp thực; missing/stale không có value. Pause/generation/uptime discontinuity/wall-uptime lệch tạo segment mới; chart không nối gap/segment. Pressure/thermal là categorical, không suy nhiệt độ/chẩn đoán. Quit dừng history. Record hết hạn bỏ khi read, chỉ xóa disk trong write thành công tiếp theo; app không chạy không tự xóa.

Capture Baseline chốt30–60record mới nhất. Median cùng key/unit, finite/available, dedupe timestamp field thật, ít nhất10quan sát mỗi phía; gần đây tối đa60record sau thời điểm capture. Chênh lệch chỉ mô tả, không causal/workload-normalized/proofregression. Baseline hết hạn theo retention.

### Smart Alerts

Mặc định off, chỉ xét evidence foreground-active mới. Rule CPU>=85% liên tục30giây cùng generation, pressure không normal, startup available<10%, thermal serious/critical. Paused/stale/missing không tạo finding. Re-arm cần recovery quan sát liên tục30giây:CPU<70%, pressure normal, available>=15%, thermal nominal/fair. Missing/gap>15giây reset recovery; lặp ít nhất15phút, Snooze1giờ, disable xóa gate. Không đổi máy.

Event tối đa100 trong RAM. Quyền notification chỉ qua nút; service chỉ khởi tạo trong bundle, tránh CLI/XCTest host không hỗ trợ. Denied/deliveryfail giữ evidence trong app. Click notification đã giao đi qua ToolboxCoordinator tới evidence. Rule tests không proof OS delivery; cần quyền và service thực.

### Sensor Charts và Recording

Stream hiện có ghi mỗi10giây trong15/30/60phút, tối đa360record trong RAM tới Quit. Clock uptime không tính sleep nên sleep kéo dài wall duration. Inactive không có menu-bar opt-in tạo gap, không backfill. Stop giữ session, Start thay session cũ. Chọn CPU/memory và sensor CPU/GPU/fanRPM/battery/systempower khi quan sát; unit/source rõ ràng, timestamp sensor cache dedupe trong chart/baseline.

Chart Canvas tuyến tính bounded, nút keyboard Previous/Next, time labels và numeric accessibility summary. Export preview JSON/CSV chốt đúng bytes trước NSSavePanel; missing blank/null kèm availability, quoted CSV/numeric không phụ thuộc locale. Không tự export/upload. Không stress test/benchmark/fancontrol/CPU-packagepower/calibratedper-coretemp.

### Network Connection Changes

Mặc định off/RAM phiên. Refresh dùng snapshot lsof bounded và PID/start đã xác minh. Key gồm processidentity/transport/numericendpoint; đổi descriptor/order không tạo event. Duplicate coalesce, state mâu thuẫn Unknown. Event Newly observed/No longer observed/State changed là quan sát, không timestamp open/close suy diễn. Chỉ socket identityverified; snapshot fullcap thành công đầu tạo baseline. Failed/cancel/truncated/routeleave/gap>10phút reset; không suy mất connection qua ranh giới.

Giữ200event, hiển thị50mới nhất/báo giới hạn; count socket unverified/omission. Clear reset event/baseline; disable xóa RAM phiên. Tênprocess/endpoint không persist/DNS/capture/firewall/traffictotals/polling. Process restricted/connection ngắn ngoài coverage, PIDreuse identityriêng.

### Kiểm chứng

Owner tests bảo vệ persistence/cadence/retention/reload thật/corruptionpreservation/baseline dedupe, identity/state/coverage/eventbounds, alert hysteresis/cooldown/gaps/snooze và CSVescaping/missing. Giữ evidence notification-host XCTest abort và correctedrun trong evidence/health-expansion. Unit/build/format/locale/static/native/resource phải gắn hashcandidate; sensorsoak/GUI cũ không proofworkflowsmới.

Gate ngoài còn Intel/macOS13 vật lý, fullVoiceOver, criticalJAcopyreview và native notification delivery. OSnotification delivery/action chưa proof tới khi quan sát thực sau cấp quyền. Localimplementation/ad-hoccontract không hàm ý publish.

## 日本語

### Scopeとownership

2026-10-14にHealth History/Baseline、Smart Alerts、Sensor Charts、Network Connection Changesを承認。このscopeは従来のpersistence/alert制限を置換。Orven 3.0の公開はreview済みrelease workflowで承認されています。新sampler/driver/privilegedhelper/interception/自動cleanup/priority・fan変更なし。

MonitoringViewModelは既存coordinator stream、HealthHistoryViewModelは記録/presentation、HealthHistoryStoreはmain actor外のversioned storageを所有。DiagnosticInsightsがrule evidence、AlertGateがrecovery/cooldown、SmartAlertsViewModelがnotification/routing。NetworkInspectionは明示boundedread、NetworkChangeTrackerは比較。MonitoringChartのCanvas/window/gap、DiagnosticsExportViewの凍結JSON/CSVpreview/save、L10n/OrvenTheme/nativecontrolを継続使用。

### Health History & Baseline

初期off/opt-in、Application Support/Toolbox/health-history-v1.jsonに保存。既存active/menu-bar demandで60秒に最大1record、history有効化は背景samplingを有効にしません。Retention24時間/7日、10080record、36field/record、24MiB/file。Bytebudgetで期限前に古いrecordを省略しcount表示、7日は上限。Record/retention/baseline保存時のみatomicwrite。Loadはschema/count/field/finite/ID/時系列を検証。破損/unknown/oversizedfileは保存しwrite停止、自動resetなし。

SystemCPU/occupiedmemory%/pressure/thermal/read-onlysensorのみ。Processname/PIDlist/path/serial/hostname/endpointなし。Fieldのavailability/source/unit/実観測timestampを保持、missing/staleはvalueなし。Pause/generation/uptime discontinuity/wall-uptime不一致は新segment、chartはgap/segmentを接続しません。Pressure/thermalはcategoricalで温度/健康診断ではありません。Quitで終了。期限切れrecordはreadで省略し次の成功writeでdiskから削除、実行しないappは能動削除しません。

Baselineは最新30–60recordを凍結。同key/unitのavailable有限値をfieldtimestampでdedupeし各側最低10観測のmedianを比較。Recentはcapture後の最大60record。差は記述的でcausal/workload-normalized/regression証明ではありません。Baselineもretentionで失効。

### Smart Alerts

初期off、freshforeground-active evidenceのみ。CPU>=85%同generation連続30秒、非normalpressure、startupavailable<10%、serious/criticalthermal。Paused/stale/missingはfindingを作りません。Re-armは30秒連続recovery：CPU<70%、normalpressure、available>=15%、nominal/fairthermal。Missing/gap>15秒はrecoveryreset、repeatは最低15分、Snooze1時間、disableでgate消去。Mac変更なし。

RAM内event最大100。Notification権限は明示button、serviceはOrvenbundle内のみ初期化し非対応CLI/XCTesthostを回避。Denied/deliveryfailでもapp内evidence保持。配信notification clickはToolboxCoordinatorでevidenceへ。Rule testsはOSdelivery証明ではなく実serviceと権限が必要。

### Sensor ChartsとRecording

既存streamから10秒ごと15/30/60分、最大360recordをQuitまでRAM保持。Uptimeclockはsleepを除くためwall時間延長。Menu-bar opt-inなしのinactiveはgap、backfillなし。Stopは保持、Startは以前のsessionを置換。観測時CPU/memory/CPU・GPUtemp/fanRPM/battery/systempowerを選択、unit/source明示、cachedsensortimestampはchart/baselineでdedupe。

LinearboundedCanvas、keyboardPrevious/Next、time/numericaccessibilitysummary。NSSavePanel前に凍結JSON/CSVを正確preview、missingblank/nullとavailability、quotedCSV/locale非依存numeric。自動export/uploadなし。Stress/benchmark/fancontrol/CPU-packagepower/calibratedper-coretempの主張なし。

### Network Connection Changes

初期off/sessionRAM。明示RefreshはboundedlsofとverifiedPID/start。比較keyはprocessidentity/transport/numericendpoint、descriptor/order変更だけはeventなし。Duplicatecoalesce、矛盾stateUnknown。Newly observed/No longer observed/State changedは観測で推定open/close時刻ではありません。Verifiedsocketのみ、最初の成功fullcapでbaseline。Failed/cancel/truncated/routeleave/10分超gapでreset、境界をまたぐ消失推定なし。

200event保持、最新50表示/上限明示、unverified/omissioncount。Clearはevent/baseline、disableはsession消去。Processname/endpointのdisk保存、DNS/capture/firewall/traffictotal/pollingなし。Restrictedprocess/短命connectionは対象外、PIDreuseは別identity。

### 検証

Owner testsはpersistence/cadence/retention/実reload/破損保持/baselinededupe、connectionidentity/state/coverage/bounds、alert hysteresis/cooldown/gap/snooze、CSVescaping/missingを検証。Notificationhost XCTestabort/correctedrunをevidence/health-expansionに保持。Unit/build/format/locale/static/native/resourceはcandidatehash付き、以前のsensorsoak/GUIは新workflowの証明ではありません。

PhysicalIntel/macOS13、fullVoiceOver、criticalJAcopyreview、native notification deliveryはexternal。OSnotificationdelivery/actionは権限と実配信確認まで未検証。Localimplementation/ad-hoccontractはpublishを意味しません。
