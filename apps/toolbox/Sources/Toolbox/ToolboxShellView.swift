import AppKit
import SwiftUI
import ToolboxChanges
import ToolboxCore
import ToolboxStorage

enum ToolboxSection: String, CaseIterable, Identifiable {
  case home
  case diagnostics
  case processes
  case cpuMemory
  case networkActivity = "diskNetwork"
  case diskActivity
  case networkTools
  case batteryThermal
  case hardware
  case sensors
  case storage
  case projects
  case applications
  case developerTools
  case startup
  case workspaces
  case fileUtilities
  case devices
  case externalDrives
  case changes
  case healthHistory
  case recovery

  var id: String { rawValue }

  var title: String {
    switch self {
    case .home: L10n.text("Action Center")
    case .diagnostics: L10n.text("Smart Diagnostics")
    case .processes: L10n.text("Processes")
    case .cpuMemory: L10n.text("CPU & Memory")
    case .networkTools: L10n.text("Wi-Fi & LAN")
    case .networkActivity: L10n.text("Network Activity")
    case .diskActivity: L10n.text("Disk Activity")
    case .hardware: L10n.text("Hardware Inspector")
    case .sensors: L10n.text("Temperatures & Fans")
    case .batteryThermal: L10n.text("Battery & Thermal")
    case .storage: L10n.text("Storage")
    case .projects: L10n.text("Projects")
    case .externalDrives: L10n.text("External Drives")
    case .devices: L10n.text("Device Inspector")
    case .fileUtilities: L10n.text("File Utilities")
    case .workspaces: L10n.text("Work Profiles")
    case .startup: L10n.text("Startup & Background")
    case .developerTools: L10n.text("Developer Tools")
    case .applications: L10n.text("Applications")
    case .healthHistory: L10n.text("Health History")
    case .changes: L10n.text("Change Timeline")
    case .recovery: L10n.text("Recovery")
    }
  }

  var symbol: String {
    switch self {
    case .home: "house"
    case .diagnostics: "stethoscope"
    case .processes: "list.bullet.rectangle"
    case .cpuMemory: "cpu"
    case .networkTools: "wifi"
    case .networkActivity: "network"
    case .diskActivity: "externaldrive"
    case .hardware: "desktopcomputer"
    case .sensors: "thermometer.medium"
    case .batteryThermal: "battery.100"
    case .storage: "internaldrive"
    case .projects: "hammer"
    case .externalDrives: "externaldrive.badge.checkmark"
    case .devices: "cable.connector"
    case .fileUtilities: "doc.badge.gearshape"
    case .workspaces: "rectangle.3.group"
    case .startup: "power"
    case .developerTools: "wrench.and.screwdriver"
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
  @ObservedObject private var coordinator: ToolboxCoordinator
  @State private var showsOnboarding = false
  @State private var showsHelp = false

  init(coordinator: ToolboxCoordinator = ToolboxRuntime.shared.navigation) {
    self.coordinator = coordinator
  }

  private var selection: Binding<ToolboxSection?> {
    Binding(
      get: { coordinator.selectedSection },
      set: { if let section = $0 { coordinator.open(.section(section)) } }
    )
  }

  var body: some View {
    NavigationSplitView {
      VStack(spacing: 0) {
        HStack(spacing: 10) {
          Image(nsImage: AppBrand.logo)
            .resizable().scaledToFit().frame(width: 32, height: 32)
            .accessibilityHidden(true)
          Text(AppMetadata.displayName).font(.system(size: 23, weight: .bold))
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 28).padding(.vertical, 16)
        Divider().padding(.horizontal, 16)
        List(selection: selection) {
          ForEach(OrvenArea.allCases) { area in
            Section {
              ForEach(area.sections) { section in
                sidebarLabel(section.title, symbol: section.symbol)
                  .font(
                    .system(
                      size: 13,
                      weight: coordinator.selectedSection == section ? .semibold : .regular)
                  )
                  .padding(.vertical, 3)
                  .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                  .tag(section)
              }
            } header: {
              Text(area.title).font(.caption.weight(.semibold))
                .foregroundStyle(OrvenTheme.secondary)
            }
          }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 30)
        VStack(alignment: .leading, spacing: 12) {
          Divider()
          if #available(macOS 14.0, *) {
            SettingsLink { sidebarLabel(L10n.text("Settings"), symbol: "gearshape") }
          } else {
            Button {
              NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
              sidebarLabel(L10n.text("Settings"), symbol: "gearshape")
            }
          }
          Button {
            showsHelp = true
          } label: {
            sidebarLabel(L10n.text("About Macinity"), symbol: "questionmark.circle")
          }
        }.buttonStyle(.plain).font(.system(size: 13))
          .padding(.horizontal, 28).padding(.vertical, 16)
      }
      .foregroundStyle(OrvenTheme.ink)
      .background(OrvenTheme.sidebar)
      .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
    } detail: {
      VStack(spacing: 0) {
        detailView.frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      // Bound the column's minimum-width proposal before wrapped copy is measured.
      // Otherwise NavigationSplitView can derive a multi-screen minimum height.
      .frame(minWidth: 600)
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
        HStack(spacing: 12) {
          Image(nsImage: AppBrand.logo).resizable().scaledToFit().frame(width: 64, height: 64)
            .accessibilityHidden(true)
          Text(AppMetadata.displayName).font(.system(size: 32, weight: .semibold))
        }
        Text(L10n.text(AppMetadata.tagline)).font(.title2)
        Text(developerCredit)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
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

  private var developerCredit: AttributedString {
    var credit = AttributedString(L10n.text("Developed by thangldw and Codex"))
    if let range = credit.range(of: "thangldw") {
      credit[range].link = URL(string: "https://thangldw.github.io/")
    }
    return credit
  }

  @ViewBuilder
  private var detailView: some View {
    switch coordinator.selectedSection {
    case .home:
      HomeView(coordinator: coordinator)
    case .diagnostics:
      SmartDiagnosticsView()
    case .processes:
      ProcessesView(model: ToolboxRuntime.shared.monitoring, focus: coordinator.processFocus)
    case .cpuMemory:
      CPUMemoryView(model: ToolboxRuntime.shared.monitoring)
    case .networkTools:
      NetworkToolsView(monitoring: ToolboxRuntime.shared.monitoring)
    case .networkActivity:
      NetworkActivityView(model: ToolboxRuntime.shared.monitoring)
    case .diskActivity:
      DiskActivityView(model: ToolboxRuntime.shared.monitoring)
    case .batteryThermal:
      BatteryThermalView(model: ToolboxRuntime.shared.monitoring)
    case .hardware:
      HardwareInspectorView(model: ToolboxRuntime.shared.monitoring, mode: .profile)
    case .sensors:
      HardwareInspectorView(model: ToolboxRuntime.shared.monitoring, mode: .sensors)
    case .storage:
      StorageModuleView(destination: .storage, focusPath: coordinator.storageFocusPath)
        .orvenSurface(padding: 0).padding(20)
    case .projects:
      StorageModuleView(destination: .projects).orvenSurface(padding: 0).padding(20)
    case .externalDrives:
      ExternalDrivesView()
    case .devices:
      DeviceInspectorView()
    case .fileUtilities:
      FileUtilitiesView()
    case .workspaces:
      WorkspacePresetsView()
    case .startup:
      StartupManagerView()
    case .developerTools:
      DeveloperToolsView()
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

  private func sidebarLabel(_ title: String, symbol: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: symbol)
        .font(.system(size: 15, weight: .medium))
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
      Text(title)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }

}
