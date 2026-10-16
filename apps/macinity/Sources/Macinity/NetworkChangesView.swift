import MacinityCore
import MacinityMonitoring
import SwiftUI

@MainActor
final class NetworkChangesViewModel: ObservableObject {
  @Published var enabled = false {
    didSet { if !enabled { tracker.clear() } else { tracker.invalidate() } }
  }
  @Published private(set) var tracker = NetworkChangeTracker()
  func consume(_ inspection: NetworkInspection) { if enabled { tracker.update(inspection) } }
  func invalidate() { tracker.invalidate() }
  func clear() { tracker.clear() }
}

struct NetworkChangesView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var model: NetworkChangesViewModel
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.text("Network Connection Changes")).font(.title2.bold())
      Toggle(L10n.text("Track observed connection changes this session"), isOn: $model.enabled)
      Text(
        L10n.text(
          "Explicit Refresh compares observable sockets with verified PID/start identities. New or no-longer-observed does not mean opened or closed at this time. Short connections and restricted processes may be missed. Process names and numeric endpoints stay in memory, capped at 200 events; nothing is uploaded or saved to disk."
        )
      )
      .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      if model.enabled {
        Text(
          L10n.text(
            model.tracker.baselineEstablished
              ? "Connection baseline established" : "Refresh to establish a connection baseline"))
        Text(
          String(
            format: L10n.text("%d unverified sockets excluded; %d older events omitted."),
            model.tracker.unverifiedSockets, model.tracker.omittedEvents)
        ).font(.caption)
        Button(L10n.text("Clear connection history")) { model.clear() }
        if model.tracker.events.isEmpty { Text(L10n.text("No connection changes observed yet.")) }
        ForEach(model.tracker.events.prefix(50)) { event in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(L10n.text(event.kind)).font(.headline)
              Text(event.observedAt, style: .time)
            }
            Text(
              event.socket.processName + " · PID " + String(event.socket.pid) + " · "
                + event.socket.transport)
            Text(event.socket.endpoint).font(.caption.monospaced()).textSelection(.enabled)
              .fixedSize(horizontal: false, vertical: true)
            if let previous = event.previousState {
              Text(L10n.text(previous) + " → " + L10n.text(event.socket.state)).font(.caption)
            }
          }.padding(.vertical, 4)
        }
        if model.tracker.events.count > 50 {
          Text(L10n.text("Showing the latest 50 change events.")).font(.caption)
        }
      }
    }.environment(
      \.locale, AppLanguage(rawValue: languageCode)?.locale ?? AppLanguage.defaultLanguage.locale)
  }
}
