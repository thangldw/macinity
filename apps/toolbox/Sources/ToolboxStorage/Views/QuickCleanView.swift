import SwiftUI
import ToolboxCore

struct QuickCleanView: View {
  @ObservedObject var model: CleanerViewModel
  @State private var showsConfirmation = false
  @State private var showsErrors = false

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Dọn nhanh",
        subtitle: "Cache, log và dữ liệu build có thể tạo lại",
        symbol: "sparkles",
        value: ByteCount.string(model.selectedBytes),
        valueLabel: "đang được chọn"
      )
      Divider()
      List {
        Section("Hạng mục") {
          ForEach($model.rows) { $row in
            HStack(spacing: 14) {
              Toggle("", isOn: $row.isSelected).toggleStyle(.checkbox).labelsHidden().disabled(
                model.isWorking)
              Image(systemName: row.target.symbol).frame(width: 24).foregroundStyle(.blue)
              VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                  Text(L10n.text(row.target.name)).fontWeight(.medium)
                  Label(
                    L10n.text(row.target.confidence.title),
                    systemImage: row.target.confidence.symbol
                  )
                  .font(.caption2)
                  .foregroundStyle(
                    row.target.confidence == .safe
                      ? .green : row.target.confidence == .review ? .orange : .red)
                }
                Text(L10n.text(row.issue ?? row.target.detail))
                  .font(.caption)
                  .foregroundStyle(row.issue == nil ? Color.secondary : Color.red)
                Text(L10n.text(row.target.confidenceReason))
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              Text(model.hasScanned ? ByteCount.string(row.bytes) : "—").foregroundStyle(.secondary)
                .monospacedDigit()
            }
            .padding(.vertical, 6)
          }
        }
      }
      .listStyle(.inset)
      Divider()
      HStack(spacing: 12) {
        if model.isWorking { ProgressView().controlSize(.small) }
        VStack(alignment: .leading, spacing: 2) {
          Text(L10n.text(model.status)).font(.callout)
          if let summary = model.cleanupSummary {
            Text(L10n.text(summary)).font(.caption).foregroundStyle(.green)
          }
        }
        Spacer()
        Button("Quét lại") { model.scan() }.disabled(model.isWorking)
        Button("Dọn dẹp…") { showsConfirmation = true }
          .buttonStyle(.borderedProminent)
          .disabled(
            model.isWorking || !model.hasScanned || model.selectedCount == 0
              || model.selectedBytes == 0)
      }
      .padding(18)
    }
    .alert("Xác nhận dọn dẹp", isPresented: $showsConfirmation) {
      Button("Hủy", role: .cancel) {}
      Button("Dọn dẹp", role: .destructive) { model.cleanSelected() }
    } message: {
      Text(
        "Chuyển khoảng \(ByteCount.string(model.selectedBytes)) từ \(model.selectedCount) hạng mục vào Trash. Dọn chính Trash sẽ xóa vĩnh viễn nội dung và thực sự giải phóng dung lượng."
      )
    }
    .alert("Một số mục không thể xóa", isPresented: $showsErrors) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(L10n.text(model.errorDetails ?? ""))
    }
    .onChange(of: model.errorDetails) { showsErrors = $0 != nil }
  }
}
