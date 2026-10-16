import MacinityCore
import MacinityMonitoring
import SwiftUI

struct PhysicalSensorPanel: View {
  @ObservedObject var model: MonitoringViewModel
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let since: Double?
  @State private var selectedGroup = "CPU sensors"
  @State private var selectedKey: String?
  private let groups = ["CPU sensors", "GPU sensors", "Fans", "Battery sensors", "System power"]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.text("Temperature & Fans")).font(.title2.bold())
      if let sample = model.snapshot?.hardware.reading.physicalSensors {
        if let snapshot = sample.value {
          HStack(alignment: .top, spacing: 20) {
            summary(
              "CPU sensors", title: "CPU • hottest mapped sensor", sample: sample,
              readings: snapshot.readings)
            summary(
              "GPU sensors", title: "GPU • hottest mapped sensor", sample: sample,
              readings: snapshot.readings)
          }
          Text(
            L10n.text("Observed at") + " "
              + sample.time.wall.formatted(.dateTime.hour().minute().second().locale(locale))
          )
          .font(.caption).foregroundStyle(.secondary)
          if snapshot.reportedFanCount == 0 {
            Text(L10n.text("SMC reports no fans. This is not a fan-speed measurement."))
          } else if snapshot.reportedFanCount == nil {
            Text(L10n.text("Fan count unavailable; no fan speeds inferred."))
          } else if snapshot.reportedFanCount! > 8 {
            Text(L10n.text("Fan coverage is capped at 8 reported fans."))
          }
          MacinityChoicePicker(
            L10n.text("Sensor"), selection: $selectedGroup,
            options: groups.map { ($0, L10n.text($0)) }, minimumWidth: 110)
          let rows = snapshot.readings.filter { $0.group == selectedGroup }
          let selected = rows.first { $0.key == selectedKey } ?? rows.first
          if rows.isEmpty {
            Text(L10n.text("No sensor samples available.")).foregroundStyle(.secondary)
          } else {
            HStack {
              Text(L10n.text(selectedGroup)).font(.headline)
              Spacer()
              Text("\(rows.filter { $0.availability == .available }.count)/\(rows.count)")
                .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            PhysicalSensorTrend(model: model, selectedKey: selected?.key)
            Text(L10n.text("Select a sensor below to view its chart."))
              .font(.caption).foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
              GridRow {
                Text(L10n.text("Sensor"))
                Text(L10n.text("Current"))
                Text(L10n.text("Minimum"))
                Text(L10n.text("Maximum"))
              }.font(.caption.bold()).foregroundStyle(.secondary)
              ForEach(rows) { reading in
                let range = SensorWindow.physicalExtrema(
                  model.snapshot?.history ?? [], sensor: reading, since: since)
                GridRow {
                  Button {
                    selectedKey = reading.key
                  } label: {
                    HStack(spacing: 6) {
                      Image(
                        systemName: selected?.key == reading.key
                          ? "checkmark.circle.fill" : "circle"
                      )
                      .foregroundStyle(
                        selected?.key == reading.key
                          ? MacinityTheme.action : MacinityTheme.secondary)
                      Text(reading.key).font(.callout.monospaced())
                    }.frame(maxWidth: .infinity, alignment: .leading)
                  }.buttonStyle(.plain)
                    .accessibilityAddTraits(selected?.key == reading.key ? .isSelected : [])
                    .help("AppleSMC/" + reading.key + " • " + (reading.dataType ?? "?"))
                  Text(current(reading, sample)).fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                  Text(value(range.minimum, reading.unit)).foregroundStyle(.secondary)
                  Text(value(range.maximum, reading.unit)).foregroundStyle(.secondary)
                }.monospacedDigit()
                Divider()
              }
            }
          }

        } else {
          Text(availabilityLabel(sample.availability)).foregroundStyle(.secondary)
        }
      } else {
        Text(L10n.text("Warming up"))
      }
      Text(
        L10n.text(
          "Read-only SMC sensors refresh every 10 seconds while monitoring runs. Coverage is limited and model-dependent. CPU/GPU labels use community mappings, not verified physical core IDs. Missing readings are never zero."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      Text(
        L10n.text(
          "Temperatures are individual mapped readings, not CPU/GPU package averages or a safety diagnosis. Fan speeds are observed RPM only; Macinity does not change fan modes or targets. Voltage, live clocks, SPD and SMART are not collected."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }.macinitySurface()
  }

  private var locale: Locale {
    AppLanguage(rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? "")?
      .locale
      ?? AppLanguage.defaultLanguage.locale
  }
  private func value(_ value: Double?, _ unit: PhysicalSensorUnit) -> String {
    guard let value else { return "—" }
    return monitoringNumber(value, digits: unit == .rpm ? 0 : 1) + " " + unit.rawValue
  }
  private func current(
    _ reading: PhysicalSensorReading, _ sample: MetricSample<PhysicalSensorSnapshot>
  ) -> String {
    guard reading.availability == .available else { return availabilityLabel(reading.availability) }
    let state = sample.freshness(at: ProcessInfo.processInfo.systemUptime, maximumAge: 20)
    guard state == .available, model.samplingMode != .paused else {
      return availabilityLabel(state == .available ? .stale : state)
    }
    return value(reading.value, reading.unit)
  }
  private func summary(
    _ group: String, title: String, sample: MetricSample<PhysicalSensorSnapshot>,
    readings: [PhysicalSensorReading]
  ) -> some View {
    let rows = readings.filter { $0.group == group && $0.availability == .available }
    let hottest = rows.max { ($0.value ?? -.infinity) < ($1.value ?? -.infinity) }
    return VStack(alignment: .leading, spacing: 6) {
      Text(L10n.text(title)).font(.headline)
      Text(hottest.map { current($0, sample) } ?? L10n.text("Unavailable"))
        .font(.system(size: 30, weight: .semibold, design: .rounded).monospacedDigit())
      if let hottest { Text("AppleSMC/" + hottest.key).font(.caption).foregroundStyle(.secondary) }
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}
