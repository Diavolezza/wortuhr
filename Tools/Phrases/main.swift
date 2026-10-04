import Foundation

// Prints grids, words and all time phrases – for comparison with the prototype
// (prototype/check.mjs). Run via: node prototype/check.mjs

let faces: [(String, ClockFace)] = [("de", .german), ("ch", .swiss), ("en", .english), ("us", .american),
                                    ("fr", .french), ("it", .italian), ("es", .spanish)]
for (name, face) in faces {
    for row in face.grid { print("grid \(name) \(row.precomposedStringWithCanonicalMapping)") }
    for key in face.words.keys.sorted(by: { Array($0.unicodeScalars.map(\.value)).lexicographicallyPrecedes($1.unicodeScalars.map(\.value)) }) {
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
                print("time \(lang.rawValue) \(intro ? 1 : 0) \(h):\(m) \(p.words.joined(separator: ",")) \(p.edges)")
            }
        }
    }
}
