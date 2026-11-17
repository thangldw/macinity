import MacinityCore
import SwiftUI

struct ClipboardSnippetsView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject private var model = MacinityRuntime.shared.clipboard
  @State private var query = ""
  @State private var newName = ""
  @State private var newText = ""

  var body: some View {
    let _ = languageCode
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 10) {
          Text(L10n.text("Clipboard & Snippets")).font(.title2.bold())
          Toggle(
            L10n.text("Record clipboard history"),
            isOn: Binding(get: { model.recording }, set: { model.setRecording($0) }))
          Text(
            L10n.text(
              "Off by default. Text only; history stays in memory, keeps the latest 50 items and is cleared when you turn recording off or quit Macinity. Items marked secret by password managers are skipped."
            )
          ).font(.caption).foregroundStyle(.secondary)
        }.macinitySurface()

        if model.recording {
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              Text(L10n.text("History")).font(.headline)
              Spacer()
              Button(L10n.text("Clear history")) { model.clearHistory() }
                .disabled(model.history.items.isEmpty)
            }
            TextField(L10n.text("Search history"), text: $query).textFieldStyle(.roundedBorder)
            let items = model.history.filtered(query)
            if items.isEmpty {
              Text(L10n.text("No clipboard items.")).foregroundStyle(.secondary)
            }
            ForEach(items.prefix(50)) { item in
              HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                  Text(item.text).lineLimit(3).font(.callout)
                  Text(item.date, style: .time).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(L10n.text("Copy")) { model.copy(item.text) }
                Button(L10n.text("Save as snippet")) {
                  newText = item.text
                  if newName.isEmpty { newName = String(item.text.prefix(30)) }
                }
                Button(L10n.text("Remove")) { model.removeItem(item.id) }
              }.controlSize(.small)
              Divider()
            }
          }.macinitySurface()
        }

        VStack(alignment: .leading, spacing: 10) {
          Text(L10n.text("Snippets")).font(.headline)
          HStack {
            TextField(L10n.text("Name"), text: $newName).frame(maxWidth: 200)
            TextField(L10n.text("Text"), text: $newText)
            Button(L10n.text("Add snippet")) {
              model.saveSnippet(name: newName, text: newText)
              if model.status.isEmpty {
                newName = ""
                newText = ""
              }
            }.disabled(newName.isEmpty || newText.isEmpty)
          }.textFieldStyle(.roundedBorder)
          if !model.status.isEmpty { Text(L10n.text(model.status)).font(.caption) }
          if model.library.snippets.isEmpty {
            Text(L10n.text("No snippets saved.")).foregroundStyle(.secondary)
          }
          ForEach(model.library.snippets) { snippet in
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 2) {
                Text(snippet.name).font(.callout.weight(.medium))
                Text(snippet.text).lineLimit(2).font(.caption).foregroundStyle(.secondary)
              }
              Spacer()
              Button(L10n.text("Copy")) { model.copy(snippet.text) }
              Button(L10n.text("Remove")) { model.removeSnippet(snippet.id) }
            }.controlSize(.small)
            Divider()
          }
          Text(L10n.text("Snippets are stored locally on this Mac and never uploaded."))
            .font(.caption).foregroundStyle(.secondary)
        }.macinitySurface()
      }.padding(20)
    }
  }
}
