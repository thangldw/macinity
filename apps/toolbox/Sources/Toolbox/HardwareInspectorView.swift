import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct HardwareInspectorView: View {
  let model: MonitoringViewModel
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @State private var profile: HardwareProfile?
  @State private var refreshToken = 0
  @State private var loading = true
  @State private var resetTime: Double?
  @State private var showsExport = false

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        OrvenPageHeader(title: L10n.text("Hardware Inspector"))
        OrvenSamplingStatus(model: model)
        PhysicalSensorPanel(model: model, since: resetTime)
        HStack {
          Text(L10n.text("Hardware profile")).font(.title2.bold())
          Spacer()
          Button(L10n.text("Refresh hardware")) { refreshToken += 1 }.disabled(loading)
          Button(L10n.text("Export hardware report…")) { showsExport = true }.disabled(
            profile == nil)
        }
        if loading { Text(L10n.text("Reading hardware profile…")).foregroundStyle(.secondary) }
        if let profile {
          HardwareProfileDetails(profile: profile, languageCode: languageCode).equatable()
        }
        Text(
          L10n.text(
            "Cache sizes are OS-reported values, not summed totals. Nominal frequency is not a live core clock. The GPU working set is a recommendation, not VRAM capacity or current usage."
          )
        )
        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        HStack {
          Text(L10n.text("Recent sensor range")).font(.title2.bold())
          Spacer()
          Button {
            resetTime = model.snapshot?.time.monotonic ?? ProcessInfo.processInfo.systemUptime
          } label: {
            Text(L10n.text("Reset range"))
          }
          .buttonStyle(.bordered)
          .accessibilityLabel(Text(L10n.text("Reset range")))
          .accessibilityIdentifier("hardware-reset-range")
          .help(L10n.text("Reset range"))
        }
        Text(
          L10n.text(
            "Min/max covers available observations in the latest sampling generation, up to 60 seconds. Missing readings are gaps. Reset affects this range only; it does not clear monitoring history."
          )
        )
        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        HardwareLiveRange(model: model, since: resetTime, languageCode: languageCode)
        Text(
          L10n.text(
            "SMC temperature, fan and power coverage is shown above. Thermal state remains a separate macOS condition. Voltage, live core clocks, SPD timings, SMART health, fan control, overclocking and stress tests are not provided."
          )
        )
        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      }.padding(28)
    }
    .environment(\.locale, locale)
    .task(id: refreshToken) {
      loading = true
      let result = await Task.detached(priority: .utility) { HardwareProfile.read() }.value
      guard !Task.isCancelled else { return }
      profile = result
      loading = false
    }
    .sheet(isPresented: $showsExport) {
      DiagnosticsExportView(model: model, hardwareProfile: profile, rangeSince: resetTime)
    }
  }

  private var locale: Locale {
    AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
  }

}

