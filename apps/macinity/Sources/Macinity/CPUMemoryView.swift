import MacinityCore
import MacinityMonitoring
import SwiftUI

struct CPUMemoryView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: MonitoringViewModel
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        MacinityPageHeader(title: L10n.text("CPU & Memory"))
        MacinitySamplingStatus(model: model)
        MonitoringChart(
          title: L10n.text("System CPU • all cores"), unit: "%",
          data: (model.snapshot?.history ?? []).map {
            ChartDatum(time: $0.time, value: $0.cpuPercent, generation: $0.generation)
          }, percentScale: true)
        MonitoringChart(
          title: L10n.text("Occupied memory • includes caches"), unit: "%",
          data: (model.snapshot?.history ?? []).map {
            ChartDatum(time: $0.time, value: $0.memoryPercent, generation: $0.generation)
          }, percentScale: true)
        if let snapshot = model.snapshot {
          HStack(alignment: .top) {
            MetricReadout(
              title: L10n.text("Physical memory"), sample: snapshot.memory,
              format: { monitoringBytes($0.totalBytes) })
            MetricReadout(
              title: L10n.text("Wired memory"), sample: snapshot.memory,
              format: { monitoringBytes($0.wiredBytes) })
            MetricReadout(
              title: L10n.text("Compressor storage"), sample: snapshot.memory,
              format: { monitoringBytes($0.compressedBytes) })
          }.macinitySurface()
          HStack(alignment: .top) {
            MetricReadout(
              title: L10n.text("Swap used"), sample: snapshot.hardware.reading.swap,
              format: { monitoringBytes($0) }, maximumAge: 6)
            MetricReadout(
              title: L10n.text("Memory pressure • last OS event"),
              sample: snapshot.hardware.reading.pressure, format: pressureLabel, maximumAge: 6)
          }.macinitySurface()
        }
        Text(
          L10n.text(
            "Occupied memory is physical memory minus free pages and includes caches. It does not measure reclaimable RAM. Pressure is an OS event, not an inferred score."
          )
        )
        .font(.caption).foregroundStyle(.secondary)
        Button(L10n.text("Review temperatures and fans")) {
          MacinityRuntime.shared.navigation.open(.section(.hardware))
        }.buttonStyle(.bordered)
        Label(
          L10n.text("GPU utilization and memory: Unsupported"), systemImage: "questionmark.circle"
        )
        .font(.callout).foregroundStyle(.secondary)
      }.padding(28)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}

func pressureLabel(_ value: MemoryPressureLevel) -> String {
  switch value {
  case .normal: L10n.text("Normal")
  case .warning: L10n.text("Warning")
  case .critical: L10n.text("Critical")
  }
}
