import AppKit
import ImageIO
import UniformTypeIdentifiers

// Renders the README images with the real screen saver view (default settings, German):
//   docs/wortuhr.png         1280×800, 11:58 – three minute edges lit
//   docs/wortuhr.gif         400×400, 3:00 to 3:15 minute by minute, with cross-fades
//   docs/social-preview.png  1280×640, clock and title for the GitHub link preview
// Usage: makedocs <output folder>   (called by ./build.sh --docs)

_ = NSApplication.shared
let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs")
let space = CGColorSpace(name: CGColorSpace.sRGB)!

/// The clock at a fixed time as an image (pixels = points × scale).
func clock(_ size: NSSize, _ h: Int, _ m: Int, scale: CGFloat = 2) -> CGImage {
    guard let view = WortuhrView(frame: NSRect(origin: .zero, size: size), isPreview: true),
          let layer = view.layer else { fatalError("Could not create the view") }
    var settings = Settings()
    settings.language = .de
    view.settings = settings
    view.fixedTime = (h, m)
    view.prepareSnapshot(scale: scale)
    let ctx = bitmap(Int(size.width * scale), Int(size.height * scale))
    ctx.scaleBy(x: scale, y: scale)
    layer.render(in: ctx)
    return ctx.makeImage()!
}

func bitmap(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func writePNG(_ image: CGImage, _ name: String) {
    let url = outDir.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Could not write \(name)") }
    print("✓ \(url.path)")
}

// 1. Still image
writePNG(clock(NSSize(width: 640, height: 400), 11, 58), "wortuhr.png")

// 2. Animation: each minute is held, the change to the next one is cross-faded
let side = NSSize(width: 400, height: 400)
let times = (0...15).map { (3, $0) }
let stills = times.map { clock(side, $0.0, $0.1, scale: 1) }
var frames: [(CGImage, Double)] = []
for (i, still) in stills.enumerated() {
    frames.append((still, 0.9))
    let next = stills[(i + 1) % stills.count]
    for step in 1...4 {
        let ctx = bitmap(still.width, still.height)
        let r = CGRect(x: 0, y: 0, width: still.width, height: still.height)
        ctx.draw(still, in: r)
        ctx.setAlpha(CGFloat(step) / 5)
        ctx.draw(next, in: r)
        frames.append((ctx.makeImage()!, 0.06))
    }
}
let gifURL = outDir.appendingPathComponent("wortuhr.gif")
let gif = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
CGImageDestinationSetProperties(gif, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
for (image, delay) in frames {
    CGImageDestinationAddImage(gif, image, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]] as CFDictionary)
}
guard CGImageDestinationFinalize(gif) else { fatalError("Could not write wortuhr.gif") }
print("✓ \(gifURL.path)")

// 3. Social preview: clock on the left, title on the right
let pw = 1280, ph = 640
let ctx = bitmap(pw, ph)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fill(CGRect(x: 0, y: 0, width: pw, height: ph))
let face = clock(NSSize(width: 320, height: 320), 11, 58)          // 640×640 pixels
ctx.draw(face, in: CGRect(x: 0, y: 0, width: 640, height: 640))
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
func text(_ s: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, y: CGFloat) {
    let font = NSFontManager.shared.font(withFamily: "Avenir Next", traits: [], weight: weight == .medium ? 7 : 5, size: size)
        ?? NSFont.systemFont(ofSize: size, weight: weight)
    NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color]).draw(at: NSPoint(x: 660, y: y))
}
let lit = NSColor(hex: "#fff1d6")
text("Wortuhr", size: 96, weight: .medium, color: lit, y: 350)
text("Word clock screen saver for macOS", size: 36, weight: .regular, color: NSColor(white: 0.85, alpha: 1), y: 285)
text("8 languages · free & open source", size: 28, weight: .regular, color: NSColor(white: 0.55, alpha: 1), y: 230)
NSGraphicsContext.current = nil
writePNG(ctx.makeImage()!, "social-preview.png")