private struct HardwareProfileDetails: View, Equatable {
  let profile: HardwareProfile
  let languageCode: String

  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.languageCode == rhs.languageCode && lhs.profile.observedAt == rhs.profile.observedAt
      && lhs.profile.fields.count == rhs.profile.fields.count
      && zip(lhs.profile.fields, rhs.profile.fields).allSatisfy { a, b in
        a.id == b.id && a.section == b.section && a.label == b.label && a.value == b.value
          && a.unit.rawValue == b.unit.rawValue && a.source == b.source
      }
  }

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 20) {
      Text(
        profile.observedAt.formatted(
          .dateTime.year().month().day().hour().minute().second().locale(locale))
      )
      .font(.caption).foregroundStyle(.secondary)
      ForEach(sections(profile), id: \.self) { section in
        VStack(alignment: .leading, spacing: 12) {
          Text(sectionTitle(section)).font(.headline)
          ForEach(profile.fields.filter { $0.section == section }) { field in
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text(field.label))
                Text(field.source).font(.caption).foregroundStyle(.secondary)
              }.frame(maxWidth: .infinity, alignment: .leading)
              Text(fieldValue(field)).monospacedDigit().textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if field.id != profile.fields.last(where: { $0.section == section })?.id {
              Divider()
            }
          }
        }.orvenSurface()
      }
    }
  }

  private var locale: Locale {
    AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
  }
  private func sections(_ profile: HardwareProfile) -> [String] {
    profile.fields.reduce(into: []) { if !$0.contains($1.section) { $0.append($1.section) } }
  }
  private func sectionTitle(_ section: String) -> String {
    if section.hasPrefix("CPU level "), let index = Int(section.dropFirst(10)) {
      return String(format: L10n.text("CPU level %d"), locale: locale, index)
    }
    return L10n.text(section)
  }
  private func fieldValue(_ field: HardwareField) -> String {
    guard let value = field.value else { return L10n.text("Unavailable") }
    switch field.unit {
    case .bytes: return UInt64(value).map(monitoringBytes) ?? L10n.text("Unavailable")
    case .hertz:
      return Double(value).map { monitoringNumber($0 / 1_000_000_000, digits: 2) + " GHz" }
        ?? L10n.text("Unavailable")
    case .count: return Int64(value)?.formatted(.number.locale(locale)) ?? L10n.text("Unavailable")
    case .text:
      return ["Yes", "No", "Performance", "Efficiency"].contains(value) ? L10n.text(value) : value
    }
  }
}

private struct HardwareLiveRange: View {
  @ObservedObject var model: MonitoringViewModel
  let since: Double?
  let languageCode: String

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
        GridRow {
          Text(L10n.text("Sensor"))
          Text(L10n.text("Current"))
          Text(L10n.text("Minimum"))
          Text(L10n.text("Maximum"))
          Text(L10n.text("Samples"))
        }.font(.caption.bold()).foregroundStyle(.secondary)
        ForEach(SensorWindow.extrema(model.snapshot?.history ?? [], since: since)) { range in
          GridRow {
            Text(L10n.text(range.sensor.title)).frame(maxWidth: .infinity, alignment: .leading)
            Text(current(range.sensor)).fixedSize(horizontal: false, vertical: true)
            Text(sensorValue(range.minimum, range.sensor))
            Text(sensorValue(range.maximum, range.sensor))
            Text(range.validSamples.formatted(.number.locale(locale)))
          }.font(.callout).monospacedDigit()
        }
      }.orvenSurface()
      if let reading = model.snapshot?.hardware.reading {
        HStack(alignment: .top) {
          MetricReadout(
            title: L10n.text("Battery"), sample: reading.battery,
            format: { monitoringNumber($0.percent, digits: 0) + "% • " + batteryState($0) },
            maximumAge: 30)
          MetricReadout(
            title: L10n.text("Thermal state"), sample: reading.thermal, format: thermalLabel,
            maximumAge: 6)
        }.orvenSurface()
      }
    }
  }

  private var locale: Locale {
    AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
  }
  private func sensorValue(_ value: Double?, _ sensor: WindowSensor) -> String {
    guard let value else { return "—" }
    return sensor.isPercent ? monitoringNumber(value, digits: 1) + "%" : rateText(value)
  }
  private func current(_ sensor: WindowSensor) -> String {
    guard let snapshot = model.snapshot else { return L10n.text("Warming up") }
    let sample: MetricSample<Double>
    switch sensor {
    case .cpu: sample = snapshot.cpu
    case .memory:
      sample = MetricSample(
        value: snapshot.memory.value?.occupiedPercent, availability: snapshot.memory.availability,
        unit: .percent, time: snapshot.memory.time, source: snapshot.memory.source)
    case .diskRead, .diskWrite, .networkReceive, .networkSend:
      sample = snapshot.hardware.aggregate(
        network: sensor == .networkReceive || sensor == .networkSend,
        output: sensor == .diskWrite || sensor == .networkSend)
    }
    let state = sample.freshness(at: ProcessInfo.processInfo.systemUptime, maximumAge: 6)
    guard state == .available, model.samplingMode != .paused else {
      return availabilityLabel(state == .available ? .stale : state)
    }
    return sensorValue(sample.value, sensor)
  }
}
