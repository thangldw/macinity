# Macinity architecture

## English

### Owners

The native executable remains Toolbox. ToolboxCore owns app metadata, locale/theme, filesystem identity, migration and bounded system/APFS inspection. ToolboxMonitoring owns coordinator cadence, processes/rates/hardware/SMC, health records/baselines, connection observations and bounded network tools. ToolboxStorage owns scanning/review/Trash/recovery/projects/applications. ToolboxChanges owns installer/snapshot/evidence/timeline workflows.

### Demand and data

One monitoring coordinator serves active main-window or optional menu-bar demand; sleep/inactivity pause sampling. UI snapshot publication is throttled while recording/history reuse original timestamps. HealthHistoryStore serializes versioned bounded writes off main actor. Network page owns one cancellable operation and visible-page path callbacks; probes use direct fixed arguments, never a shell. No extra background sampler or persistent endpoint history is added.

### Compatibility and trust

Public app is Macinity.app version3.1.0, executable Toolbox, bundleIDcom.thang.toolbox and ApplicationSupportToolbox preserved. Four locale resources share stable user-visible strings. Mutations revalidate paths/process identities at execution and require explicit review. Ad-hoc integrity is not Apple notarization. [Architecture diagram](diagrams/toolbox-architecture.html), [Health](monitoring/HEALTH-WORKFLOWS.md), [Network](monitoring/NETWORK-TOOLS.md).

## Tiếng Việt

### Owners

Executable vẫn mang tên Toolbox. ToolboxCore quản lý metadata, locale/theme, định danh filesystem, migration và kiểm tra hệ thống/APFS có giới hạn. ToolboxMonitoring quản lý nhịp lấy mẫu, process, tốc độ, hardware/SMC, health records/baseline và công cụ mạng. ToolboxStorage quản lý quét, duyệt, Trash, khôi phục, dự án và ứng dụng. ToolboxChanges quản lý installer, snapshots, bằng chứng và timeline.

### Demand and data

Một MonitoringCoordinator phục vụ cửa sổ chính đang hoạt động hoặc giám sát menu bar tùy chọn. Sleep hoặc inactive tạm dừng lấy mẫu. UI giới hạn nhịp cập nhật; history và recording dùng timestamp gốc. HealthHistoryStore ghi dữ liệu có phiên bản và giới hạn ngoài main actor. Trang mạng sở hữu một tác vụ có thể hủy và callback đường mạng khi trang hiện diện; probe dùng executable và arguments cố định, không qua shell. Không có sampler nền bổ sung hoặc lịch sử endpoint lưu trên disk.

### Compatibility and trust

App là Macinity.app 3.1.0; executable Toolbox, bundle ID `com.thang.toolbox` và `Application Support/Toolbox` được giữ để tương thích. App có bốn ngôn ngữ. Mutation kiểm tra lại path và định danh process ngay trước khi chạy, sau khi người dùng duyệt. Chữ ký ad-hoc không phải Apple notarization. Xem [diagram](diagrams/toolbox-architecture.html), [Health](monitoring/HEALTH-WORKFLOWS.md), [Network](monitoring/NETWORK-TOOLS.md).

## 日本語

### Owners

Executable名はToolboxを保持します。ToolboxCoreはmetadata、locale/theme、filesystem identity、migration、限定されたsystem/APFS観測を担当します。ToolboxMonitoringはsampling cadence、process/rate、hardware/SMC、health records/baselinesとnetwork toolsを担当します。ToolboxStorageはscan、review、Trash、recovery、projects/applications、ToolboxChangesはinstaller、snapshots、evidence、timelineを担当します。

### Demand and data

一つのMonitoringCoordinatorがactive main windowまたは任意のmenu-bar監視を処理します。Sleep/inactiveではsamplingを停止します。UI更新の頻度を制限し、history/recordingは元のtimestampを保持します。HealthHistoryStoreはmain actorの外でversionedかつboundedなwriteを行います。Network pageは一つのcancel可能operationと表示中のpath callbackを所有します。Probeは固定executable/argumentsを使い、shellを経由しません。追加のbackground samplerやdisk上のendpoint historyはありません。

### Compatibility and trust

AppはMacinity.app 3.1.0です。Executable Toolbox、bundle ID `com.thang.toolbox`、`Application Support/Toolbox`を互換性のため維持し、四言語を提供します。Mutationは明示的なreview後、実行直前にpath/process identityを再確認します。Ad-hoc署名はApple notarizationではありません。[Diagram](diagrams/toolbox-architecture.html)、[Health](monitoring/HEALTH-WORKFLOWS.md)、[Network](monitoring/NETWORK-TOOLS.md)を参照してください。
