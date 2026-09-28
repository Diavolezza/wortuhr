import AppKit

// Creates thumbnail.png and thumbnail@2x.png for System Settings:
// the word clock with default settings at 11:55 ("ES IST FÜNF VOR ZWÖLF").
// Usage: makethumb <output folder>

_ = NSApplication.shared
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
// Same size as Apple's screen savers: 90×58 and 180×116 pixels
let size = NSSize(width: 90, height: 58)

for (scale, name) in [(1, "thumbnail.png"), (2, "thumbnail@2x.png")] {
    guard let view = WortuhrView(frame: NSRect(origin: .zero, size: size), isPreview: true),
          let layer = view.layer else {
        FileHandle.standardError.write("Could not create the view\n".data(using: .utf8)!)
        exit(1)
    }
    // Fixed defaults in German – independent of the builder's saved settings and system language
    var settings = Settings()
    settings.language = .de
    view.settings = settings
    view.fixedTime = (11, 55)
    view.prepareSnapshot(scale: CGFloat(scale))

    let w = Int(size.width) * scale, h = Int(size.height) * scale
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let gc = NSGraphicsContext(bitmapImageRep: rep) else { exit(1) }
    let ctx = gc.cgContext
    ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    layer.render(in: ctx)

    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
    try png.write(to: url)
    print("✓ \(url.path)")
}
