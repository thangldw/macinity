import SwiftUI
import ToolboxCore
import ToolboxStorage

@MainActor
final class ToolboxSettingsViewModel: ObservableObject {
  @Published private(set) var coverage = DiskAccessProbe().assess()
  @Published private(set) var hasLegacySchedule = ScheduledScanService().hasLegacyLaunchAgent
  @Published private(set) var latestVersion: SemanticVersion?
  @Published private(set) var isCheckingUpdates = false
  @Published private(set) var isReplacingSchedule = false
  @Published var statusMessage: String?
  @Published var errorMessage: String?
  @Published var replacementIntervalHours = 24

  private let scheduledScan: ScheduledScanService
  private let updateChecker: ReleaseUpdateChecker

  init(
    scheduledScan: ScheduledScanService = ScheduledScanService(),
    updateChecker: ReleaseUpdateChecker = ReleaseUpdateChecker()
  ) {
    self.scheduledScan = scheduledScan
    self.updateChecker = updateChecker
  }

  func refresh() {
    coverage = DiskAccessProbe().assess()
    hasLegacySchedule = scheduledScan.hasLegacyLaunchAgent
  }

  func replaceLegacySchedule() {
    guard !isReplacingSchedule else { return }
    isReplacingSchedule = true
    errorMessage = nil
    let hours = replacementIntervalHours
    Task {
      do {
        try await scheduledScan.replaceLegacyLaunchAgent(intervalHours: hours)
        statusMessage = L10n.text("Legacy schedule replaced after Toolbox bootstrap succeeded.")
      } catch {
        errorMessage = error.localizedDescription
      }
      hasLegacySchedule = scheduledScan.hasLegacyLaunchAgent
      isReplacingSchedule = false
    }
  }

  func checkForUpdates() {
    guard !isCheckingUpdates else { return }
    guard !ScanActivityRegistry.shared.isActive else {
      errorMessage = L10n.text("Finish the active scan before checking for updates.")
      return
    }
    isCheckingUpdates = true
    errorMessage = nil
    Task {
      do {
        latestVersion = try await updateChecker.latestVersion()
        let current = SemanticVersion(AppMetadata.version)
        statusMessage =
          if let latestVersion, let current, current < latestVersion {
            String(
              format: L10n.text("Toolbox %@ is available."), latestVersion.description)
          } else {
            L10n.text("You are using the latest public release.")
          }
      } catch {
        errorMessage = error.localizedDescription
      }
      isCheckingUpdates = false
    }
  }
}

struct SettingsView: View {
  @StateObject private var model = ToolboxSettingsViewModel()
  @State private var confirmsScheduleReplacement = false
  @State private var showsError = false

  var body: some View {
    Form {
      Section(L10n.text("Privacy and coverage")) {
        switch model.coverage {
        case .full:
          Label(L10n.text("Sentinel folders are readable."), systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        case .reduced(let paths):
          Label(
            L10n.text("Coverage is reduced until protected folders are readable."),
            systemImage: "exclamationmark.triangle.fill"
          )
          .foregroundStyle(.orange)
          Text(paths.joined(separator: "\n"))
            .font(.caption.monospaced())
            .textSelection(.enabled)
        }
        Button(L10n.text("Check again")) { model.refresh() }
      }

      Section(L10n.text("Legacy scheduled scan")) {
        if model.hasLegacySchedule {
          Label(
            L10n.text("A Diskora scheduled scan is installed."),
            systemImage: "calendar.badge.exclamationmark")
          Picker(L10n.text("Run every"), selection: $model.replacementIntervalHours) {
            Text(L10n.text("6 hours")).tag(6)
            Text(L10n.text("12 hours")).tag(12)
            Text(L10n.text("24 hours")).tag(24)
            Text(L10n.text("7 days")).tag(168)
          }
          .pickerStyle(.segmented)
          Button(L10n.text("Replace with Toolbox schedule…")) {
            confirmsScheduleReplacement = true
          }
          .disabled(model.isReplacingSchedule)
        } else {
          Label(L10n.text("No Diskora schedule needs migration."), systemImage: "checkmark.circle")
            .foregroundStyle(.secondary)
        }
        Text(
          L10n.text(
            "The old agent remains untouched unless the new scan-only agent bootstraps successfully."
          )
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Section(L10n.text("Updates")) {
        Text(
          L10n.text(
            "Only when you click the button, Toolbox requests public release metadata from GitHub. No scan or device data is sent."
          )
        )
        .foregroundStyle(.secondary)
        Button {
          model.checkForUpdates()
        } label: {
          if model.isCheckingUpdates {
            ProgressView().controlSize(.small)
          } else {
            Label(L10n.text("Check for Updates"), systemImage: "arrow.triangle.2.circlepath")
          }
        }
        .disabled(model.isCheckingUpdates || model.isReplacingSchedule)
      }

      if let status = model.statusMessage {
        Section {
          Label(status, systemImage: "checkmark.circle")
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .frame(width: 620, height: 560)
    .onAppear { model.refresh() }
    .onChange(of: model.errorMessage) { showsError = $0 != nil }
    .confirmationDialog(
      L10n.text("Replace the Diskora scheduled scan?"),
      isPresented: $confirmsScheduleReplacement
    ) {
      Button(L10n.text("Replace after verification")) { model.replaceLegacySchedule() }
      Button(L10n.text("Cancel"), role: .cancel) {}
    } message: {
      Text(
        L10n.text(
          "Toolbox first installs and bootstraps its scan-only agent. The Diskora plist is removed only after that succeeds."
        ))
    }
    .alert(L10n.text("Settings error"), isPresented: $showsError) {
      Button(L10n.text("Close"), role: .cancel) { model.errorMessage = nil }
    } message: {
      Text(model.errorMessage ?? "")
    }
  }
}
