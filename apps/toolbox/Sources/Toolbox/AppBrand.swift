import AppKit

@MainActor
enum AppBrand {
  static let logo: NSImage = {
    guard let url = Bundle.main.url(forResource: "MacinityLogo", withExtension: "png"),
      let image = NSImage(contentsOf: url)
    else { return NSImage(named: NSImage.applicationIconName) ?? NSImage() }
    return image
  }()

  static let menuIcon: NSImage = {
    let image: NSImage
    if let url = Bundle.main.url(forResource: "MacinityMenuTemplate", withExtension: "png"),
      let loaded = NSImage(contentsOf: url)
    {
      image = loaded
      if let retinaURL = Bundle.main.url(
        forResource: "MacinityMenuTemplate@2x", withExtension: "png"),
        let data = try? Data(contentsOf: retinaURL),
        let representation = NSBitmapImageRep(data: data)
      {
        representation.size = NSSize(width: 18, height: 18)
        image.addRepresentation(representation)
      }
    } else {
      image =
        NSImage(systemSymbolName: "m.square", accessibilityDescription: "Macinity") ?? NSImage()
    }
    image.size = NSSize(width: 18, height: 18)
    image.isTemplate = true
    return image
  }()
}
