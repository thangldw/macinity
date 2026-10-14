import AppKit
import SwiftUI
import ToolboxChanges
import ToolboxCore
import ToolboxStorage

enum ToolboxSection: String, CaseIterable, Identifiable {
  case home
  case processes
  case cpuMemory
  case diskNetwork
  case networkTools
  case batteryThermal
  case hardware
  case storage
  case projects
  case applications
  case changes
  case healthHistory
  case recovery

  var id: String { rawValue }

  var title: String {
    switch self {
    case .home: L10n.text("Overview")
    case .processes: L10n.text("Processes")
    case .cpuMemory: L10n.text("CPU & Memory")
    case .networkTools: L10n.text("Wi-Fi & LAN")
    case .diskNetwork: L10n.text("Disk & Network")
    case .hardware: L10n.text("Hardware Inspector")
    case .batteryThermal: L10n.text("Battery & Thermal")
    case .storage: L10n.text("Storage")
    case .projects: L10n.text("Projects")
    case .applications: L10n.text("Applications")
    case .healthHistory: L10n.text("Health History")
    case .changes: L10n.text("Change Timeline")
    case .recovery: L10n.text("Recovery")
    }
  }

  var symbol: String {
    switch self {
    case .home: "house"
    case .processes: "list.bullet.rectangle"
    case .cpuMemory: "cpu"
    case .networkTools: "wifi"
    case .diskNetwork: "network"
    case .hardware: "desktopcomputer"
    case .batteryThermal: "battery.100"
    case .storage: "internaldrive"
    case .projects: "hammer"
    case .applications: "app.dashed"
    case .healthHistory: "chart.xyaxis.line"
    case .changes: "arrow.trianglehead.2.clockwise.rotate.90"
    case .recovery: "clock.arrow.circlepath"
    }
  }
}

