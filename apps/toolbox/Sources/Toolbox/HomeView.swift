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
        OrvenPageHeader(title: L10n.text("Action Center"))
        MacIdentityStrip {
          coordinator.open(.section(.hardware))
        }
        ActionCenterView(coordinator: coordinator)
        MonitoringOverviewView(model: ToolboxRuntime.shared.monitoring)
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 18) {
            Button(L10n.text("Change Timeline")) { coordinator.open(.section(.changes)) }
            Button(L10n.text("Recovery")) { coordinator.open(.section(.recovery)) }
          }
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

/// Static system facts stay outside the per-sample observation tree.
private struct MacIdentityStrip: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let inspect: () -> Void
  private let system = ProcessInfo.processInfo

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 24) {
        identity
        Spacer(minLength: 8)
        Button(L10n.text("Inspect this Mac"), action: inspect).buttonStyle(.borderedProminent)
      }
      VStack(alignment: .leading, spacing: 16) {
        identity
        Button(L10n.text("Inspect this Mac"), action: inspect).buttonStyle(.borderedProminent)
      }
    }.padding(.vertical, 12)
  }

  private var identity: some View {
    HStack(spacing: 20) {
      Image(systemName: "desktopcomputer").font(.system(size: 44, weight: .light))
        .foregroundStyle(OrvenTheme.accent).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 8) {
        let version = system.operatingSystemVersion
        Text("macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)")
          .font(.title2.weight(.semibold)).foregroundStyle(OrvenTheme.ink)
        HStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text("Installed memory")).font(.caption)
            Text(monitoringBytes(system.physicalMemory)).font(.body.weight(.medium))
          }
          VStack(alignment: .leading, spacing: 4) {
            Text(L10n.text("Logical processors")).font(.caption)
            Text(system.processorCount, format: .number).font(.body.weight(.medium))
          }
        }.foregroundStyle(OrvenTheme.secondary)
      }
    }
  }
}
