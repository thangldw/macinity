import SwiftUI

struct ScheduledScanView: View {
  @StateObject private var model = ScheduledScanViewModel()
  @State private var selectedHours = 24
  @State private var showsError = false

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Lịch quét", subtitle: "Quét nền và thông báo, không tự động xóa",
        symbol: "calendar.badge.clock", value: model.isEnabled ? "Bật" : "Tắt",
        valueLabel: model.isEnabled ? "mỗi \(model.intervalHours) giờ" : "không có lịch")
      Divider()
      Form {
        Section("Nguyên tắc") {
          Label("Chỉ quét các mục được phân loại An toàn", systemImage: "checkmark.shield")
          Label("Gửi notification với dung lượng cần xem xét", systemImage: "bell")
          Label("Không tự chọn, không chuyển Trash và không xóa", systemImage: "hand.raised")
        }
        Section("Tần suất") {
          Picker("Quét mỗi", selection: $selectedHours) {
            Text("6 giờ").tag(6)
            Text("12 giờ").tag(12)
            Text("24 giờ").tag(24)
            Text("7 ngày").tag(168)
          }
          .pickerStyle(.segmented)
          HStack {
            Button(L10n.text(model.isEnabled ? "Cập nhật lịch" : "Bật lịch quét")) {
              model.enable(hours: selectedHours)
            }
            .buttonStyle(.borderedProminent).disabled(model.isWorking)
            if model.isEnabled {
              Button("Tắt lịch", role: .destructive) { model.disable() }.disabled(model.isWorking)
            }
          }
        }
        if let lastRun = model.lastRun {
          Section("Lần chạy gần nhất") {
            LabeledContent("Thời gian", value: lastRun.formatted())
            LabeledContent("Dữ liệu cần xem xét", value: ByteCount.string(model.lastBytes))
          }
        }
      }
      .formStyle(.grouped)
      Divider()
      HStack {
        if model.isWorking { ProgressView().controlSize(.small) }
        Text(L10n.text(model.status)).font(.callout).foregroundStyle(.secondary)
        Spacer()
      }.padding(18)
    }
    .onAppear { selectedHours = model.isEnabled ? model.intervalHours : 24 }
    .onChange(of: model.errorMessage) { showsError = $0 != nil }
    .alert("Không thể cập nhật lịch quét", isPresented: $showsError) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(L10n.text(model.errorMessage ?? ""))
    }
  }
}
