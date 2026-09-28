import Foundation

/// Sprache der Zeitansage. Die Rohwerte sind die gespeicherten Schlüssel
/// („hoch“ und „sued“ stammen noch aus der Zeit, als es nur Deutsch gab).
enum Language: String, CaseIterable {
    case hoch   // VIERTEL NACH DREI, ZWANZIG NACH DREI, VIERTEL VOR VIER
    case sued   // VIERTEL VIER, ZEHN VOR HALB VIER, DREIVIERTEL VIER
    case en     // A QUARTER PAST THREE, TWENTY FIVE TO FOUR (britisch)

    var face: ClockFace {
        switch self {
        case .hoch, .sued: return .german
        case .en:          return .english
        }
    }

    /// Sprache des Optionen-Dialogs.
    var ui: UILanguage { self == .en ? .en : .de }
}

enum UILanguage { case de, en }

/// Buchstabenraster und Zeitlogik der Wortuhr, je Sprache.
/// Identisch zum HTML-Prototyp; dort prüft `prototype/check.mjs` alle Stellungen.
struct ClockFace {
    static let rows = 10
    static let cols = 11

    let grid: [String]
    /// Wort -> (Zeile, Spalte, Länge)
    let words: [String: (Int, Int, Int)]
    /// Einleitung („ES IST“, „IT IS“)
    let intro: [String]
    /// Zusatzzeichen zwischen zwei Feldern (Apostroph in O'CLOCK):
    /// Zeichen, Zeile, Spalte links davon, Wort, mit dem es leuchtet.
    let marks: [(glyph: String, row: Int, afterCol: Int, word: String)]

    /// Buchstabe an Zeile/Spalte (vorkomponiert, damit Ü/Ö ein einzelnes Zeichen sind).
    func letter(row: Int, col: Int) -> String {
        let chars = Array(grid[row].precomposedStringWithCanonicalMapping)
        return String(chars[col])
    }

    /// Indizes (Zeile * 11 + Spalte) der leuchtenden Buchstaben.
    func litCells(for words: [String]) -> Set<Int> {
        var on = Set<Int>()
        for word in words {
            guard let pos = self.words[word] else { continue }
            let (r, c, l) = pos
            for i in 0..<l { on.insert(r * Self.cols + c + i) }
        }
        return on
    }

    static func phrase(hour24: Int, minute: Int, language: Language, intro: Bool) -> (words: [String], dots: Int) {
        let m5 = (minute / 5) * 5
        let h = hour24 % 12
        let n = (h + 1) % 12
        let w: [String]
        switch language {
        case .hoch, .sued: w = germanWords(m5: m5, h: h, n: n, sued: language == .sued)
        case .en:          w = englishWords(m5: m5, h: h, n: n)
        }
        return ((intro ? language.face.intro : []) + w, minute % 5)
    }

    private static func H(_ x: Int) -> String { "H\(x)" }

    // MARK: - Deutsch

    static let german = ClockFace(
        grid: [
            "ESRISTLZEHN",
            "FÜNFZWANZIG",
            "DREIVIERTEL",
            "NACHQTVORMJ",
            "HALBXSIEBEN",
            "ZWÖLFKEINSA",
            "ZWEIDREIELF",
            "VIERYFÜNFOT",
            "SECHSRACHTN",
            "NEUNZEHNUHR",
        ],
        words: [
            "ES": (0, 0, 2), "IST": (0, 3, 3),
            "M5": (1, 0, 4), "M10": (0, 7, 4), "M20": (1, 4, 7),
            "DV": (2, 0, 11), "V": (2, 4, 7),
            "NACH": (3, 0, 4), "VOR": (3, 6, 3), "HALB": (4, 0, 4),
            "H7": (4, 5, 6), "H0": (5, 0, 5), "EIN": (5, 6, 3), "H1": (5, 6, 4),
            "H2": (6, 0, 4), "H3": (6, 4, 4), "H11": (6, 8, 3),
            "H4": (7, 0, 4), "H5": (7, 5, 4),
            "H6": (8, 0, 5), "H8": (8, 6, 4),
            "H9": (9, 0, 4), "H10": (9, 4, 4), "UHR": (9, 8, 3),
        ],
        intro: ["ES", "IST"],
        marks: []
    )

    private static func germanWords(m5: Int, h: Int, n: Int, sued: Bool) -> [String] {
        switch m5 {
        case 0:  return [h == 1 ? "EIN" : H(h), "UHR"]
        case 5:  return ["M5", "NACH", H(h)]
        case 10: return ["M10", "NACH", H(h)]
        case 15: return sued ? ["V", H(n)] : ["V", "NACH", H(h)]
        case 20: return sued ? ["M10", "VOR", "HALB", H(n)] : ["M20", "NACH", H(h)]
        case 25: return ["M5", "VOR", "HALB", H(n)]
        case 30: return ["HALB", H(n)]
        case 35: return ["M5", "NACH", "HALB", H(n)]
        case 40: return sued ? ["M10", "NACH", "HALB", H(n)] : ["M20", "VOR", H(n)]
        case 45: return sued ? ["DV", H(n)] : ["V", "VOR", H(n)]
        case 50: return ["M10", "VOR", H(n)]
        default: return ["M5", "VOR", H(n)]
        }
    }

    // MARK: - Englisch (britisch)

    static let english = ClockFace(
        grid: [
            "ITLISQHALFP",
            "AZQUARTERCK",
            "TWENTYXFIVE",
            "TENRPASTBTO",
            "ONEXTWOVSIX",
            "THREEKSEVEN",
            "FOURBELEVEN",
            "FIVEMTWELVE",
            "EIGHTRTENPU",
            "NINEWOCLOCK",
        ],
        words: [
            "IT": (0, 0, 2), "IS": (0, 3, 2), "HALF": (0, 6, 4),
            "A": (1, 0, 1), "QUARTER": (1, 2, 7),
            "M20": (2, 0, 6), "M5": (2, 7, 4),
            "M10": (3, 0, 3), "PAST": (3, 4, 4), "TO": (3, 9, 2),
            "H1": (4, 0, 3), "H2": (4, 4, 3), "H6": (4, 8, 3),
            "H3": (5, 0, 5), "H7": (5, 6, 5),
            "H4": (6, 0, 4), "H11": (6, 5, 6),
            "H5": (7, 0, 4), "H0": (7, 5, 6),
            "H8": (8, 0, 5), "H10": (8, 6, 3),
            "H9": (9, 0, 4), "OCLOCK": (9, 5, 6),
        ],
        intro: ["IT", "IS"],
        marks: [("’", 9, 5, "OCLOCK")]
    )

    private static func englishWords(m5: Int, h: Int, n: Int) -> [String] {
        switch m5 {
        case 0:  return [H(h), "OCLOCK"]
        case 5:  return ["M5", "PAST", H(h)]
        case 10: return ["M10", "PAST", H(h)]
        case 15: return ["A", "QUARTER", "PAST", H(h)]
        case 20: return ["M20", "PAST", H(h)]
        case 25: return ["M20", "M5", "PAST", H(h)]
        case 30: return ["HALF", "PAST", H(h)]
        case 35: return ["M20", "M5", "TO", H(n)]
        case 40: return ["M20", "TO", H(n)]
        case 45: return ["A", "QUARTER", "TO", H(n)]
        case 50: return ["M10", "TO", H(n)]
        default: return ["M5", "TO", H(n)]
        }
    }
}
