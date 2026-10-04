import AppKit
import ScreenSaver

/// All Wortuhr settings. Defaults = values tuned in the prototype.
struct Settings {
    var language: Language = .systemDefault
    var intro = true              // always show "ES IST" / "IT IS"
    var front = NSColor(hex: "#0e0f11")
    var lit = NSColor(hex: "#fff1d6")
    var dim: Double = 10          // brightness of unlit letters in %
    var glow: Double = 40         // glow in %
    var edge: Double = 40         // emphasis of the plate edge in %
    var font = "Avenir Next"
    var weight = 400
    var letterScale: Double = 100 // %
    var size: Double = 92         // % of the shorter screen side
    var fade: Double = 0.8        // seconds
    var minuteEdges = true        // minutes past the five-minute step light up the edges
    var edgeStrength: Double = 100 // brightness of the minute edges in % (10 … 200)
    var edgeSpread: Double = 50   // light outside the plate: 0 = none … 100 = wide halo
    var edgeTrail: Double = 40    // brightness of the earlier edges: 0 = only the latest edge lit,
                                  // 40 = trail fading backwards, 100 = all lit edges equally bright
    var drift = false
    var mainScreenOnly = false    // other displays stay black

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
        s.size = dbl("size", s.size)
        s.fade = dbl("fade", s.fade)
        s.minuteEdges = bool("minuteEdges", s.minuteEdges)
        s.edgeStrength = dbl("edgeStrength", s.edgeStrength)
        s.edgeSpread = dbl("edgeSpread", s.edgeSpread)
        s.edgeTrail = dbl("edgeTrail", s.edgeTrail)
        s.drift = bool("drift", s.drift)
        s.mainScreenOnly = bool("mainScreenOnly", s.mainScreenOnly)
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
        d.set(size, forKey: "size")
        d.set(fade, forKey: "fade")
        d.set(minuteEdges, forKey: "minuteEdges")
        d.set(edgeStrength, forKey: "edgeStrength")
        d.set(edgeSpread, forKey: "edgeSpread")
        d.set(edgeTrail, forKey: "edgeTrail")
        // Keys of removed options (full-screen style, minute dots)
        d.removeObject(forKey: "flat")
        d.removeObject(forKey: "dots")
        d.set(drift, forKey: "drift")
        d.set(mainScreenOnly, forKey: "mainScreenOnly")
        d.synchronize()
    }

    /// Glow of the minute edges as fractions of the plate width, same as edgeSpread() in the prototype:
    /// depth = how far the glow reaches into the plate (fixed: a hint), halo = light outside the plate,
    /// set by the spread (0 % none, 50 % 0.7 %, 100 % 2 % of the plate width).
    var edgeGeometry: (depth: CGFloat, halo: CGFloat) {
        let v = CGFloat(edgeSpread) / 100
        return (0.005, 0.02 * pow(v, 1.5))
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
