import SwiftUI
import ToolboxCore

private enum ChangeTimelineSection: String, CaseIterable, Identifiable {
  case overview = "Theo dõi thay đổi"
  case changes = "Thay đổi"
  case history = "Lịch sử"
  case coverage = "Phạm vi & quyền riêng tư"

  var id: String { rawValue }
  var title: String { L10n.text(rawValue) }
}

public struct ChangeModuleSummary: Sendable, Equatable {
  public let sessionCount: Int
  public let activeSession: Bool

  public init(sessionCount: Int, activeSession: Bool) {
    self.sessionCount = sessionCount
    self.activeSession = activeSession
  }
}

public struct ChangeTimelineModuleView: View {
  @State private var selection = ChangeTimelineSection.overview
  @StateObject private var model = ChangeoraViewModel()

  public init() {}

  public var body: some View {
    VStack(spacing: 0) {
      Picker(L10n.text("Change Timeline"), selection: $selection) {
        ForEach(ChangeTimelineSection.allCases) { section in
          Text(section.title).tag(section)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .padding(.horizontal, 24)
      .padding(.vertical, 12)

      Divider()

      Group {
        switch selection {
        case .overview:
          InstallTraceDropView(model: model)
        case .changes:
          ChangesView(model: model)
        case .history:
          SessionHistoryView(model: model)
        case .coverage:
          CoverageView(model: model)
        }
      }
    }
    .alert(
      "Toolbox",
      isPresented: Binding(
        get: { model.errorMessage != nil },
        set: { if !$0 { model.errorMessage = nil } }
      )
    ) {
      Button(L10n.text("Đóng"), role: .cancel) { model.errorMessage = nil }
    } message: {
      Text(L10n.text(model.errorMessage ?? ""))
    }
  }
}
