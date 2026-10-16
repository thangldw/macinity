import MacinityCore
import MacinityMonitoring
import SwiftUI

struct SleepInspectorView: View {
  @Environment(\.locale) private var locale
  let engine: MonitoringCoordinator
  @State private var result: MetricSample<SleepInspection>?
  @State private var requestID = 0
  @State private var reading = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(L10n.text("Sleep Inspector")).font(.title2.bold())
        Spacer()
        Button(L10n.text("Refresh sleep requests")) { requestID += 1 }
          .disabled(reading)
      }
      Text(
        L10n.text(
          "A snapshot of active macOS power requests. Requests can be legitimate; they do not explain every sleep or wake event."
        )
      )
      .font(.callout).foregroundStyle(MacinityTheme.secondary)
      if reading {
        ProgressView(L10n.text("Reading sleep requests"))
      } else if let result {
        if let inspection = result.value {
          Text(
            L10n.text("Observed at") + " "
              + result.time.wall.formatted(.dateTime.hour().minute().second().locale(locale))
          )
          .font(.caption).foregroundStyle(MacinityTheme.secondary)
          if inspection.requests.isEmpty {
            if inspection.omittedCount == 0 {
              Text(L10n.text("No active requests in this snapshot"))
            } else {
              Text(L10n.text("No readable requests in this snapshot"))
            }
          }
          ForEach(inspection.requests) { request in
            VStack(alignment: .leading, spacing: 6) {
              HStack {
                Text(request.owner?.name ?? "PID \(request.pid)").font(.headline)
                Spacer()
                if let owner = request.owner {
                  Button(L10n.text("Inspect process")) {
                    MacinityRuntime.shared.navigation.open(.inspectProcess(owner.identity))
                  }
                  .accessibilityLabel(
                    L10n.text("Inspect process") + " " + owner.name + " PID \(owner.identity.pid)")
                }
              }
              Text(request.type).font(.system(.callout, design: .monospaced))
              if !request.name.isEmpty { Text(request.name).font(.callout).textSelection(.enabled) }
              if request.owner == nil {
                Text(L10n.text("Process identity unavailable; ownership is unverified"))
                  .font(.caption).foregroundStyle(MacinityTheme.secondary)
              }
            }
            Divider()
          }
          if inspection.omittedCount > 0 {
            Text(L10n.text("Some requests could not be displayed") + ": \(inspection.omittedCount)")
              .font(.caption).foregroundStyle(MacinityTheme.secondary)
          }
        } else {
          Label(availabilityLabel(result.availability), systemImage: "exclamationmark.circle")
        }
      } else {
        Text(L10n.text("Refresh to inspect current requests. No background polling."))
          .foregroundStyle(MacinityTheme.secondary)
      }
    }
    .macinitySurface()
    .task(id: requestID) {
      guard requestID > 0 else { return }
      reading = true
      let sample = await engine.inspectSleepRequests()
      if !Task.isCancelled { result = sample }
      reading = false
    }
  }
}
