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
          ToolboxRuntime.shared.navigation.open(.section(.hardware))
        }.buttonStyle(.bordered)
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
}
