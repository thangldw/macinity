import Foundation
import ToolboxCore
import ToolboxMonitoring
import UserNotifications

// A re-arm requires observed recovery; missing/paused evidence cannot re-arm an alert.
struct AlertGate {
  private var latched: Set<String> = []
  private var clearSince: [String: Double] = [:]
  private var delivered: [String: Double] = [:]
  private var lastTime: Double?
  var snoozedUntil = Date.distantPast

  mutating func evaluate(
    findings: Set<String>, recoveries: Set<String>, now: Double, wall: Date = Date()
  ) -> [String] {
    guard now.isFinite else { return [] }
    if let lastTime, now < lastTime {
      latched = []
      clearSince = [:]
      delivered = [:]
      snoozedUntil = .distantPast
    }
    if let lastTime, now - lastTime > 15 { clearSince = [:] }
    self.lastTime = now
    for key in latched {
      if recoveries.contains(key) {
        if clearSince[key] == nil { clearSince[key] = now }
        if now - (clearSince[key] ?? now) >= 30 {
          latched.remove(key)
          clearSince[key] = nil
        }
      } else {
        clearSince[key] = nil
      }
    }
    guard wall >= snoozedUntil else { return [] }
    return findings.sorted().filter { key in
      guard !latched.contains(key), now - (delivered[key] ?? -.infinity) >= 900 else {
        return false
      }
      latched.insert(key)
      delivered[key] = now
      return true
    }
  }
}

struct SmartAlertEvent: Identifiable {
  let id = UUID()
  let observedAt: Date
  let title: String
  let evidence: String
  let section: ToolboxSection
}

@MainActor
final class SmartAlertsViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
  @Published private(set) var events: [SmartAlertEvent] = []
  @Published private(set) var status: String?
  @Published private(set) var requestingPermission = false
  @Published var enabled: Bool {
    didSet {
      defaults.set(enabled, forKey: "toolbox.smartAlerts.enabled")
      if !enabled { gate = AlertGate() }
    }
  }
  private let defaults: UserDefaults
  private var gate = AlertGate()
  private var center: UNUserNotificationCenter? {
    guard Bundle.main.bundleIdentifier == AppMetadata.bundleIdentifier else { return nil }
    return UNUserNotificationCenter.current()
  }
  override convenience init() { self.init(defaults: .standard) }
  init(defaults: UserDefaults) {
    self.defaults = defaults
    enabled = defaults.bool(forKey: "toolbox.smartAlerts.enabled")
    super.init()
    center?.delegate = self
  }

  func requestPermission() async {
    guard !requestingPermission else { return }
    guard let center else {
      status = "Notifications require the Macinity app bundle."
      return
    }
    requestingPermission = true
    status =
      "Waiting for macOS notification permission. Respond to the system prompt if it appears."
    defer { requestingPermission = false }
    do {
      let allowed = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Bool, Error>) in
        center.requestAuthorization(options: [.alert, .sound]) { allowed, error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: allowed)
          }
        }
      }
      status =
        allowed
        ? "Notification permission granted."
        : "Notifications are not allowed. In-app alerts remain available."
    } catch {
      status = "Notification permission could not be requested. In-app alerts remain available."
    }
  }
  func snooze() {
    gate.snoozedUntil = Date().addingTimeInterval(3600)
    status = "Alerts snoozed for one hour."
  }
  func consume(_ snapshot: MonitoringSnapshot, active: Bool) {
    guard enabled, active else { return }
    let now = ProcessInfo.processInfo.systemUptime
    guard now >= snapshot.time.monotonic, now - snapshot.time.monotonic <= 6 else { return }
    let insights = DiagnosticInsights.evaluate(snapshot, now: now, active: active)
    var recovered: Set<String> = []
    if snapshot.cpu.freshness(at: now, maximumAge: 6) == .available,
      let cpu = snapshot.cpu.value, cpu < 70
    {
      recovered.insert("cpu")
    }
    let h = snapshot.hardware.reading
    if h.pressure.freshness(at: now, maximumAge: 6) == .available,
      h.pressure.value == .normal
    {
      recovered.insert("memory")
    }
    if h.thermal.freshness(at: now, maximumAge: 6) == .available,
      h.thermal.value == .nominal || h.thermal.value == .fair
    {
      recovered.insert("thermal")
    }
    if h.capacity.freshness(at: now, maximumAge: 30) == .available,
      let capacity = h.capacity.value, capacity.totalBytes > 0,
      Double(capacity.availableBytes) / Double(capacity.totalBytes) >= 0.15
    {
      recovered.insert("storage")
    }
    let keys = gate.evaluate(findings: Set(insights.map(\.id)), recoveries: recovered, now: now)
    for insight in insights where keys.contains(insight.id) {
      events.insert(
        SmartAlertEvent(
          observedAt: snapshot.time.wall, title: insight.title,
          evidence: insight.evidence, section: insight.section), at: 0)
      events = Array(events.prefix(100))
      let content = UNMutableNotificationContent()
      content.title = L10n.text(insight.title)
      content.body = L10n.text(insight.explanation)
      content.userInfo = ["section": insight.section.rawValue]
      let request = UNNotificationRequest(
        identifier: "orven.health." + insight.id, content: content, trigger: nil)
      Task {
        guard let center else { return }
        // Older SDK settings objects are not Sendable; only transfer the authorization value.
        let authorized = await withCheckedContinuation {
          (continuation: CheckedContinuation<Bool, Never>) in
          center.getNotificationSettings { settings in
            continuation.resume(returning: settings.authorizationStatus == .authorized)
          }
        }
        guard enabled, Date() >= gate.snoozedUntil,
          ProcessInfo.processInfo.systemUptime - snapshot.time.monotonic <= 6,
          authorized
        else {
          return
        }
        do {
          try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
              if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
          }
        } catch {
          status = "Notification delivery failed. Review the in-app alert evidence."
        }
      }
    }
  }
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let raw = response.notification.request.content.userInfo["section"] as? String
    Task { @MainActor in
      if let raw, let section = ToolboxSection(rawValue: raw) {
        ToolboxRuntime.shared.navigation.open(.section(section))
      }
    }
    completionHandler()
  }
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
