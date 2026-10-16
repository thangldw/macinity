import SwiftUI
import ToolboxCore

@MainActor
final class ActionFavorites: ObservableObject {
  @Published private(set) var sections: [ToolboxSection]
  private let defaults: UserDefaults
  static func normalize(_ values: [String]) -> [ToolboxSection] {
    var seen: Set<String> = []
    return Array(
      values.compactMap { value in
        guard let section = ToolboxSection(rawValue: value), section != .home,
          seen.insert(value).inserted
        else { return nil }
        return section
      }.prefix(8))
  }
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    sections = Self.normalize(
      defaults.stringArray(forKey: "orven.actionFavorites") ?? [
        "diagnostics", "workspaces", "networkTools", "sensors",
      ])
  }
  func toggle(_ section: ToolboxSection) {
    if sections.contains(section) {
      sections.removeAll { $0 == section }
    } else if sections.count < 8, section != .home {
      sections.append(section)
    }
    defaults.set(sections.map(\.rawValue), forKey: "orven.actionFavorites")
  }
}

struct ActionCenterView: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  @ObservedObject var coordinator: ToolboxCoordinator
  @ObservedObject private var favorites = ToolboxRuntime.shared.favorites
  @State private var editing = false
  var body: some View {
    let _ = languageCode
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(L10n.text("Quick actions")).font(.title3.bold())
        Spacer()
        Button(L10n.text(editing ? "Done" : "Edit favorites")) { editing.toggle() }
      }
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 180), alignment: .leading)], alignment: .leading
      ) {
        ForEach(editing ? ToolboxSection.allCases.filter { $0 != .home } : favorites.sections) {
          section in
          Button {
            if editing { favorites.toggle(section) } else { coordinator.open(.section(section)) }
          } label: {
            Label(
              section.title,
              systemImage: editing
                ? (favorites.sections.contains(section) ? "star.fill" : "star") : section.symbol
            )
            .frame(maxWidth: .infinity, alignment: .leading)
          }.buttonStyle(.bordered)
            .accessibilityAddTraits(
              editing && favorites.sections.contains(section) ? [.isSelected] : []
            )
            .disabled(
              editing && !favorites.sections.contains(section) && favorites.sections.count >= 8)
        }
      }
      if editing { Text(L10n.text("Choose up to eight favorites.")).font(.caption) }
      ActionAttentionSummary(coordinator: coordinator)
      ActionSessionStatus(coordinator: coordinator)
      ActionDiagnosticSummary(coordinator: coordinator)
      ActionAlertsSummary(coordinator: coordinator)
      Text(L10n.text("Recent activity")).font(.headline)
      if coordinator.summaryError != nil {
        Text(L10n.text("Activity summary unavailable")).foregroundStyle(.secondary)
      }
      if coordinator.summaryError == nil && coordinator.recentActivities.isEmpty {
        Text(L10n.text("No recorded activity.")).foregroundStyle(.secondary)
      }
      ForEach(coordinator.recentActivities) { entry in
        ActionSummaryButton(
          title: L10n.text(entry.kind.rawValue.capitalized) + " · "
            + L10n.text(entry.status.rawValue.capitalized),
          detail: workflowTimestamp(entry.occurredAt, language: languageCode)
        ) { coordinator.open(.section(.changes)) }
      }
    }
  }
}

