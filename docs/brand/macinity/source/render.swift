import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let root = CommandLine.arguments[1]
let object = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: root + "/source/mark.json"))) as! [String: Any]
let paths = object["paths"] as! [[[Any]]]
let mark = CGMutablePath()
for commands in paths {
    for command in commands {
        func n(_ index: Int) -> CGFloat { (command[index] as! NSNumber).doubleValue }
        switch command[0] as! String {
        case "M": mark.move(to: CGPoint(x: n(1), y: n(2)))
        case "L": mark.addLine(to: CGPoint(x: n(1), y: n(2)))
        case "Q": mark.addQuadCurve(to: CGPoint(x: n(3), y: n(4)), control: CGPoint(x: n(1), y: n(2)))
        default: mark.closeSubpath()
        }
    }
}
let space = CGColorSpace(name: CGColorSpace.sRGB)!
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r / 255, g / 255, b / 255, a])!
}
func gradient(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: locations)!
}
func render(_ pixels: Int, _ kind: String, _ filename: String) throws {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: pixels * 4,
                        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(pixels))
    ctx.scaleBy(x: CGFloat(pixels) / 512, y: -CGFloat(pixels) / 512)
    ctx.setAllowsAntialiasing(true)
    if kind == "icon" {
        let tile = CGPath(roundedRect: CGRect(x: 24, y: 24, width: 464, height: 464), cornerWidth: 104, cornerHeight: 104, transform: nil)
        ctx.saveGState()
        ctx.addPath(tile); ctx.clip()
        ctx.drawLinearGradient(gradient([color(48,59,75), color(16,21,29)], [0,1]), start: CGPoint(x: 256,y: 24), end: CGPoint(x:256,y:488), options: [])
        ctx.restoreGState()
        ctx.addPath(tile); ctx.setStrokeColor(color(96,112,132,0.5)); ctx.setLineWidth(2); ctx.strokePath()
        ctx.translateBy(x: 102.4, y: 102.4); ctx.scaleBy(x: 1.2, y: 1.2)
        ctx.saveGState(); ctx.addPath(mark); ctx.clip()
        ctx.drawLinearGradient(gradient([color(120,185,255),color(65,105,245),color(39,84,229)], [0,0.38,1]), start: CGPoint(x: 64,y: 29), end: CGPoint(x: 128,y:227), options: [.drawsBeforeStartLocation,.drawsAfterEndLocation])
        ctx.restoreGState()
        ctx.addPath(mark); ctx.setStrokeColor(color(165,204,255,0.55)); ctx.setLineWidth(1); ctx.strokePath()
    } else {
        ctx.scaleBy(x: 2, y: 2)
        ctx.addPath(mark)
        ctx.setFillColor(kind == "white" ? color(255,255,255) : kind == "cobalt" ? color(65,105,245) : color(0,0,0))
        ctx.fillPath()
    }
    let image = ctx.makeImage()!
    let url = URL(fileURLWithPath: root + "/" + filename)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "PNG", code: 1) }
}
for size in [16,32,128,256,512] {
    try render(size, "icon", "Macinity.iconset/icon_\(size)x\(size).png")
    try render(size * 2, "icon", "Macinity.iconset/icon_\(size)x\(size)@2x.png")
}
try render(1024, "icon", "assets/app-icon-1024.png")
for kind in ["cobalt","black","white"] { try render(1024, kind, "assets/mark-\(kind)-1024.png") }
for size in [16,18,20,22] {
    for scale in [1,2] {
        try render(size * scale, "black", "assets/menu-\(size)pt\(scale == 2 ? "@2x" : "").png")
    }
}
