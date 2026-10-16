import AppKit
import SwiftUI
import ToolboxCore
import ToolboxMonitoring

private struct PackageReview: Identifiable {
  let id = UUID()
  let command: PackageCommand
}

struct PackageManagerView: View {
  @Environment(\.dismiss) private var dismiss
  let executable: String
  let tool: String
  @State private var inventory: PackageInventory?
  @State private var output = ""
  @State private var busy = false
  @State private var query = ""
  @State private var pending: PackageReview?
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text(tool).font(.title2.bold())
        Spacer()
        Button(L10n.text("Close")) { dismiss() }.disabled(busy)
      }
      Text(executable).font(.caption).textSelection(.enabled)
      Text(
        L10n.text(
          "Tools run only after a button press, without shell startup files. Package mutations can download and execute package code, affect dependencies and are not automatically reversible. No sudo. Python writes require a virtual environment; npm writes skip lifecycle scripts."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      HStack {
        Button(L10n.text("Read version")) {
          execute(.init(executable: executable, tool: tool, action: .version))
        }.disabled(busy)
        if ["brew", "python3", "npm"].contains(tool) {
          Button(L10n.text("Read packages / environment")) {
            execute(.init(executable: executable, tool: tool, action: .inventory))
          }.disabled(busy)
        }
        if busy { ProgressView().controlSize(.small) }
      }
      if let inventory {
        Text(inventory.environment).font(.caption).textSelection(.enabled)
        TextField(L10n.text("Filter packages"), text: $query).textFieldStyle(.roundedBorder)
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(
              inventory.entries.filter { query.isEmpty || $0.name.localizedStandardContains(query) }
            ) { entry in
              HStack {
                VStack(alignment: .leading) {
                  Text(entry.name).font(.headline)
                  Text(entry.version + (entry.cask ? " · cask" : "")).font(.caption)
                }
                Spacer()
                if tool != "python3" || inventory.isVirtualEnvironment {
                  Button(L10n.text("Review update")) { review(entry, .upgrade) }
                  Button(L10n.text("Review uninstall")) { review(entry, .uninstall) }
                }
              }.disabled(busy)
            }
          }
        }.frame(minHeight: 120, maxHeight: 300)
      }
      if !output.isEmpty {
        ScrollView {
          Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled).frame(
            maxWidth: .infinity, alignment: .leading)
        }.frame(maxHeight: 160)
      }
    }
    .interactiveDismissDisabled(busy)
    .sheet(item: $pending) { review in
      VStack(alignment: .leading, spacing: 16) {
        Text(L10n.text("Review package operation")).font(.title2.bold())
        Text(review.command.preview).font(.system(.caption, design: .monospaced)).textSelection(
          .enabled)
        Text(
          L10n.text(
            "This changes installed software and may run package code. Dependencies can change. A timeout or error may leave partial changes; inspect the package manager before retrying."
          ))
        HStack {
          Button(L10n.text("Cancel")) {
            pending = nil
          }
          Button(L10n.text("Apply")) {
            pending = nil
            execute(review.command)
          }
        }
      }.padding(24).frame(width: 500)
    }
  }
  private func review(_ entry: PackageEntry, _ action: PackageAction) {
    pending = PackageReview(
      command: .init(
        executable: executable, tool: tool, action: action, package: entry.name, cask: entry.cask))
  }
  private func execute(_ command: PackageCommand) {
    guard !busy else { return }
    busy = true
    output = ""
    Task {
      do {
        let result = try await Task.detached(priority: .utility) { try command.run() }.value
        output = "exit \(result.status)\n" + String(result.text.prefix(20000))
        if command.action == .inventory, result.status == 0 {
          inventory = try PackageInventory.parse(result.text, tool: tool)
          output = L10n.text("Observation completed.") + " · \(inventory?.entries.count ?? 0)"
        }
        if command.isMutation { inventory = nil }
      } catch {
        output =
          L10n.text("Operation failed or timed out; inspect current state before retrying") + "\n"
          + error.localizedDescription
      }
      busy = false
    }
  }
}
