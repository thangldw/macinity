import AppKit
import MacinityCore
import SwiftUI

/// Explicit inspection of the selected scan result; no additional folder scan or mutation.
struct AppDossierView: View {
  let app: InstalledApplication
  let observedAt: Date?
  var activity: AnyView? = nil
  var embedded = false
  @Environment(\.dismiss) private var dismiss
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  private var locale: Locale {
    AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(L10n.text("App Dossier")).font(.title2.bold())
        Spacer()
        if !embedded {
          Button(L10n.text("Close")) { dismiss() }.keyboardShortcut(.cancelAction)
        }
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Text(app.name).font(.title.bold())
          field("Bundle ID", app.bundleIdentifier ?? L10n.text("Unknown"))
          field("Application path", app.url.path)
          if let info = Bundle(url: app.url)?.infoDictionary {
            field("Version", info["CFBundleShortVersionString"] as? String ?? L10n.text("Unknown"))
            field(
              "Minimum macOS", info["LSMinimumSystemVersion"] as? String ?? L10n.text("Unknown"))
          }
          if let activity { activity }
          Divider()
          field("Application bundle size", ByteCount.string(app.bytes))
          field("Related data observed", ByteCount.string(app.totalBytes - app.bytes))
          if let observedAt {
            field(
              "Last application scan",
              observedAt.formatted(
                .dateTime.year().month().day().hour().minute().locale(locale)))
          }
          Text(
            L10n.text(
              "Sizes are from the last scan. Related data is attributed by scan evidence, not proof of exclusive ownership. Unreadable locations may be missing."
            )
          )
          .font(.callout).foregroundStyle(.secondary)
          if !app.backgroundEvidenceAvailable {
            Text(
              L10n.text(
                "Background-item evidence unavailable. The macOS helper did not complete; scan coverage is partial."
              )
            )
            .font(.callout).foregroundStyle(.secondary)
          }
          ForEach(app.leftovers) { item in
            VStack(alignment: .leading, spacing: 5) {
              HStack {
                Text(L10n.text(item.kind.rawValue)).fontWeight(.semibold)
                Spacer()
                Text(ByteCount.string(item.entry.bytes)).monospacedDigit()
              }
              Text(item.entry.url.path).font(.caption).textSelection(.enabled)
              Text(L10n.text(item.evidence)).font(.caption).foregroundStyle(.secondary)
              Label(L10n.text(item.confidence.title), systemImage: item.confidence.symbol)
                .font(.caption)
            }.padding(12).background(MacinityTheme.canvas, in: RoundedRectangle(cornerRadius: 8))
          }
          if app.leftovers.isEmpty {
            Text(L10n.text("No related data found within scan coverage."))
              .foregroundStyle(.secondary)
          }
        }.frame(maxWidth: .infinity, alignment: .leading)
      }
      Button(L10n.text("Show in Finder")) {
        NSWorkspace.shared.activateFileViewerSelecting([app.url])
      }
    }.padding(24).frame(width: embedded ? nil : 600, height: embedded ? nil : 560).background(
      MacinityTheme.surface
    )
    .environment(\.locale, locale)
  }

  private func field(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(L10n.text(title)).font(.caption).foregroundStyle(.secondary)
      Text(value).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
    }
  }
}
