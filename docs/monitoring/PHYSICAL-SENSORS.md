# Orven physical sensor contract

## English

### Scope

AppleSMC observation is read-only and uses community key mappings. The observed M3 host provided CPU/GPU mapped temperatures, two fan RPM readings, battery temperature and system-power observations. Each row carries key, group, unit, source, availability and observation time. Missing key Te0L remains unavailable, not zero.

### Coverage and limits

Mappings and available keys vary by machine. Group labels do not prove calibrated package/core identity. Observed system power is not CPU package power; RPM is not a fan-control action. No voltage, active frequency, fan writes, kernel driver, privileged helper or hidden fallback reading is added.

### Verification

Previous eight-hour frozen engine evidence included sleep/wake transitions and cannot be relabeled as current production GUI validation.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## Tiếng Việt

### Scope

AppleSMC chỉ đọc, sử dụng community key mappings. M3 đã quan sát có mapped CPU/GPU temperature, hai fan RPM, battery temperature và system power. Mỗi row có key/group/unit/source/availability/timestamp. Te0L thiếu được giữ unavailable, không0.

### Coverage and limits

Mapping/key khác theo máy. Group không chứng minh calibrated package/core identity; system power không phải CPU package power, RPM không điều khiển quạt. Không voltage/frequency/fan write/kernel driver/privileged helper hay fallback ẩn.

### Verification

Soak engine8giờ trước có sleep/wake và không được đổi nhãn thành current production GUI validation.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## 日本語

### Scope

AppleSMCはcommunity key mappingに基づく読み取り専用です。観測したM3ではCPU/GPU温度、fanRPM二件、battery温度、system powerが得られました。Rowにkey/group/unit/source/availability/timestampを保持。Te0L欠測は0ではなくunavailable。

### Coverage and limits

Mappingとkeyは機種依存。Groupはcalibrated package/core identityを証明しません。System powerはCPU package powerではなくRPMはfancontrolではありません。Voltage/frequency/fan write/kernel driver/privileged helper/隠れたfallbackなし。

### Verification

以前の8時間engineにはsleep/wakeがあり、current production GUI validationとして再利用しません。

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)
