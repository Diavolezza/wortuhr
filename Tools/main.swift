import AppKit

// Erzeugt thumbnail.png und thumbnail@2x.png für die Systemeinstellungen:
// die Wortuhr mit den Voreinstellungen, Uhrzeit 11:55 („ES IST FÜNF VOR ZWÖLF“).
// Aufruf: makethumb <Zielordner>

_ = NSApplication.shared
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
// Größe wie bei den Apple-Bildschirmschonern: 90×58 bzw. 180×116 Pixel
let size = NSSize(width: 90, height: 58)

for (scale, name) in [(1, "thumbnail.png"), (2, "thumbnail@2x.png")] {
    guard let view = WortuhrView(frame: NSRect(origin: .zero, size: size), isPreview: true),
          let layer = view.layer else {
        FileHandle.standardError.write("Ansicht konnte nicht erzeugt werden\n".data(using: .utf8)!)
        exit(1)
    }
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
