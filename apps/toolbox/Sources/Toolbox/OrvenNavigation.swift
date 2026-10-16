import SwiftUI
import ToolboxCore

/// Product areas group existing routes without changing persisted route identities.
enum OrvenArea: String, CaseIterable, Identifiable {
  case overview, mac, thermals, software, files, network
  var id: String { rawValue }

  var title: String {
    switch self {
    case .overview: L10n.text("Overview")
    case .mac: L10n.text("My Mac")
    case .thermals: L10n.text("Thermals")
    case .software: L10n.text("Software")
    case .files: L10n.text("Files")
    case .network: L10n.text("Network")
    }
  }

  var symbol: String {
    switch self {
    case .overview: "house"
    case .mac: "laptopcomputer"
    case .thermals: "thermometer.medium"
    case .software: "square.grid.2x2"
    case .files: "folder"
    case .network: "network"
    }
  }

  var sections: [ToolboxSection] {
    switch self {
    case .overview: [.home, .diagnostics, .healthHistory, .changes]
    case .mac: [.hardware, .devices, .cpuMemory, .workspaces]
    case .thermals: [.sensors, .batteryThermal]
    case .software: [.applications, .developerTools, .startup, .processes, .projects]
    case .files: [.diskActivity, .externalDrives, .fileUtilities, .storage, .recovery]
    case .network: [.networkTools, .networkActivity]
    }
  }
}

extension ToolboxSection {
  var area: OrvenArea {
    switch self {
    case .home, .diagnostics, .healthHistory, .changes: .overview
    case .hardware, .devices, .cpuMemory, .workspaces: .mac
    case .sensors, .batteryThermal: .thermals
    case .applications, .developerTools, .startup, .processes, .projects: .software
    case .diskActivity, .externalDrives, .fileUtilities, .storage, .recovery: .files
    case .networkTools, .networkActivity: .network
    }
  }

  static func matching(_ query: String) -> [Self] {
    let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
    return OrvenArea.allCases.flatMap(\.sections).filter { section in
      let text = section.area.title + " " + section.title
      return words.allSatisfy { text.localizedStandardContains($0) }
    }
  }
}

/// Searches the bounded route catalog only; never scans files or starts operations.
struct OrvenToolSearch: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let open: (ToolboxSection) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @FocusState private var searchFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(L10n.text("Search Macinity")).font(.title2.bold())
        Spacer()
        Button(L10n.text("Close")) { dismiss() }.keyboardShortcut(.cancelAction)
      }
      HStack {
        Image(systemName: "magnifyingglass").foregroundStyle(OrvenTheme.secondary)
        TextField(L10n.text("Find a tool or page"), text: $query)
          .textFieldStyle(.plain).focused($searchFocused)
        if !query.isEmpty {
          Button {
            query = ""
            searchFocused = true
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .accessibilityLabel(L10n.text("Clear search"))
          .buttonStyle(.borderless)
        }
      }.padding(12).background(OrvenTheme.canvas, in: RoundedRectangle(cornerRadius: 9))
      Text(L10n.text("Find tools and pages. File and application contents are not searched."))
        .font(.callout).foregroundStyle(OrvenTheme.secondary)
        .fixedSize(horizontal: false, vertical: true)
      let results = ToolboxSection.matching(query)
      if results.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "magnifyingglass").font(.largeTitle)
          Text(L10n.text("No matching tools")).font(.headline)
          Text(L10n.text("Try another name or clear the search."))
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(spacing: 4) {
            ForEach(results) { section in
              Button {
                open(section)
              } label: {
                HStack(spacing: 12) {
                  Image(systemName: section.symbol).frame(width: 24)
                  Text(section.title)
                  Spacer()
                  Text(section.area.title).foregroundStyle(OrvenTheme.secondary)
                  Image(systemName: "arrow.up.right").accessibilityHidden(true)
                }.padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
              }.buttonStyle(.bordered)
            }
          }
        }
      }
    }
    .padding(24).frame(width: 560, height: 460)
    .foregroundStyle(OrvenTheme.ink).background(OrvenTheme.surface)
    .onAppear { searchFocused = true }
  }
}
