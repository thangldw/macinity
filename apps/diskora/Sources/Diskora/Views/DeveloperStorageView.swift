import SwiftUI

struct DeveloperStorageView: View {
  @ObservedObject var model: AnalyzerViewModel
  @StateObject private var runtimes = DeveloperRuntimeViewModel()
  @StateObject private var cleanup = DeveloperCleanupViewModel()
  @State private var runtimeToTrash: RuntimeVersion?
  @State private var actionToRun: DeveloperCleanupAction?
  @State private var showsCleanupError = false

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Developer",
        subtitle: "SDK, runtime, simulator và môi trường lập trình",
        symbol: "hammer",
        value: developerTotal,
        valueLabel: "đã nhận diện"
      )
      Divider()
      if let snapshot = model.snapshot,
        !snapshot.developerData.isEmpty || !runtimes.versions.isEmpty || !cleanup.actions.isEmpty
      {
        List {
          Section("Tổng quan") {
            ForEach(snapshot.developerData) { item in
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Image(systemName: "terminal").foregroundStyle(.purple).frame(width: 24)
                  VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).fontWeight(.semibold)
                    Text(L10n.text(item.detail)).font(.caption).foregroundStyle(.secondary)
                  }
                  Spacer()
                  Text(ByteCount.string(item.bytes)).monospacedDigit()
                  Button("Finder") { model.reveal(item.url) }
                }
                Label(L10n.text(item.safetyNote), systemImage: "exclamationmark.shield")
                  .font(.caption).foregroundStyle(.orange)
              }
              .padding(.vertical, 8)
            }
          }
          if !runtimes.versions.isEmpty {
            Section("Phiên bản runtime") {
              ForEach(runtimes.versions) { runtime in
                HStack {
                  Image(
                    systemName: runtime.isReferenced
                      ? "checkmark.shield.fill" : "questionmark.folder"
                  )
                  .foregroundStyle(runtime.isReferenced ? .green : .orange)
                  VStack(alignment: .leading) {
                    Text("\(runtime.tool) \(runtime.version)").fontWeight(.medium)
                    Text(
                      L10n.text(
                        runtime.isReferenced
                          ? "Được tham chiếu bởi \(runtime.referencedBy.count) dự án"
                          : "Chưa tìm thấy file cấu hình sử dụng"
                      )
                    )
                    .font(.caption).foregroundStyle(.secondary)
                  }
                  Spacer()
                  Text(ByteCount.string(runtime.bytes))
                  Button("Trash…") { runtimeToTrash = runtime }.disabled(runtime.isReferenced)
                }
              }
            }
          }
          if !cleanup.actions.isEmpty {
            Section("Dọn bằng công cụ chính thức") {
              ForEach(cleanup.actions) { action in
                HStack {
                  Image(systemName: action.confidence.symbol).foregroundStyle(
                    action.confidence == .safe
                      ? .green : action.confidence == .review ? .orange : .red)
                  VStack(alignment: .leading, spacing: 3) {
                    Text(action.tool.rawValue).fontWeight(.medium)
                    Text(L10n.text(action.detail)).font(.caption).foregroundStyle(.secondary)
                    Text(action.commandPreview).font(.caption2).monospaced().textSelection(.enabled)
                  }
                  Spacer()
                  Text(ByteCount.string(action.estimatedBytes)).foregroundStyle(.secondary)
                  Button("Chạy…") { actionToRun = action }.disabled(cleanup.isWorking)
                }
              }
            }
          }
        }
        .listStyle(.inset)
      } else {
        EmptyStateView(
          title: "Chưa nhận diện dữ liệu Developer",
          symbol: "hammer",
          detail: "Quét thư mục người dùng ở mục Phân tích dung lượng để thống kê môi trường dev."
        )
      }
      Divider()
      HStack {
        Text("Diskora chỉ dọn sau khi xác nhận và ưu tiên command chính thức của từng công cụ.")
          .font(.callout).foregroundStyle(.secondary)
        Spacer()
        Button("Quét thư mục người dùng") {
          model.rootURL = FileManager.default.homeDirectoryForCurrentUser
          model.scan()
          runtimes.scan()
          cleanup.refresh()
        }
        .disabled(model.isScanning || runtimes.isScanning)
      }
      .padding(18)
    }
    .alert(
      "Gỡ phiên bản runtime?",
      isPresented: Binding(get: { runtimeToTrash != nil }, set: { if !$0 { runtimeToTrash = nil } })
    ) {
      Button("Hủy", role: .cancel) { runtimeToTrash = nil }
      Button("Chuyển vào Trash", role: .destructive) {
        if let runtimeToTrash { runtimes.trash(runtimeToTrash) }
        runtimeToTrash = nil
      }
    } message: {
      Text(
        "App chưa tìm thấy file cấu hình dự án tham chiếu phiên bản này. Việc quét không thể đảm bảo bao phủ mọi dự án, hãy kiểm tra trước khi tiếp tục."
      )
    }
    .alert(
      "Chạy công cụ dọn dẹp?",
      isPresented: Binding(get: { actionToRun != nil }, set: { if !$0 { actionToRun = nil } })
    ) {
      Button("Hủy", role: .cancel) { actionToRun = nil }
      Button("Chạy", role: .destructive) {
        if let actionToRun { cleanup.run(actionToRun) }
        actionToRun = nil
      }
    } message: {
      Text(
        "Diskora sẽ chạy đúng command được hiển thị từ allowlist. Command này không chuyển dữ liệu vào Trash và không thể Undo."
      )
    }
    .alert("Developer Cleanup thất bại", isPresented: $showsCleanupError) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(L10n.text(cleanup.errorMessage ?? ""))
    }
    .onAppear { cleanup.refresh() }
    .onChange(of: cleanup.errorMessage) { showsCleanupError = $0 != nil }
  }

  private var developerTotal: String {
    guard let data = model.snapshot?.developerData else { return "—" }
    return ByteCount.string(data.reduce(Int64(0)) { $0 + $1.bytes })
  }
}
