import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Synthetic images for photo-similarity tests.
enum PhotoFixtures {
  static func context(width: Int, height: Int) -> CGContext {
    CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  }

  /// Horizontal gradient with a dark rectangle and a bright disc: structured, asymmetric.
  static func structured(width: Int = 400, height: Int = 300) -> CGImage {
    let ctx = context(width: width, height: height)
    let space = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
      colorsSpace: space,
      colors: [
        CGColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 1),
        CGColor(red: 0.9, green: 0.8, blue: 0.3, alpha: 1),
      ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
      gradient, start: .zero, end: CGPoint(x: width, y: 0), options: [])
    ctx.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1))
    ctx.fill(CGRect(x: width / 10, y: height / 2, width: width / 4, height: height / 3))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillEllipse(
      in: CGRect(x: width * 6 / 10, y: height / 10, width: width / 4, height: width / 4))
    return ctx.makeImage()!
  }

  static func checkerboard(width: Int = 400, height: Int = 300, cell: Int = 20) -> CGImage {
    let ctx = context(width: width, height: height)
    for row in 0..<(height / cell + 1) {
      for column in 0..<(width / cell + 1) {
        let dark = (row + column) % 2 == 0
        ctx.setFillColor(CGColor(gray: dark ? 0.05 : 0.95, alpha: 1))
        ctx.fill(CGRect(x: column * cell, y: row * cell, width: cell, height: cell))
      }
    }
    return ctx.makeImage()!
  }

  static func solid(gray: CGFloat, width: Int = 200, height: Int = 150) -> CGImage {
    let ctx = context(width: width, height: height)
    ctx.setFillColor(CGColor(gray: gray, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return ctx.makeImage()!
  }

  static func resized(_ image: CGImage, width: Int, height: Int) -> CGImage {
    let ctx = context(width: width, height: height)
    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return ctx.makeImage()!
  }

  /// Pixels rotated 90 degrees counter-clockwise; with EXIF orientation 6 it displays upright.
  static func rotatedCounterClockwise(_ image: CGImage) -> CGImage {
    let ctx = context(width: image.height, height: image.width)
    ctx.translateBy(x: CGFloat(image.height), y: 0)
    ctx.rotate(by: .pi / 2)
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return ctx.makeImage()!
  }

  @discardableResult
  static func write(
    _ image: CGImage, to url: URL, type: UTType = .png, orientation: Int? = nil
  ) -> URL {
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)!
    var properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 1.0]
    if let orientation { properties[kCGImagePropertyOrientation] = orientation }
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)
    CGImageDestinationFinalize(destination)
    return url
  }

  static func temporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}
