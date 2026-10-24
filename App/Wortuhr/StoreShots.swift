#if os(macOS)
import AppKit
import SwiftUI

/// Screenshots for the App Store in the sizes Apple asks for (rendered by `./build.sh --snapshots`
/// into build/snapshots/store): iPhone 6.9" 1320 × 2868, iPad 13" 2064 × 2752, Mac 2880 × 1800.
extension Snapshots {
    @MainActor
    static func storeShots(_ dir: URL) {
        let out = dir.appendingPathComponent("store", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        func at(_ h: Int, _ m: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: h, minute: m)) ?? .now
        }
        func style(_ lang: Language, front: String = "#0e0f11", lit: String = "#fff1d6") -> ClockStyle {
            var s = ClockStyle(language: lang)
            s.front = front
            s.lit = lit
            return s
        }
        let classic = style(.de)
        let amber = style(.en, front: "#101b2c", lit: "#ffb24a")
        let chalk = style(.fr, front: "#e9e7e1", lit: "#1d1f22")
        let mint = style(.it, front: "#14261e", lit: "#9ff0c8")
        let ice = style(.es, front: "#2a2c30", lit: "#9ad7ff")

        func app(_ s: ClockStyle, _ date: Date, _ w: CGFloat, _ h: CGFloat) -> some View {
            WordClockView(style: s, date: date).frame(width: w, height: h).background(Color.black)
        }
        func widget(_ s: ClockStyle, _ date: Date, _ w: CGFloat, _ h: CGFloat, radius: CGFloat = 24) -> some View {
            let ws = s.forWidget(mono: false)
            return WordClockView(style: ws, date: date, plate: false)
                .frame(width: w, height: h)
                .background(ws.frontColor)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        }
        let wallpaper = LinearGradient(colors: [Color(red: 0.16, green: 0.20, blue: 0.36), Color(red: 0.42, green: 0.30, blue: 0.46),
                                                Color(red: 0.86, green: 0.56, blue: 0.42)],
                                       startPoint: .top, endPoint: .bottom)

        // iPhone 6.9": 440 × 956 points at 3×
        write(app(classic, at(10, 23), 440, 956), "iphone-1.png", out, scale: 3)
        write(app(amber, at(19, 32), 440, 956), "iphone-2.png", out, scale: 3)
        write(app(chalk, at(8, 16), 440, 956), "iphone-3.png", out, scale: 3)
        write(VStack(spacing: 26) {
            widget(classic, at(10, 23), 364, 382)
            HStack(spacing: 24) {
                widget(amber, at(10, 23), 170, 170)
                widget(mint, at(10, 23), 170, 170)
            }
        }
        .frame(width: 440, height: 956).background(wallpaper), "iphone-4.png", out, scale: 3)

        // iPad 13": 1032 × 1376 points at 2×
        write(app(classic, at(10, 23), 1032, 1376), "ipad-1.png", out, scale: 2)
        write(app(mint, at(21, 47), 1032, 1376), "ipad-2.png", out, scale: 2)
        write(VStack(spacing: 32) {
            HStack(spacing: 32) {
                widget(classic, at(10, 23), 412, 412, radius: 28)
                widget(ice, at(10, 23), 412, 412, radius: 28)
            }
            widget(amber, at(10, 23), 856, 412, radius: 28)
        }
        .frame(width: 1032, height: 1376).background(wallpaper), "ipad-3.png", out, scale: 2)

        // Mac: 1440 × 900 points at 2× (full screen, and widgets on the desktop)
        write(app(classic, at(10, 23), 1440, 900), "mac-1.png", out, scale: 2)
        write(app(ice, at(14, 38), 1440, 900), "mac-2.png", out, scale: 2)
        // Desktop: widgets on the left, the app's window on the right
        let window = ZStack(alignment: .topLeading) {
            app(mint, at(10, 23), 700, 700)
            HStack(spacing: 8) {
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.34))
                Circle().fill(Color(red: 1, green: 0.74, blue: 0.18))
                Circle().fill(Color(red: 0.16, green: 0.79, blue: 0.25))
            }
            .frame(width: 60, height: 12)
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 30, y: 16)
        write(HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 24) {
                widget(classic, at(10, 23), 344, 344, radius: 22)
                HStack(spacing: 24) {
                    widget(amber, at(10, 23), 160, 160, radius: 20)
                    widget(chalk, at(10, 23), 160, 160, radius: 20)
                }
            }
            Spacer()
            window
            Spacer()
        }
        .padding(48)
        .frame(width: 1440, height: 900, alignment: .topLeading)
        .background(wallpaper), "mac-3.png", out, scale: 2)
    }

    @MainActor
    private static func write(_ view: some View, _ name: String, _ dir: URL, scale: CGFloat) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        // App Store Connect wants screenshots without alpha channel: redraw into an RGB bitmap
        guard let image = renderer.cgImage,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { return }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let flat = ctx.makeImage(),
              let png = NSBitmapImageRep(cgImage: flat).representation(using: .png, properties: [:]) else { return }
        try? png.write(to: dir.appendingPathComponent(name))
        print("✓ store/\(name) \(flat.width)×\(flat.height)")
    }
}
#endif
