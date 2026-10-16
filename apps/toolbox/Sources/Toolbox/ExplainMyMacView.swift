import AppKit
import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct ExplainMyMacView: View {
  @ObservedObject var model: MonitoringViewModel
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @State private var showsExport = false
  var body: some View {
    let insights = DiagnosticInsights.evaluate(
      model.snapshot,
      now: ProcessInfo.processInfo.systemUptime, active: model.samplingMode == .active)
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.text("Explain My Mac")).font(.title2.bold())
        Spacer()
        Button(L10n.text("Export diagnostics…")) { showsExport = true }
      }
      Text(
        L10n.text(
          "Evidence from recent samples. These observations do not establish causality and do not change your Mac."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      if insights.isEmpty {
        Text(
          L10n.text(
            model.samplingMode == .active
              ? "No matching findings in fresh, available samples. Missing data is not a health check."
              : "Sampling is paused. Resume active monitoring to evaluate current evidence.")
        )
        .foregroundStyle(.secondary)
      }
      ForEach(insights) { insight in
        VStack(alignment: .leading, spacing: 7) {
          HStack {
            Text(L10n.text(insight.title)).font(.headline)
            Spacer()
            Button(L10n.text("Review evidence")) {
              ToolboxRuntime.shared.navigation.open(.section(insight.section))
            }
          }
          Text(L10n.text(insight.explanation))
          Text(L10n.text(insight.evidence)).font(.caption.monospaced()).foregroundStyle(.secondary)
        }.padding(.vertical, 6)
      }
    }.orvenSurface()
      .sheet(isPresented: $showsExport) { DiagnosticsExportView(model: model) }
  }
}

struct DiagnosticsExportView: View {
  @ObservedObject var model: MonitoringViewModel
  var preparedReport: String? = nil
  var reportName = "Macinity-health.json"
  var hardwareProfile: HardwareProfile? = nil
  var rangeSince: Double? = nil
  @Environment(\.dismiss) private var dismiss
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @State private var includeNames = false
  @State private var preview = ""
  @State private var status: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(
        L10n.text(
          preparedReport != nil
            ? "Local report export"
            : (hardwareProfile == nil ? "Local Diagnostics Export" : "Hardware report"))
      ).font(
        .title2.bold())
      Text(
        L10n.text(
          preparedReport != nil
            ? "This report is frozen when opened. Close and reopen for newer observations. Preview the exact content before saving; nothing is uploaded."
            : hardwareProfile == nil
              ? "Preview the exact JSON before saving. No dedicated path, username, hostname or network endpoint fields are included. Opt-in process names may contain identifying text. Nothing is uploaded."
              : "Preview the hardware profile and recent range before saving. No serial, hostname, paths, process names or network endpoints are included. Nothing is uploaded."
        ))
      if hardwareProfile == nil && preparedReport == nil {
        Toggle(L10n.text("Include process names"), isOn: $includeNames)
          .onChange(of: includeNames) { _ in refreshPreview() }
      }
      ScrollView {
        Text(preview).font(.caption.monospaced()).textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }.frame(maxHeight: .infinity).padding(12).background(OrvenTheme.canvas)
      if let status { Text(L10n.text(status)).foregroundStyle(.secondary) }
      HStack {
        Button(L10n.text("Close")) { dismiss() }.keyboardShortcut(.cancelAction)
        if preparedReport == nil { Button(L10n.text("Refresh preview")) { refreshPreview() } }
        Spacer()
        Button(L10n.text(preparedReport != nil ? "Save report…" : "Save JSON…")) {
          let panel = NSSavePanel()
          panel.nameFieldStringValue =
            preparedReport != nil
            ? reportName
            : (hardwareProfile == nil ? "Macinity-diagnostics.json" : "Macinity-hardware.json")
          guard panel.runModal() == .OK, let url = panel.url else { return }
          do {
            try Data(preview.utf8).write(to: url, options: .atomic)
            status = preparedReport != nil ? "Report saved." : "Diagnostics saved."
          } catch {
            status =
              preparedReport != nil
              ? "Could not save the report. Choose a writable location and try again."
              : "Could not save diagnostics. Choose a writable location and try again."
          }
        }.disabled(preview.isEmpty).buttonStyle(.borderedProminent)
      }
    }.padding(24).frame(width: 640, height: 560).background(OrvenTheme.surface)
      .onAppear { refreshPreview() }
  }
  private func refreshPreview() {
    do {
      if let preparedReport {
        preview = preparedReport
        status = nil
        return
      }
      if let hardwareProfile {
        preview = String(
          decoding: try HardwareReport.encode(
            hardwareProfile, snapshot: model.snapshot,
            active: model.samplingMode == .active, since: rangeSince), as: UTF8.self)
        status = nil
        return
      }
      preview = String(
        decoding: try LocalDiagnosticsReport.encode(
          model.snapshot,
          active: model.samplingMode == .active, includeProcessNames: includeNames), as: UTF8.self)
      status = nil
    } catch {
      preview = ""
      status = "Could not generate diagnostics from the current sample. Refresh and try again."
    }
  }
}
