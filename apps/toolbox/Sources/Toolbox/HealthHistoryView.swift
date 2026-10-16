import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct HealthHistoryView: View {
  @ObservedObject var model: HealthHistoryViewModel
  @ObservedObject var alerts: SmartAlertsViewModel
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @State private var hours = 24
  @State private var report: LocalReportPreview?
  @State private var exportError = false

  private var records: [HealthRecord] {
    let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
    return model.archive.records.filter { $0.observedAt >= cutoff }
  }
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 20) {
        OrvenPageHeader(title: L10n.text("Health History & Baseline"))
        OrvenSamplingStatus(model: ToolboxRuntime.shared.monitoring)
        VStack(alignment: .leading, spacing: 12) {
          Toggle(L10n.text("Record health history locally"), isOn: $model.enabled)
          Text(
            L10n.text(
              "One observed sample per minute, up to seven days. No process names, paths or network endpoints. Paused, sleep and missing samples are gaps; enabling history does not enable background monitoring."
            )
          )
          .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
          Picker(L10n.text("History retention"), selection: $model.retentionHours) {
            Text(L10n.text("24 hours")).tag(24)
            Text(L10n.text("7 days")).tag(168)
          }.pickerStyle(.radioGroup).frame(maxWidth: 280)
          Text(String(format: L10n.text("%d recorded observations"), model.archive.records.count))
          Text(
            String(
              format: L10n.text("%d older observations omitted by the file-size budget."),
              model.archive.omittedRecords)
          ).font(.caption)
          if let status = model.status { Text(L10n.text(status)).foregroundStyle(.secondary) }
          Picker(L10n.text("Time range"), selection: $hours) {
            Text(L10n.text("1 hour")).tag(1)
            Text(L10n.text("24 hours")).tag(24)
            Text(L10n.text("7 days")).tag(168)
          }.pickerStyle(.segmented)
          HealthHistoryChartSection(
            records: records, hours: hours, languageCode: languageCode
          ).equatable()
          if exportError {
            Text(L10n.text("Could not prepare the local report. Stop recording and try again."))
          }
          Button(L10n.text("Export history JSON…")) { export(records) }.disabled(records.isEmpty)
        }.orvenSurface()
        HealthBaselineView(archive: model.archive, languageCode: languageCode) {
          Task { await model.captureBaseline() }
        }.equatable()
        SensorRecordingView(model: model)
        SmartAlertsView(model: alerts)
      }.padding(28)
    }.environment(\.locale, AppLanguage(rawValue: languageCode)?.locale ?? .current)
      .sheet(item: $report) { report in
        DiagnosticsExportView(
          model: ToolboxRuntime.shared.monitoring, preparedReport: report.text,
          reportName: report.filename)
      }
  }
  private func export(_ records: [HealthRecord]) {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      report = LocalReportPreview(
        text: String(decoding: try encoder.encode(records), as: UTF8.self),
        filename: "Macinity-health.json")
      exportError = false
    } catch {
      report = nil
      exportError = true
    }
  }
}

private struct HealthHistoryChartSection: View, Equatable {
  let records: [HealthRecord]
  let hours: Int
  let languageCode: String
  @State private var key = "cpu"

  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.records == rhs.records && lhs.hours == rhs.hours && lhs.languageCode == rhs.languageCode
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HealthMetricChart(
        records: records, selectedKey: $key, maximumGap: 90,
        windowSeconds: Double(hours) * 3600)
      Text(L10n.text("Recent pressure and thermal observations")).font(.headline)
      ForEach(records.suffix(12).reversed()) { record in
        HStack {
          Text(record.observedAt, style: .time)
          Text(
            L10n.text("Memory pressure") + ": " + L10n.text(record.pressure ?? "Unavailable"))
          Text(L10n.text("Thermal state") + ": " + L10n.text(record.thermal ?? "Unavailable"))
        }.font(.caption)
      }
    }
  }
}

