import MacinityCore
import SwiftUI

struct NearDuplicatePhotosView: View {
  @ObservedObject var model: NearDuplicatePhotoViewModel
  @State private var confirmsTrash = false
  @State private var comparison: PhotoComparison?

  var body: some View {
    VStack(spacing: 0) {
      PageHeader(
        title: "Ảnh giống nhau", subtitle: model.rootURL.path, symbol: "photo.stack",
        value: ByteCount.string(model.bytesFreed), valueLabel: "đã chọn")
      Divider()
      if model.groups.isEmpty {
        EmptyStateView(
          title: "Chưa có nhóm ảnh tương tự", symbol: "photo.stack",
          detail: model.hasScanned
            ? "Không có nhóm nào ở mức giống này. Hãy hạ thanh trượt hoặc quét thư mục khác."
            : "Quét thư mục để tìm ảnh trùng lặp hoặc rất giống nhau, kể cả ảnh đã đổi kích thước hoặc nén lại."
        )
      } else {
        List {
          ForEach(model.groups) { group in
            Section(header: header(for: group)) {
              ForEach(group.photos) { photo in
                row(photo, in: group)
              }
            }
          }
        }.listStyle(.inset)
      }
      Divider()
      controls
    }
    .sheet(item: $comparison) { item in
      PhotoCompareSheet(comparison: item) { comparison = nil }
    }
    .alert(L10n.text("Chuyển ảnh đã chọn vào Trash?"), isPresented: $confirmsTrash) {
      Button(L10n.text("Hủy"), role: .cancel) {}
      Button(L10n.text("Chuyển vào Trash"), role: .destructive) { model.trashSelected() }
    } message: {
      Text(
        String(
          format: L10n.text(
            "Ảnh tương tự không phải bản sao tuyệt đối. Hãy kiểm tra kỹ trước khi chuyển %lld ảnh vào Trash."
          ), model.deleteCount))
    }
  }

  private func header(for group: SimilarPhotoGroup) -> some View {
    // `maximumDistance` is the weakest link inside the group: members are chained together and
    // may not all be that similar to each other, so the wording says "linked", not "similar".
    Text(
      String(
        format: L10n.text("%lld ảnh • nối với nhau ở mức ≥ %lld%% (ước lượng) • giải phóng %@"),
        group.photos.count,
        Int(((1 - Double(group.maximumDistance)) * 100 + 1e-4).rounded(.down)),
        ByteCount.string(group.reclaimableBytes)))
  }

  private func row(_ photo: SimilarPhoto, in group: SimilarPhotoGroup) -> some View {
    HStack(spacing: 12) {
      PhotoThumbnail(url: photo.url, maxPixel: 240).frame(width: 96, height: 72).cornerRadius(6)
      VStack(alignment: .leading, spacing: 3) {
        Text(photo.url.lastPathComponent).font(.callout.weight(.medium)).lineLimit(1)
        Text(photo.url.deletingLastPathComponent().path).font(.caption).foregroundStyle(.secondary)
          .lineLimit(1).truncationMode(.middle)
        Text(
          "\(photo.pixelWidth)×\(photo.pixelHeight) • \(ByteCount.string(photo.bytes)) • "
            + photo.capturedAt.formatted(date: .abbreviated, time: .omitted) + " • "
            + String(
              format: L10n.text("độ nét %@"),
              photo.sharpnessScore.formatted(.number.precision(.fractionLength(1))))
        ).font(.caption2).foregroundStyle(.secondary)
        if photo.id == group.recommendedID {
          Text(keepReasonText(group.keepReason)).font(.caption2.weight(.semibold))
            .foregroundStyle(.green)
        } else if let similarity = model.similarityToKeeper(photo, in: group) {
          Text(
            String(
              format: L10n.text("Giống ảnh giữ lại: %lld%%"),
              Int((similarity * 100 + 1e-4).rounded(.down)))
          ).font(.caption2).foregroundStyle(.secondary)
        } else {
          Text(L10n.text("Chưa so sánh trực tiếp với ảnh giữ lại")).font(.caption2)
            .foregroundStyle(.orange)
        }
      }
      Spacer()
      if let kept = model.keptPhoto(for: photo, in: group) {
        Button(L10n.text("So sánh")) {
          comparison = PhotoComparison(kept: kept, other: photo)
        }.controlSize(.small)
      }
      Picker(
        "",
        selection: Binding(
          get: { model.isDeleting(photo) }, set: { model.setDelete(photo, $0) })
      ) {
        Text(L10n.text("Giữ")).tag(false)
        Text(L10n.text("Loại bỏ")).tag(true)
      }.pickerStyle(.segmented).frame(width: 150).labelsHidden()
        .disabled(model.isWorking)
    }.padding(.vertical, 2)
  }

