import Foundation

// Gibt Raster, Wörter und alle Zeitansagen aus – zum Vergleich mit dem Prototyp
// (prototype/check.mjs). Aufruf über: node prototype/check.mjs

for (name, face) in [("de", ClockFace.german), ("en", ClockFace.english)] {
    for row in face.grid { print("grid \(name) \(row.precomposedStringWithCanonicalMapping)") }
    for key in face.words.keys.sorted() {
        let (r, c, l) = face.words[key]!
        print("word \(name) \(key) \(r) \(c) \(l)")
    }
    for m in face.marks { print("mark \(name) \(m.glyph) \(m.row) \(m.afterCol) \(m.word)") }
}
for lang in Language.allCases {
    for intro in [true, false] {
        for h in 0..<24 {
            for m in 0..<60 {
                let p = ClockFace.phrase(hour24: h, minute: m, language: lang, intro: intro)
                print("time \(lang.rawValue) \(intro ? 1 : 0) \(h):\(m) \(p.words.joined(separator: ",")) \(p.dots)")
            }
        }
    }
}
