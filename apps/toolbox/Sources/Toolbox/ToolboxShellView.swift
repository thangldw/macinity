import SwiftUI
import ToolboxChanges
import ToolboxCore
import ToolboxStorage

enum ToolboxSection: String, CaseIterable, Identifiable {
  case home
  case storage
  case projects
  case applications
  case changes
  case recovery

  var id: String { rawValue }

  var title: String {
    switch self {
    case .home: L10n.text("Home")
    case .storage: L10n.text("Storage")
    case .projects: L10n.text("Projects")
    case .applications: L10n.text("Applications")
    case .changes: L10n.text("Change Timeline")
    case .recovery: L10n.text("Recovery")
    }
  }

  var symbol: String {
    switch self {
    case .home: "house"
    case .storage: "internaldrive"
    case .projects: "hammer"
    case .applications: "app.dashed"
    case .changes: "arrow.trianglehead.2.clockwise.rotate.90"
    case .recovery: "clock.arrow.circlepath"
    }
  }
}

struct ToolboxShellView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @SceneStorage("toolbox.selectedSection") private var selectedSectionRaw =
    ToolboxSection.home.rawValue

  private var selection: Binding<ToolboxSection?> {
    Binding(
      get: { ToolboxSection(rawValue: selectedSectionRaw) ?? .home },
      set: { selectedSectionRaw = ($0 ?? .home).rawValue }
    )
  }

  var body: some View {
    NavigationSplitView {
      List(ToolboxSection.allCases, selection: selection) { section in
        Label(section.title, systemImage: section.symbol)
          .tag(section)
      }
      .listStyle(.sidebar)
      .navigationTitle("Toolbox")
      .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
      .safeAreaInset(edge: .bottom) {
        languagePicker
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
      }
    } detail: {
      detailView
        .navigationTitle((ToolboxSection(rawValue: selectedSectionRaw) ?? .home).title)
    }
    .environment(
      \.locale,
      AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
    )
    .frame(minWidth: 960, minHeight: 640)
  }

  @ViewBuilder
  private var detailView: some View {
    switch ToolboxSection(rawValue: selectedSectionRaw) ?? .home {
    case .home:
      HomeView(selection: selection)
    case .storage:
      StorageModuleView(destination: .storage)
    case .projects:
      StorageModuleView(destination: .projects)
    case .applications:
      StorageModuleView(destination: .applications)
    case .changes:
      ChangeTimelineModuleView()
    case .recovery:
      StorageModuleView(destination: .recovery)
    }
  }

  private var languagePicker: some View {
    Picker(L10n.text("Language"), selection: $languageCode) {
      ForEach(AppLanguage.allCases) { language in
        Text(language.displayName).tag(language.rawValue)
      }
    }
    .labelsHidden()
    .pickerStyle(.menu)
  }
}
