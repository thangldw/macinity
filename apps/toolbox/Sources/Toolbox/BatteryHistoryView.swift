import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct BatteryHistoryView: View {
  @ObservedObject var model: HealthHistoryViewModel
  @State private var hours = 24
  var body: some View {
    let records = model.archive.records.filter {
      $0.observedAt >= Date().addingTimeInterval(-Double(hours) * 3600)
    }
    VStack(alignment: .leading, spacing: 16) {
      Text(L10n.text("Battery level & charging history")).font(.title2.bold())
      Toggle(L10n.text("Save local health history"), isOn: $model.enabled)
      HStack {
        ForEach([1, 24, 168], id: \.self) { range in
          Button(L10n.text(range == 1 ? "1 hour" : range == 24 ? "24 hours" : "7 days")) {
            hours = range
          }
          .buttonStyle(.bordered).tint(hours == range ? .accentColor : .secondary)
        }
      }
      MonitoringChart(
        title: L10n.text("Battery level"), unit: "%", data: data(records),
        percentScale: true, embedded: true, height: 180,
        windowSeconds: Double(hours) * 3600, maximumGap: 90)
      Text(
        L10n.text(
          "One sample per minute while monitoring is active. Uses Health History retention. Sleep, pauses and missing samples remain gaps; earlier macOS history is not imported."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      if let status = model.status { Text(L10n.text(status)).foregroundStyle(.orange) }
      let intervals = Array(BatteryHistoryAnalysis.intervals(records).suffix(20).reversed())
      if intervals.isEmpty {
        Text(L10n.text("No battery history yet. Enable recording and keep monitoring active."))
          .foregroundStyle(.secondary)
      }
      ForEach(intervals) { interval in
        VStack(alignment: .leading, spacing: 5) {
          HStack {
            Label(
              L10n.text(interval.state),
              systemImage: interval.state == "Charging" ? "bolt.fill" : "battery.75percent")
            Spacer()
            Text(
              monitoringNumber(interval.startLevel, digits: 0) + "% → "
                + monitoringNumber(interval.endLevel, digits: 0) + "%"
            )
            .monospacedDigit()
          }
          Text(
            interval.start.formatted(date: .abbreviated, time: .shortened) + " — "
              + interval.end.formatted(date: .abbreviated, time: .shortened)
          )
          .font(.caption).foregroundStyle(.secondary)
        }.fixedSize(horizontal: false, vertical: true)
        Divider()
      }
      Text(
        L10n.text(
          "Latest 20 observed intervals. Times mark recorded samples, not exact plug/unplug events."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
    }.orvenSurface()
  }
  private func data(_ records: [HealthRecord]) -> [ChartDatum] {
    var segments: [UUID: Int] = [:]
    var seen: Set<Date> = []
    return records.map { record in
      if segments[record.segment] == nil { segments[record.segment] = segments.count }
      let field = record.values.first { $0.id == "battery.level" }
      let fresh = field.map { seen.insert($0.observedAt).inserted } ?? false
      return ChartDatum(
        time: SampleTime(
          wall: record.observedAt, monotonic: record.observedAt.timeIntervalSince1970),
        value: fresh && field?.availability == .available ? field?.value : nil,
        generation: segments[record.segment] ?? 0)
    }
  }
}

struct SystemBatteryHealthView: View {
  @State private var report: BatteryHealthReport?
  @State private var loading = false
  @State private var failed = false
  @State private var request = UUID()
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(L10n.text("macOS Battery Health")).font(.title2.bold())
        Spacer()
        Button(L10n.text("Refresh")) { request = UUID() }.disabled(loading)
      }
      if loading { ProgressView() }
      if failed { Text(L10n.text("Unavailable")).foregroundStyle(.secondary) }
      if let report {
        LabeledContent(L10n.text("Battery condition"), value: condition(report.condition))
        LabeledContent(
          L10n.text("Maximum Capacity"),
          value: report.maximumCapacity.map { monitoringNumber($0, digits: 0) + "%" }
            ?? L10n.text("Unavailable"))
        Text(report.observedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption)
          .foregroundStyle(.secondary)
      }
      Text(
        L10n.text(
          "Reported by macOS System Information, separately from the raw capacity ratio. Availability and rounding depend on macOS and hardware. Refresh to update."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }.orvenSurface()
      .task(id: request) {
        loading = true
        failed = false
        report = nil
        let work = Task.detached(priority: .utility) { try BatteryHealthReport.read() }
        do {
          let result = try await withTaskCancellationHandler(
            operation: { try await work.value }, onCancel: { work.cancel() })
          try Task.checkCancellation()
          report = result
        } catch { if !Task.isCancelled { failed = true } }
        loading = false
      }
  }
  private func condition(_ value: String?) -> String {
    switch value {
    case "Good", "Normal": L10n.text("Normal")
    case "Check Battery", "Service Battery", "Replace Now", "Replace Soon", "Service Recommended":
      L10n.text("Service Recommended")
    default: value ?? L10n.text("Unavailable")
    }
  }
}
