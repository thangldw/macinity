import Foundation
import MacinityCore
import MacinityMonitoring

enum MacinityRoute: Equatable {
  case section(MacinitySection)
  case inspectProcess(ProcessIdentity)
  case reviewStorage(path: String)

  var storagePath: String? {
    guard case .reviewStorage(let path) = self else { return nil }
    return URL(fileURLWithPath: path).standardizedFileURL.path
  }
}

@MainActor
final class MacinityCoordinator: ObservableObject {
  @Published var selectedSection: MacinitySection
  @Published private(set) var storageFocusPath: String?
  @Published private(set) var processFocus: ProcessIdentity?
  @Published private(set) var recentActivities: [ActivityEntry] = []
  @Published private(set) var recoverableBytes: Int64 = 0
  @Published private(set) var attentionCount = 0
  @Published private(set) var reducedCoverage = false
  @Published private(set) var summaryError: String?

  private var recentSections: [MacinityArea: MacinitySection] = [:]

  private let activityLedger: ActivityLedger
  private let evidenceStore: EvidenceStore
  private let defaults: UserDefaults

  init(
    activityLedger: ActivityLedger = ActivityLedger(),
    evidenceStore: EvidenceStore = EvidenceStore(),
    defaults: UserDefaults = .standard
  ) {
    self.activityLedger = activityLedger
    self.evidenceStore = evidenceStore
    self.defaults = defaults
    selectedSection =
      MacinitySection(rawValue: defaults.string(forKey: "toolbox.selectedSection") ?? "") ?? .home
  }

  func openArea(_ area: MacinityArea) {
    guard selectedSection.area != area else { return }
    open(.section(recentSections[area] ?? area.sections[0]))
  }

  func open(_ route: MacinityRoute) {
    recentSections[selectedSection.area] = selectedSection
    switch route {
    case .section(let section):
      if selectedSection != section { selectedSection = section }
    case .inspectProcess(let identity):
      if processFocus != identity { processFocus = identity }
      if selectedSection != .processes { selectedSection = .processes }
    case .reviewStorage:
      if storageFocusPath != route.storagePath { storageFocusPath = route.storagePath }
      if selectedSection != .storage { selectedSection = .storage }
    }
    if defaults.string(forKey: "toolbox.selectedSection") != selectedSection.rawValue {
      defaults.set(selectedSection.rawValue, forKey: "toolbox.selectedSection")
    }
  }

  func refreshSummaries() {
    do {
      let activities = try activityLedger.load()
      recentActivities = Array(activities.sorted { $0.occurredAt > $1.occurredAt }.prefix(5))
      recoverableBytes = activities.filter {
        $0.kind == .cleanup && $0.status == .succeeded && $0.recoverable
      }.reduce(0) { $0 + $1.affectedBytes }
      attentionCount = try evidenceStore.load().count { $0.safety == .protected }
      reducedCoverage = DiskAccessProbe().assess() != .full
      summaryError = nil
    } catch {
      summaryError = error.localizedDescription
    }
  }
}
