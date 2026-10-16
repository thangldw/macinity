import SwiftUI
import ToolboxCore

struct ApplicationsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: ApplicationViewModel
  var applicationActivity: ((URL) -> AnyView)? = nil
  @State private var selected: InstalledApplication?
  @State private var includeLeftovers = true
  @State private var inspected: InstalledApplication?
  @State private var focusedAppID: String?
  @State private var searchText = ""
  @State private var sortsByName = false
  @FocusState private var searchFocused: Bool

  private var displayedApplications: [InstalledApplication] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    return model.applications.filter { app in
      query.isEmpty || app.name.localizedCaseInsensitiveContains(query)
        || (app.bundleIdentifier?.localizedCaseInsensitiveContains(query) ?? false)
    }.sorted { lhs, rhs in
      if sortsByName { return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending }
      return lhs.totalBytes == rhs.totalBytes ? lhs.id < rhs.id : lhs.totalBytes > rhs.totalBytes
    }
  }
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Applications", subtitle: "Ứng dụng và dữ liệu còn sót", symbol: "app.badge",
        value: model.applications.count.formatted(), valueLabel: "ứng dụng")
      Divider()
      HStack {
        TextField(L10n.text("Search apps or Bundle ID"), text: $searchText)
          .textFieldStyle(.roundedBorder).focused($searchFocused)
        if !searchText.isEmpty {
          Button {
            searchText = ""
            searchFocused = true
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .accessibilityLabel(L10n.text("Clear search"))
          .buttonStyle(.borderless)
        }
        Toggle(L10n.text("Sort by name"), isOn: $sortsByName).toggleStyle(.checkbox)
      }.padding(.horizontal, 18).padding(.vertical, 10)
      if model.applications.isEmpty {
        if model.isWorking || model.scannedAt == nil {
          VStack(spacing: 12) {
            ProgressView()
            Text(L10n.text("Đang phân tích ứng dụng và dữ liệu liên quan…"))
              .foregroundStyle(.secondary)
          }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          EmptyStateView(
            title: "No applications found", symbol: "app.badge",
            detail: "No readable application bundles were found in /Applications or ~/Applications."
          )
        }
      } else if displayedApplications.isEmpty {
        EmptyStateView(
          title: "No matching applications", symbol: "magnifyingglass",
          detail: "Clear filters or change the search query.")
      } else {
        GeometryReader { geometry in
          HStack(spacing: 0) {
            applicationsList.frame(maxWidth: .infinity, maxHeight: .infinity)
            if geometry.size.width >= 900,
              let app = displayedApplications.first(where: { $0.id == focusedAppID })
            {
              Divider()
              AppDossierView(
                app: app, observedAt: model.scannedAt, embedded: true
              ).id(app.id).frame(width: 340)
            }
          }
        }
      }
      Divider()
      HStack {
        if model.isWorking { ProgressView().controlSize(.small) }
        Text(L10n.text(model.status))
        Spacer()
        Button(L10n.text("App Dossier")) {
          inspected = displayedApplications.first { $0.id == focusedAppID }
        }.disabled(!displayedApplications.contains { $0.id == focusedAppID })
        Button("Quét ứng dụng") { model.scan() }.disabled(model.isWorking)
      }.padding(18)
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
    )
    .task { model.scanIfNeeded() }
    .sheet(item: $inspected) { app in
      AppDossierView(app: app, observedAt: model.scannedAt, activity: applicationActivity?(app.url))
    }.alert(
      "Gỡ \(selected?.name ?? "ứng dụng")?",
      isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } })
    ) {
      Toggle("Kèm dữ liệu còn sót", isOn: $includeLeftovers)
      Button("Hủy", role: .cancel) { selected = nil }
      Button("Chuyển vào Trash", role: .destructive) {
        if let selected { model.uninstall(selected, includeLeftovers: includeLeftovers) }
        selected = nil
      }
    } message: {
      Text(
        "Ứng dụng và dữ liệu đã chọn sẽ được chuyển vào Trash. Một số ứng dụng hệ thống có thể yêu cầu quyền quản trị."
      )
    }
  }

  private var applicationsList: some View {
    List(displayedApplications, selection: $focusedAppID) { app in
      HStack(alignment: .top, spacing: 12) {
        DisclosureGroup {
          ForEach(app.leftovers) { item in
            HStack {
              Image(systemName: item.confidence.symbol).foregroundStyle(
                item.confidence == .safe ? .green : item.confidence == .review ? .orange : .red)
              VStack(alignment: .leading, spacing: 2) {
                Text(item.entry.url.path).lineLimit(1)
                Text("\(L10n.text(item.kind.rawValue)) • \(L10n.text(item.evidence))")
                  .font(.caption).foregroundStyle(.secondary)
              }
              Spacer()
              Text(ByteCount.string(item.entry.bytes))
            }
          }
        } label: {
          HStack {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path)).resizable().frame(
              width: 34, height: 34)
            VStack(alignment: .leading) {
              Text(app.name).fontWeight(.medium)
              Text(app.bundleIdentifier ?? L10n.text("Không có Bundle ID")).font(.caption)
                .foregroundStyle(
                  .secondary)
            }
            Spacer()
            Text(ByteCount.string(app.totalBytes))

          }
        }
        Button("Gỡ…") { selected = app }.buttonStyle(.bordered)
      }.padding(.vertical, 4).tag(app.id)
    }.listStyle(.inset).scrollContentBackground(.hidden).background(OrvenTheme.surface)
  }

}
