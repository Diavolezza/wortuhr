import Foundation

enum Dialect: String {
    case hoch   // VIERTEL NACH DREI, ZWANZIG NACH DREI, VIERTEL VOR VIER
    case sued   // VIERTEL VIER, ZEHN VOR HALB VIER, DREIVIERTEL VIER
}

/// Buchstabenraster und Zeitlogik der Wortuhr.
/// Identisch zum HTML-Prototyp; dort sind alle 288 Stellungen geprüft.
enum ClockFace {
    static let rows = 10
    static let cols = 11

    static let grid: [String] = [
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
    ]

    /// Wort -> (Zeile, Spalte, Länge)
    static let words: [String: (Int, Int, Int)] = [
        "ES": (0, 0, 2), "IST": (0, 3, 3),
        "M5": (1, 0, 4), "M10": (0, 7, 4), "M20": (1, 4, 7),
        "DV": (2, 0, 11), "V": (2, 4, 7),
        "NACH": (3, 0, 4), "VOR": (3, 6, 3), "HALB": (4, 0, 4),
        "H7": (4, 5, 6), "H0": (5, 0, 5), "EIN": (5, 6, 3), "H1": (5, 6, 4),
        "H2": (6, 0, 4), "H3": (6, 4, 4), "H11": (6, 8, 3),
        "H4": (7, 0, 4), "H5": (7, 5, 4),
        "H6": (8, 0, 5), "H8": (8, 6, 4),
        "H9": (9, 0, 4), "H10": (9, 4, 4), "UHR": (9, 8, 3),
    ]

    /// Buchstabe an Zeile/Spalte (vorkomponiert, damit Ü/Ö ein einzelnes Zeichen sind).
    static func letter(row: Int, col: Int) -> String {
        let chars = Array(grid[row].precomposedStringWithCanonicalMapping)
        return String(chars[col])
    }

    static func phrase(hour24: Int, minute: Int, dialect: Dialect, esIst: Bool) -> (words: [String], dots: Int) {
        let m5 = (minute / 5) * 5
        let h = hour24 % 12
        let n = (h + 1) % 12
        func H(_ x: Int) -> String { "H\(x)" }
        let sued = (dialect == .sued)

        let w: [String]
        switch m5 {
        case 0:  w = [h == 1 ? "EIN" : H(h), "UHR"]
        case 5:  w = ["M5", "NACH", H(h)]
        case 10: w = ["M10", "NACH", H(h)]
        case 15: w = sued ? ["V", H(n)] : ["V", "NACH", H(h)]
        case 20: w = sued ? ["M10", "VOR", "HALB", H(n)] : ["M20", "NACH", H(h)]
        case 25: w = ["M5", "VOR", "HALB", H(n)]
        case 30: w = ["HALB", H(n)]
        case 35: w = ["M5", "NACH", "HALB", H(n)]
        case 40: w = sued ? ["M10", "NACH", "HALB", H(n)] : ["M20", "VOR", H(n)]
        case 45: w = sued ? ["DV", H(n)] : ["V", "VOR", H(n)]
        case 50: w = ["M10", "VOR", H(n)]
        default: w = ["M5", "VOR", H(n)]
        }
        return ((esIst ? ["ES", "IST"] : []) + w, minute % 5)
    }

    /// Indizes (Zeile * 11 + Spalte) der leuchtenden Buchstaben.
    static func litCells(for words: [String]) -> Set<Int> {
        var on = Set<Int>()
        for word in words {
            guard let pos = self.words[word] else { continue }
            let (r, c, l) = pos
            for i in 0..<l { on.insert(r * cols + c + i) }
        }
        return on
    }
}
