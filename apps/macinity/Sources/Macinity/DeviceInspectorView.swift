import MacinityCore
import MacinityMonitoring
import SwiftUI

struct DeviceInspectorView: View {
  @State private var report: DeviceInventory?
  @State private var request = 0
  @State private var busy = false
  @State private var status = ""
  @State private var category = "SPUSBDataType"
  @State private var tracking = false
  @State private var events: [String] = []
  private let categories = [
    ("SPUSBDataType", "USB"), ("SPThunderboltDataType", "Thunderbolt"),
    ("SPDisplaysDataType", "Displays"), ("SPAudioDataType", "Audio"),
    ("SPBluetoothDataType", "Bluetooth"),
  ]
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        MacinityPageHeader(title: L10n.text("Device Inspector"))
        HStack {
          Button(L10n.text("Refresh")) { request += 1 }.disabled(busy)
          if busy { ProgressView().controlSize(.small) }
        }
        Text(
          L10n.text(
            "System Information snapshot. Accessory battery is shown only when macOS supplies it. Bluetooth entries may include paired, disconnected devices. Change history compares explicit refreshes, not exact physical plug/unplug times."
          )
        )
        .font(.caption).foregroundStyle(.secondary)
        MacinityChoicePicker(
          L10n.text("Device category"), selection: $category,
          options: categories.map { ($0.0, L10n.text($0.1)) }, minimumWidth: 120)
        Toggle(L10n.text("Track device changes during this visit"), isOn: $tracking)
        Text(status).font(.caption)
        if let report {
          Text(report.observedAt, style: .time).font(.caption)
          if report.truncated {
            Text(L10n.text("Partial inventory: display limit reached")).foregroundStyle(.orange)
          }
          let rows = report.entries.filter { $0.category == category }
          if rows.isEmpty { Text(L10n.text("No readable devices in this category")) }
          ForEach(rows) { entry in
            VStack(alignment: .leading, spacing: 8) {
              Text(entry.name).font(.headline)
              ForEach(entry.fields, id: \.self) { field in
                let parts = field.components(separatedBy: ": ")
                Text(
                  L10n.text(parts.first ?? field) + ": "
                    + L10n.text(parts.dropFirst().joined(separator: ": "))
                ).font(.caption).textSelection(.enabled)
              }
            }.macinitySurface()
          }
        }
        if !events.isEmpty {
          Text(L10n.text("Latest observed device changes")).font(.headline)
          ForEach(Array(events.enumerated()), id: \.offset) { _, event in Text(event).font(.caption)
          }
          Button(L10n.text("Clear")) { events = [] }
        }
      }.padding(28)
    }.task(id: request) {
      busy = true
      let worker = Task.detached { try DeviceInventory.read() }
      do {
        let result = try await withTaskCancellationHandler(
          operation: { try await worker.value }, onCancel: { worker.cancel() })
        if !Task.isCancelled {
          if tracking, let previous = report, !result.truncated, !previous.truncated {
            let old = Set(previous.entries.map(\.id))
            let new = Set(result.entries.map(\.id))
            let date = result.observedAt.formatted(date: .omitted, time: .standard)
            for entry in result.entries where !old.contains(entry.id) {
              events.append(date + " · " + L10n.text("Newly observed") + " · " + entry.name)
            }
            for entry in previous.entries where !new.contains(entry.id) {
              events.append(date + " · " + L10n.text("No longer observed") + " · " + entry.name)
            }
            for entry in result.entries {
              if let old = previous.entries.first(where: { $0.id == entry.id }),
                old.fields != entry.fields
              {
                events.append(
                  date + " · " + L10n.text("Device details changed") + " · " + entry.name)
              }
            }
            events = Array(events.suffix(200))
          }
          report = result
          status = ""
        }
      } catch {
        if !Task.isCancelled {
          status = L10n.text("Device inspection failed or access is restricted")
        }
      }
      busy = false
    }.onChange(of: tracking) { _ in events = [] }
  }
}
