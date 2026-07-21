import SwiftUI

struct HistoryView: View {
  @ObservedObject var model: HistoryViewModel
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Lịch sử", subtitle: "Nhật ký dọn dẹp và khả năng khôi phục",
        symbol: "clock.arrow.circlepath", value: model.entries.count.formatted(),
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
            Text(entry.note).font(.caption).foregroundStyle(.secondary)
          } label: {
            HStack {
              Image(systemName: entry.recoverable ? "trash" : "eraser").foregroundStyle(
                entry.recoverable ? .blue : .orange)
              VStack(alignment: .leading) {
                Text(entry.action).fontWeight(.medium)
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
        Text("Mục có biểu tượng Trash có thể được khôi phục thủ công từ Trash.").font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Mở Trash") {
          NSWorkspace.shared.open(
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash"))
        }
        Button("Làm mới") { model.refresh() }
      }.padding(18)
    }.onAppear { model.refresh() }
  }
}
