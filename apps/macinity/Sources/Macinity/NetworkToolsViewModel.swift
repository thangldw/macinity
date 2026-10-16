import CoreLocation
import Foundation
import MacinityMonitoring
import Network

@MainActor
final class NetworkToolsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published private(set) var overview: NetworkOverview?
  @Published private(set) var scan: NearbyWiFiScan?
  @Published private(set) var checks: [ConnectionCheck] = []
  @Published private(set) var latency: LatencyReport?
  @Published private(set) var busy: String?
  @Published private(set) var status = "Refresh to inspect Wi-Fi and LAN."
  @Published private(set) var pathStatus = "Unknown"
  @Published private(set) var pathInterfaces = ""
  @Published private(set) var constrained = false
  @Published private(set) var expensive = false
  @Published private(set) var changes = NetworkOverviewChanges()
  @Published private(set) var pathEvents: [PathObservation] = []
  @Published private(set) var omittedPathEvents = 0
  @Published var tracksChanges = false
  @Published private(set) var locationStatus = "Not requested"
  private var task: Task<Void, Never>?
  private var monitor: NWPathMonitor?
  private var generation = UUID()
  private var lastPath: String?
  private var stopRequested = false
  private let location = CLLocationManager()

  struct PathObservation: Identifiable {
    let id = UUID()
    let observedAt: Date
    let state: String
    let interfaces: String
  }
  override init() {
    super.init()
    location.delegate = self
    updateLocationStatus()
  }
  func appear() {
    guard monitor == nil else { return }
    let monitor = NWPathMonitor()
    self.monitor = monitor
    let token = UUID()
    generation = token
    monitor.pathUpdateHandler = { [weak self] path in
      let state =
        path.status == .satisfied
        ? "Available path"
        : path.status == .requiresConnection ? "Connection required" : "No available path"
      let names = Array(
        Set(path.availableInterfaces.filter { path.usesInterfaceType($0.type) }.map(\.name))
      )
      .sorted().joined(separator: ", ")
      let constrained = path.isConstrained
      let expensive = path.isExpensive
      Task { @MainActor [weak self] in
        guard let self, self.generation == token else { return }
        self.pathStatus = state
        self.pathInterfaces = names
        self.constrained = constrained
        self.expensive = expensive
        let key = "\(state)|\(names)|\(constrained)|\(expensive)"
        if self.tracksChanges, let previous = self.lastPath, previous != key {
          self.pathEvents.append(.init(observedAt: Date(), state: state, interfaces: names))
          if self.pathEvents.count > 200 {
            self.omittedPathEvents += self.pathEvents.count - 200
            self.pathEvents.removeFirst(self.pathEvents.count - 200)
          }
        }
        self.lastPath = key
      }
    }
    monitor.start(queue: DispatchQueue(label: "com.thang.toolbox.network-path"))
  }
  func disappear() {
    generation = UUID()
    monitor?.cancel()
    monitor = nil
    lastPath = nil
    changes.reset()
    cancel()
  }
  func resetTracking() {
    changes.reset()
    lastPath = nil
  }
  func clearChanges() {
    changes.clear()
    pathEvents = []
    omittedPathEvents = 0
    lastPath = nil
  }
  func cancel() {
    guard busy != nil else { return }
    stopRequested = true
    status =
      busy == "Scanning Wi-Fi"
      ? "Stopping after the macOS Wi-Fi scan returns." : "Stopping measurement."
    task?.cancel()
  }
  func refresh() {
    run("Reading network status") {
      try NetworkOverviewProvider.read()
    } publish: { value in
      self.overview = value
      if self.tracksChanges { self.changes.consume(value) } else { self.changes.reset() }
    }
  }
  func scanNearby() {
    run("Scanning Wi-Fi") {
      try NetworkOverviewProvider.scan()
    } publish: {
      self.scan = $0
    }
  }
  func measure(_ target: String) {
    guard let host = NetworkTarget.validate(target) else {
      status = "Enter a hostname or IP address without a URL, port or spaces."
      return
    }
    run("Measuring latency") {
      try NetworkDiagnostics.latency(target: host)
    } publish: {
      self.latency = $0
    }
  }
  func diagnose(_ target: String) {
    guard let host = NetworkTarget.validate(target) else {
      status = "Enter a hostname or IP address without a URL, port or spaces."
      return
    }
    // An old gateway observation must not silently become the target of a new test.
    let current = overview.flatMap { Date().timeIntervalSince($0.observedAt) <= 60 ? $0 : nil }
    let gateway = current?.gateway4 ?? current?.gateway6
    run("Checking connection") {
      try NetworkDiagnostics.connection(target: host, gateway: gateway)
    } publish: {
      self.checks = $0
    }
  }
  private func run<T: Sendable>(
    _ label: String, operation: @escaping @Sendable () throws -> T,
    publish: @escaping @MainActor (T) -> Void
  ) {
    guard busy == nil else { return }
    busy = label
    status = label
    stopRequested = false
    let worker = Task.detached(priority: .utility) { try operation() }
    task = Task {
      defer {
        busy = nil
        task = nil
      }
      do {
        let value = try await withTaskCancellationHandler {
          try await worker.value
        } onCancel: {
          worker.cancel()
        }
        try Task.checkCancellation()
        publish(value)
        status = "Observation completed."
      } catch is CancellationError {
        if label == "Reading network status" { changes.reset() }
        status = "Cancelled. Previous results remain timestamped."
      } catch {
        if label == "Reading network status" { changes.reset() }
        status =
          stopRequested
          ? "Cancelled. Previous results remain timestamped."
          : "Network observation failed or timed out. Check permissions and retry."
      }
    }
  }
  func requestWiFiIdentityPermission() { location.requestWhenInUseAuthorization() }
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor [weak self] in self?.updateLocationStatus() }
  }
  private func updateLocationStatus() {
    switch location.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse: locationStatus = "Authorized"
    case .denied: locationStatus = "Denied"
    case .restricted: locationStatus = "Restricted"
    case .notDetermined: locationStatus = "Not requested"
    @unknown default: locationStatus = "Unknown"
    }
  }
}
