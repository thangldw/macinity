# Macinity hardware tools contract

## English

### Scope

Hardware Inspector shows bounded machine, CPU, memory, graphics, storage, OS and power profile information exposed by native OS reads. Static profile data is cached and displayed separately from live sampling. Language changes use the canonical app locale. Physical sensors use the separate read-only mapped sensor owner.

### Coverage and limits

Missing/permission-reduced fields are visible. The app does not promise CPU-Z/HWMonitor platform parity, SPD/voltage/current CPU clocks, a stress benchmark or SMART health diagnosis. Platform support declarations and universal slices are separate from physical Intel/macOS13 tests.

### Verification

Current release resource and native/platform coverage is recorded in release readiness; old profile benchmarks do not prove this package.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## Tiếng Việt

### Scope

Hardware Inspector hiển thị thông tin bounded về máy, CPU, memory, graphics, storage, OS/power qua native OS reads. Static profile được cache và tách khỏi live sampling. Locale theo owner chung. Physical sensor dùng mapped read-only owner riêng.

### Coverage and limits

Missing/quyền giảm coverage hiển thị rõ. Không hứa CPU-Z/HWMonitor parity, SPD/voltage/current CPU clocks/stress/SMART health diagnosis. Universal slices và khai báo platform khác với physical Intel/macOS13 tests.

### Verification

Ghi resource/native/platform coverage của release hiện tại trong readiness; benchmark profile cũ không chứng minh package mới.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## 日本語

### Scope

Hardware Inspectorはnative OS readのboundedなmachine/CPU/memory/graphics/storage/OS/power情報を表示。Static profileはcacheしてlive samplingと分離。Localeは共通owner、physical sensorは別read-only mapped ownerを使用。

### Coverage and limits

Missingと権限によるcoverage低下を明示。CPU-Z/HWMonitor parity、SPD/voltage/current CPU clock/stress/SMART診断を約束しません。Universal slice/platform宣言はphysical Intel/macOS13 testとは別。

### Verification

Current releaseのresource/native/platform coverageはreadinessに記録、以前のprofile benchmarkで新packageを検証しません。

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)