private struct ActionSessionStatus: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let coordinator: ToolboxCoordinator
  @ObservedObject private var profiles = ToolboxRuntime.shared.workspaces
  @ObservedObject private var awake = KeepAwakeController.shared
  var body: some View {
    let _ = languageCode
    VStack(alignment: .leading, spacing: 8) {
      if awake.remaining > 0 {
        HStack {
          Text(L10n.text("Keep Awake"))
          Text("\(awake.remaining / 60):\(String(format: "%02d", awake.remaining % 60))")
            .monospacedDigit()
          Button(L10n.text("Stop")) { awake.stop() }
        }
      }
      if let name = profiles.runningName {
        Text(L10n.text("Applying work profile") + ": " + name)
        Button(L10n.text("Stop after current step")) { profiles.cancelRun() }.disabled(
          profiles.cancelling)
      }
      ForEach(profiles.runs.prefix(3)) { run in
        ActionSummaryButton(
          title: run.name,
          detail: "\(run.steps.filter { $0.outcome == .succeeded }.count)/\(run.steps.count) "
            + L10n.text("steps succeeded") + " · "
            + workflowTimestamp(run.date, language: languageCode)
        ) {
          profiles.inspectedRunID = run.id
          coordinator.open(.section(.workspaces))
        }
      }
    }
  }
}

private struct ActionDiagnosticSummary: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let coordinator: ToolboxCoordinator
  @ObservedObject private var model = ToolboxRuntime.shared.diagnostics
  var body: some View {
    let _ = languageCode
    if let report = model.report {
      ActionSummaryButton(
        title: L10n.text("Latest diagnostic") + ": " + L10n.text(report.topic.title),
        detail: workflowTimestamp(report.createdAt, language: languageCode) + " · "
          + L10n.text("A saved observation, not current health status.")
      ) { coordinator.open(.section(.diagnostics)) }
    } else {
      Button(L10n.text("Analyze a problem")) { coordinator.open(.section(.diagnostics)) }
    }
  }
}

private struct ActionAlertsSummary: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let coordinator: ToolboxCoordinator
  @ObservedObject private var alerts = ToolboxRuntime.shared.monitoring.alerts
  var body: some View {
    let _ = languageCode
    if !alerts.events.isEmpty {
      Text(L10n.text("Recent alerts")).font(.headline)
      ForEach(alerts.events.prefix(3)) { event in
        ActionSummaryButton(
          title: L10n.text(event.title),
          detail: workflowTimestamp(event.observedAt, language: languageCode) + " · "
            + L10n.text(event.evidence)
        ) { coordinator.open(.section(event.section)) }
      }
    }
  }
}

private struct ActionAttentionSummary: View {
  @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.defaultLanguage
    .rawValue
  let coordinator: ToolboxCoordinator
  @ObservedObject private var monitoring = ToolboxRuntime.shared.monitoring
  var body: some View {
    let _ = languageCode
    let now = ProcessInfo.processInfo.systemUptime
    let metrics = SmartDiagnostics.metrics(
      snapshot: monitoring.snapshot, active: monitoring.samplingMode != .paused)
    let reports = [DiagnosticTopic.slow, .hot, .battery, .storage].map {
      SmartDiagnostics.report(topic: $0, metrics: metrics, now: now)
    }
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.text("Needs attention")).font(.headline)
      ForEach(reports.filter { $0.attentionCount > 0 }) { report in
        Button {
          coordinator.open(.section(report.topic.section))
        } label: {
          Text(L10n.text(report.topic.title) + " · \(report.attentionCount)")
        }.buttonStyle(.bordered)
      }
      Text(
        L10n.text(
          "Hints use available samples from the last 15 seconds. Missing or paused checks cannot establish normal operation."
        )
      )
      .font(.caption).foregroundStyle(.secondary)
      if let date = monitoring.snapshot?.time.wall { Text(date, style: .time).font(.caption) }
    }
  }
}

func workflowTimestamp(_ date: Date, language: String) -> String {
  date.formatted(
    Date.FormatStyle(date: .abbreviated, time: .shortened)
      .locale(AppLanguage(rawValue: language)?.locale ?? AppLanguage.defaultLanguage.locale))
}

/// Native link buttons can keep a wide intrinsic label; flexible summaries must wrap.
struct ActionSummaryButton: View {
  let title: String
  let detail: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.body.weight(.medium))
        Text(detail).font(.caption)
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }.buttonStyle(.plain).foregroundStyle(OrvenTheme.action)
  }
}
