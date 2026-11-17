import AppKit
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct MenuBarDiagnosticsView: View {
  @ObservedObject var model: MonitoringViewModel
  @ObservedObject private var awake = KeepAwakeController.shared
  @ObservedObject private var favorites = MacinityRuntime.shared.favorites
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
        Divider()
        quickActions
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

  @ViewBuilder private var quickActions: some View {
    Text(L10n.text("Quick actions")).font(.subheadline.weight(.semibold))
    HStack {
      Text(L10n.text("Keep Awake")).font(.caption)
      Spacer()
      if awake.remaining > 0 {
        Text(
          String(
            format: "%d:%02d:%02d", awake.remaining / 3600, awake.remaining / 60 % 60,
            awake.remaining % 60)
        ).font(.caption.monospacedDigit())
        Button(L10n.text("Stop")) { awake.stop() }.buttonStyle(.borderedProminent)
      } else {
        ForEach([15, 30, 60], id: \.self) { minutes in
          Button("\(minutes) min") { awake.start(minutes: minutes, pid: nil) }
        }
      }
    }.controlSize(.small)
    if let battery = model.snapshot?.hardware.reading.battery.value {
      Text(L10n.text(battery.onBattery ? "On battery" : "AC Power") + " · \(Int(battery.percent))%")
        .font(.caption).foregroundStyle(battery.onBattery ? Color.orange : .secondary)
    }
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], spacing: 6) {
      ForEach(favorites.sections.prefix(6)) { section in
        Button { open(section) } label: {
          Label(section.title, systemImage: section.symbol)
            .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
        }.buttonStyle(.bordered).controlSize(.small)
      }
    }
  }

  private func open(_ section: MacinitySection) {
    MacinityRuntime.shared.navigation.open(.section(section))
    NSApp.activate(ignoringOtherApps: true)
    _ = NSApp.delegate?.applicationShouldHandleReopen?(NSApp, hasVisibleWindows: false)
  }
}
