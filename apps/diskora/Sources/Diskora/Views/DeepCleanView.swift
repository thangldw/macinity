import SwiftUI

struct DeepCleanView: View {
  @ObservedObject var model: DeepCleanViewModel
  @State private var confirms = false
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Dọn chuyên sâu", subtitle: "Phân loại theo mức rủi ro",
        symbol: "sparkles.rectangle.stack", value: ByteCount.string(model.selectedBytes),
        valueLabel: "đã chọn")
      Divider()
      List {
        ForEach(CleanupRisk.allCases, id: \.rawValue) { risk in
          Section(risk.rawValue) {
            ForEach($model.rows.filter { $0.wrappedValue.definition.risk == risk }) { $row in
              HStack {
                Toggle("", isOn: $row.selected).toggleStyle(.checkbox).labelsHidden().disabled(
                  risk == .dangerous || model.isWorking)
                Image(systemName: risk.symbol).foregroundStyle(
                  risk == .safe ? .green : risk == .review ? .orange : .red)
                VStack(alignment: .leading) {
                  Text(row.definition.name).fontWeight(.medium)
                  Text(row.definition.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(ByteCount.string(row.bytes)).monospacedDigit()
              }.padding(.vertical, 5)
            }
          }
        }
      }.listStyle(.inset)
      Divider()
      HStack {
        if model.isWorking { ProgressView().controlSize(.small) }
        Text(model.status)
        Spacer()
        Button("Quét chuyên sâu") { model.scan() }.disabled(model.isWorking)
        Button("Dọn mục đã chọn…") { confirms = true }.buttonStyle(.borderedProminent).disabled(
          model.selectedBytes == 0 || model.isWorking)
      }.padding(18)
    }.alert("Xác nhận dọn chuyên sâu", isPresented: $confirms) {
      Button("Hủy", role: .cancel) {}
      Button("Dọn dẹp", role: .destructive) { model.cleanSelected() }
    } message: {
      Text(
        "Mục 'Cần xem lại' có thể phải tải hoặc tạo lại. Các mục nguy hiểm không bao giờ được xóa tự động."
      )
    }
  }
}
