import SwiftUI
import CoreText

/// Look and behaviour of the word clock in the app and the widget.
/// Same settings and defaults as the screen saver (Sources/Settings.swift).
struct ClockStyle: Codable, Equatable {
    var language: Language = .systemDefault
    var intro = true              // always show "ES IST" / "IT IS"
    var front = "#0e0f11"         // plate colour
    var lit = "#fff1d6"           // colour of lit letters
    var dim: Double = 10          // brightness of unlit letters in %
    var glow: Double = 40         // glow in %
    var edge: Double = 40         // emphasis of the plate edge in %
    var font = "Avenir Next"
    var weight = 400
    var letterScale: Double = 100 // %
    var size: Double = 92         // % of the shorter side
    var fade: Double = 0.8        // seconds
    var minuteEdges = true        // minutes past the five-minute step light up the edges
    var edgeStrength: Double = 100 // brightness of the minute edges in % (10 … 200)
    var edgeSpread: Double = 50   // light outside the plate: 0 = none … 100 = wide halo
    var edgeTrail: Double = 40    // brightness of the earlier edges

    static let fonts = ["Helvetica Neue", "System", "Avenir Next", "Futura", "DIN Alternate", "Gill Sans", "SF Mono"]
    static let frontPresets = ["#0e0f11", "#2a2c30", "#101b2c", "#14261e", "#5e231d", "#e9e7e1"]
    static let litPresets = ["#fff1d6", "#f3f7ff", "#ffb24a", "#9ad7ff", "#9ff0c8", "#1d1f22"]

    var frontColor: Color { Color(hex: front) }
    var litColor: Color { Color(hex: lit) }
    /// Unlit letters: dim % lit colour, the rest plate colour (like CSS color-mix).
    var offColor: Color { Color.mix(lit, front, dim / 100) }

    func font(size pt: CGFloat) -> Font {
        let w: Font.Weight
        switch weight {
        case ..<350: w = .light
        case ..<450: w = .regular
        case ..<600: w = .medium
        default:     w = .bold
        }
        switch font {
        case "System":  return .system(size: pt, weight: w)
        case "SF Mono": return .system(size: pt, weight: w, design: .monospaced)
        default:        return .custom(font, fixedSize: pt).weight(w)
        }
    }

    /// Cap height of the letter font, used to centre the capitals vertically in their cells.
    func capHeight(size pt: CGFloat) -> CGFloat {
        let f: CTFont
        switch font {
        case "System", "SF Mono":
            f = CTFontCreateUIFontForLanguage(.system, pt, nil) ?? CTFontCreateWithName("Helvetica" as CFString, pt, nil)
        default:
            let d = CTFontDescriptorCreateWithAttributes([kCTFontFamilyNameAttribute as String: font] as CFDictionary)
            f = CTFontCreateWithFontDescriptor(d, pt, nil)
        }
        return CTFontGetCapHeight(f)
    }

    /// Minute edges: depth inside the plate and halo outside, as fractions of the plate side.
    var edgeGeometry: (depth: CGFloat, halo: CGFloat) {
        (0.005, 0.02 * pow(CGFloat(edgeSpread) / 100, 1.5))
    }

    // MARK: - Persistence

    private static let key = "clockStyle"

    static func load(from defaults: UserDefaults = .standard) -> ClockStyle {
        guard let data = defaults.data(forKey: key),
              let style = try? JSONDecoder().decode(ClockStyle.self, from: data) else { return ClockStyle() }
        return style
    }

    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Self.key) }
    }
}

extension Language: Codable {}

extension Color {
    /// Colour from "#rrggbb" (sRGB).
    init(hex: String) {
        let c = Color.components(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: 1)
    }

    /// Mix of two hex colours: t × a + (1 − t) × b.
    static func mix(_ a: String, _ b: String, _ t: Double) -> Color {
        let x = components(a), y = components(b)
        return Color(.sRGB, red: x.r * t + y.r * (1 - t), green: x.g * t + y.g * (1 - t),
                     blue: x.b * t + y.b * (1 - t), opacity: 1)
    }

    static func components(_ hex: String) -> (r: Double, g: Double, b: Double) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt64(s, radix: 16) ?? 0
        return (Double((v >> 16) & 0xff) / 255, Double((v >> 8) & 0xff) / 255, Double(v & 0xff) / 255)
    }
}