  private func keepReasonText(_ reason: KeepReason) -> String {
    switch reason {
    case .highestResolution: L10n.text("Giữ vì độ phân giải cao nhất")
    case .sharpest: L10n.text("Giữ vì nét nhất")
    case .largestFile: L10n.text("Giữ vì dung lượng lớn nhất")
    }
  }

  private var controls: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        if model.isWorking { ProgressView().controlSize(.small) }
        Text(model.status).fixedSize(horizontal: false, vertical: true)
      }
      if let hint = model.hint {
        Text(hint).font(.caption).foregroundStyle(.orange)
      }
      if let error = model.errorMessage {
        Text(error).font(.caption).foregroundStyle(.red)
      }
      ForEach(model.trashErrors, id: \.self) { message in
        Text(message).font(.caption).foregroundStyle(.red)
      }
      if model.skippedPhotos > 0 {
        Text(
          String(
            format: L10n.text(
              "Bỏ qua %lld ảnh có dấu vân tay giống hệt nhau (ảnh phẳng hoặc trống)"),
            model.skippedPhotos)
        ).font(.caption).foregroundStyle(.orange)
      }
      if model.skippedFiles > 0 {
        Text(String(format: L10n.text("%lld ảnh không đọc được đã bị bỏ qua"), model.skippedFiles))
          .font(.caption).foregroundStyle(.secondary)
      }
      Text(
        L10n.text(
          "Độ giống là ước lượng, không phải xác suất hai ảnh trùng. Hãy xem kỹ trước khi chuyển vào Trash."
        )
      ).font(.caption).foregroundStyle(.secondary)
      HStack(spacing: 14) {
        Text(
          L10n.text("Độ giống tối thiểu") + ": \(Int((model.minimumSimilarity * 100).rounded()))%")
        Slider(
          value: Binding(
            get: { model.minimumSimilarity * 100 },
            set: { model.setMinimumSimilarity(($0 / 100 * 100).rounded() / 100) }),
          in: 80...100, step: 1
        ).frame(maxWidth: 220)
        Picker(L10n.text("Thư mục"), selection: $model.folderFilter) {
          Text(L10n.text("Tất cả thư mục")).tag(String?.none)
          ForEach(model.folders, id: \.self) { folder in
            Text(folder).tag(String?.some(folder))
          }
        }.frame(maxWidth: 320)
      }.disabled(model.isWorking || model.allGroups.isEmpty && !model.hasScanned)
      HStack {
        Text(
          String(
            format: L10n.text("Giữ %lld · Loại bỏ %lld · Giải phóng %@"), model.keepCount,
            model.deleteCount, ByteCount.string(model.bytesFreed))
        ).monospacedDigit()
        Spacer()
        Button(L10n.text("Chọn thư mục…")) { model.chooseRoot() }.disabled(model.isWorking)
        Button(L10n.text("Áp dụng đề xuất")) { model.applySuggestions() }
          .disabled(model.groups.isEmpty || model.isWorking)
        if model.isWorking && !model.isTrashing {
          Button(L10n.text("Dừng")) { model.cancel() }
        } else {
          Button(L10n.text("Quét ảnh")) { model.scan() }.disabled(model.isTrashing)
        }
        Button(L10n.text("Chuyển vào Trash…")) { confirmsTrash = true }
          .buttonStyle(.borderedProminent).disabled(model.deleteCount == 0 || model.isWorking)
      }
    }.padding(18)
  }
}
