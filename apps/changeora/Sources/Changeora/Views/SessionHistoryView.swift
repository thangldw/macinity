import AppKit
import SwiftUI

struct SessionHistoryView: View {
  @ObservedObject var model: ChangeoraViewModel
  @State private var olderID: UUID?
  @State private var newerID: UUID?

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Lịch sử",
        subtitle: "Mọi báo cáo được lưu cục bộ trên máy Mac này.",
        symbol: "clock.arrow.circlepath",
        value: "\(model.sessions.count)",
        valueLabel: "phiên"
      )
      Divider()
      HStack(spacing: 10) {
        Button("Tạo baseline hiện tại") { model.createBaseline() }.disabled(model.isScanning)
        Button("So sánh với baseline") { model.compareWithBaseline() }
          .disabled(model.baselineSnapshot == nil || model.isScanning)
        if model.sessions.count > 1 {
          Divider().frame(height: 20)
          Picker("Phiên trước", selection: $olderID) {
            Text("Chọn phiên").tag(UUID?.none)
            ForEach(model.sessions) { Text($0.title).tag(Optional($0.id)) }
          }.frame(maxWidth: 190)
          Picker("Phiên sau", selection: $newerID) {
            Text("Chọn phiên").tag(UUID?.none)
            ForEach(model.sessions) { Text($0.title).tag(Optional($0.id)) }
          }.frame(maxWidth: 190)
          Button("So sánh hai phiên") {
            if let olderID, let newerID {
              model.compareSessions(olderID: olderID, newerID: newerID)
            }
          }.disabled(olderID == nil || newerID == nil || olderID == newerID)
        }
        Spacer()
      }.padding(12)
      Divider()
      if model.sessions.isEmpty && model.adHocSession == nil {
        EmptyStateView(
          title: "Chưa có lịch sử",
          symbol: "clock",
          detail: "Các phiên so sánh hoàn tất sẽ xuất hiện tại đây."
        )
      } else {
        HSplitView {
          List(model.sessions, selection: $model.selectedSessionID) { session in
            VStack(alignment: .leading, spacing: 4) {
              Text(session.title).fontWeight(.semibold)
              Text(session.finishedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption).foregroundStyle(.secondary)
              Text("\(session.comparison.changes.count) thay đổi")
                .font(.caption).foregroundStyle(.secondary)
            }
            .tag(session.id)
            .padding(.vertical, 4)
          }
          .frame(minWidth: 260, idealWidth: 300)

          if let session = model.selectedSession {
            SessionDetailView(session: session, model: model)
          }
        }
      }
    }
  }
}

private struct SessionDetailView: View {
  let session: WatchSession
  @ObservedObject var model: ChangeoraViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(session.title).font(.title2).fontWeight(.semibold)
            Text("\(session.startedAt.formatted()) → \(session.finishedAt.formatted())")
              .foregroundStyle(.secondary)
          }
          Spacer()
          Button {
            exportReport(format: "md")
          } label: {
            Label("Export Markdown", systemImage: "square.and.arrow.up")
          }
          Button {
            exportReport(format: "json")
          } label: {
            Label("Export JSON", systemImage: "curlybraces")
          }
        }
        HStack(spacing: 12) {
          MetricCard(
            title: "Đã thêm", value: "\(session.comparison.addedCount)", symbol: "plus.circle",
            color: .green)
          MetricCard(
            title: "Đã gỡ", value: "\(session.comparison.removedCount)", symbol: "minus.circle",
            color: .red)
          MetricCard(
            title: "Đã đổi", value: "\(session.comparison.modifiedCount)",
            symbol: "arrow.triangle.2.circlepath", color: .orange)
        }
        if session.comparison.changes.isEmpty {
          Label("Không phát hiện thay đổi trong phạm vi theo dõi.", systemImage: "checkmark.shield")
            .foregroundStyle(.secondary)
        } else {
          ForEach(session.comparison.changes.prefix(12)) { change in
            HStack {
              Image(systemName: change.item.category.symbol).foregroundStyle(.purple)
              VStack(alignment: .leading) {
                Text(change.item.name).fontWeight(.medium)
                Text("\(change.kind.rawValue) • \(change.item.category.rawValue)")
                  .font(.caption).foregroundStyle(.secondary)
              }
              Spacer()
              RiskBadge(risk: change.risk)
            }
            Divider()
          }
        }
      }
      .padding(24)
    }
  }

  private func exportReport(format: String) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = format == "json" ? [.json] : [.plainText]
    panel.nameFieldStringValue =
      "Changeora-\(session.finishedAt.formatted(.iso8601.year().month().day())).\(format)"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let report =
        try format == "json"
        ? model.jsonReport(for: session) : model.markdownReport(for: session)
      try report.write(to: url, atomically: true, encoding: .utf8)
    } catch {
      model.errorMessage = "Không thể export báo cáo: \(error.localizedDescription)"
    }
  }
}
