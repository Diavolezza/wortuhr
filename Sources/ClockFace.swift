import Foundation

/// Language of the time phrase, in the order of the selection list (alphabetical).
/// The raw values are stored in the settings – changing them resets the saved language.
enum Language: String, CaseIterable {
    case de       // VIERTEL NACH DREI, ZWANZIG NACH DREI, VIERTEL VOR VIER
    case deSouth  // VIERTEL VIER, ZEHN VOR HALB VIER, DREIVIERTEL VIER (southern German)
    case en       // A QUARTER PAST THREE, TWENTY FIVE TO FOUR (British)
    case us       // A QUARTER AFTER THREE, HALF PAST THREE (American)
    case es       // LAS TRES Y CUARTO, ES LA UNA
    case fr       // TROIS HEURES ET QUART, QUATRE HEURES MOINS LE QUART, MIDI, MINUIT
    case it       // LE TRE E UN QUARTO, È L'UNA

    var face: ClockFace {
        switch self {
        case .de, .deSouth: return .german
        case .en:          return .english
        case .us:          return .american
        case .fr:          return .french
        case .it:          return .italian
        case .es:          return .spanish
        }
    }

    /// Language of the options dialog.
    var ui: UILanguage {
        switch self {
        case .de, .deSouth: return .de
        case .en:          return .enGB
        case .us:          return .enUS
        case .fr:          return .fr
        case .it:          return .it
        case .es:          return .es
        }
    }
}

enum UILanguage { case de, enGB, enUS, fr, it, es }

/// Letter grid and time logic of the word clock, per language.
/// Identical to the HTML prototype (prototype/faces.js); `node prototype/check.mjs` checks both.
struct ClockFace {
    static let rows = 10
    static let cols = 11

    let grid: [String]
    /// word -> (row, column, length)
    let words: [String: (Int, Int, Int)]
    /// Extra glyphs between two cells (apostrophe in O'CLOCK, hyphen in VINGT-CINQ):
    /// glyph, row, column to its left, word it lights up with.
    let marks: [(glyph: String, row: Int, afterCol: Int, word: String)]

    /// Letter at row/column (precomposed so that Ü/Ö/È are single characters).
    func letter(row: Int, col: Int) -> String {
        let chars = Array(grid[row].precomposedStringWithCanonicalMapping)
        return String(chars[col])
    }

    /// Indices (row * 11 + column) of the lit letters.
    func litCells(for words: [String]) -> Set<Int> {
        var on = Set<Int>()
        for word in words {
            guard let pos = self.words[word] else { continue }
            let (r, c, l) = pos
            for i in 0..<l { on.insert(r * Self.cols + c + i) }
        }
        return on
    }

    /// Time phrase: intro ("ES IST", "IT IS" …, optional), words and minute dots.
    static func phrase(hour24: Int, minute: Int, language: Language, intro: Bool) -> (words: [String], dots: Int) {
        let m5 = (minute / 5) * 5
        let h = hour24 % 12
        let n = (h + 1) % 12
        let p: (intro: [String], words: [String])
        switch language {
        case .de, .deSouth: p = germanWords(m5: m5, h: h, n: n, south: language == .deSouth)
        case .en, .us:     p = englishWords(m5: m5, h: h, n: n, american: language == .us)
        case .fr:          p = frenchWords(m5: m5, h24: hour24)
        case .it:          p = italianWords(m5: m5, h: h, n: n)
        case .es:          p = spanishWords(m5: m5, h: h, n: n)
        }
        return ((intro ? p.intro : []) + p.words, minute % 5)
    }

    private static func H(_ x: Int) -> String { "H\(x)" }

