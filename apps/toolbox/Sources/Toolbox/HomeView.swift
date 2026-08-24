import SwiftUI
import ToolboxCore

struct HomeView: View {
  @Binding var selection: ToolboxSection?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
          HomeActionCard(
            title: L10n.text("Recover space safely"),
            detail: L10n.text("See reclaimable files before anything moves to Trash."),
            action: L10n.text("Scan storage"),
            symbol: "internaldrive",
            destination: .storage,
            selection: $selection)
          HomeActionCard(
            title: L10n.text("Understand app changes"),
            detail: L10n.text("Compare local snapshots around an install, update, or removal."),
            action: L10n.text("Start a trace"),
            symbol: "scope",
            destination: .changes,
            selection: $selection)
          HomeActionCard(
            title: L10n.text("Undo before regret"),
            detail: L10n.text("Review recoverable actions and restore without overwriting files."),
            action: L10n.text("Open Recovery"),
            symbol: "clock.arrow.circlepath",
            destination: .recovery,
            selection: $selection)
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
  @Binding var selection: ToolboxSection?

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

      Button(action) { selection = destination }
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
