import SwiftUI

/// Keeps choices visible and keyboard-accessible without an intermediate menu.
public struct OrvenChoicePicker<Value: Hashable>: View {
  let title: String
  @Binding var selection: Value
  let options: [(Value, String)]
  let searchable: Bool
  let minimumWidth: CGFloat
  @State private var query = ""
  @FocusState private var searchFocused: Bool
  @Environment(\.isEnabled) private var isEnabled

  public init(
    _ title: String, selection: Binding<Value>, options: [(Value, String)],
    searchable: Bool = false, minimumWidth: CGFloat = 120
  ) {
    self.title = title
    _selection = selection
    self.options = options
    self.searchable = searchable
    self.minimumWidth = minimumWidth
  }

  private var matches: [(Value, String)] {
    options.filter { query.isEmpty || $0.1.localizedStandardContains(query) }
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.caption).foregroundStyle(OrvenTheme.secondary)
      if searchable && (options.count > 8 || !query.isEmpty) {
        HStack {
          TextField(L10n.text("Filter choices"), text: $query)
            .textFieldStyle(.roundedBorder)
            .focused($searchFocused)
            .accessibilityLabel(title + " — " + L10n.text("Filter choices"))
          if !query.isEmpty {
            Button {
              query = ""
              searchFocused = true
            } label: {
              Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("Clear search"))
          }
        }
      }
      if options.count > 8 {
        ScrollView { choices }.frame(height: 144)
      } else {
        choices
      }
    }
  }

  private var choices: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: 6)], spacing: 6) {
      ForEach(matches, id: \.0) { value, label in
        Button {
          selection = value
        } label: {
          HStack(spacing: 4) {
            if selection == value {
              Image(systemName: "checkmark").accessibilityHidden(true)
            }
            Text(label).fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, minHeight: 22)
          .padding(.horizontal, 8).padding(.vertical, 5)
          .foregroundStyle(selection == value ? OrvenTheme.action : OrvenTheme.ink)
          .background(
            selection == value ? OrvenTheme.action.opacity(0.12) : OrvenTheme.surface,
            in: RoundedRectangle(cornerRadius: 8)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 8)
              .stroke(selection == value ? OrvenTheme.action : OrvenTheme.border, lineWidth: 1)
          }
          .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selection == value ? [.isSelected] : [])
      }
      if matches.isEmpty {
        Text(L10n.text("No matching choices")).font(.callout).foregroundStyle(OrvenTheme.secondary)
      }
    }
  }
}
