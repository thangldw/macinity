import IOKit.pwr_mgt
import MacinityCore
import MacinityMonitoring
import SwiftUI

@MainActor
final class KeepAwakeController: ObservableObject {
  static let shared = KeepAwakeController()
  @Published private(set) var remaining = 0
  @Published private(set) var process: ProcessIdentity?
  @Published private(set) var status = "No active Keep Awake session"
  private var assertion: IOPMAssertionID?
  private var task: Task<Void, Never>?

  func start(minutes: Int, pid: Int32?) {
    stop()
    let identity: ProcessIdentity?
    if let pid {
      guard let metadata = try? SystemProcessAccess().metadata(pid: pid) else {
        status = "Process is unavailable; no session started"
        return
      }
      identity = metadata.identity
    } else {
      identity = nil
    }
    let seconds = identity == nil ? [15, 30, 60].contains(minutes) ? minutes * 60 : 900 : 86400
    var id: IOPMAssertionID = 0
    let result = IOPMAssertionCreateWithDescription(
      kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
      "Macinity Keep Awake" as CFString, nil, nil, nil, Double(seconds),
      kIOPMAssertionTimeoutActionRelease as CFString, &id)
    guard result == kIOReturnSuccess else {
      status = "Keep Awake could not start"
      return
    }
    assertion = id
    process = identity
    remaining = seconds
    status = "Keep Awake is active"
    let end = Date().addingTimeInterval(Double(seconds))
    task = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled, let self else { return }
        self.remaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
        if let identity,
          (try? SystemProcessAccess().metadata(pid: identity.pid).identity) != identity
        {
          self.stop()
          return
        }
        if self.remaining == 0 {
          self.stop()
          return
        }
      }
    }
  }
  func stop() {
    task?.cancel()
    task = nil
    if let assertion { IOPMAssertionRelease(assertion) }
    assertion = nil
    process = nil
    remaining = 0
    status = "No active Keep Awake session"
  }
}

struct KeepAwakeView: View {
  @ObservedObject private var controller = KeepAwakeController.shared
  @ObservedObject var monitoring: MonitoringViewModel
  @State private var pid = ""
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(L10n.text("Keep Awake")).font(.title2.bold())
      Text(
        L10n.text(
          "Prevents idle system sleep only. Display sleep, screen locking and manual sleep remain unchanged. Process sessions stop on exit or after 24 hours; quitting Macinity releases the request."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      HStack {
        ForEach([15, 30, 60], id: \.self) { minutes in
          Button("\(minutes) min") { controller.start(minutes: minutes, pid: nil) }
        }
        if controller.remaining > 0 {
          Button(L10n.text("Stop")) { controller.stop() }.buttonStyle(.borderedProminent)
        }
      }.buttonStyle(.bordered)
      HStack {
        TextField("PID", text: $pid).frame(maxWidth: 120).textFieldStyle(.roundedBorder)
        Button(L10n.text("Until process exits")) {
          if let value = Int32(pid), value > 0 { controller.start(minutes: 0, pid: value) }
        }.disabled(Int32(pid).map { $0 <= 0 } ?? true)
      }
      Text(L10n.text(controller.status))
      if controller.remaining > 0 {
        Text(
          String(
            format: "%02d:%02d:%02d", controller.remaining / 3600, controller.remaining / 60 % 60,
            controller.remaining % 60)
        )
        .font(.title2.monospacedDigit())
        if let process = controller.process { Text("PID \(process.pid)").font(.caption) }
      }
      if let battery = monitoring.snapshot?.hardware.reading.battery.value {
        Text(
          L10n.text(battery.onBattery ? "On battery" : "AC Power") + " · \(Int(battery.percent))%"
        )
        .foregroundStyle(battery.onBattery ? Color.orange : .secondary)
      }
    }.macinitySurface()
  }
}
