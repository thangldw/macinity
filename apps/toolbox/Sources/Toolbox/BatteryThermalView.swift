import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct BatteryThermalView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: MonitoringViewModel
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        OrvenPageHeader(title: L10n.text("Battery & Thermal"))
        OrvenSamplingStatus(model: model)
        if let hardware = model.snapshot?.hardware {
          HStack(alignment: .top, spacing: 28) {
            MetricReadout(
              title: L10n.text("Battery"), sample: hardware.reading.battery,
              format: {
                monitoringNumber($0.percent, digits: 0) + "% • "
                  + batteryState($0)
              }, maximumAge: 30)
            MetricReadout(
              title: L10n.text("Thermal state"), sample: hardware.reading.thermal,
              format: thermalLabel, maximumAge: 6)
          }.orvenSurface()
          SystemBatteryHealthView()
          BatteryHistoryView(model: model.health)
          if let battery = hardware.reading.battery.value {
            VStack(alignment: .leading, spacing: 14) {
              Text(L10n.text("Battery details")).font(.title2.bold())
              let fresh =
                hardware.reading.battery.freshness(
                  at: ProcessInfo.processInfo.systemUptime, maximumAge: 30) == .available
                && model.samplingMode != .paused
              if !fresh { Text(L10n.text("Stale")).foregroundStyle(.secondary) }
              detail("Power source", L10n.text(battery.onBattery ? "Battery" : "AC Power"))
              detail(
                "Low Power Mode",
                L10n.text(ProcessInfo.processInfo.isLowPowerModeEnabled ? "Bật" : "Tắt"))
              detail(
                battery.charging ? "Estimated time to full" : "Estimated time remaining",
                fresh
                  ? battery.minutesRemaining.map {
                    monitoringNumber(Double($0), digits: 0) + " min"
                  } : nil)
              Divider()
              detail(
                "Charge cycles",
                battery.details?.cycles.map { monitoringNumber(Double($0), digits: 0) })
              detail(
                "Design capacity", number(battery.details?.designCapacity, unit: "mAh", digits: 0))
              detail(
                "Full charge capacity",
                number(battery.details?.fullCapacity, unit: "mAh", digits: 0))
              detail(
                "Capacity vs. design", number(battery.details?.capacityRatio, unit: "%", digits: 1))
              Divider()
              detail(
                "Battery voltage",
                fresh ? number(battery.details?.voltage, unit: "V", digits: 2) : nil)
              detail(
                "Reported adapter power",
                fresh ? number(battery.details?.adapterWatts, unit: "W", digits: 0) : nil)
              Text(
                L10n.text(
                  "Capacity ratio is calculated from reported full and design capacity; it may differ from macOS Battery Health. Adapter watts describe the adapter, not live charging power. Missing values are unavailable, not zero."
                )
              )
              .font(.caption).foregroundStyle(.secondary).fixedSize(
                horizontal: false, vertical: true)
              Text("IOPowerSources · AppleSmartBattery").font(.caption).foregroundStyle(.secondary)
            }.orvenSurface()
          }
        } else {
          Text(L10n.text("Warming up"))
        }
        Text(
          L10n.text(
            "Thermal state is macOS's coarse system condition, not a temperature in °C. Macs without an internal battery report Unsupported."
          )
        )
        .font(.callout).foregroundStyle(.secondary)
        Button(L10n.text("Review temperatures and fans")) {
          ToolboxRuntime.shared.navigation.open(.section(.sensors))
        }.buttonStyle(.bordered)
        KeepAwakeView(monitoring: model)
        SleepInspectorView(engine: model.engine)
        Label(
          L10n.text("Per-process energy: Unsupported"),
          systemImage: "questionmark.circle"
        )
        .foregroundStyle(.secondary)
      }.padding(28)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
  private func number(_ value: Double?, unit: String, digits: Int) -> String? {
    value.map { monitoringNumber($0, digits: digits) + " " + unit }
  }
  private func detail(_ title: String, _ value: String?) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Text(L10n.text(title)).foregroundStyle(.secondary)
      Spacer(minLength: 12)
      Text(value ?? L10n.text("Unavailable")).monospacedDigit()
        .multilineTextAlignment(.trailing).textSelection(.enabled)
    }.fixedSize(horizontal: false, vertical: true)
  }
}
