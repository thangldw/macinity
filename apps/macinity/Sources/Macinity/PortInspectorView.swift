import AppKit
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct PortInspectorView: View {
  @State private var port = "3000"
  @State private var report: NetworkInspection?
  @State private var command = ""
  @State private var busy = false
  @State private var status = ""
  private var number: Int? { Int(port).flatMap { (1...65535).contains($0) ? $0 : nil } }
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(L10n.text("Port & Service Inspector")).font(.title2.bold())
      HStack {
        TextField(L10n.text("Port"), text: $port).frame(maxWidth: 140).textFieldStyle(
          .roundedBorder)
        ForEach([3000, 5432, 8080], id: \.self) { value in
          Button(String(value)) { port = String(value) }
        }
        Button(L10n.text("Inspect")) { Task { await refresh() } }.disabled(number == nil || busy)
        if busy { ProgressView().controlSize(.small) }
      }
      Text(
        L10n.text(
          "Local socket ownership only. Wildcard binding is not proof of Internet exposure; firewalls and routers still apply. Restricted and short-lived processes may be missing."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      Text(status).font(.caption)
      if let report {
        Text(report.observedAt, style: .time).font(.caption)
        let rows = report.sockets.filter { socket in
          guard let number else { return false }
          let local = String(socket.endpoint.components(separatedBy: "->")[0])
          return local.hasSuffix(":\(number)")
        }
        if rows.isEmpty { Text(L10n.text("No matching observable sockets")) }
        ForEach(rows) { socket in
          VStack(alignment: .leading, spacing: 8) {
            Text(socket.processName + " · PID \(socket.pid)").font(.headline)
            Text(socket.transport + " · " + socket.state + " · " + socket.endpoint).textSelection(
              .enabled)
            Text(L10n.text(binding(socket.endpoint))).font(.caption).foregroundStyle(.secondary)
            if let identity = socket.identity {
              HStack {
                Button(L10n.text("Inspect process")) {
                  MacinityRuntime.shared.navigation.open(.inspectProcess(identity))
                }
                Button(L10n.text("Show launch command")) { Task { await readCommand(identity) } }
                  .disabled(busy)
              }
            }
          }.padding(.vertical, 8)
          Divider()
        }
      }
      if !command.isEmpty {
        Text(
          L10n.text(
            "Command arguments may contain secrets. Displayed locally only; clear after review.")
        )
        .font(.caption).foregroundStyle(.secondary)
        Text(command).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
        Button(L10n.text("Clear")) { command = "" }
      }
    }.macinitySurface().onDisappear { command = "" }
  }
  private func binding(_ endpoint: String) -> String {
    let local = endpoint.components(separatedBy: "->")[0]
    if local.hasPrefix("127.") || local.hasPrefix("[::1]:") || local.hasPrefix("::1:") {
      return "Loopback only"
    }
    if local.hasPrefix("*:") || local.hasPrefix("0.0.0.0:") || local.hasPrefix("[::]:") {
      return "All local interfaces"
    }
    return "Specific interface address"
  }
  private func refresh() async {
    busy = true
    command = ""
    do {
      report = try await Task.detached { try NetworkInspection.read() }.value
      status = ""
    } catch { status = L10n.text("Inspection failed or access is restricted") }
    busy = false
  }
  private func readCommand(_ identity: ProcessIdentity) async {
    busy = true
    do {
      command = try await Task.detached {
        let access = SystemProcessAccess()
        guard try access.metadata(pid: identity.pid).identity == identity else {
          throw ProcessReadError.identityChanged
        }
        let result = try UtilityCommand.processCommand(identity.pid).read()
        guard result.status == 0, try access.metadata(pid: identity.pid).identity == identity else {
          throw ProcessReadError.identityChanged
        }
        return String(result.text.prefix(8192))
      }.value
    } catch {
      command = ""
      status = L10n.text("Process is unavailable; refresh before retrying")
    }
    busy = false
  }
}
