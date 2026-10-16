import MacinityCore
import MacinityMonitoring
import SwiftUI

struct DiskActivityView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: MonitoringViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        MacinityPageHeader(title: L10n.text("Disk Activity"))
        MacinitySamplingStatus(model: model)
        APFSSpaceInspectorView()
        if let hardware = model.snapshot?.hardware {
          MetricReadout(
            title: L10n.text("Startup volume available"), sample: hardware.reading.capacity,
            format: {
              monitoringBytes($0.availableBytes) + " / "
                + monitoringBytes($0.totalBytes)
            }, maximumAge: 30
          ).macinitySurface()
          HStack {
            Button(L10n.text("Review Storage")) {
              MacinityRuntime.shared.navigation.open(.section(.storage))
            }
            Button(L10n.text("Review Projects")) {
              MacinityRuntime.shared.navigation.open(.section(.projects))
            }
          }
          Text(
            L10n.text(
              "APFS volumes share container capacity. Capacity is shown for the startup volume once; I/O is per observed storage driver, including virtual devices when exposed."
            )
          )
          .font(.caption).foregroundStyle(.secondary)
          Text(L10n.text("Disk I/O by device")).font(.headline)
          if let disks = hardware.disks.value {
            VStack(alignment: .leading, spacing: 18) {
              ForEach(disks) { disk in
                HStack(alignment: .top) {
                  MetricReadout(
                    title: disk.name + " • " + L10n.text("Read"), sample: disk.input,
                    format: rateText, maximumAge: 6)
                  MetricReadout(
                    title: L10n.text("Write"), sample: disk.output, format: rateText, maximumAge: 6)
                }
                if disk.id != disks.last?.id { Divider() }
              }
            }.macinitySurface()
          } else {
            Text(availabilityLabel(hardware.disks.availability))
          }
          if let reason = hardware.disks.reason { Text(reason).font(.caption) }

        } else {
          Text(L10n.text("Warming up"))
        }
        MonitoringChart(
          title: L10n.text("Disk writes • observed drivers"), unit: "MB/s",
          data: (model.snapshot?.history ?? []).filter(\.ioSampled).map {
            ChartDatum(
              time: $0.time, value: $0.diskOutput.map { $0 / 1_000_000 }, generation: $0.generation)
          })

      }.padding(28)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}
