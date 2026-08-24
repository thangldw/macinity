import Foundation
import ToolboxCore

enum ToolboxRoute: Equatable {
  case section(ToolboxSection)
  case reviewStorage(path: String)

  var storagePath: String? {
    guard case .reviewStorage(let path) = self else { return nil }
    return URL(fileURLWithPath: path).standardizedFileURL.path
  }
}

@MainActor
final class ToolboxCoordinator: ObservableObject {
  @Published var selectedSection: ToolboxSection
  @Published private(set) var storageFocusPath: String?
  @Published private(set) var recoverableBytes: Int64 = 0
  @Published private(set) var attentionCount = 0
  @Published private(set) var reducedCoverage = false
  @Published private(set) var summaryError: String?

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
      ToolboxSection(rawValue: defaults.string(forKey: "toolbox.selectedSection") ?? "") ?? .home
  }

  func open(_ route: ToolboxRoute) {
    switch route {
    case .section(let section):
      selectedSection = section
    case .reviewStorage:
      storageFocusPath = route.storagePath
      selectedSection = .storage
    }
    defaults.set(selectedSection.rawValue, forKey: "toolbox.selectedSection")
  }

  func refreshSummaries() {
    do {
      let activities = try activityLedger.load()
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
