import SwiftUI
import CoreText

/// Look and behaviour of the word clock in the app and the widget.
/// Same settings and defaults as the screen saver (Sources/Settings.swift).
struct ClockStyle: Equatable {
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
    var drift = false             // the plate drifts slowly (burn-in protection)
    /// Widget in tinted / vibrant rendering (not saved): the system colours the widget itself and keeps
    /// only the opacity – so no filled areas, and unlit letters by opacity instead of by colour.
    var mono = false

    static let fonts = ["Helvetica Neue", "System", "Avenir Next", "Futura", "DIN Alternate", "Gill Sans", "SF Mono"]
    static let frontPresets = ["#0e0f11", "#2a2c30", "#101b2c", "#14261e", "#5e231d", "#e9e7e1"]
    static let litPresets = ["#fff1d6", "#f3f7ff", "#ffb24a", "#9ad7ff", "#9ff0c8", "#1d1f22"]
    static let weights: [(String, Int)] = [("Light", 300), ("Regular", 400), ("Medium", 500), ("Bold", 700)]

    var frontColor: Color { Color(hex: front) }
    var litColor: Color { Color(hex: lit) }
    /// Unlit letters: dim % lit colour, the rest plate colour (like CSS color-mix).
    var offColor: Color { mono ? Color(hex: lit).opacity(dim / 100) : Color.mix(lit, front, dim / 100) }

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

    // MARK: - Persistence and exchange

    /// Stored as the same text that "Copy" puts on the clipboard (see Shared/SettingsExchange.swift).
    private static let key = "settings"

    static func load(from defaults: UserDefaults = .shared) -> ClockStyle {
        var style = ClockStyle()
        if let text = defaults.string(forKey: key), let x = SettingsExchange(text: text) { style.apply(x) }
        return style
    }

    func save(to defaults: UserDefaults = .shared) {
        defaults.set(exchange.text, forKey: Self.key)
    }

    var exchange: SettingsExchange {
        var x = SettingsExchange()
        x.language = language.rawValue
        x.intro = intro
        x.front = front
        x.lit = lit
        x.dim = dim
        x.glow = glow
        x.edge = edge
        x.font = font
        x.weight = weight
        x.letterScale = letterScale
        x.size = size
        x.fade = fade
        x.minuteEdges = minuteEdges
        x.edgeStrength = edgeStrength
        x.edgeSpread = edgeSpread
        x.edgeTrail = edgeTrail
        x.drift = drift
        return x
    }

    /// Takes over pasted settings; values that are missing stay as they are.
    mutating func apply(_ x: SettingsExchange) {
        if let v = x.language.flatMap(Language.init(rawValue:)) { language = v }
        if let v = x.intro { intro = v }
        if let v = x.front { front = v }
        if let v = x.lit { lit = v }
        if let v = x.dim { dim = v }
        if let v = x.glow { glow = v }
        if let v = x.edge { edge = v }
        if let v = x.font, Self.fonts.contains(v) { font = v }
        if let v = x.weight { weight = v }
        if let v = x.letterScale { letterScale = v }
        if let v = x.size { size = v }
        if let v = x.fade { fade = v }
        if let v = x.minuteEdges { minuteEdges = v }
        if let v = x.edgeStrength { edgeStrength = v }
        if let v = x.edgeSpread { edgeSpread = v }
        if let v = x.edgeTrail { edgeTrail = v }
        if let v = x.drift { drift = v }
    }
}

extension UserDefaults {
    /// Shared by the app and the widget (App Group).
    static let shared = UserDefaults(suiteName: "group.de.wanner-it.wordclock") ?? .standard
}

extension ClockStyle {
    /// Look of a widget: the app's settings, the whole tile, no drift.
    /// mono: tinted / vibrant rendering (StandBy at night, tinted Home Screen, Mac desktop in the
    /// background) – the system colours the widget itself, so plain white letters without glow.
    func forWidget(mono: Bool) -> ClockStyle {
        var s = self
        s.size = 100
        s.drift = false
        if mono {
            s.mono = true
            s.front = "#000000"
            s.lit = "#ffffff"
            s.dim = 22
            s.glow = 0
            s.edge = 0
        }
        return s
    }
}

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

    /// "#rrggbb" of a colour (sRGB), e.g. from the colour picker.
    var hexString: String {
        #if os(macOS)
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .black
        let r = c.redComponent, g = c.greenComponent, b = c.blueComponent
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        func byte(_ x: CGFloat) -> Int { Int((min(max(x, 0), 1) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", byte(r), byte(g), byte(b))
    }

    static func components(_ hex: String) -> (r: Double, g: Double, b: Double) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt64(s, radix: 16) ?? 0
        return (Double((v >> 16) & 0xff) / 255, Double((v >> 8) & 0xff) / 255, Double(v & 0xff) / 255)
    }
}
