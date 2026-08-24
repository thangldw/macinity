import SwiftUI
import ToolboxCore

struct HistoryView: View {
  @ObservedObject var model: HistoryViewModel
  @State private var entryToRestore: CleanupHistoryEntry?
  @State private var showsError = false
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Undo Center", subtitle: "Lịch sử, vị trí Trash và khôi phục có kiểm tra xung đột",
        symbol: "arrow.uturn.backward.circle", value: model.entries.count.formatted(),
        valueLabel: "mục có thể khôi phục")
      Divider()
      if model.entries.isEmpty, model.activityEntries.isEmpty {
        EmptyStateView(
          title: "Chưa có lịch sử", symbol: "clock",
          detail: "Các thao tác dọn dẹp và gỡ ứng dụng sẽ xuất hiện tại đây.")
      } else {
        List {
          if !model.entries.isEmpty {
            Section("Có thể khôi phục từ Trash") {
              ForEach(model.entries) { entry in
                historyRow(entry)
              }
            }
          }
          if !model.activityEntries.isEmpty {
            Section("Toàn bộ hoạt động") {
              ForEach(model.activityEntries.prefix(100)) { activity in
                activityRow(activity)
              }
            }
          }
        }
        .listStyle(.inset)
      }
      Divider()
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Undo Center không ghi đè dữ liệu đang tồn tại ở vị trí gốc.").font(.caption)
          if let statusMessage = model.statusMessage {
            Text(L10n.text(statusMessage)).font(.caption).foregroundStyle(.green)
          }
        }
        .foregroundStyle(.secondary)
        Spacer()
        Button("Mở Trash") {
          NSWorkspace.shared.open(
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash"))
        }
        Button("Làm mới") { model.refresh() }
      }.padding(18)
    }
    .onAppear { model.refresh() }
    .onChange(of: model.errorMessage) { showsError = $0 != nil }
    .alert(
      "Khôi phục từ Trash?",
      isPresented: Binding(get: { entryToRestore != nil }, set: { if !$0 { entryToRestore = nil } })
    ) {
      Button("Hủy", role: .cancel) { entryToRestore = nil }
      Button("Khôi phục") {
        if let entryToRestore { model.restore(entryToRestore) }
        entryToRestore = nil
      }
    } message: {
      Text("Mục chỉ được khôi phục khi vị trí gốc chưa có dữ liệu mới.")
    }
    .alert("Một số mục không thể khôi phục", isPresented: $showsError) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(L10n.text(model.errorMessage ?? ""))
    }
  }

  private func historyRow(_ entry: CleanupHistoryEntry) -> some View {
    DisclosureGroup {
      ForEach(entry.paths, id: \.self) { Text($0).font(.caption).textSelection(.enabled) }
      Text(L10n.text(entry.note)).font(.caption).foregroundStyle(.secondary)
      if entry.pendingRestoreCount > 0 {
        Button("Khôi phục \(entry.pendingRestoreCount) mục…") {
          entryToRestore = entry
        }
        .disabled(model.isRestoring)
      } else if entry.recoverable, entry.moves != nil {
        Label("Đã khôi phục hoặc không còn mục trong Trash", systemImage: "checkmark.circle")
          .font(.caption).foregroundStyle(.secondary)
      }
    } label: {
      HStack {
        Image(systemName: entry.recoverable ? "trash" : "eraser").foregroundStyle(
          entry.recoverable ? .blue : .orange)
        VStack(alignment: .leading) {
          Text(L10n.text(entry.action)).fontWeight(.medium)
          Text(entry.date.formatted()).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Text(ByteCount.string(entry.bytes))
      }
    }
  }

  private func activityTitle(_ kind: ActivityKind) -> String {
    switch kind {
    case .cleanup: L10n.text("Cleanup")
    case .command: L10n.text("Developer command")
    case .restore: L10n.text("Restore")
    case .trace: L10n.text("Install Trace")
    case .migration: L10n.text("Migration")
    case .export: L10n.text("Export")
    }
  }

  private func activityRow(_ activity: ActivityEntry) -> some View {
    let succeeded = activity.status == .succeeded
    return DisclosureGroup {
      ForEach(activity.paths, id: \.self) { path in
        Text(path)
          .font(.caption)
          .textSelection(.enabled)
      }
      ForEach(activity.errors, id: \.self) { message in
        Text(message)
          .font(.caption)
          .foregroundStyle(Color.red)
      }
    } label: {
      HStack {
        Label(activityTitle(activity.kind), systemImage: activitySymbol(activity.kind))
        Spacer()
        Label(
          activityStatus(activity.status),
          systemImage: succeeded ? "checkmark.circle" : "exclamationmark.triangle"
        )
        .foregroundStyle(succeeded ? Color.secondary : Color.orange)
        Text(activity.occurredAt.formatted())
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func activitySymbol(_ kind: ActivityKind) -> String {
    switch kind {
    case .cleanup: "trash"
    case .command: "terminal"
    case .restore: "arrow.uturn.backward"
    case .trace: "scope"
    case .migration: "arrow.triangle.2.circlepath"
    case .export: "square.and.arrow.up"
    }
  }

  private func activityStatus(_ status: ActivityStatus) -> String {
    switch status {
    case .started: L10n.text("Started")
    case .succeeded: L10n.text("Succeeded")
    case .failed: L10n.text("Failed")
    case .cancelled: L10n.text("Cancelled")
    }
  }
}