private struct HealthBaselineView: View, Equatable {
  let archive: HealthArchive
  let languageCode: String
  let captureBaseline: () -> Void

  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.archive == rhs.archive && lhs.languageCode == rhs.languageCode
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.text("Baseline comparison")).font(.title2.bold())
        Spacer()
        Button(L10n.text("Capture baseline")) { captureBaseline() }
          .disabled(archive.records.count < 30)
      }
      Text(
        L10n.text(
          "Capture the latest 30–60 recorded samples as a reference. Compare medians with at least ten newer samples per metric. Workload differences can explain changes; this is not causal diagnosis."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      if let baseline = archive.baseline {
        Text(baseline.capturedAt, style: .date)
        Text(baseline.capturedAt, style: .time)
      }
      let comparisons = HealthAnalysis.comparisons(archive)
      if comparisons.isEmpty {
        Text(
          L10n.text(
            "Not enough baseline or newer observations yet. Keep recording during comparable workloads."
          )
        )
        .foregroundStyle(.secondary)
      }
      ForEach(comparisons) { comparison in
        HealthComparisonRow(comparison: comparison)
      }
    }.orvenSurface()
  }
}

private struct HealthComparisonRow: View {
  let comparison: HealthComparison

  private var medianText: String {
    let baseline = monitoringNumber(comparison.baselineMedian, digits: 1)
    let recent = monitoringNumber(comparison.currentMedian, digits: 1)
    return
      "\(L10n.text("Baseline median")): \(baseline) \(comparison.unit) → \(L10n.text("Recent median")): \(recent) \(comparison.unit)"
  }

  private var changeText: String {
    let change = monitoringNumber(comparison.currentMedian - comparison.baselineMedian, digits: 1)
    return
      "\(L10n.text("Change")): \(change) \(comparison.unit) · \(comparison.baselineCount) / \(comparison.currentCount)"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(healthMetricTitle(comparison.title)).font(.headline)
      Text(medianText)
      Text(changeText).font(.caption).monospacedDigit()
    }
  }
}

