import AppKit
import SwiftUI
import ToolboxCore

enum DiskAccessCoverage: Equatable {
  case full
  case reduced(unreadablePaths: [String])
}

struct DiskAccessProbe {
  let sentinelURLs: [URL]

  init(homeURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
    sentinelURLs = [
      homeURL.appendingPathComponent("Library/Mail"),
      homeURL.appendingPathComponent("Library/Safari"),
    ]
  }

  func assess() -> DiskAccessCoverage {
    let manager = FileManager.default
    let existing = sentinelURLs.filter { manager.fileExists(atPath: $0.path) }
    guard !existing.isEmpty else { return .reduced(unreadablePaths: sentinelURLs.map(\.path)) }
    let unreadable = existing.compactMap { url -> String? in
      do {
        _ = try manager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return nil
      } catch {
        return url.path
      }
    }
    return unreadable.isEmpty ? .full : .reduced(unreadablePaths: unreadable)
  }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
  @Published private(set) var migration: MigrationAssessment
  @Published private(set) var coverage: DiskAccessCoverage
  @Published private(set) var isMigrating = false
  @Published private(set) var migrationReport: MigrationReport?
  @Published var errorMessage: String?

  private let migrationService: MigrationService
  private let accessProbe: DiskAccessProbe

  init(
    migrationService: MigrationService = MigrationService(),
    accessProbe: DiskAccessProbe = DiskAccessProbe()
  ) {
    self.migrationService = migrationService
    self.accessProbe = accessProbe
    migration = migrationService.inspect()
    coverage = accessProbe.assess()
  }

  func reassessCoverage() {
    coverage = accessProbe.assess()
  }

  func migrate() {
    guard !isMigrating else { return }
    isMigrating = true
    errorMessage = nil
    let service = migrationService
    Task {
      do {
        let report = try await Task.detached(priority: .userInitiated) {
          try service.migrate()
        }.value
        migrationReport = report
        migration = service.inspect()
      } catch {
        errorMessage = error.localizedDescription
        migration = service.inspect()
      }
      isMigrating = false
    }
  }
}

struct OnboardingView: View {
  @StateObject private var model: OnboardingViewModel
  let onComplete: () -> Void

  init(model: OnboardingViewModel = OnboardingViewModel(), onComplete: @escaping () -> Void) {
    _model = StateObject(wrappedValue: model)
    self.onComplete = onComplete
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      VStack(alignment: .leading, spacing: 6) {
        Text(L10n.text("Welcome to Toolbox"))
          .font(.system(size: 28, weight: .bold))
        Text(L10n.text("Local evidence for safer cleanup and app changes."))
          .font(.title3)
          .foregroundStyle(.secondary)
      }

      privacyStep
      accessStep
      migrationStep

      HStack {
        Text(L10n.text("You can change these choices later in Settings."))
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button(L10n.text("Continue to Toolbox"), action: onComplete)
          .buttonStyle(.borderedProminent)
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(30)
    .frame(width: 680)
    .alert(
      L10n.text("Migration error"),
      isPresented: Binding(
        get: { model.errorMessage != nil },
        set: { if !$0 { model.errorMessage = nil } })
    ) {
      Button(L10n.text("Close"), role: .cancel) { model.errorMessage = nil }
    } message: {
      Text(model.errorMessage ?? "")
    }
  }

  private var privacyStep: some View {
    onboardingCard(symbol: "lock.shield", title: "Private by default") {
      VStack(alignment: .leading, spacing: 8) {
        Text(
          L10n.text(
            "Scans, snapshots, and activity stay on this Mac. Toolbox has no telemetry and never cleans automatically."
          )
        )
        .foregroundStyle(.secondary)
        Divider()
        Label(L10n.text("First-launch approval"), systemImage: "checkmark.shield")
          .font(.subheadline.weight(.semibold))
        Text(
          L10n.text(
            "If macOS blocks Toolbox, open it once, then use System Settings → Privacy & Security → Open Anyway. Never disable Gatekeeper."
          )
        )
        .foregroundStyle(.secondary)
        Link(
          L10n.text("Open installation guide"),
          destination: URL(string: "https://thangldw.github.io/toolbox/#install")!)
      }
    }
  }

  private var accessStep: some View {
    onboardingCard(symbol: "externaldrive.badge.checkmark", title: "Scan coverage") {
      switch model.coverage {
      case .full:
        Label(L10n.text("Sentinel folders are readable."), systemImage: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case .reduced(let paths):
        VStack(alignment: .leading, spacing: 9) {
          Label(
            L10n.text("Coverage is reduced until protected folders are readable."),
            systemImage: "exclamationmark.triangle.fill"
          )
          .foregroundStyle(.orange)
          Text(paths.joined(separator: "\n"))
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
          HStack {
            Button(L10n.text("Open Full Disk Access")) { openFullDiskAccessSettings() }
            Button(L10n.text("Check again")) { model.reassessCoverage() }
          }
        }
      }
    }
  }

  private var migrationStep: some View {
    onboardingCard(symbol: "arrow.triangle.2.circlepath", title: "Keep your existing history") {
      if model.migration.alreadyMigrated || model.migrationReport != nil {
        Label(
          L10n.text("Legacy data was copied and verified."), systemImage: "checkmark.circle.fill"
        )
        .foregroundStyle(.green)
      } else if model.migration.hasLegacyData {
        VStack(alignment: .leading, spacing: 9) {
          Text(
            String(
              format: L10n.text(
                "%lld cleanup records and %lld trace sessions are ready to import."),
              model.migration.cleanupEntriesAvailable,
              model.migration.traceSessionsAvailable))
          Text(L10n.text("Diskora and Changeora files remain untouched."))
            .font(.caption)
            .foregroundStyle(.secondary)
          Button {
            model.migrate()
          } label: {
            if model.isMigrating {
              ProgressView().controlSize(.small)
            } else {
              Text(L10n.text(model.migration.errors.isEmpty ? "Import and verify" : "Retry import"))
            }
          }
          .disabled(model.isMigrating)
        }
      } else {
        Label(L10n.text("No legacy data found."), systemImage: "checkmark.circle")
          .foregroundStyle(.secondary)
      }
    }
  }

  private func onboardingCard<Content: View>(
    symbol: String, title: String, @ViewBuilder content: () -> Content
  ) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Image(systemName: symbol)
        .font(.title2)
        .foregroundStyle(.tint)
        .frame(width: 34)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 8) {
        Text(L10n.text(title)).font(.headline)
        content()
      }
      Spacer(minLength: 0)
    }
    .padding(17)
    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 13))
  }

  private func openFullDiskAccessSettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    else { return }
    NSWorkspace.shared.open(url)
  }
}
