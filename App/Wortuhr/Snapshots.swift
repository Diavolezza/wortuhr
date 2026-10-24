#if os(macOS)
import AppKit
import SwiftUI

/// `Wortuhr -snapshot <folder>`: renders the clock face with fixed times to PNG files and quits.
/// For checking the look against the screen saver (docs/wortuhr.png: 640×400, 11:58, German).
/// Called by `./build.sh --snapshots`.
enum Snapshots {
    @MainActor
    static func runIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "-snapshot"), i + 1 < args.count else { return }
        let dir = URL(fileURLWithPath: args[i + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        func at(_ h: Int, _ m: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: h, minute: m)) ?? .now
        }
        let de = ClockStyle(language: .de)
        let widget = de.forWidget(mono: false)
        var light = widget
        light.front = "#e9e7e1"
        light.lit = "#1d1f22"
        let mono = de.forWidget(mono: true)
        var en = de
        en.language = .en

        func app(_ style: ClockStyle, _ date: Date, _ w: CGFloat, _ h: CGFloat) -> some View {
            WordClockView(style: style, date: date).frame(width: w, height: h).background(Color.black)
        }
        func widgetView(_ style: ClockStyle, _ date: Date, _ w: CGFloat, _ h: CGFloat,
                        wallpaper: Color = Color(white: 0.35)) -> some View {
            WordClockView(style: style, date: date, plate: false)
                .frame(width: w, height: h)
                .background(style.frontColor)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(20)
                .background(wallpaper)
        }

        write(app(de, at(11, 58), 640, 400), "compare-11-58.png", dir)
        write(app(de, at(10, 23), 600, 600), "app-de-10-23.png", dir)
        write(app(en, at(15, 47), 600, 600), "app-en-15-47.png", dir)
        write(widgetView(widget, at(10, 23), 158, 158), "widget-small.png", dir)
        write(widgetView(widget, at(19, 31), 338, 158), "widget-medium.png", dir)
        write(widgetView(widget, at(15, 47), 338, 354), "widget-large.png", dir)
        write(widgetView(light, at(9, 2), 158, 158), "widget-small-light.png", dir)
        // Tinted / vibrant: the system tints the letters and removes the background
        write(widgetView(mono, at(22, 44), 158, 158, wallpaper: Color(red: 0.12, green: 0.18, blue: 0.3)),
              "widget-small-mono.png", dir)
        exit(0)
    }

    @MainActor
    private static func write(_ view: some View, _ name: String, _ dir: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            print("✗ \(name)")
            return
        }
        let url = dir.appendingPathComponent(name)
        try? png.write(to: url)
        print("✓ \(url.path)")
    }
}
#endif
