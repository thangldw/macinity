import SwiftUI
import ToolboxCore

struct SmartDiagnosticsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject private var model = ToolboxRuntime.shared.diagnostics
  @State private var topic = DiagnosticTopic.slow
  var body: some View {
    let _ = languageCode
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        OrvenPageHeader(title: L10n.text("Smart Diagnostics"))
        Text(
          L10n.text(
            "Read-only triage from timestamped observations. Findings are hints, not a diagnosis of root cause. Reports stay in this app session."
          )
        )
        .font(.callout).foregroundStyle(OrvenTheme.secondary)
        OrvenChoicePicker(
          L10n.text("What needs attention?"), selection: $topic,
          options: DiagnosticTopic.allCases.map { ($0, L10n.text($0.title)) }, minimumWidth: 180
        )
        .disabled(model.busy)
        HStack {
          Button(L10n.text("Analyze latest evidence")) {
            model.analyze(topic, monitoring: ToolboxRuntime.shared.monitoring)
          }
          .buttonStyle(.borderedProminent).disabled(model.busy)
          if model.busy {
            ProgressView().controlSize(.small)
            Button(L10n.text("Cancel")) { model.cancel() }
          } else {
            Button(L10n.text("Clear report")) { model.clear() }.disabled(model.report == nil)
          }
        }
        if let report = model.report {
          VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text(report.topic.title)).font(.title2.bold())
            Text(workflowTimestamp(report.createdAt, language: languageCode)).font(.caption)
            Text(
              L10n.text(
                "Saved observation, not a live status. Analyze again after taking action. Unavailable evidence is never treated as healthy."
              )
            )
            .font(.caption).foregroundStyle(OrvenTheme.secondary)
            ForEach(report.findings) { finding in
              VStack(alignment: .leading, spacing: 8) {
                Label(
                  L10n.text(finding.title),
                  systemImage: finding.level == .attention
                    ? "exclamationmark.triangle"
                    : finding.level == .unknown ? "questionmark.circle" : "info.circle"
                )
                .font(.headline)
                if let metric = report.metrics.first(where: { $0.id == finding.id }) {
                  Text(
                    L10n.text(metric.label) + ": "
                      + (metric.freshValue(at: report.monotonic).map {
                        monitoringNumber($0, digits: 1)
                      } ?? L10n.text("Unavailable")))
                  Text(
                    metric.source + " · "
                      + metric.observedAt.formatted(date: .omitted, time: .standard)
                  ).font(.caption).foregroundStyle(OrvenTheme.secondary)
                } else {
                  Text(
                    report.topic.keys.contains(finding.id) ? L10n.text(metricLabel(finding.id)) : ""
                  ).font(.caption)
                }
                Text(L10n.text(finding.explanation)).font(.callout)
              }.frame(maxWidth: .infinity, alignment: .leading).orvenSurface()
            }
            Button(L10n.text("Open related tools")) {
              ToolboxRuntime.shared.navigation.open(.section(report.topic.section))
            }
            if !report.processes.isEmpty {
              Text(L10n.text("Largest observed CPU consumers")).font(.headline)
              Text(
                L10n.text(
                  "Process CPU may exceed 100% across cores. Identity is checked again by the process inspector."
                )
              )
              .font(.caption).foregroundStyle(OrvenTheme.secondary)
              ForEach(report.processes) { process in
                Button {
                  ToolboxRuntime.shared.navigation.open(.inspectProcess(process.identity))
                } label: {
                  HStack {
                    Text(process.name + " · PID \(process.identity.pid)")
                    Spacer()
                    Text(monitoringNumber(process.cpu, digits: 1) + "%")
                  }
                }.buttonStyle(.bordered)
              }
            }
            if let previous = model.previous {
              Text(L10n.text("Compared with previous analysis")).font(.headline)
              Text(workflowTimestamp(previous.createdAt, language: languageCode)).font(
                .caption)
              let deltas = SmartDiagnostics.comparison(report, previous)
              if deltas.isEmpty { Text(L10n.text("No newer comparable measurements")) }
              ForEach(deltas, id: \.0) { label, delta in
                Text(L10n.text(label) + ": Δ " + monitoringNumber(delta, digits: 1))
              }
              Text(
                L10n.text(
                  "Differences describe observations; they do not prove an action caused the change."
                )
              )
              .font(.caption).foregroundStyle(OrvenTheme.secondary)
            }
          }
        } else {
          Text(
            L10n.text(
              "Choose a symptom and analyze. Network analysis reads configuration only; it sends no probe traffic."
            ))
        }
      }.padding(28).frame(maxWidth: 1400, alignment: .leading)
    }.background(OrvenTheme.canvas).onDisappear { model.cancel() }
  }
  private func metricLabel(_ id: String) -> String {
    DiagnosticMetric(
      id: id, value: nil, observedAt: .distantPast, monotonic: 0, source: "", available: false
    ).label
  }
}
