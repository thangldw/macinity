import MacinityCore
import MacinityMonitoring
import SwiftUI

struct NetworkInspectorView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject private var changes = MacinityRuntime.shared.networkChanges
  @State private var reading: NetworkInspection?
  @State private var isReading = false
  @State private var hasReadFailure = false
  @State private var task: Task<Void, Never>?
  @State private var query = ""
  @State private var selectedSocketID: String?
  @FocusState private var searchFocused: Bool
  private var sockets: [NetworkSocket] {
    (reading?.sockets ?? []).filter {
      query.isEmpty || $0.processName.localizedCaseInsensitiveContains(query)
        || $0.endpoint.localizedCaseInsensitiveContains(query) || String($0.pid).contains(query)
    }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(L10n.text("Network Inspector")).font(.title2.bold())
        Spacer()
        if isReading { ProgressView().controlSize(.small) }
        Button(L10n.text("Refresh connections")) { refresh() }.disabled(isReading)
      }
      Text(
        L10n.text(
          "Explicit TCP/UDP socket snapshot from lsof. Restricted processes and short-lived connections may be missing. No traffic history, domain attribution, byte totals or firewall control."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      HStack {
        TextField(L10n.text("Search process, PID or endpoint"), text: $query).textFieldStyle(
          .roundedBorder
        ).focused($searchFocused)
        Button(L10n.text("Clear search")) {
          query = ""
          searchFocused = true
        }.disabled(query.isEmpty)
      }
      if hasReadFailure {
        Text(
          L10n.text("Connection inspection failed. Refresh to try again; coverage remains unknown.")
        )
      }
      if let reading {
        Text(reading.observedAt, style: .time).font(.caption)
        Text(
          String(
            format: L10n.text("%d observed sockets; %d omitted by the display cap."),
            reading.sockets.count, reading.omitted)
        ).font(.caption)
        Table(sockets, selection: $selectedSocketID) {
          TableColumn(L10n.text("Process")) { socket in
            VStack(alignment: .leading) {
              Text(socket.processName).help(socket.processName)
              Text("PID " + String(socket.pid)).font(.caption)
            }.accessibilityElement(children: .ignore)
              .accessibilityLabel(
                String(
                  format: L10n.text("%@, PID %d, %@, %@, %@"),
                  socket.processName, socket.pid, socket.transport, socket.endpoint,
                  L10n.text(socket.state)))
          }
          TableColumn(L10n.text("Protocol"), value: \.transport).width(60)
          TableColumn(L10n.text("Endpoint")) {
            Text($0.endpoint).textSelection(.enabled).help($0.endpoint)
          }
          TableColumn(L10n.text("State")) { Text(L10n.text($0.state)) }.width(105)
        }.frame(height: 320)
        Button(L10n.text("Inspect selected process")) {
          if let identity = sockets.first(where: { $0.id == selectedSocketID })?.identity {
            MacinityRuntime.shared.navigation.open(.inspectProcess(identity))
          }
        }.disabled(
          isReading || sockets.first(where: { $0.id == selectedSocketID })?.identity == nil
        )
        .help(L10n.text("Only a revalidated PID/start identity can be inspected."))
        if sockets.isEmpty {
          Text(
            L10n.text(
              "No matching sockets within observable coverage. This does not prove the Mac has no connections."
            )
          )
          .foregroundStyle(.secondary)
        }
      } else if !isReading {
        Text(L10n.text("Refresh to inspect current connections."))
      }
      Divider()
      NetworkChangesView(model: changes)
    }.macinitySurface().onDisappear {
      task?.cancel()
      changes.invalidate()
    }
  }
  private func refresh() {
    isReading = true
    selectedSocketID = nil
    hasReadFailure = false
    task = Task {
      let worker = Task.detached(priority: .utility) { try NetworkInspection.read() }
      defer { isReading = false }
      do {
        let value = try await withTaskCancellationHandler {
          try await worker.value
        } onCancel: {
          worker.cancel()
        }
        try Task.checkCancellation()
        reading = value
        changes.consume(value)
      } catch is CancellationError {
        changes.invalidate()
      } catch {
        hasReadFailure = true
        changes.invalidate()
      }
    }
  }
}
