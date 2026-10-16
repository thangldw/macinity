import AppKit
import MacinityCore
import MacinityMonitoring
import SwiftUI

struct AppActivityTimelineView: View {
  let applicationURL: URL
  @ObservedObject var model: MonitoringViewModel
  @State private var sleepReading: MetricSample<SleepInspection>?
  @State private var inspecting = false
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  private var mappedProcesses: [ProcessSample] {
    (model.snapshot?.processes.value ?? []).filter { process in
      guard let identity = process.identity,
        let app = NSRunningApplication(processIdentifier: process.pid),
        let url = app.bundleURL, url.standardizedFileURL == applicationURL.standardizedFileURL,
        let launch = app.launchDate,
        abs(launch.timeIntervalSince(identity.startDate)) < 1
      else { return false }
      return true
    }
  }
  var body: some View {
    let processes = mappedProcesses
    VStack(alignment: .leading, spacing: 12) {
      Text(L10n.text("App Activity Timeline")).font(.title2.bold())
      Text(
        L10n.text(
          "Recent in-memory CPU trends for running processes mapped by bundle path and launch identity. Helper processes, older activity and unverified ownership may be missing. Related-data sizes remain scan-time observations."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
      Text(L10n.text(model.samplingMode == .active ? "Active monitoring" : "Sampling paused"))
        .font(.caption)
      if let snapshot = model.snapshot { Text(snapshot.time.wall, style: .time).font(.caption) }
      if processes.isEmpty {
        Text(L10n.text("No running process could be mapped within current coverage."))
      }
      ForEach(Array(processes.prefix(8))) { process in
        HStack {
          Text(process.name + " · PID \(process.pid)").font(.headline)
          Spacer()
          VStack(alignment: .trailing) {
            Text(process.memory.value.map(monitoringBytes) ?? L10n.text("Unavailable"))
            Text(
              availabilityLabel(
                model.samplingMode == .active
                  ? process.memory.freshness(
                    at: ProcessInfo.processInfo.systemUptime, maximumAge: 6)
                  : .stale)
            ).font(.caption)
          }
          Button(L10n.text("Inspect process")) {
            if let identity = process.identity {
              MacinityRuntime.shared.navigation.open(.inspectProcess(identity))
            }
          }
        }
        MonitoringChart(
          title: L10n.text("Process CPU • one core"), unit: "%",
          data: process.cpuHistory.map { ChartDatum(time: $0.time, value: $0.cpu) },
          embedded: true, height: 110)
      }
      Button(L10n.text("Inspect app sleep requests")) {
        inspecting = true
        Task {
          sleepReading = await model.engine.inspectSleepRequests()
          inspecting = false
        }
      }.disabled(inspecting)
      if let sleepReading {
        Text(sleepReading.time.wall, style: .time).font(.caption)
        Text(
          availabilityLabel(
            sleepReading.freshness(
              at: ProcessInfo.processInfo.systemUptime,
              maximumAge: 30))
        ).font(.caption)
        let identities = Set(processes.compactMap(\.identity))
        let requests =
          sleepReading.value?.requests.filter {
            $0.owner.map { identities.contains($0.identity) } ?? false
          } ?? []
        ForEach(requests) { request in
          Text(request.type + " · " + request.name).font(.caption).textSelection(.enabled)
        }
        if requests.isEmpty {
          Text(
            L10n.text(
              "No sleep requests attributed to mapped processes within this snapshot's coverage.")
          )
          .font(.caption).foregroundStyle(.secondary)
        }
        if (sleepReading.value?.omittedCount ?? 0) > 0 {
          Text(L10n.text("Some assertion entries were omitted; coverage is partial."))
            .font(.caption)
        }
      }
    }.padding(16).background(MacinityTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
  }
}