struct HealthMetricChart: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let records: [HealthRecord]
  @Binding var selectedKey: String
  let maximumGap: Double
  let windowSeconds: Double
  private var metrics: [HealthValue] {
    var latest: [String: HealthValue] = [:]
    for record in records {
      for value in record.values { latest[value.id] = value }
    }
    return latest.values.sorted { $0.id < $1.id }
  }
  var body: some View {
    let availableMetrics = metrics
    return VStack(alignment: .leading, spacing: 12) {
      OrvenChoicePicker(
        L10n.text("Chart metric"), selection: $selectedKey,
        options: [("cpu", L10n.text("System CPU"))]
          + availableMetrics.filter { $0.id != "cpu" }.map { ($0.id, healthMetricTitle($0.title)) },
        searchable: true, minimumWidth: 160)
      let metric = availableMetrics.first { $0.id == selectedKey }
      HealthChartPlot(
        title: healthMetricTitle(metric?.title ?? "System CPU"), unit: metric?.unit ?? "%",
        data: data, percentScale: (metric?.unit ?? "%") == "%",
        windowSeconds: max(60, windowSeconds), maximumGap: maximumGap, languageCode: languageCode
      ).equatable()
      if let metric { Text(metric.source).font(.caption).foregroundStyle(.secondary) }
      Text(
        L10n.text(
          "Temperature labels use community mappings; missing readings are gaps. Fan RPM and system power are observations, not fan control or CPU package power."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
  private var data: [ChartDatum] {
    var segments: [UUID: Int] = [:]
    var seen: Set<Date> = []
    return records.map { record in
      if segments[record.segment] == nil { segments[record.segment] = segments.count }
      let field = record.values.first { $0.id == selectedKey }
      let fresh = field.map { seen.insert($0.observedAt).inserted } ?? false
      return ChartDatum(
        time: SampleTime(
          wall: record.observedAt, monotonic: record.observedAt.timeIntervalSince1970),
        value: fresh && field?.availability == .available ? field?.value : nil,
        generation: segments[record.segment] ?? 0)
    }
  }
}

private struct HealthChartPlot: View, Equatable {
  let title: String
  let unit: String
  let data: [ChartDatum]
  let percentScale: Bool
  let windowSeconds: Double
  let maximumGap: Double
  let languageCode: String

  var body: some View {
    MonitoringChart(
      title: title, unit: unit, data: data, percentScale: percentScale,
      embedded: true, height: 180, windowSeconds: windowSeconds, maximumGap: maximumGap
    )
    .environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}

struct SensorRecordingView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: HealthHistoryViewModel
  @State private var key = "cpu"
  @State private var report: LocalReportPreview?
  @State private var exportError = false
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.text("Sensor Charts & Recording")).font(.title2.bold())
      Text(
        L10n.text(
          "Record existing samples every ten seconds for 15, 30 or 60 minutes. Sleep extends the wall-clock duration. The session stays in memory until Quit. Sampling pauses when the app is inactive unless menu bar monitoring is enabled; no readings are backfilled."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      HStack {
        Picker(L10n.text("Recording duration"), selection: $model.recordingMinutes) {
          Text(L10n.text("15 minutes")).tag(15)
          Text(L10n.text("30 minutes")).tag(30)
          Text(L10n.text("60 minutes")).tag(60)
        }.pickerStyle(.radioGroup).frame(maxWidth: 220).disabled(model.recording)
        Button(L10n.text(model.recording ? "Stop recording" : "Start recording")) {
          if model.recording {
            model.stopRecording()
          } else {
            model.startRecording(minutes: model.recordingMinutes)
          }
        }
      }
      Text(
        L10n.text(
          model.recording
            ? (model.samplingPaused
              ? "Recording paused until monitoring resumes" : "Recording observed samples")
            : "Recording stopped")
          + " · " + String(model.session.count))
      HealthMetricChart(
        records: model.session, selectedKey: $key, maximumGap: 15,
        windowSeconds: Double(model.recordingMinutes) * 60)
      if exportError {
        Text(L10n.text("Could not prepare the local report. Stop recording and try again."))
      }
      HStack {
        Button(L10n.text("Export session JSON…")) { export(csv: false) }.disabled(
          model.session.isEmpty)
        Button(L10n.text("Export session CSV…")) { export(csv: true) }.disabled(
          model.session.isEmpty)
      }
    }.orvenSurface()
      .environment(
        \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
      )
      .sheet(item: $report) { report in
        DiagnosticsExportView(
          model: ToolboxRuntime.shared.monitoring, preparedReport: report.text,
          reportName: report.filename)
      }
  }
  private func export(csv: Bool) {
    do {
      if csv {
        report = LocalReportPreview(
          text: HealthSessionExport.csv(model.session), filename: "Macinity-sensors.csv")
      } else {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        report = LocalReportPreview(
          text: String(decoding: try encoder.encode(model.session), as: UTF8.self),
          filename: "Macinity-sensors.json")
      }
      exportError = false
    } catch {
      report = nil
      exportError = true
    }
  }
}

enum HealthSessionExport {
  static func csv(_ records: [HealthRecord]) -> String {
    let formatter = ISO8601DateFormatter()
    func quote(_ value: String) -> String {
      "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    var rows = ["observedAt,metricObservedAt,segment,metric,unit,value,availability,source"]
    for record in records {
      for metric in record.values {
        rows.append(
          [
            formatter.string(from: record.observedAt), formatter.string(from: metric.observedAt),
            record.segment.uuidString, metric.id,
            metric.unit, metric.value.map { String($0) } ?? "", metric.availability.rawValue,
            metric.source,
          ]
          .map(quote).joined(separator: ","))
      }
    }
    return rows.joined(separator: "\n") + "\n"
  }
}

struct SmartAlertsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: SmartAlertsViewModel
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.text("Smart Alerts")).font(.title2.bold())
      Toggle(L10n.text("Enable health alerts"), isOn: $model.enabled)
      Text(
        L10n.text(
          "Off by default. Fresh active evidence only: sustained CPU, memory pressure, low startup space and elevated thermal state. A recovered condition must stay clear for 30 seconds; repeat alerts wait at least 15 minutes. Nothing is changed automatically."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      HStack {
        Button(L10n.text("Allow macOS notifications…")) { Task { await model.requestPermission() } }
          .disabled(model.requestingPermission)
        Button(L10n.text("Snooze for one hour")) { model.snooze() }.disabled(!model.enabled)
      }
      if let status = model.status { Text(L10n.text(status)).foregroundStyle(.secondary) }
      if model.events.isEmpty { Text(L10n.text("No alert events in this app session.")) }
      ForEach(model.events) { event in
        HStack(alignment: .top) {
          VStack(alignment: .leading) {
            Text(L10n.text(event.title)).font(.headline)
            Text(event.observedAt, style: .time)
            Text(L10n.text(event.evidence)).font(.caption)
          }
          Spacer()
          Button(L10n.text("Review evidence")) {
            ToolboxRuntime.shared.navigation.open(.section(event.section))
          }
        }
      }
    }.orvenSurface()
      .environment(
        \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}

private func healthMetricTitle(_ title: String) -> String {
  let pieces = title.components(separatedBy: " • ")
  return pieces.count == 2 ? L10n.text(pieces[0]) + " • " + pieces[1] : L10n.text(title)
}

private struct LocalReportPreview: Identifiable {
  let id = UUID()
  let text: String
  let filename: String
}
