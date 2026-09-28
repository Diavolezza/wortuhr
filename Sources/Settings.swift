import AppKit
import ScreenSaver

/// All Wortuhr settings. Defaults = values tuned in the prototype.
struct Settings {
    var language: Language = .systemDefault
    var intro = true              // always show "ES IST" / "IT IS"
    var front = NSColor(hex: "#0e0f11")
    var lit = NSColor(hex: "#fff1d6")
    var dim: Double = 14          // brightness of unlit letters in %
    var glow: Double = 35         // glow in %
    var edge: Double = 40         // emphasis of the plate edge in %
    var font = "Avenir Next"
    var weight = 400
    var letterScale: Double = 100 // %
    var flat = false              // true = full screen, false = front plate
    var size: Double = 92         // % of the shorter screen side
    var fade: Double = 0.8        // seconds
    var dots = true
    var drift = false

    static let moduleName = "de.wanner-it.wortuhr"

    /// Typefaces (keys; "System" = SF Pro, display name in Texts.systemFont)
    static let fonts = ["Helvetica Neue", "System", "Avenir Next", "Futura", "DIN Alternate", "Gill Sans", "SF Mono"]
    /// Colours (hex; names per language in Texts.frontNames / Texts.litNames)
    static let frontPresets = ["#0e0f11", "#2a2c30", "#101b2c", "#14261e", "#5e231d", "#e9e7e1"]
    static let litPresets = ["#fff1d6", "#f3f7ff", "#ffb24a", "#9ad7ff", "#9ff0c8", "#1d1f22"]
    static let weights: [(String, Int)] = [("Light", 300), ("Regular", 400), ("Medium", 500), ("Bold", 700)]

    private static var store: ScreenSaverDefaults? {
        ScreenSaverDefaults(forModuleWithName: moduleName)
    }

    static func load() -> Settings {
        var s = Settings()
        guard let d = store else { return s }
        func dbl(_ k: String, _ def: Double) -> Double { d.object(forKey: k) != nil ? d.double(forKey: k) : def }
        func bool(_ k: String, _ def: Bool) -> Bool { d.object(forKey: k) != nil ? d.bool(forKey: k) : def }
        if let v = d.string(forKey: "language"),
           let x = Language(rawValue: v) { s.language = x }
        s.intro = bool("intro", s.intro)
        if let v = d.string(forKey: "front") { s.front = NSColor(hex: v) }
        if let v = d.string(forKey: "lit") { s.lit = NSColor(hex: v) }
        s.dim = dbl("dim", s.dim)
        s.glow = dbl("glow", s.glow)
        s.edge = dbl("edge", s.edge)
        if let v = d.string(forKey: "font") { s.font = v }
        if d.object(forKey: "weight") != nil { s.weight = d.integer(forKey: "weight") }
        s.letterScale = dbl("letterScale", s.letterScale)
        s.flat = bool("flat", s.flat)
        s.size = dbl("size", s.size)
        s.fade = dbl("fade", s.fade)
        s.dots = bool("dots", s.dots)
        s.drift = bool("drift", s.drift)
        return s
    }

    func save() {
        guard let d = Settings.store else { return }
        d.set(language.rawValue, forKey: "language")
        d.set(intro, forKey: "intro")
        d.set(front.hexString, forKey: "front")
        d.set(lit.hexString, forKey: "lit")
        d.set(dim, forKey: "dim")
        d.set(glow, forKey: "glow")
        d.set(edge, forKey: "edge")
        d.set(font, forKey: "font")
        d.set(weight, forKey: "weight")
        d.set(letterScale, forKey: "letterScale")
        d.set(flat, forKey: "flat")
        d.set(size, forKey: "size")
        d.set(fade, forKey: "fade")
        d.set(dots, forKey: "dots")
        d.set(drift, forKey: "drift")
        d.synchronize()
    }

    /// Colour of unlit letters: dim % light colour, the rest front colour.
    var offColor: NSColor { NSColor.mix(lit, front, CGFloat(dim / 100)) }

    func makeFont(size pt: CGFloat) -> NSFont {
        let w: NSFont.Weight
        switch weight {
        case ..<350: w = .light
        case ..<450: w = .regular
        case ..<600: w = .medium
        default:     w = .bold
        }
        switch font {
        case "System":  return NSFont.systemFont(ofSize: pt, weight: w)
        case "SF Mono": return NSFont.monospacedSystemFont(ofSize: pt, weight: w)
        default:
            // NSFontManager weights: 3 light, 5 regular, 6/7 medium, 9 bold
            let fmWeight = [300: 3, 400: 5, 500: 7, 700: 9][weight] ?? 5
            let traits: NSFontTraitMask = weight >= 700 ? .boldFontMask : []
            if let f = NSFontManager.shared.font(withFamily: font, traits: traits, weight: fmWeight, size: pt) {
                return f
            }
            return NSFont.systemFont(ofSize: pt, weight: w)
        }
    }
}

extension NSColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt64(s, radix: 16) ?? 0
        self.init(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
                  green: CGFloat((v >> 8) & 0xff) / 255,
                  blue: CGFloat(v & 0xff) / 255,
                  alpha: 1)
    }

    var srgb: NSColor { usingColorSpace(.sRGB) ?? self }

    var hexString: String {
        let c = srgb
        func b(_ x: CGFloat) -> Int { Int((min(max(x, 0), 1) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", b(c.redComponent), b(c.greenComponent), b(c.blueComponent))
    }

    /// Mix like CSS color-mix(in srgb, a t, b).
    static func mix(_ a: NSColor, _ b: NSColor, _ t: CGFloat) -> NSColor {
        let x = a.srgb, y = b.srgb
        return NSColor(srgbRed: x.redComponent * t + y.redComponent * (1 - t),
                       green: x.greenComponent * t + y.greenComponent * (1 - t),
                       blue: x.blueComponent * t + y.blueComponent * (1 - t),
                       alpha: 1)
    }
}
