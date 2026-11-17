import CoreGraphics
import Foundation
import ImageIO

/// 64-bit difference hash: robust to resizing, recompression and format conversion.
enum PhotoFingerprint {
  /// `gray9x8` is 9 columns by 8 rows, row-major. Bit `row * 8 + column` is set when a pixel is
  /// darker than its right-hand neighbour.
  static func dHash(gray9x8: [UInt8]) -> UInt64 {
    precondition(gray9x8.count == 72, "dHash expects a 9x8 grayscale image")
    var hash: UInt64 = 0
    for row in 0..<8 {
      for column in 0..<8 where gray9x8[row * 9 + column] < gray9x8[row * 9 + column + 1] {
        hash |= 1 << UInt64(row * 8 + column)
      }
    }
    return hash
  }

  static func hamming(_ first: UInt64, _ second: UInt64) -> Int {
    (first ^ second).nonzeroBitCount
  }

  /// Returns nil when the image cannot be decoded. EXIF orientation is applied.
  static func dHash(of url: URL) -> UInt64? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let thumbnail = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: 64,
        ] as CFDictionary)
    else { return nil }
    var pixels = [UInt8](repeating: 0, count: 72)
    let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: 9, height: 8, bitsPerComponent: 8, bytesPerRow: 9,
          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
      else { return false }
      context.interpolationQuality = .high
      context.draw(thumbnail, in: CGRect(x: 0, y: 0, width: 9, height: 8))
      return true
    }
    return drawn ? dHash(gray9x8: pixels) : nil
  }
}
