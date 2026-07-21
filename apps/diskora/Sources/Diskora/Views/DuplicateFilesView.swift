import SwiftUI

struct DuplicateFilesView: View {
  @ObservedObject var model: DuplicateViewModel
  @State private var confirmsTrash = false
  @State private var showsError = false

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Tệp trùng lặp",
        subtitle: model.rootURL.path,
        symbol: "doc.on.doc",
        value: ByteCount.string(model.selectedBytes),
        valueLabel: "đã chọn vào Trash"
      )
      Divider()
      if let snapshot = model.snapshot {
        if snapshot.groups.isEmpty {
          EmptyStateView(
            title: "Không tìm thấy tệp trùng lặp",
            symbol: "checkmark.circle",
            detail:
              "App chỉ hash các tệp từ 1 MB và bỏ qua package ứng dụng, Trash cùng cache hệ thống."
          )
        } else {
          List {
            Section {
              HStack {
                MetricCard(
                  title: "Nhóm trùng", value: snapshot.groups.count.formatted(),
                  symbol: "square.stack.3d.up")
                MetricCard(
                  title: "Có thể giải phóng", value: ByteCount.string(snapshot.reclaimableBytes),
                  symbol: "externaldrive.badge.minus")
                MetricCard(
                  title: "Tệp đã hash", value: snapshot.hashedCount.formatted(), symbol: "number")
              }
              .listRowInsets(EdgeInsets()).padding(.vertical, 8)
            }
            if !snapshot.nameWarnings.isEmpty {
              Section {
                ForEach(snapshot.nameWarnings.prefix(40)) { warning in
                  HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 3) {
                      Text(warning.first.url.lastPathComponent)
                      Text(warning.second.url.lastPathComponent)
                      Text(
                        "Tên giống \(Int(warning.similarity * 100))% • Nội dung khác nhau, không phải duplicate"
                      )
                      .font(.caption).foregroundStyle(.orange)
                    }
                    Spacer()
                    Button {
                      model.reveal(warning.first.url)
                    } label: {
                      Image(systemName: "1.magnifyingglass")
                    }
                    .buttonStyle(.borderless).help("Hiển thị tệp thứ nhất")
                    Button {
                      model.reveal(warning.second.url)
                    } label: {
                      Image(systemName: "2.magnifyingglass")
                    }
                    .buttonStyle(.borderless).help("Hiển thị tệp thứ hai")
                  }
                  .padding(.vertical, 4)
                }
              } header: {
                Text("Cảnh báo tên dễ nhầm — không được chọn để xóa")
              }
            }
            ForEach(snapshot.groups) { group in
              Section {
                ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                  HStack(spacing: 10) {
                    if index == 0 {
                      Image(systemName: "checkmark.shield.fill").foregroundStyle(.green).frame(
                        width: 18)
                    } else {
                      Toggle("", isOn: model.isSelected(file)).toggleStyle(.checkbox).labelsHidden()
                        .disabled(model.isWorking)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                      HStack {
                        Text(file.url.lastPathComponent).lineLimit(1)
                        if index == 0 {
                          Text("GIỮ LẠI").font(.caption2).fontWeight(.bold).foregroundStyle(.green)
                        }
                      }
                      Text(file.url.deletingLastPathComponent().path).font(.caption)
                        .foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    if let date = file.modifiedAt {
                      Text(date, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                      model.reveal(file.url)
                    } label: {
                      Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.borderless).help("Hiển thị trong Finder")
                  }
                  .padding(.vertical, 4)
                }
              } header: {
                HStack {
                  Text(
                    "\(group.files.count) bản giống nhau • \(ByteCount.string(group.bytesPerFile))/tệp"
                  )
                  if group.hasDifferentNames {
                    Text("TÊN KHÁC • NỘI DUNG GIỐNG HỆT").foregroundStyle(.blue)
                  }
                }
              }
            }
          }
          .listStyle(.inset)
        }
      } else {
        EmptyStateView(
          title: "Chưa quét tệp trùng lặp",
          symbol: "doc.on.doc",
          detail:
            "Các tệp cùng kích thước sẽ được xác minh bằng SHA-256. App không so sánh chỉ dựa trên tên tệp."
        )
      }
      Divider()
      VStack(spacing: 8) {
        if let summary = model.summary {
          HStack {
            Text(summary).font(.caption).foregroundStyle(.green)
            if let report = model.lastReportURL {
              Button("Mở báo cáo") { model.reveal(report) }.buttonStyle(.link)
            }
            Spacer()
          }
        }
        HStack(spacing: 10) {
          if model.isWorking { ProgressView().controlSize(.small) }
          Text(model.status).font(.callout).lineLimit(1)
          Spacer()
          Button("Chọn vị trí…") { model.chooseRoot() }.disabled(model.isWorking)
          if model.snapshot != nil {
            Button("Chọn bản sao") { model.selectRecommendedCopies() }.disabled(model.isWorking)
            Button("Bỏ chọn") { model.clearSelection() }.disabled(
              model.isWorking || model.selectedPaths.isEmpty)
          }
          if model.isWorking {
            Button("Dừng") { model.cancel() }
          } else {
            Button("Quét") { model.scan() }
          }
          Button("Chuyển vào Trash…") { confirmsTrash = true }
            .buttonStyle(.borderedProminent)
            .disabled(model.isWorking || model.selectedPaths.isEmpty)
        }
      }
      .padding(18)
    }
    .alert("Chuyển tệp trùng lặp vào Trash?", isPresented: $confirmsTrash) {
      Button("Hủy", role: .cancel) {}
      Button("Chuyển vào Trash", role: .destructive) { model.trashSelected() }
    } message: {
      Text(
        "\(model.selectedPaths.count) tệp (\(ByteCount.string(model.selectedBytes))) sẽ được chuyển vào Trash. Một bản mới nhất trong mỗi nhóm luôn được giữ lại."
      )
    }
    .alert("Một số thao tác không thành công", isPresented: $showsError) {
      Button("Đóng", role: .cancel) {}
    } message: {
      Text(model.errorMessage ?? "")
    }
    .onChange(of: model.errorMessage) { showsError = $0 != nil }
  }
}
