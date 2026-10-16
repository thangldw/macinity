import MacinityCore
import MacinityMonitoring
import SwiftUI

struct MonitoringOverviewView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @Environment(\.monitoringDisplayState) private var displayState
  @ObservedObject var model: MonitoringViewModel
  private var topProcesses: [ProcessSample] {
    Array(
      ProcessOrdering.cpu.sorted(
        (model.snapshot?.processes.value ?? []).filter { $0.cpu.value != nil }, query: ""
      ).prefix(3))
  }
  var body: some View {
    let processes = topProcesses
    return VStack(alignment: .leading, spacing: 18) {
      MacinitySamplingStatus(model: model)
      OverviewMetricsLayout {
        cpuChart
        summary
      }.macinitySurface()
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text(L10n.text("Using the most CPU")).font(.title2.weight(.semibold))
          Spacer()
          Button(L10n.text("Show all processes")) {
            MacinityRuntime.shared.navigation.open(.section(.processes))
          }.buttonStyle(.link).tint(MacinityTheme.accent)
        }
        HStack {
          Text(L10n.text("Process")).frame(maxWidth: .infinity, alignment: .leading)
          Text(L10n.text("CPU • one core")).frame(width: 110, alignment: .trailing)
          Text(L10n.text("Resident memory")).frame(width: 110, alignment: .trailing)
          Color.clear.frame(width: 130, height: 1)
        }.font(.caption).foregroundStyle(MacinityTheme.secondary)
        if processes.isEmpty {
          Text(
            L10n.text(
              model.snapshot?.processes.value == nil ? "No process data available." : "Warming up"
            )
          ).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100)
        }
        ForEach(processes, id: \.id) { process in
          VStack(spacing: 0) {
            processRow(process)
            if process.id != processes.last?.id { Divider() }
          }
        }
        if let sample = model.snapshot?.processes {
          Text(
            String(
              format: L10n.text("%d of %d processes have CPU samples."),
              sample.value?.filter { $0.cpu.value != nil }.count ?? 0,
              sample.value?.count ?? 0)
          ).font(.caption).foregroundStyle(MacinityTheme.secondary)
          Text(
            availabilityLabel(
              displayState.availability(
                of: sample, at: ProcessInfo.processInfo.systemUptime, maximumAge: 6))
          )
          .font(.caption).foregroundStyle(MacinityTheme.secondary)
        }
      }.macinitySurface()
      storageStrip.macinitySurface()
      ExplainMyMacView(model: model)
      Text(L10n.text("Read-only. Recent trends stay on this Mac and are not saved."))
        .font(.caption).foregroundStyle(MacinityTheme.secondary)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }

  private func processRow(_ process: ProcessSample) -> some View {
    HStack(spacing: 12) {
      MacinityProcessIcon(process: process)
      VStack(alignment: .leading, spacing: 3) {
        Text(process.name).font(.body.weight(.semibold)).lineLimit(1).help(process.name)
        Text("PID \(process.pid)").font(.caption).foregroundStyle(MacinityTheme.secondary)
      }.frame(maxWidth: .infinity, alignment: .leading)
      Text(processText(process.cpu, format: { monitoringNumber($0, digits: 1) + "%" }))
        .monospacedDigit().lineLimit(2).fixedSize(horizontal: false, vertical: true)
        .frame(width: 110, alignment: .trailing)
      Text(processText(process.memory, format: monitoringBytes))
        .monospacedDigit().lineLimit(2).fixedSize(horizontal: false, vertical: true)
        .frame(width: 110, alignment: .trailing)
      Button(L10n.text("Inspect process")) {
        if let identity = process.identity {
          MacinityRuntime.shared.navigation.open(.inspectProcess(identity))
        }
      }.buttonStyle(.bordered).disabled(process.identity == nil).frame(width: 130)
    }.padding(.vertical, 8)
  }

  private var cpuChart: some View {
    MonitoringChart(
      title: L10n.text("System CPU • all cores"), unit: "%",
      data: (model.snapshot?.history ?? []).map {
        ChartDatum(time: $0.time, value: $0.cpuPercent, generation: $0.generation)
      }, percentScale: true, embedded: true, height: 190)
  }

  private var summary: some View {
    VStack(alignment: .leading, spacing: 10) {
      MetricReadout(
        title: L10n.text("CPU • all cores"), sample: model.snapshot?.cpu,
        format: { monitoringNumber($0, digits: 1) + "%" }, valueFont: .system(size: 32))
      Divider()
      MetricReadout(
        title: L10n.text("Memory • includes caches"), sample: model.snapshot?.memory,
        format: { value in
          guard value.occupiedPercent != nil else { return L10n.text("Unavailable") }
          return monitoringBytes(value.totalBytes - value.freeBytes) + " / "
            + monitoringBytes(value.totalBytes)
        })
      Divider()
      MetricReadout(
        title: L10n.text("Thermal state"), sample: model.snapshot?.hardware.reading.thermal,
        format: thermalLabel, maximumAge: 6)
      Text(L10n.text("Thermal state is not a temperature in °C.")).font(.caption).foregroundStyle(
        MacinityTheme.secondary)
    }
  }

  private var storageStrip: some View {
    HStack(spacing: 18) {
      Image(systemName: "internaldrive").font(.system(size: 32)).foregroundStyle(
        MacinityTheme.secondary)
      VStack(alignment: .leading, spacing: 7) {
        MetricReadout(
          title: L10n.text("Startup volume available"),
          sample: model.snapshot?.hardware.reading.capacity,
          format: { monitoringBytes($0.availableBytes) + " / " + monitoringBytes($0.totalBytes) },
          maximumAge: 30)
        if let capacity = model.snapshot?.hardware.reading.capacity.value,
          capacity.totalBytes > 0, capacity.availableBytes <= capacity.totalBytes
        {
          ProgressView(
            value: Double(capacity.totalBytes - capacity.availableBytes),
            total: Double(capacity.totalBytes)
          )
          .accessibilityLabel(L10n.text("Used storage"))
        }
      }
      Spacer(minLength: 8)
      Button(L10n.text("Open storage")) {
        MacinityRuntime.shared.navigation.open(.section(.storage))
      }
      .buttonStyle(.bordered)
    }
  }

  private func processText<Value>(_ sample: MetricSample<Value>, format: (Value) -> String)
    -> String
  {
    let state = displayState.availability(
      of: sample, at: ProcessInfo.processInfo.systemUptime, maximumAge: 6)
    guard let value = sample.value, state == .available || state == .stale else {
      return availabilityLabel(state)
    }
    return format(value)
  }
}

