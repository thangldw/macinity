import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
  case overview = "Theo dõi cài đặt"
  case changes = "Thay đổi"
  case history = "Lịch sử"
  case coverage = "Phạm vi & quyền riêng tư"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .overview: "scope"
    case .changes: "arrow.left.arrow.right"
    case .history: "clock.arrow.circlepath"
    case .coverage: "hand.raised"
    }
  }
}

struct ContentView: View {
  @State private var selection: AppSection? = .overview
  @StateObject private var model = ChangeoraViewModel()

  var body: some View {
    NavigationSplitView {
      List(AppSection.allCases, selection: $selection) { section in
        Label(section.rawValue, systemImage: section.symbol).tag(section)
      }
      .navigationTitle("Changeora")
      .navigationSplitViewColumnWidth(min: 210, ideal: 235)
    } detail: {
      switch selection ?? .overview {
      case .overview:
        WatchInstallationView(model: model)
      case .changes:
        ChangesView(model: model)
      case .history:
        SessionHistoryView(model: model)
      case .coverage:
        CoverageView(model: model)
      }
    }
    .frame(minWidth: 980, minHeight: 680)
    .alert(
      "Changeora",
      isPresented: Binding(
        get: { model.errorMessage != nil },
        set: { if !$0 { model.errorMessage = nil } }
      )
    ) {
      Button("Đóng", role: .cancel) { model.errorMessage = nil }
    } message: {
      Text(model.errorMessage ?? "")
    }
  }
}
