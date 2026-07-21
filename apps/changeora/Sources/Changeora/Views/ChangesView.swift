import SwiftUI

struct ChangesView: View {
  @ObservedObject var model: ChangeoraViewModel
  @State private var searchText = ""
  @State private var riskFilter: ChangeRisk?

  private var changes: [ChangeRecord] {
    guard let session = model.selectedSession else { return [] }
    return session.comparison.changes.filter { change in
      let matchesRisk = riskFilter == nil || change.risk == riskFilter
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      let matchesSearch =
        query.isEmpty
        || change.item.name.localizedCaseInsensitiveContains(query)
        || change.item.path.localizedCaseInsensitiveContains(query)
        || (change.item.ownerHint?.localizedCaseInsensitiveContains(query) ?? false)
      return matchesRisk && matchesSearch
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Thay đổi",
        subtitle: model.selectedSession?.title ?? "Chưa có phiên so sánh.",
        symbol: "arrow.left.arrow.right",
        value: "\(changes.count)",
        valueLabel: "kết quả đang hiển thị"
      )
      Divider()
      if model.selectedSession == nil {
        EmptyStateView(
          title: "Chưa có thay đổi",
          symbol: "arrow.left.arrow.right",
          detail: "Hãy hoàn thành một phiên theo dõi cài đặt để xem kết quả trước và sau."
        )
      } else {
        controls
        Divider()
        if changes.isEmpty {
          EmptyStateView(
            title: "Không có kết quả phù hợp",
            symbol: "checkmark.shield",
            detail: "Thử bỏ bộ lọc hoặc thay đổi từ khóa tìm kiếm."
          )
        } else {
          List(changes) { change in
            ChangeRow(change: change) { model.reveal(change.item) }
          }
          .listStyle(.inset)
        }
      }
    }
  }

  private var controls: some View {
    HStack(spacing: 12) {
      TextField("Tìm tên, đường dẫn hoặc chủ sở hữu", text: $searchText)
        .textFieldStyle(.roundedBorder)
      Picker("Mức", selection: $riskFilter) {
        Text("Tất cả mức").tag(ChangeRisk?.none)
        ForEach(ChangeRisk.allCases, id: \.rawValue) { risk in
          Text(risk.title).tag(Optional(risk))
        }
      }
      .frame(width: 150)
    }
    .padding(14)
  }
}

private struct ChangeRow: View {
  let change: ChangeRecord
  let reveal: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: change.item.category.symbol)
        .font(.title2).foregroundStyle(change.risk == .important ? .red : .purple)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 8) {
          Text(change.item.name).fontWeight(.semibold)
          Text(change.kind.rawValue).font(.caption).foregroundStyle(.secondary)
          RiskBadge(risk: change.risk)
        }
        Text(change.item.path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
        HStack(spacing: 12) {
          Label(change.item.category.rawValue, systemImage: "tag")
          if let owner = change.item.ownerHint {
            Label(owner, systemImage: "building.2")
          }
          if let version = change.item.version {
            Label(version, systemImage: "number")
          }
          if let signature = change.item.signatureStatus {
            Label(signature, systemImage: "checkmark.seal")
          }
        }
        .font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      Button("Finder", action: reveal).buttonStyle(.borderless)
    }
    .padding(.vertical, 6)
  }
}
