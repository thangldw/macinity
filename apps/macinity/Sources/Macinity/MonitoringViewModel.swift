import AppKit
import Foundation
import MacinityCore
import MacinityMonitoring

@MainActor
final class MonitoringViewModel: ObservableObject {
  @Published private(set) var samplingMode = MonitoringMode.paused
  @Published private(set) var snapshot: MonitoringSnapshot?
  @Published private(set) var processDetails: ProcessObservation?
  @Published private(set) var canOpenApplication = false
  private var detailIdentity: ProcessIdentity?
  let health = HealthHistoryViewModel()
  let alerts = SmartAlertsViewModel()
  let engine: MonitoringCoordinator
  private var observation: Task<Void, Never>?
  private var lastPublishedTime: Double?
  @Published var menuBarEnabled: Bool {
    didSet {
      defaults.set(menuBarEnabled, forKey: "toolbox.monitoring.menuBar.enabled")
      updateDemand()
    }
  }
  @Published var menuBarIndicator: MenuBarIndicator {
    didSet {
      defaults.set(menuBarIndicator.rawValue, forKey: "toolbox.monitoring.menuBar.indicator")
    }
  }
  private let defaults: UserDefaults
  private var demandTask: Task<Void, Never>?
  private var mainWindowVisible = false
  private var active = false
  private var sleeping = false

  init(engine: MonitoringCoordinator = MonitoringCoordinator(), defaults: UserDefaults = .standard)
  {
    self.engine = engine
    self.defaults = defaults
    menuBarEnabled = defaults.bool(forKey: "toolbox.monitoring.menuBar.enabled")
    menuBarIndicator =
      MenuBarIndicator(
        rawValue: defaults.string(forKey: "toolbox.monitoring.menuBar.indicator") ?? "") ?? .cpu
  }

  private var requestedMode: MonitoringMode {
    SamplingPolicy.mode(
      appActive: active, mainWindowVisible: mainWindowVisible, sleeping: sleeping,
      menuBarEnabled: menuBarEnabled)
  }

  func setMainWindowVisible(_ visible: Bool) {
    mainWindowVisible = visible
    updateDemand()
  }

  func start() {
    guard observation == nil else { return }
    observation = Task {
      await health.load()
      let stream = await engine.snapshots()
      await engine.setMode(requestedMode)
      for await snapshot in stream {
        guard !Task.isCancelled else { return }
        await health.consume(snapshot, active: samplingMode != .paused)
        alerts.consume(snapshot, active: samplingMode == .active)
        // Keep one-second samples/history, while limiting scene updates to four seconds.
        if let lastPublishedTime, snapshot.time.monotonic - lastPublishedTime < 4 { continue }
        lastPublishedTime = snapshot.time.monotonic
        self.snapshot = snapshot
      }
    }
  }

  func setActive(_ active: Bool) {
    self.active = active
    updateDemand()
  }

  func setSleeping(_ sleeping: Bool) {
    self.sleeping = sleeping
    updateDemand()
  }

  private func updateDemand() {
    let mode = requestedMode
    if samplingMode != mode {
      lastPublishedTime = nil
      samplingMode = mode
      if mode == .paused { health.markGap() }
    }
    demandTask?.cancel()
    demandTask = Task {
      guard !Task.isCancelled else { return }
      await engine.setMode(mode)
    }
  }

  func loadDetails(for identity: ProcessIdentity?) async {
    detailIdentity = identity
    processDetails = nil
    canOpenApplication = false
    guard let identity else { return }
    let detail = await engine.inspectProcess(identity)
    guard !Task.isCancelled, detailIdentity == identity else { return }
    processDetails = detail
    guard detail.availability == .available,
      let app = NSRunningApplication(processIdentifier: identity.pid),
      app.bundleIdentifier != nil, app.bundleURL != nil,
      let launch = app.launchDate, abs(launch.timeIntervalSince(identity.startDate)) < 1
    else { return }
    let revalidated = await engine.inspectProcess(identity)
    guard !Task.isCancelled, detailIdentity == identity, revalidated.availability == .available
    else { return }
    canOpenApplication = true
  }

  func details(for identity: ProcessIdentity) -> ProcessObservation? {
    detailIdentity == identity ? processDetails : nil
  }

  func applicationMapped(to identity: ProcessIdentity) -> Bool {
    canOpenApplication && detailIdentity == identity
  }

  func openMappedApplication(for identity: ProcessIdentity) {
    guard applicationMapped(to: identity) else { return }
    Task {
      await loadDetails(for: identity)
      guard canOpenApplication, detailIdentity == identity else { return }
      MacinityRuntime.shared.navigation.open(.section(.applications))
    }
  }

  var menuBarTitle: String {
    guard let snapshot else {
      return L10n.text(samplingMode == .paused ? "Sampling paused" : "Warming up")
    }
    if samplingMode == .paused { return L10n.text("Stale") }
    let now = ProcessInfo.processInfo.systemUptime
    switch menuBarIndicator {
    case .cpu:
      guard snapshot.cpu.freshness(at: now, maximumAge: 15) == .available,
        let value = snapshot.cpu.value
      else {
        return L10n.text("CPU") + " "
          + availabilityLabel(snapshot.cpu.freshness(at: now, maximumAge: 15))
      }
      return L10n.text("CPU") + " " + monitoringNumber(value, digits: 0) + "%"
    case .memory:
      let metric = MetricSample(
        value: snapshot.memory.value?.occupiedPercent, availability: snapshot.memory.availability,
        unit: .percent, time: snapshot.memory.time, source: snapshot.memory.source)
      guard metric.freshness(at: now, maximumAge: 15) == .available,
        let value = metric.value
      else {
        return L10n.text("Memory") + " "
          + availabilityLabel(metric.freshness(at: now, maximumAge: 15))
      }
      return L10n.text("Memory") + " "
        + monitoringNumber(value, digits: 0) + "%"
    case .network:
      let metric = snapshot.hardware.aggregate(network: true, output: false)
      guard metric.freshness(at: now, maximumAge: 15) == .available, let value = metric.value else {
        return L10n.text("Network") + " "
          + availabilityLabel(metric.freshness(at: now, maximumAge: 15))
      }
      return "↓ " + rateText(value)
    }
  }

  func stop() async {
    if samplingMode != .paused { samplingMode = .paused }
    demandTask?.cancel()
    await demandTask?.value
    demandTask = nil
    await engine.stop()
    observation?.cancel()
    await observation?.value
    observation = nil
  }
}

@MainActor
final class MacinityRuntime {
  static let shared = MacinityRuntime()
  let navigation = MacinityCoordinator()
  let monitoring = MonitoringViewModel()
  let networkChanges = NetworkChangesViewModel()
  let workspaces = WorkspacePresets()
  let diagnostics = DiagnosticsModel()
  let favorites = ActionFavorites()
}
