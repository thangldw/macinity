import SwiftUI
import ToolboxCore

struct HomeView: View {
  @ObservedObject var coordinator: ToolboxCoordinator

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        HStack(spacing: 12) {
          HomeMetric(
            title: L10n.text("Recoverable"), value: ByteCount.string(coordinator.recoverableBytes),
            symbol: "trash")
          HomeMetric(
            title: L10n.text("Needs attention"), value: "\(coordinator.attentionCount)",
            symbol: "exclamationmark.shield")
          HomeMetric(
            title: L10n.text("Coverage"),
            value: L10n.text(coordinator.reducedCoverage ? "Reduced" : "Full"),
            symbol: "externaldrive.badge.checkmark")
        }

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
          HomeActionCard(
            title: L10n.text("Recover space safely"),
            detail: L10n.text("See reclaimable files before anything moves to Trash."),
            action: L10n.text("Scan storage"),
            symbol: "internaldrive",
            destination: .storage, coordinator: coordinator)
          HomeActionCard(
            title: L10n.text("Understand app changes"),
            detail: L10n.text("Compare local snapshots around an install, update, or removal."),
            action: L10n.text("Start a trace"),
            symbol: "scope",
            destination: .changes, coordinator: coordinator)
          HomeActionCard(
            title: L10n.text("Undo before regret"),
            detail: L10n.text("Review recoverable actions and restore without overwriting files."),
            action: L10n.text("Open Recovery"),
            symbol: "clock.arrow.circlepath",
            destination: .recovery, coordinator: coordinator)
        }

        Label(
          L10n.text("Runs locally. No telemetry. Nothing is deleted automatically."),
          systemImage: "lock.shield"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
      }
      .padding(32)
      .frame(maxWidth: 1_100, alignment: .leading)
    }
    .onAppear { coordinator.refreshSummaries() }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.text("Your Mac, explained."))
        .font(.system(size: 34, weight: .bold))
      Text(L10n.text(AppMetadata.tagline))
        .font(.title3)
        .foregroundStyle(.secondary)
    }
  }
}

private struct HomeActionCard: View {
  let title: String
  let detail: String
  let action: String
  let symbol: String
  let destination: ToolboxSection
  @ObservedObject var coordinator: ToolboxCoordinator

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 24, weight: .semibold))
        .foregroundStyle(.tint)
        .frame(width: 44, height: 44)
        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

      Text(title)
        .font(.title2.weight(.semibold))
      Text(detail)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 4)

      Button(action) { coordinator.open(.section(destination)) }
        .buttonStyle(.borderedProminent)
    }
    .padding(20)
    .frame(maxWidth: .infinity, minHeight: 230, alignment: .leading)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    .overlay {
      RoundedRectangle(cornerRadius: 16)
        .stroke(.separator.opacity(0.45), lineWidth: 1)
    }
  }
}

private struct HomeMetric: View {
  let title: String
  let value: String
  let symbol: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol).foregroundStyle(.tint).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(value).font(.title3.weight(.semibold))
        Text(title).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}
