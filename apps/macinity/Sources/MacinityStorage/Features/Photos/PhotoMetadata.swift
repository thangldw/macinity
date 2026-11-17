import CoreGraphics
import Foundation
import ImageIO

enum PhotoMetadata {
  static func read(url: URL, fallback: Date) -> (date: Date, width: Int, height: Int) {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
    else { return (fallback, 0, 0) }
    let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
    let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
    guard let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
      let value = exif[kCGImagePropertyExifDateTimeOriginal] as? String
    else { return (fallback, width, height) }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return (formatter.date(from: value) ?? fallback, width, height)
  }

  static func sharpness(at url: URL) -> Double {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceThumbnailMaxPixelSize: 96,
        ] as CFDictionary)
    else { return 0 }
    let width = image.width
    let height = image.height
    guard width > 1, height > 1 else { return 0 }
    var pixels = [UInt8](repeating: 0, count: width * height)
    let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
          bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
          bitmapInfo: CGImageAlphaInfo.none.rawValue)
      else { return false }
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard rendered else { return 0 }
    var difference = 0.0
    var comparisons = 0
    for y in 0..<height {
      for x in 0..<width {
        let value = Int(pixels[y * width + x])
        if x + 1 < width {
          difference += Double(abs(value - Int(pixels[y * width + x + 1])))
          comparisons += 1
        }
        if y + 1 < height {
          difference += Double(abs(value - Int(pixels[(y + 1) * width + x])))
          comparisons += 1
        }
      }
    }
    return comparisons > 0 ? difference / Double(comparisons) : 0
  }
}
