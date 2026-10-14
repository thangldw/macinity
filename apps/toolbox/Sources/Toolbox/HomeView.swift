import SwiftUI
import ToolboxCore

struct HomeView: View {
  // L10n returns plain strings, so static page copy must observe language changes.
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var coordinator: ToolboxCoordinator
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        OrvenPageHeader(title: L10n.text("Your Mac, at a glance"))
        MonitoringOverviewView(model: ToolboxRuntime.shared.monitoring)
        HStack(spacing: 18) {
          Button(L10n.text("Change Timeline")) { coordinator.open(.section(.changes)) }
          Button(L10n.text("Recovery")) { coordinator.open(.section(.recovery)) }
          Spacer()
          Text(L10n.text("Runs locally. No telemetry. Nothing is deleted automatically."))
            .font(.caption).foregroundStyle(OrvenTheme.secondary)
        }.buttonStyle(.link)
      }.padding(28).frame(maxWidth: 1400, alignment: .leading)
    }.background(OrvenTheme.canvas)
      .environment(
        \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
      )
      .onAppear { coordinator.refreshSummaries() }
  }
}
