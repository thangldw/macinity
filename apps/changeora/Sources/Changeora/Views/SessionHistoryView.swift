import AppKit
import SwiftUI

struct SessionHistoryView: View {
  @ObservedObject var model: ChangeoraViewModel

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
      if model.sessions.isEmpty {
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
            exportReport()
          } label: {
            Label("Export Markdown", systemImage: "square.and.arrow.up")
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

  private func exportReport() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue =
      "Changeora-\(session.finishedAt.formatted(.iso8601.year().month().day())).md"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      try model.markdownReport(for: session).write(to: url, atomically: true, encoding: .utf8)
    } catch {
      model.errorMessage = "Không thể export báo cáo: \(error.localizedDescription)"
    }
  }
}
