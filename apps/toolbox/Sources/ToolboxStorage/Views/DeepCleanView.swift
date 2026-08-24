import SwiftUI
import ToolboxCore

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
        ForEach(CleanupConfidence.allCases, id: \.rawValue) { confidence in
          Section(confidence.title) {
            ForEach(
              $model.rows.filter { $0.wrappedValue.definition.confidence == confidence }
            ) { $row in
              HStack {
                Toggle("", isOn: $row.selected).toggleStyle(.checkbox).labelsHidden().disabled(
                  confidence == .dangerous || model.isWorking)
                Image(systemName: confidence.symbol).foregroundStyle(
                  confidence == .safe ? .green : confidence == .review ? .orange : .red)
                VStack(alignment: .leading) {
                  Text(L10n.text(row.definition.name)).fontWeight(.medium)
                  Text(L10n.text(row.definition.detail)).font(.caption).foregroundStyle(.secondary)
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
        Text(L10n.text(model.status))
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
        "Nội dung sẽ được chuyển vào Trash. Mục 'Cần xem lại' có thể phải tải hoặc tạo lại; các mục nguy hiểm không bao giờ được dọn tự động."
      )
    }
  }
}