    // MARK: - German

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
            "ZEHNEUNXUHR",   // ZEHN and NEUN share the N, gap before UHR
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
            "H10": (9, 0, 4), "H9": (9, 3, 4), "UHR": (9, 8, 3),
        ],
        marks: []
    )

    private static func germanWords(m5: Int, h: Int, n: Int, south: Bool) -> ([String], [String]) {
        let w: [String]
        switch m5 {
        case 0:  w = [h == 1 ? "EIN" : H(h), "UHR"]
        case 5:  w = ["M5", "NACH", H(h)]
        case 10: w = ["M10", "NACH", H(h)]
        case 15: w = south ? ["V", H(n)] : ["V", "NACH", H(h)]
        case 20: w = south ? ["M10", "VOR", "HALB", H(n)] : ["M20", "NACH", H(h)]
        case 25: w = ["M5", "VOR", "HALB", H(n)]
        case 30: w = ["HALB", H(n)]
        case 35: w = ["M5", "NACH", "HALB", H(n)]
        case 40: w = south ? ["M10", "NACH", "HALB", H(n)] : ["M20", "VOR", H(n)]
        case 45: w = south ? ["DV", H(n)] : ["V", "VOR", H(n)]
        case 50: w = ["M10", "VOR", H(n)]
        default: w = ["M5", "VOR", H(n)]
        }
        return (["ES", "IST"], w)
    }

    // MARK: - English (British and American)

    /// Hour rows and words: identical in both English grids.
    private static let englishHourRows = [
        "ONEXTWOVSIX",
        "THREEKSEVEN",
        "FOURBELEVEN",
        "FIVEMTWELVE",
        "EIGHTRTENPU",
        "NINEWOCLOCK",
    ]
    private static let englishHours: [String: (Int, Int, Int)] = [
        "H1": (4, 0, 3), "H2": (4, 4, 3), "H6": (4, 8, 3),
        "H3": (5, 0, 5), "H7": (5, 6, 5),
        "H4": (6, 0, 4), "H11": (6, 5, 6),
        "H5": (7, 0, 4), "H0": (7, 5, 6),
        "H8": (8, 0, 5), "H10": (8, 6, 3),
        "H9": (9, 0, 4), "OCLOCK": (9, 5, 6),
    ]

    static let english = ClockFace(
        grid: [
            "ITLISQHALFP",
            "AZQUARTERCK",
            "TWENTYXFIVE",
            "TENRPASTBTO",
        ] + englishHourRows,
        words: englishHours.merging([
            "IT": (0, 0, 2), "IS": (0, 3, 2), "HALF": (0, 6, 4),
            "A": (1, 0, 1), "QUARTER": (1, 2, 7),
            "M20": (2, 0, 6), "M5": (2, 7, 4),
            "M10": (3, 0, 3), "PAST": (3, 4, 4), "TO": (3, 9, 2),
        ]) { a, _ in a },
        marks: [("’", 9, 5, "OCLOCK")]
    )

    static let american = ClockFace(
        grid: [
            "ITLISZHALFA",
            "QUARTERPAST",
            "TWENTYXFIVE",
            "TENKAFTERTO",
        ] + englishHourRows,
        words: englishHours.merging([
            "IT": (0, 0, 2), "IS": (0, 3, 2), "HALF": (0, 6, 4), "A": (0, 10, 1),
            "QUARTER": (1, 0, 7), "PAST": (1, 7, 4),
            "M20": (2, 0, 6), "M5": (2, 7, 4),
            "M10": (3, 0, 3), "AFTER": (3, 4, 5), "TO": (3, 9, 2),
        ]) { a, _ in a },
        marks: [("’", 9, 5, "OCLOCK")]
    )

    private static func englishWords(m5: Int, h: Int, n: Int, american: Bool) -> ([String], [String]) {
        let past = american ? "AFTER" : "PAST"
        let w: [String]
        switch m5 {
        case 0:  w = [H(h), "OCLOCK"]
        case 5:  w = ["M5", past, H(h)]
        case 10: w = ["M10", past, H(h)]
        case 15: w = ["A", "QUARTER", past, H(h)]
        case 20: w = ["M20", past, H(h)]
        case 25: w = ["M20", "M5", past, H(h)]
        case 30: w = ["HALF", "PAST", H(h)]
        case 35: w = ["M20", "M5", "TO", H(n)]
        case 40: w = ["M20", "TO", H(n)]
        case 45: w = ["A", "QUARTER", "TO", H(n)]
        case 50: w = ["M10", "TO", H(n)]
        default: w = ["M5", "TO", H(n)]
        }
        return (["IT", "IS"], w)
    }

    // MARK: - French

    static let french = ClockFace(
        grid: [
            "ILKESTRDEUX",
            "QUATRETROIS",
            "UNECINQSEPT",
            "HUITNEUFSIX",
            "MIDIXMINUIT",
            "ONZEPHEURES",
            "MOINSVLEDIX",
            "ETSQUARTFLN",
            "VINGTCINQHB",
            "ZDEMIEWKLPT",
        ],
        words: [
            "IL": (0, 0, 2), "EST": (0, 3, 3), "H2": (0, 7, 4),
            "H4": (1, 0, 6), "H3": (1, 6, 5),
            "H1": (2, 0, 3), "H5": (2, 3, 4), "H7": (2, 7, 4),
            "H8": (3, 0, 4), "H9": (3, 4, 4), "H6": (3, 8, 3),
            "MIDI": (4, 0, 4), "H10": (4, 2, 3), "MINUIT": (4, 5, 6),
            "H11": (5, 0, 4), "HEURE": (5, 5, 5), "HEURES": (5, 5, 6),
            "MOINS": (6, 0, 5), "LE": (6, 6, 2), "M10": (6, 8, 3),
            "ET": (7, 0, 2), "QUART": (7, 3, 5),
            "M20": (8, 0, 5), "M5": (8, 5, 4), "M25": (8, 0, 9),
            "DEMI": (9, 1, 4), "DEMIE": (9, 1, 5),
        ],
        marks: [("-", 8, 4, "M25")]
    )

    private static func frenchWords(m5: Int, h24: Int) -> ([String], [String]) {
        // hour (24 h) -> hour word and "heure(s)"; 12:00 = midi, 0:00 = minuit
        func hw(_ x: Int) -> [String] {
            if x == 0 { return ["MINUIT"] }
            if x == 12 { return ["MIDI"] }
            return [H(x % 12), x % 12 == 1 ? "HEURE" : "HEURES"]
        }
        let cur = hw(h24), nxt = hw((h24 + 1) % 24)
        let demi = cur.count == 1 ? "DEMI" : "DEMIE"   // midi et demi, trois heures et demie
        let w: [String]
        switch m5 {
        case 0:  w = cur
        case 5:  w = cur + ["M5"]
        case 10: w = cur + ["M10"]
        case 15: w = cur + ["ET", "QUART"]
        case 20: w = cur + ["M20"]
        case 25: w = cur + ["M25"]
        case 30: w = cur + ["ET", demi]
        case 35: w = nxt + ["MOINS", "M25"]
        case 40: w = nxt + ["MOINS", "M20"]
        case 45: w = nxt + ["MOINS", "LE", "QUART"]
        case 50: w = nxt + ["MOINS", "M10"]
        default: w = nxt + ["MOINS", "M5"]
        }
        return (["IL", "EST"], w)
    }

    // MARK: - Italian

    static let italian = ClockFace(
        grid: [
            "SONORLEBSEI",
            "ÈPLUNASETTE",
            "QUATTROOTTO",
            "CINQUEDIECI",
            "UNDICINOVEK",
            "DODICIDUEFG",
            "TREKEMENOZS",
            "UNRQUARTOFT",
            "VENTICINQUE",
            "MEZZAPDIECI",
        ],
        words: [
            "SONO": (0, 0, 4), "LE": (0, 5, 2), "H6": (0, 8, 3),
            "È": (1, 0, 1), "H1": (1, 2, 4), "H7": (1, 6, 5),
            "H4": (2, 0, 7), "H8": (2, 7, 4),
            "H5": (3, 0, 6), "H10": (3, 6, 5),
            "H11": (4, 0, 6), "H9": (4, 6, 4),
            "H0": (5, 0, 6), "H2": (5, 6, 3),
            "H3": (6, 0, 3), "E": (6, 4, 1), "MENO": (6, 5, 4),
            "UN": (7, 0, 2), "QUARTO": (7, 3, 6),
            "M20": (8, 0, 5), "M5": (8, 5, 6), "M25": (8, 0, 11),
            "MEZZA": (9, 0, 5), "M10": (9, 6, 5),
        ],
        marks: [("’", 1, 2, "H1")]
    )

    private static func italianWords(m5: Int, h: Int, n: Int) -> ([String], [String]) {
        // è l'una / sono le due
        func hw(_ x: Int) -> [String] { x == 1 ? [H(1)] : ["LE", H(x)] }
        let cur = hw(h), nxt = hw(n)
        let w: [String]
        switch m5 {
        case 0:  w = cur
        case 5:  w = cur + ["E", "M5"]
        case 10: w = cur + ["E", "M10"]
        case 15: w = cur + ["E", "UN", "QUARTO"]
        case 20: w = cur + ["E", "M20"]
        case 25: w = cur + ["E", "M25"]
        case 30: w = cur + ["E", "MEZZA"]
        case 35: w = nxt + ["MENO", "M25"]
        case 40: w = nxt + ["MENO", "M20"]
        case 45: w = nxt + ["MENO", "UN", "QUARTO"]
        case 50: w = nxt + ["MENO", "M10"]
        default: w = nxt + ["MENO", "M5"]
        }
        let hr = m5 < 35 ? h : n
        return ([hr == 1 ? "È" : "SONO"], w)
    }

    // MARK: - Spanish

    static let spanish = ClockFace(
        grid: [
            "ESONRLASFKT",
            "UNADOSCINCO",
            "CUATROSIETE",
            "NUEVEPTRESG",
            "OCHONCEDIEZ",
            "SEISRDOCEBU",
            "YMENOSKDIEZ",
            "VEINTICINCO",
            "CUARTOMEDIA",
            "VEINTEHPXLS",
        ],
        words: [
            "ES": (0, 0, 2), "SON": (0, 1, 3), "LA": (0, 5, 2), "LAS": (0, 5, 3),
            "H1": (1, 0, 3), "H2": (1, 3, 3), "H5": (1, 6, 5),
            "H4": (2, 0, 6), "H7": (2, 6, 5),
            "H9": (3, 0, 5), "H3": (3, 6, 4),
            "H8": (4, 0, 4), "H11": (4, 3, 4), "H10": (4, 7, 4),
            "H6": (5, 0, 4), "H0": (5, 5, 4),
            "Y": (6, 0, 1), "MENOS": (6, 1, 5), "M10": (6, 7, 4),
            "M25": (7, 0, 11), "M5": (7, 6, 5),
            "CUARTO": (8, 0, 6), "MEDIA": (8, 6, 5),
            "M20": (9, 0, 6),
        ],
        marks: []
    )

    private static func spanishWords(m5: Int, h: Int, n: Int) -> ([String], [String]) {
        // es la una / son las dos
        func hw(_ x: Int) -> [String] { [x == 1 ? "LA" : "LAS", H(x)] }
        let cur = hw(h), nxt = hw(n)
        let w: [String]
        switch m5 {
        case 0:  w = cur
        case 5:  w = cur + ["Y", "M5"]
        case 10: w = cur + ["Y", "M10"]
        case 15: w = cur + ["Y", "CUARTO"]
        case 20: w = cur + ["Y", "M20"]
        case 25: w = cur + ["Y", "M25"]
        case 30: w = cur + ["Y", "MEDIA"]
        case 35: w = nxt + ["MENOS", "M25"]
        case 40: w = nxt + ["MENOS", "M20"]
        case 45: w = nxt + ["MENOS", "CUARTO"]
        case 50: w = nxt + ["MENOS", "M10"]
        default: w = nxt + ["MENOS", "M5"]
        }
        let hr = m5 < 35 ? h : n
        return ([hr == 1 ? "ES" : "SON"], w)
    }
}
