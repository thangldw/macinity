import SwiftUI

struct DeveloperStorageView: View {
  @ObservedObject var model: AnalyzerViewModel
  @StateObject private var runtimes = DeveloperRuntimeViewModel()
  @State private var runtimeToTrash: RuntimeVersion?

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
        !snapshot.developerData.isEmpty || !runtimes.versions.isEmpty
      {
        List {
          Section("Tổng quan") {
            ForEach(snapshot.developerData) { item in
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Image(systemName: "terminal").foregroundStyle(.purple).frame(width: 24)
                  VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).fontWeight(.semibold)
                    Text(item.detail).font(.caption).foregroundStyle(.secondary)
                  }
                  Spacer()
                  Text(ByteCount.string(item.bytes)).monospacedDigit()
                  Button("Finder") { model.reveal(item.url) }
                }
                Label(item.safetyNote, systemImage: "exclamationmark.shield")
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
                      runtime.isReferenced
                        ? "Được tham chiếu bởi \(runtime.referencedBy.count) dự án"
                        : "Chưa tìm thấy file cấu hình sử dụng"
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
        Text("App chỉ thống kê ở màn hình này; chưa tự động xóa runtime hoặc môi trường dev.")
          .font(.callout).foregroundStyle(.secondary)
        Spacer()
        Button("Quét thư mục người dùng") {
          model.rootURL = FileManager.default.homeDirectoryForCurrentUser
          model.scan()
          runtimes.scan()
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
  }

  private var developerTotal: String {
    guard let data = model.snapshot?.developerData else { return "—" }
    return ByteCount.string(data.reduce(Int64(0)) { $0 + $1.bytes })
  }
}
