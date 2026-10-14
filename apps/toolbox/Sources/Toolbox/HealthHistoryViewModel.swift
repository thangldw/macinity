import AppKit
import Foundation
import ToolboxCore
import ToolboxMonitoring

@MainActor
final class HealthHistoryViewModel: ObservableObject {
  @Published private(set) var archive = HealthArchive()
  @Published private(set) var session: [HealthRecord] = []
  @Published private(set) var recording = false
  @Published var recordingMinutes = 15
  @Published private(set) var samplingPaused = true
  @Published private(set) var status: String?
  @Published var enabled: Bool {
    didSet { defaults.set(enabled, forKey: "toolbox.healthHistory.enabled") }
  }
  @Published var retentionHours: Int {
    didSet {
      defaults.set(retentionHours, forKey: "toolbox.healthHistory.retentionHours")
      Task { await refreshRetention() }
    }
  }
  private let defaults: UserDefaults
  private let store: HealthHistoryStore
  private var segment = UUID()
  private var lastGeneration: Int?
  private var lastUptime: Double?
  private var lastWall: Date?
  private var historyTick: Double?
  private var sessionTick: Double?
  private var recordingStart: Double?
  private var recordingSeconds = 900.0

  init(
    defaults: UserDefaults = .standard, directory: URL = AppMetadata.applicationSupportDirectory()
  ) {
    self.defaults = defaults
    store = HealthHistoryStore(url: directory.appendingPathComponent("health-history-v1.json"))
    enabled = defaults.bool(forKey: "toolbox.healthHistory.enabled")
    retentionHours =
      defaults.integer(forKey: "toolbox.healthHistory.retentionHours") == 24 ? 24 : 168
  }

  func load() async {
    do { archive = try await store.read(now: Date(), retentionHours: retentionHours) } catch {
      status =
        "History could not be read. The existing file is preserved; recording to disk is blocked."
    }
  }

  func consume(_ snapshot: MonitoringSnapshot, active: Bool) async {
    guard active else {
      markGap()
      return
    }
    if samplingPaused { samplingPaused = false }
    let tick = snapshot.time.monotonic
    if recording, let recordingStart, tick - recordingStart >= recordingSeconds {
      recording = false
    }
    let generation = snapshot.history.last?.generation
    if let lastUptime, let lastWall,
      tick <= lastUptime || tick - lastUptime > 15 || generation != lastGeneration
        || abs(snapshot.time.wall.timeIntervalSince(lastWall) - (tick - lastUptime)) > 5
    {
      segment = UUID()
    }
    lastUptime = tick
    lastWall = snapshot.time.wall
    lastGeneration = generation
    let historyDue = enabled && (historyTick == nil || tick - (historyTick ?? 0) >= 60)
    let sessionDue = recording && (sessionTick == nil || tick - (sessionTick ?? 0) >= 10)
    guard historyDue || sessionDue else { return }
    let point = HealthRecord(
      snapshot: snapshot, segment: segment, now: ProcessInfo.processInfo.systemUptime)
    if recording, let recordingStart {
      if tick - recordingStart >= recordingSeconds {
        recording = false
      } else if sessionTick == nil || tick - (sessionTick ?? 0) >= 10 {
        session.append(point)
        session = Array(session.suffix(360))
        sessionTick = tick
      }
    }
    if historyDue {
      historyTick = tick
      do {
        archive = try await store.append(point, retentionHours: retentionHours)
        status = nil
      } catch {
        status =
          "History could not be saved. Existing data is preserved; check the local storage location."
      }
    }
  }

  func markGap() {
    if !samplingPaused { samplingPaused = true }
    segment = UUID()
    lastUptime = nil
    lastWall = nil
    lastGeneration = nil
  }
  func startRecording(minutes: Int) {
    session = []
    sessionTick = nil
    segment = UUID()
    recordingStart = ProcessInfo.processInfo.systemUptime
    recordingMinutes = [15, 30, 60].contains(minutes) ? minutes : 15
    recordingSeconds = Double(recordingMinutes) * 60
    recording = true
  }
  func stopRecording() { recording = false }
  func captureBaseline() async {
    do {
      archive = try await store.captureBaseline(now: Date(), retentionHours: retentionHours)
      status = nil
    } catch { status = "Baseline needs at least 30 recorded samples and writable local storage." }
  }
  private func refreshRetention() async {
    do {
      archive = try await store.setRetention(now: Date(), hours: retentionHours)
      status = nil
    } catch { status = "History retention could not be saved. Existing data is preserved." }
  }
}
