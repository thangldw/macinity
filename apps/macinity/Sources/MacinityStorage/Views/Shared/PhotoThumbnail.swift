import AppKit
import ImageIO
import SwiftUI

/// Decodes a downsampled thumbnail off the main thread; never loads the full-size image.
struct PhotoThumbnail: View {
  let url: URL
  let maxPixel: Int
  @State private var image: NSImage?

  var body: some View {
    ZStack {
      Rectangle().fill(.quaternary)
      if let image {
        Image(nsImage: image).resizable().scaledToFill()
      }
    }
    .clipped()
    .task(id: url) {
      let url = url
      let maxPixel = maxPixel
      let decoded = try? await CancellableWork.run(priority: .utility) { () -> CGImage? in
        guard !Task.isCancelled, let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0,
            [
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            ] as CFDictionary)
        else { return nil }
        return cgImage
      }
      if let cgImage = decoded { image = NSImage(cgImage: cgImage, size: .zero) }
    }
    .accessibilityHidden(true)
  }
}
