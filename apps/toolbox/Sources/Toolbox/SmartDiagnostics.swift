import Foundation
import ToolboxMonitoring

enum DiagnosticTopic: String, CaseIterable, Identifiable {
  case slow, hot, battery, network, storage
  var id: String { rawValue }
  var title: String {
    switch self {
    case .slow: "Mac feels slow"
    case .hot: "Mac feels hot"
    case .battery: "Battery drains quickly"
    case .network: "Network feels slow"
    case .storage: "Running out of storage"
    }
  }
  var section: ToolboxSection {
    switch self {
    case .slow: .processes
    case .hot: .sensors
    case .battery: .batteryThermal
    case .network: .networkTools
    case .storage: .storage
    }
  }
  var keys: [String] {
    switch self {
    case .slow: ["cpu", "pressure"]
    case .hot: ["thermal", "cpu"]
    case .battery: ["battery", "discharging", "cpu", "thermal"]
    case .network: ["rssi", "gateway", "dns"]
    case .storage: ["free"]
    }
  }
}

struct DiagnosticMetric: Identifiable, Sendable {
  let id: String
  let value: Double?
  let observedAt: Date
  let monotonic: Double
  let source: String
  let available: Bool
  var label: String {
    switch id {
    case "cpu": "CPU (%)"
    case "pressure": "Memory pressure (0 normal, 1 warning, 2 critical)"
    case "thermal": "Thermal state (0 nominal, 1 fair, 2 serious, 3 critical)"
    case "battery": "Battery (%)"
    case "discharging": "On battery (1 yes, 0 no)"
    case "free": "Available storage (%)"
    case "rssi": "Wi-Fi signal (dBm)"
    case "gateway": "Default gateway configured (1 yes, 0 no)"
    default: "Global DNS servers configured"
    }
  }
  func freshValue(at now: Double) -> Double? {
    guard available, now.isFinite, monotonic.isFinite, now >= monotonic,
      now - monotonic <= 15, let value, value.isFinite
    else { return nil }
    return value
  }
}
struct DiagnosticFinding: Identifiable {
  enum Level { case attention, observation, unknown }
  let id: String
  let title: String
  let explanation: String
  let level: Level
}
struct DiagnosticProcess: Identifiable {
  var id: ProcessIdentity { identity }
  let identity: ProcessIdentity
  let name: String
  let cpu: Double
}
struct DiagnosticReport: Identifiable {
  let id = UUID()
  let topic: DiagnosticTopic
  let createdAt: Date
  let monotonic: Double
  let metrics: [DiagnosticMetric]
  let findings: [DiagnosticFinding]
  let processes: [DiagnosticProcess]
  var attentionCount: Int { findings.filter { $0.level == .attention }.count }
}

