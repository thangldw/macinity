import MacinityCore
import SwiftUI

struct PhotoComparison: Identifiable {
  let id = UUID()
  let kept: SimilarPhoto
  let other: SimilarPhoto
}

struct PhotoCompareSheet: View {
  let comparison: PhotoComparison
  let close: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .top, spacing: 16) {
        side(L10n.text("Ảnh đề xuất giữ"), comparison.kept)
        side(L10n.text("Ảnh đang chọn"), comparison.other)
      }
      Button(L10n.text("Đóng"), action: close).keyboardShortcut(.cancelAction)
    }.padding(20).frame(minWidth: 900, minHeight: 560)
  }

  private func side(_ title: String, _ photo: SimilarPhoto) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.headline)
      PhotoThumbnail(url: photo.url, maxPixel: 1_000)
        .frame(maxWidth: .infinity, minHeight: 380, maxHeight: 420)
        .cornerRadius(8)
      Text(photo.url.lastPathComponent).font(.callout.weight(.medium))
      Text(photo.url.deletingLastPathComponent().path).font(.caption).foregroundStyle(.secondary)
        .lineLimit(1).truncationMode(.middle)
      Text("\(photo.pixelWidth)×\(photo.pixelHeight) • \(ByteCount.string(photo.bytes))")
        .font(.caption)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}