struct MetricReadout<Value: Sendable>: View {
  @Environment(\.monitoringDisplayState) private var displayState
  let title: String
  let sample: MetricSample<Value>?
  let format: (Value) -> String
  var maximumAge: Double = 3
  var valueFont: Font = .title2

  private var state: MetricAvailability {
    sample.map {
      displayState.availability(
        of: $0, at: ProcessInfo.processInfo.systemUptime, maximumAge: maximumAge)
    } ?? .loading
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.callout).foregroundStyle(.secondary)
      if let value = sample?.value, state == .available || state == .stale {
        Text(format(value)).font(valueFont.monospacedDigit().weight(.semibold))
      } else {
        Text(availabilityLabel(state)).font(.title3)
      }
      if let sample {
        HStack(spacing: 6) {
          Text(availabilityLabel(state))
          Text(sample.time.wall, style: .time)
        }
        .font(.caption).foregroundStyle(.secondary)
        if let reason = sample.reason { Text(reason).font(.caption).foregroundStyle(.secondary) }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

func availabilityLabel(_ state: MetricAvailability) -> String {
  switch state {
  case .loading: L10n.text("Warming up")
  case .available: L10n.text("Available")
  case .stale: L10n.text("Stale")
  case .unsupported: L10n.text("Unsupported")
  case .permissionRequired: L10n.text("Permission required")
  case .temporarilyUnavailable: L10n.text("Temporarily unavailable")
  case .error: L10n.text("Read failed")
  }
}

func monitoringNumber(_ value: Double, digits: Int) -> String {
  let locale =
    AppLanguage(rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? "")?
    .locale ?? AppLanguage.defaultLanguage.locale
  return value.formatted(.number.locale(locale).precision(.fractionLength(digits)))
}

func monitoringBytes(_ value: UInt64) -> String { byteText(Double(value)) }

private func byteText(_ value: Double) -> String {
  guard value.isFinite, value >= 0 else { return L10n.text("Unavailable") }
  let units = ["B", "KB", "MB", "GB", "TB"]
  var scaled = value
  var index = 0
  while scaled >= 1000 && index < units.count - 1 {
    scaled /= 1000
    index += 1
  }
  let locale =
    AppLanguage(rawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? "")?
    .locale ?? AppLanguage.defaultLanguage.locale
  return scaled.formatted(.number.locale(locale).precision(.significantDigits(1...3))) + " "
    + units[index]
}

func rateText(_ value: Double) -> String { byteText(value) + "/s" }

func batteryState(_ battery: BatteryInfo) -> String {
  if battery.charging { return L10n.text("Charging") }
  return L10n.text(battery.onBattery ? "On battery" : "External power")
}

func thermalLabel(_ thermal: ThermalLevel) -> String {
  switch thermal {
  case .nominal: L10n.text("Nominal")
  case .fair: L10n.text("Fair")
  case .serious: L10n.text("Serious")
  case .critical: L10n.text("Critical")
  case .unknown: L10n.text("Unknown")
  }
}

// Measure and place a single chart instance; hidden fallback charts still incur mark layout work.
private struct OverviewMetricsLayout: Layout {
  private let summaryWidth: CGFloat = 245
  private let gap: CGFloat = 24
  private func horizontal(_ width: CGFloat) -> Bool { width >= 410 + summaryWidth + gap }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.width ?? 900
    let chartWidth = horizontal(width) ? width - summaryWidth - gap : width
    let chart = subviews[0].sizeThatFits(ProposedViewSize(width: chartWidth, height: nil))
    let summary = subviews[1].sizeThatFits(
      ProposedViewSize(width: horizontal(width) ? summaryWidth : width, height: nil))
    return CGSize(
      width: width,
      height: horizontal(width)
        ? max(chart.height, summary.height) : chart.height + gap + summary.height)
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let wide = horizontal(bounds.width)
    let chartWidth = wide ? bounds.width - summaryWidth - gap : bounds.width
    let chartProposal = ProposedViewSize(width: chartWidth, height: nil)
    subviews[0].place(at: bounds.origin, anchor: .topLeading, proposal: chartProposal)
    let origin =
      wide
      ? CGPoint(x: bounds.maxX - summaryWidth, y: bounds.minY)
      : CGPoint(
        x: bounds.minX, y: bounds.minY + subviews[0].sizeThatFits(chartProposal).height + gap)
    subviews[1].place(
      at: origin, anchor: .topLeading,
      proposal: ProposedViewSize(width: wide ? summaryWidth : bounds.width, height: nil))
  }
}