enum SmartDiagnostics {
  static func metrics(snapshot: MonitoringSnapshot?, active: Bool) -> [DiagnosticMetric] {
    guard let snapshot else { return [] }
    func metric<T>(_ id: String, _ sample: MetricSample<T>, _ value: Double?) -> DiagnosticMetric {
      .init(
        id: id, value: value, observedAt: sample.time.wall, monotonic: sample.time.monotonic,
        source: sample.source, available: active && sample.availability == .available)
    }
    let h = snapshot.hardware.reading
    let pressure = h.pressure.value.map { $0 == .normal ? 0.0 : $0 == .warning ? 1.0 : 2.0 }
    let thermal = h.thermal.value.flatMap {
      [ThermalLevel.nominal: 0.0, .fair: 1, .serious: 2, .critical: 3][$0]
    }
    let free = h.capacity.value.flatMap {
      $0.totalBytes > 0 && $0.availableBytes <= $0.totalBytes
        ? Double($0.availableBytes) * 100 / Double($0.totalBytes) : nil
    }
    return [
      metric("cpu", snapshot.cpu, snapshot.cpu.value), metric("pressure", h.pressure, pressure),
      metric("thermal", h.thermal, thermal), metric("battery", h.battery, h.battery.value?.percent),
      metric("discharging", h.battery, h.battery.value.map { $0.onBattery ? 1 : 0 }),
      metric("free", h.capacity, free),
    ]
  }
  static func networkMetrics(_ overview: NetworkOverview, now: Double) -> [DiagnosticMetric] {
    // Do not retain SSIDs, addresses or DNS server identities in the diagnostic report.
    func metric(_ id: String, _ value: Double?) -> DiagnosticMetric {
      .init(
        id: id, value: value, observedAt: overview.observedAt, monotonic: now,
        source: "SystemConfiguration / CoreWLAN", available: value != nil)
    }
    let signal = overview.wifi.first { $0.interface == overview.primary }?.rssi
    return [
      metric("rssi", signal.map(Double.init)),
      metric("gateway", overview.gateway4 != nil || overview.gateway6 != nil ? 1 : 0),
      metric("dns", Double(overview.dns.count)),
    ]
  }
  static func report(
    topic: DiagnosticTopic, metrics: [DiagnosticMetric], now: Double,
    date: Date = Date(), processes: [DiagnosticProcess] = []
  ) -> DiagnosticReport {
    let selected = topic.keys.compactMap { key in metrics.first { $0.id == key } }
    var findings: [DiagnosticFinding] = []
    func add(_ id: String, _ title: String, _ text: String, _ level: DiagnosticFinding.Level) {
      findings.append(.init(id: id, title: title, explanation: text, level: level))
    }
    for key in topic.keys {
      guard let metric = selected.first(where: { $0.id == key }),
        let value = metric.freshValue(at: now)
      else {
        add(
          key, "Fresh evidence unavailable",
          "Paused, missing or older than 15 seconds. This check cannot establish normal operation.",
          .unknown)
        continue
      }
      switch key {
      case "cpu":
        add(
          key, value >= 80 ? "CPU is elevated in this observation" : "CPU observation available",
          "Review the largest CPU consumers. The 80% threshold is a triage hint, not proof of a persistent fault or its cause.",
          value >= 80 ? .attention : .observation)
      case "pressure":
        add(
          key,
          value >= 1
            ? "Memory pressure needs attention" : "No pressure warning in this observation",
          "Use memory pressure rather than occupied RAM alone. Review applications before closing anything.",
          value >= 1 ? .attention : .observation)
      case "thermal":
        add(
          key, value >= 2 ? "macOS reports thermal pressure" : "Thermal observation available",
          "Serious or critical is the macOS thermal classification. Inspect sensor coverage and recent load; no fan or CPU policy is changed.",
          value >= 2 ? .attention : .observation)
      case "battery":
        add(
          key, value <= 20 ? "Battery level is low" : "Battery observation available",
          "20% is a low-charge hint. One reading cannot establish drain rate or battery wear; review Battery History.",
          value <= 20 ? .attention : .observation)
      case "discharging":
        add(
          key, value == 1 ? "Running on battery" : "External power observed",
          "Review Keep Awake and power-consuming applications. A process CPU reading is not a per-app energy measurement.",
          .observation)
      case "free":
        add(
          key, value <= 10 ? "Available storage is low" : "Storage observation available",
          "10% available is a triage threshold for the sampled volume. Review storage accounting and cleanup previews; no files are deleted here.",
          value <= 10 ? .attention : .observation)
      case "rssi":
        add(
          key, value <= -75 ? "Wi-Fi signal is weak" : "Wi-Fi signal observed",
          "At or below -75 dBm suggests weak reception. Signal alone does not measure Internet speed or prove channel interference.",
          value <= -75 ? .attention : .observation)
      case "gateway":
        add(
          key, value == 0 ? "No default gateway observed" : "Default gateway configured",
          "Configuration does not prove reachability. Use explicit gateway and latency checks in Wi-Fi & LAN.",
          value == 0 ? .attention : .observation)
      default:
        add(
          key, value == 0 ? "No global DNS servers observed" : "Global DNS configuration observed",
          "Scoped VPN and per-domain resolvers may differ. Run an explicit DNS check; this cannot diagnose an incorrect Wi-Fi password.",
          .observation)
      }
    }
    return .init(
      topic: topic, createdAt: date, monotonic: now, metrics: selected, findings: findings,
      processes: topic == .slow || topic == .hot || topic == .battery
        ? Array(processes.prefix(3)) : [])
  }
  static func comparison(_ current: DiagnosticReport, _ previous: DiagnosticReport) -> [(
    String, Double
  )] {
    guard current.topic == previous.topic, current.monotonic > previous.monotonic else { return [] }
    return current.metrics.compactMap { metric in
      guard ["cpu", "battery", "free", "rssi"].contains(metric.id),
        let before = previous.metrics.first(where: { $0.id == metric.id }),
        metric.monotonic > before.monotonic,
        let a = before.freshValue(at: previous.monotonic),
        let b = metric.freshValue(at: current.monotonic)
      else { return nil }
      return (metric.label, b - a)
    }
  }
}

@MainActor
final class DiagnosticsModel: ObservableObject {
  @Published private(set) var report: DiagnosticReport?
  @Published private(set) var previous: DiagnosticReport?
  @Published private(set) var busy = false
  private var work: Task<Void, Never>?
  func analyze(_ topic: DiagnosticTopic, monitoring: MonitoringViewModel) {
    guard !busy else { return }
    busy = true
    work = Task {
      var metrics = SmartDiagnostics.metrics(
        snapshot: monitoring.snapshot, active: monitoring.samplingMode != .paused)
      if topic == .network {
        let worker = Task.detached(priority: .utility) { try NetworkOverviewProvider.read() }
        let observation = try? await withTaskCancellationHandler(
          operation: { try await worker.value }, onCancel: { worker.cancel() })
        if let observation {
          metrics += SmartDiagnostics.networkMetrics(
            observation, now: ProcessInfo.processInfo.systemUptime)
        }
      }
      defer { busy = false }
      guard !Task.isCancelled else { return }
      let now = ProcessInfo.processInfo.systemUptime
      let snapshot = monitoring.snapshot
      let processes: [DiagnosticProcess] =
        monitoring.samplingMode == .paused
        ? []
        : (snapshot?.processes.value ?? []).compactMap { process in
          guard snapshot?.processes.freshness(at: now, maximumAge: 15) == .available,
            let identity = process.identity,
            process.cpu.freshness(at: now, maximumAge: 15) == .available,
            let cpu = process.cpu.value, cpu.isFinite
          else { return nil }
          return .init(identity: identity, name: process.name, cpu: cpu)
        }.sorted { $0.cpu > $1.cpu }
      previous = report?.topic == topic ? report : nil
      report = SmartDiagnostics.report(
        topic: topic, metrics: metrics, now: now, processes: processes)
    }
  }
  func cancel() { work?.cancel() }
  func clear() {
    guard !busy else { return }
    report = nil
    previous = nil
  }
}
