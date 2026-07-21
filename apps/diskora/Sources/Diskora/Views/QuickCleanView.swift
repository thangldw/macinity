import SwiftUI

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
                Text(row.target.name).fontWeight(.medium)
                Text(row.issue ?? row.target.detail)
                  .font(.caption)
                  .foregroundStyle(row.issue == nil ? Color.secondary : Color.red)
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
          Text(model.status).font(.callout)
          if let summary = model.cleanupSummary {
            Text(summary).font(.caption).foregroundStyle(.green)
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
        "Xóa nội dung của \(model.selectedCount) hạng mục và giải phóng khoảng \(ByteCount.string(model.selectedBytes)). Thao tác này không thể hoàn tác."
      )
    }
    .alert("Một số mục không thể xóa", isPresented: $showsErrors) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(model.errorDetails ?? "")
    }
    .onChange(of: model.errorDetails) { showsErrors = $0 != nil }
  }
}
