import Foundation

/// The settings as one line of text, to copy them between the screen saver's options and the app:
///   Wortuhr {"dim":10,"font":"Avenir Next","front":"#0e0f11",…}
/// Keys as in the screen saver's defaults. Missing or invalid values are left out, so they keep
/// their current value. "Main display only" is a Mac screen saver option and is not exchanged.
struct SettingsExchange: Codable, Equatable {
    var language: String?
    var intro: Bool?
    var front: String?
    var lit: String?
    var dim: Double?
    var glow: Double?
    var edge: Double?
    var font: String?
    var weight: Int?
    var letterScale: Double?
    var size: Double?
    var fade: Double?
    var minuteEdges: Bool?
    var edgeStrength: Double?
    var edgeSpread: Double?
    var edgeTrail: Double?
    var drift: Bool?

    static let prefix = "Wortuhr "

    init() {}

    var text: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let json = (try? encoder.encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return Self.prefix + json
    }

    /// Reads the settings from pasted text, also from a longer message that contains them.
    init?(text: String) {
        guard let a = text.firstIndex(of: "{"), let b = text.lastIndex(of: "}"), a < b,
              let x = try? JSONDecoder().decode(SettingsExchange.self, from: Data(text[a...b].utf8))
        else { return nil }
        self = x.checked
        if self == SettingsExchange() { return nil }
    }

    /// Ranges as in the options dialog; anything else is dropped.
    private var checked: SettingsExchange {
        var x = self
        func range(_ v: Double?, _ r: ClosedRange<Double>) -> Double? {
            guard let v, v.isFinite else { return nil }
            return min(max(v, r.lowerBound), r.upperBound)
        }
        func hex(_ s: String?) -> String? {
            guard var s = s?.trimmingCharacters(in: .whitespaces).lowercased() else { return nil }
            if s.hasPrefix("#") { s.removeFirst() }
            return s.count == 6 && s.allSatisfy(\.isHexDigit) ? "#" + s : nil
        }
        x.language = language.flatMap { Language(rawValue: $0) != nil ? $0 : nil }
        x.front = hex(front)
        x.lit = hex(lit)
        x.dim = range(dim, 0...40)
        x.glow = range(glow, 0...100)
        x.edge = range(edge, 0...100)
        x.weight = weight.flatMap { [300, 400, 500, 700].contains($0) ? $0 : nil }
        x.letterScale = range(letterScale, 70...140)
        x.size = range(size, 40...100)
        x.fade = range(fade, 0...3)
        x.edgeStrength = range(edgeStrength, 10...200)
        x.edgeSpread = range(edgeSpread, 0...100)
        x.edgeTrail = range(edgeTrail, 0...100)
        return x
    }
}
