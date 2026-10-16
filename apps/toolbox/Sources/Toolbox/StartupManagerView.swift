import AppKit
import SwiftUI
import ToolboxCore
import ToolboxMonitoring

struct StartupManagerView: View {
  @State private var inventory: StartupInventory?
  @State private var busy = false
  @State private var message = ""
  @State private var query = ""
  @State private var pending: StartupEntry?
  @State private var backgroundReport = ""
  @State private var request = 0
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      OrvenPageHeader(title: L10n.text("Startup & Background"))
      Text(
        L10n.text(
          "Launch plists and current user registrations. System daemon status is unknown. Modern login items are managed in macOS Settings. Runtime changes affect this session; original plists stay intact."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      HStack {
        Button(L10n.text("Refresh")) { request += 1 }.disabled(busy)
        Button(L10n.text("Open Login Items Settings")) {
          if let url = URL(
            string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")
          {
            NSWorkspace.shared.open(url)
          }
        }
        Button(L10n.text("Read macOS login items report")) {
          busy = true
          Task {
            do {
              let result = try await Task.detached { try UtilityCommand.backgroundItems.read() }
                .value
              backgroundReport = "exit \(result.status)\n" + String(result.text.prefix(24000))
            } catch {
              backgroundReport = L10n.text("Login items report unavailable; use macOS Settings")
            }
            busy = false
          }
        }.disabled(busy)
        if busy { ProgressView().controlSize(.small) }
      }
      if !backgroundReport.isEmpty {
        Text(
          L10n.text(
            "macOS login item registrations; this report does not prove a service is running. Output is limited to 24,000 characters."
          )
        )
        .font(.caption)
        ScrollView {
          Text(backgroundReport).font(.system(.caption, design: .monospaced)).textSelection(
            .enabled
          ).frame(maxWidth: .infinity, alignment: .leading)
        }.frame(height: 170)
        Button(L10n.text("Clear report")) { backgroundReport = "" }
      }
      TextField(L10n.text("Filter by name or path"), text: $query).textFieldStyle(.roundedBorder)
      if !message.isEmpty { Text(message).font(.caption).textSelection(.enabled) }
      if let inventory {
        Text(inventory.observedAt, style: .time).font(.caption)
        List(
          inventory.entries.filter {
            query.isEmpty || ($0.label + $0.path + $0.program).localizedStandardContains(query)
          }
        ) { entry in
          entryRow(entry)
        }.scrollContentBackground(.hidden)
        if inventory.omitted > 0 {
          Text(L10n.text("Unreadable or omitted entries") + ": \(inventory.omitted)").font(.caption)
        }
      }
    }.padding(28)
      .task(id: request) { await refresh() }
      .sheet(item: $pending) { entry in
        VStack(alignment: .leading, spacing: 16) {
          Text(L10n.text("Review runtime change")).font(.title2.bold())
          Text(entry.label).textSelection(.enabled)
          Text(entry.path).font(.caption).textSelection(.enabled)
          Text(
            L10n.text(
              entry.registered == true
                ? "Stop and unregister this user agent now. Its process may terminate. Start it again from the same unchanged plist to restore registration."
                : "Register this user agent now. Its configured executable may run. Stop it again to undo registration."
            ))
          HStack {
            Button(L10n.text("Cancel")) { pending = nil }
            Button(L10n.text("Apply")) {
              pending = nil
              Task { await change(entry) }
            }.buttonStyle(.borderedProminent)
          }
        }.padding(24).frame(width: 480)
      }
  }
  private func entryStatus(_ entry: StartupEntry) -> String {
    let state: String
    if entry.registered == true {
      state = entry.pid == nil ? "Registered, not running" : "Running"
    } else {
      state = entry.registered == false ? "Not registered" : "Unknown"
    }
    var result = entry.owner + " · " + L10n.text(state)
    if let pid = entry.pid { result += " · PID \(pid)" }
    if let exit = entry.lastExit { result += " · exit \(exit)" }
    return result
  }

  private func entryRow(_ entry: StartupEntry) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(entry.label).font(.headline)
      Text(entry.path).font(.caption).textSelection(.enabled)
      Text(entry.program).font(.caption).textSelection(.enabled)
      Text(entryStatus(entry)).font(.caption).foregroundStyle(.secondary)
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 180), alignment: .leading)], alignment: .leading
      ) {
        Button(L10n.text("Show in Finder")) {
          NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.path)])
        }
        if !entry.program.isEmpty {
          Button(L10n.text("Locate executable")) {
            NSWorkspace.shared.activateFileViewerSelecting([
              URL(fileURLWithPath: entry.program)
            ])
          }
        }
        if let related = relatedApplication(entry.program) {
          Button(
            L10n.text("Related application") + ": "
              + related.deletingPathExtension().lastPathComponent
          ) {
            NSWorkspace.shared.activateFileViewerSelecting([related])
          }
        }
        if entry.canChange {
          Button(L10n.text(entry.registered == true ? "Preview stop" : "Preview start")) {
            pending = entry
          }.disabled(busy)
        }
      }
    }.padding(.vertical, 5)
  }

  private func refresh() async {
    busy = true
    let worker = Task.detached(priority: .utility) { try StartupInventory.read() }
    do {
      let result = try await withTaskCancellationHandler(
        operation: { try await worker.value }, onCancel: { worker.cancel() })
      if !Task.isCancelled { inventory = result }
    } catch { if !Task.isCancelled { message = L10n.text("Startup inspection failed") } }
    busy = false
  }
  private func change(_ entry: StartupEntry) async {
    busy = true
    do {
      let result = try await Task.detached {
        try StartupInventory.change(entry, load: entry.registered != true)
      }.value
      message = "exit \(result.status)\n" + String(result.text.prefix(4000))
    } catch { message = L10n.text("Change failed or state changed; refresh before retrying") }
    await refresh()
  }
  private func relatedApplication(_ program: String) -> URL? {
    guard program.hasPrefix("/") else { return nil }
    var url = URL(fileURLWithPath: program).resolvingSymlinksInPath()
    while url.path != "/" {
      if url.pathExtension == "app", Bundle(url: url)?.bundleIdentifier != nil { return url }
      url.deleteLastPathComponent()
    }
    return nil
  }

}
