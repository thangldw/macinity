import SwiftUI

struct SimilarPhotosView: View {
  @ObservedObject var model: SimilarPhotoViewModel
  @State private var confirmsTrash = false
  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Ảnh tương tự", subtitle: model.rootURL.path, symbol: "photo.stack",
        value: ByteCount.string(model.selectedBytes), valueLabel: "đã chọn")
      Divider()
      if let snapshot = model.snapshot, !snapshot.groups.isEmpty {
        List {
          ForEach(snapshot.groups) { group in
            Section(
              "\(group.photos.count) ảnh • tương đồng \(Int((1 - group.maximumDistance) * 100))%"
            ) {
              ScrollView(.horizontal) {
                HStack {
                  ForEach(group.photos) { photo in
                    VStack(alignment: .leading, spacing: 5) {
                      ZStack(alignment: .topTrailing) {
                        Image(nsImage: NSImage(contentsOf: photo.url) ?? NSImage()).resizable()
                          .scaledToFill().frame(width: 150, height: 105).clipped().cornerRadius(8)
                        if photo.id == group.recommendedID {
                          Text("GIỮ").font(.caption2).bold().padding(4).background(.green)
                            .foregroundStyle(.white).cornerRadius(4).padding(5)
                        }
                      }
                      Toggle(photo.url.lastPathComponent, isOn: model.toggle(photo)).toggleStyle(
                        .checkbox
                      ).frame(width: 150, alignment: .leading).disabled(
                        photo.id == group.recommendedID)
                      Text(ByteCount.string(photo.bytes)).font(.caption).foregroundStyle(.secondary)
                    }.onTapGesture { model.reveal(photo.url) }
                  }
                }
              }
            }
          }
        }.listStyle(.inset)
      } else {
        EmptyStateView(
          title: "Chưa có nhóm ảnh tương tự", symbol: "photo.stack",
          detail:
            "Vision so sánh ảnh chụp gần nhau trong cùng thư mục; ảnh được đề xuất giữ dựa trên chất lượng tệp cao hơn."
        )
      }
      Divider()
      HStack {
        if model.isWorking { ProgressView().controlSize(.small) }
        Text(model.status)
        Spacer()
        Button("Chọn thư mục…") { model.chooseRoot() }.disabled(model.isWorking)
        Button("Chọn ảnh đề xuất loại") { model.selectSuggestions() }.disabled(
          model.snapshot == nil || model.isWorking)
        if model.isWorking {
          Button("Dừng") { model.cancel() }
        } else {
          Button("Quét ảnh") { model.scan() }
        }
        Button("Chuyển vào Trash…") { confirmsTrash = true }.buttonStyle(.borderedProminent)
          .disabled(model.selectedPaths.isEmpty || model.isWorking)
      }.padding(18)
    }
    .alert("Chuyển ảnh đã chọn vào Trash?", isPresented: $confirmsTrash) {
      Button("Hủy", role: .cancel) {}
      Button("Chuyển vào Trash", role: .destructive) { model.trashSelected() }
    } message: {
      Text(
        "Ảnh tương tự không phải bản sao tuyệt đối. Hãy kiểm tra kỹ trước khi chuyển \(model.selectedPaths.count) ảnh vào Trash."
      )
    }
  }
}
