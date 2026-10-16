import SwiftUI
import ToolboxCore
import ToolboxMonitoring

/// Projects the existing slow-cadence observations; never resamples or backfills.
struct PhysicalSensorTrend: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: MonitoringViewModel
  let selectedKey: String?

  var body: some View {
    let readings = model.snapshot?.hardware.reading.physicalSensors.value?.readings ?? []
    let selected = readings.first(where: { $0.key == selectedKey }) ?? readings.first
    VStack(alignment: .leading, spacing: 14) {
      if let selected {
        MonitoringChart(
          title: L10n.text("Recent sensor readings") + " · " + selected.key,
          unit: selected.unit.rawValue,
          data: (model.snapshot?.history ?? []).compactMap { point -> ChartDatum? in
            guard let sensors = point.physicalSensors else { return nil }
            let reading = sensors.first {
              $0.key == selected.key && $0.unit == selected.unit && $0.group == selected.group
            }
            return ChartDatum(
              time: point.time,
              value: reading?.availability == .available ? reading?.value : nil,
              generation: point.generation)
          }, embedded: true, height: 190, maximumGap: 15
        ).id(selected.key)
        Text(
          L10n.text(
            "Observed sensor samples only. Missing readings remain gaps; the chart does not diagnose thermal safety."
          )
        )
        .font(.caption).foregroundStyle(OrvenTheme.secondary)
        .fixedSize(horizontal: false, vertical: true)
      } else {
        Text(L10n.text("Recent sensor readings")).font(.title2.bold())
        Text(L10n.text("No sensor samples available."))
          .foregroundStyle(OrvenTheme.secondary)
      }
    }.orvenSurface()
  }
}