struct ToolboxShellView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @AppStorage("toolbox.onboarding.completed.v2") private var onboardingCompleted = false
  @ObservedObject private var coordinator = ToolboxRuntime.shared.navigation
  @State private var showsOnboarding = false
  @State private var showsHelp = false

  private var selection: Binding<ToolboxSection?> {
    Binding(
      get: { coordinator.selectedSection },
      set: { coordinator.open(.section($0 ?? .home)) }
    )
  }

  var body: some View {
    NavigationSplitView {
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
            .resizable().scaledToFit().frame(width: 46, height: 46).accessibilityHidden(true)
          Text(AppMetadata.displayName).font(.system(size: 27, weight: .bold))
          Spacer(minLength: 0)
        }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)
        List(selection: selection) {
          navigationRow(.home)
          Section(L10n.text("Monitoring")) {
            ForEach([
              ToolboxSection.processes, .cpuMemory, .diskNetwork, .networkTools, .batteryThermal,
              .hardware,
            ]) {
              navigationRow($0)
            }
          }
          Section(L10n.text("Management")) {
            ForEach([ToolboxSection.storage, .projects, .applications]) { navigationRow($0) }
          }
          Section(L10n.text("History")) {
            ForEach([ToolboxSection.healthHistory, .changes, .recovery]) { navigationRow($0) }
          }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 40)
        VStack(alignment: .leading, spacing: 12) {
          Divider()
          if #available(macOS 14.0, *) {
            SettingsLink { Label(L10n.text("Settings"), systemImage: "gearshape") }
          } else {
            Button {
              NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
              Label(L10n.text("Settings"), systemImage: "gearshape")
            }
          }
          Button {
            showsHelp = true
          } label: {
            Label(L10n.text("About Orven"), systemImage: "questionmark.circle")
          }
          languagePicker
        }.buttonStyle(.plain).font(.body).padding(20)
      }
      .foregroundStyle(OrvenTheme.ink)
      .background(OrvenTheme.sidebar)
      .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
    } detail: {
      GeometryReader { geometry in
        detailView.frame(width: geometry.size.width, height: geometry.size.height)
      }
      .background(OrvenTheme.canvas)
      .navigationTitle(coordinator.selectedSection.title)
    }
    .environment(
      \.locale,
      AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
    )
    .tint(OrvenTheme.action)
    .background(MainWindowMarker())
    .frame(minWidth: 960, minHeight: 640)
    .task {
      if !onboardingCompleted { showsOnboarding = true }
      coordinator.refreshSummaries()
    }
    .sheet(isPresented: $showsHelp) {
      VStack(alignment: .leading, spacing: 18) {
        if let url = Bundle.main.url(forResource: "OrvenLogo", withExtension: "png"),
          let logo = NSImage(contentsOf: url)
        {
          Image(nsImage: logo).resizable().scaledToFit().frame(width: 260, height: 88)
            .accessibilityLabel(AppMetadata.displayName)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        }
        Text(L10n.text(AppMetadata.tagline)).font(.title2)
        Text(L10n.text("Read-only. Recent trends stay on this Mac and are not saved."))
        Text(L10n.text("Runs locally. No telemetry. Nothing is deleted automatically."))
          .foregroundStyle(.secondary)
        Button(L10n.text("Close")) { showsHelp = false }.keyboardShortcut(.cancelAction)
      }.padding(28).frame(width: 430).background(OrvenTheme.surface)
    }
    .sheet(isPresented: $showsOnboarding) {
      OnboardingView {
        onboardingCompleted = true
        showsOnboarding = false
      }
      .interactiveDismissDisabled()
    }
  }

  @ViewBuilder
  private var detailView: some View {
    switch coordinator.selectedSection {
    case .home:
      HomeView(coordinator: coordinator)
    case .processes:
      ProcessesView(model: ToolboxRuntime.shared.monitoring, focus: coordinator.processFocus)
    case .cpuMemory:
      CPUMemoryView(model: ToolboxRuntime.shared.monitoring)
    case .networkTools:
      NetworkToolsView(monitoring: ToolboxRuntime.shared.monitoring)
    case .diskNetwork:
      DiskNetworkView(model: ToolboxRuntime.shared.monitoring)
    case .batteryThermal:
      BatteryThermalView(model: ToolboxRuntime.shared.monitoring)
    case .hardware:
      HardwareInspectorView(model: ToolboxRuntime.shared.monitoring)
    case .storage:
      StorageModuleView(destination: .storage, focusPath: coordinator.storageFocusPath)
        .orvenSurface(padding: 0).padding(20)
    case .projects:
      StorageModuleView(destination: .projects).orvenSurface(padding: 0).padding(20)
    case .applications:
      StorageModuleView(
        destination: .applications,
        applicationActivity: { url in
          AnyView(
            AppActivityTimelineView(applicationURL: url, model: ToolboxRuntime.shared.monitoring))
        }
      ).orvenSurface(padding: 0).padding(20)
    case .healthHistory:
      HealthHistoryView(
        model: ToolboxRuntime.shared.monitoring.health,
        alerts: ToolboxRuntime.shared.monitoring.alerts)
    case .changes:
      ChangeTimelineModuleView { path in
        coordinator.open(.reviewStorage(path: path))
      }.orvenSurface(padding: 0).padding(20)
    case .recovery:
      StorageModuleView(destination: .recovery).orvenSurface(padding: 0).padding(20)
    }
  }

  private func navigationRow(_ section: ToolboxSection) -> some View {
    Label(section.title, systemImage: section.symbol).font(.system(size: 16))
      .padding(.vertical, 5)
      .foregroundStyle(coordinator.selectedSection == section ? Color.white : OrvenTheme.ink)
      .tag(section)
  }

  private var languagePicker: some View {
    Picker(L10n.text("Language"), selection: $languageCode) {
      ForEach(AppLanguage.allCases) { language in
        Text(language.displayName).tag(language.rawValue)
      }
    }
    .labelsHidden()
    .pickerStyle(.menu)
    .tint(OrvenTheme.accent)
  }
}
