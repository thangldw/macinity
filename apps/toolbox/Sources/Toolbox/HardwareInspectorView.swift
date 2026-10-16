import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct HardwareInspectorView: View {
  enum Mode { case profile, sensors }
  let model: MonitoringViewModel
  var mode: Mode = .profile
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
        OrvenPageHeader(
          title: mode == .profile
            ? L10n.text("Hardware Inspector") : L10n.text("Temperatures & Fans"))
        OrvenSamplingStatus(model: model)
        if mode == .sensors {
          PhysicalSensorPanel(model: model, since: resetTime)
        }
        if mode == .profile {
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
        }
        if mode == .sensors {
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
          Text(
            L10n.text(
              "SMC temperature, fan and power coverage is shown above. Thermal state remains a separate macOS condition. Voltage, live core clocks, SPD timings, SMART health, fan control, overclocking and stress tests are not provided."
            )
          )
          .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
      }.padding(28)
    }
    .environment(\.locale, locale)
    .task(id: refreshToken) {
      guard mode == .profile else { return }
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
