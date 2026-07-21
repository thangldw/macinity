import SwiftUI

struct StorageAnalyzerView: View {
  @ObservedObject var model: AnalyzerViewModel
  @State private var showsError = false

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Phân tích dung lượng",
        subtitle: model.rootURL.path,
        symbol: "internaldrive",
        value: model.snapshot.map { ByteCount.string($0.scannedBytes) } ?? "—",
        valueLabel: "đã phân tích"
      )
      Divider()
      if let snapshot = model.snapshot {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            summary(snapshot)
            TreemapView(entries: snapshot.topFolders)
              .frame(height: 210)
            if !model.folderDeltas.isEmpty {
              deltaSection
            }
            categorySection(snapshot)
            entrySection("Thư mục lớn nhất", entries: snapshot.topFolders)
            entrySection("Tệp lớn trên 100 MB", entries: snapshot.largeFiles)
          }
          .padding(24)
        }
      } else {
        EmptyStateView(
          title: "Chưa có dữ liệu phân tích",
          symbol: "chart.pie",
          detail:
            "Quét thư mục người dùng hoặc chọn một ổ đĩa khác để tìm nơi đang chiếm dung lượng."
        )
      }
      Divider()
      HStack {
        if model.isScanning { ProgressView().controlSize(.small) }
        Text(model.status).font(.callout).lineLimit(1)
        Spacer()
        Button("Chọn vị trí…") { model.chooseRoot() }.disabled(model.isScanning)
        if model.isScanning {
          Button("Dừng") { model.cancel() }
        } else {
          Button("Quét dung lượng") { model.scan() }.buttonStyle(.borderedProminent)
        }
      }
      .padding(18)
    }
    .alert("Không thể phân tích", isPresented: $showsError) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(model.errorMessage ?? "")
    }
    .onChange(of: model.errorMessage) { showsError = $0 != nil }
  }

  private var deltaSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Thay đổi từ lần quét trước").font(.title2).fontWeight(.semibold)
      ForEach(model.folderDeltas.prefix(10)) { delta in
        HStack {
          Image(systemName: delta.bytes > 0 ? "arrow.up.right" : "arrow.down.right")
            .foregroundStyle(delta.bytes > 0 ? .orange : .green)
          Text(URL(fileURLWithPath: delta.path).lastPathComponent)
          Spacer()
          Text((delta.bytes > 0 ? "+" : "−") + ByteCount.string(abs(delta.bytes))).monospacedDigit()
        }
      }
    }
  }

  private func summary(_ snapshot: StorageSnapshot) -> some View {
    HStack(spacing: 12) {
      MetricCard(title: "Tệp đã quét", value: snapshot.fileCount.formatted(), symbol: "doc.on.doc")
      MetricCard(
        title: "Dung lượng", value: ByteCount.string(snapshot.scannedBytes), symbol: "internaldrive"
      )
      MetricCard(
        title: "Không thể đọc", value: snapshot.inaccessibleCount.formatted(), symbol: "lock")
    }
  }

  private func categorySection(_ snapshot: StorageSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Phân loại dữ liệu").font(.title2).fontWeight(.semibold)
      ForEach(snapshot.categories) { usage in
        HStack(spacing: 10) {
          Image(systemName: usage.category.symbol).frame(width: 22).foregroundStyle(.blue)
          Text(usage.category.rawValue).frame(width: 100, alignment: .leading)
          ProgressView(value: Double(usage.bytes), total: Double(max(snapshot.scannedBytes, 1)))
          Text(ByteCount.string(usage.bytes)).frame(width: 90, alignment: .trailing)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func entrySection(_ title: String, entries: [StorageEntry]) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title).font(.title2).fontWeight(.semibold)
      if entries.isEmpty {
        Text("Không tìm thấy mục phù hợp.").foregroundStyle(.secondary)
      } else {
        ForEach(entries.prefix(30)) { entry in
          HStack(spacing: 10) {
            Image(systemName: entry.url.hasDirectoryPath ? "folder" : "doc").foregroundStyle(.blue)
              .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
              Text(entry.name).lineLimit(1)
              Text(entry.url.deletingLastPathComponent().path).font(.caption).foregroundStyle(
                .secondary
              ).lineLimit(1)
            }
            Spacer()
            Text(ByteCount.string(entry.bytes)).monospacedDigit().foregroundStyle(.secondary)
            Button {
              model.reveal(entry.url)
            } label: {
              Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderless).help("Hiển thị trong Finder")
          }
          .padding(.vertical, 4)
          Divider()
        }
      }
    }
  }
}
