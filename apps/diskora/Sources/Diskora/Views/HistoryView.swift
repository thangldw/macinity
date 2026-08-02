import SwiftUI

struct HistoryView: View {
  @ObservedObject var model: HistoryViewModel
  @State private var entryToRestore: CleanupHistoryEntry?
  @State private var showsError = false
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Undo Center", subtitle: "Lịch sử, vị trí Trash và khôi phục có kiểm tra xung đột",
        symbol: "arrow.uturn.backward.circle", value: model.entries.count.formatted(),
        valueLabel: "thao tác")
      Divider()
      if model.entries.isEmpty {
        EmptyStateView(
          title: "Chưa có lịch sử", symbol: "clock",
          detail: "Các thao tác dọn dẹp và gỡ ứng dụng sẽ xuất hiện tại đây.")
      } else {
        List(model.entries) { entry in
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
        }.listStyle(.inset)
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
}
