import MacinityCore
import MacinityMonitoring
import SwiftUI

struct NetworkActivityView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: MonitoringViewModel
  @State private var showsVirtualInterfaces = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        MacinityPageHeader(title: L10n.text("Network Activity"))
        MacinitySamplingStatus(model: model)
        NetworkInspectorView()
        if let hardware = model.snapshot?.hardware {
          Toggle(
            L10n.text("Show loopback, tunnels and other interfaces"), isOn: $showsVirtualInterfaces)
          Text(
            L10n.text(
              "Physical summary includes active en* interfaces. Tunnel and loopback counters are shown separately and are never added to that summary."
            )
          )
          .font(.caption).foregroundStyle(.secondary)
          if let interfaces = hardware.interfaces.value {
            VStack(alignment: .leading, spacing: 18) {
              ForEach(interfaces.filter { showsVirtualInterfaces || $0.includeInAggregate }) {
                interface in
                HStack(alignment: .top) {
                  MetricReadout(
                    title: interface.name + " • " + L10n.text("Received"), sample: interface.input,
                    format: rateText, maximumAge: 6)
                  MetricReadout(
                    title: L10n.text("Sent"), sample: interface.output, format: rateText,
                    maximumAge: 6)
                }
                Divider()
              }
            }.macinitySurface()
          } else {
            Text(availabilityLabel(hardware.interfaces.availability))
          }
        } else {
          Text(L10n.text("Warming up"))
        }
        MonitoringChart(
          title: L10n.text("Network received • physical"), unit: "MB/s",
          data: (model.snapshot?.history ?? []).filter(\.ioSampled).map {
            ChartDatum(
              time: $0.time, value: $0.networkInput.map { $0 / 1_000_000 },
              generation: $0.generation)
          })

      }.padding(28)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}
