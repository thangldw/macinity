import AppKit
import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct MenuBarDiagnosticsView: View {
  @ObservedObject var model: MonitoringViewModel
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue

  var body: some View {
    TimelineView(.periodic(from: .now, by: 5)) { _ in
      VStack(alignment: .leading, spacing: 12) {
        Text(AppMetadata.displayName).font(.headline)
        Text(model.menuBarTitle).font(.title2.monospacedDigit())
        if let snapshot = model.snapshot {
          HStack {
            Text(L10n.text("Last sample"))
            Text(snapshot.time.wall, style: .time)
            Text(
              availabilityLabel(
                snapshot.cpu.freshness(at: ProcessInfo.processInfo.systemUptime, maximumAge: 15)))
          }.font(.caption).foregroundStyle(.secondary)
          Divider()
          Text(L10n.text("Top CPU consumers • one core")).font(.subheadline.weight(.semibold))
          if snapshot.processes.freshness(at: ProcessInfo.processInfo.systemUptime, maximumAge: 15)
            == .available
          {
            ForEach(ProcessOrdering.cpu.sorted(snapshot.processes.value ?? []).prefix(5)) {
              process in
              HStack {
                Text(process.name).lineLimit(1).help(process.name)
                Spacer()
                Text(
                  process.cpu.value.map {
                    monitoringNumber($0, digits: 1) + "%"
                  } ?? availabilityLabel(process.cpu.availability)
                ).monospacedDigit()
              }.font(.caption)
            }
          } else {
            Text(
              availabilityLabel(
                snapshot.processes.freshness(
                  at: ProcessInfo.processInfo.systemUptime, maximumAge: 15))
            ).font(.caption)
          }
          HStack {
            Text(L10n.text("Thermal state"))
            let thermal = snapshot.hardware.reading.thermal
            let state = thermal.freshness(
              at: ProcessInfo.processInfo.systemUptime, maximumAge: 15)
            Text(
              state == .available
                ? thermal.value.map(thermalLabel) ?? L10n.text("Unavailable")
                : availabilityLabel(state))
          }.font(.caption)
        }
        Text(L10n.text("Automatic alerts are not available.")).font(.caption).foregroundStyle(
          .secondary)
        Divider()
        HStack {
          Button(L10n.text("Overview")) { open(.home) }
          Button(L10n.text("Processes")) { open(.processes) }
          Button(L10n.text("Storage")) { open(.storage) }
        }
        HStack {
          Button(L10n.text("Disable menu bar")) { model.menuBarEnabled = false }
          Spacer()
          Button(L10n.text("Quit Macinity")) { NSApp.terminate(nil) }
        }
      }.padding(16).frame(width: 360)
    }
    .environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }

  private func open(_ section: ToolboxSection) {
    ToolboxRuntime.shared.navigation.open(.section(section))
    NSApp.activate(ignoringOtherApps: true)
    _ = NSApp.delegate?.applicationShouldHandleReopen?(NSApp, hasVisibleWindows: false)
  }
}
