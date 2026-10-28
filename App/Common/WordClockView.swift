import SwiftUI
import WidgetKit

/// The word clock: plate, letter grid with glow and minute bar, centred in the available space.
/// SwiftUI port of the screen saver's Core Animation view (Sources/WortuhrView.swift).
struct WordClockView: View {
    var style: ClockStyle
    var date: Date
    /// Rim and sheen of the plate (off in widgets, which bring their own background).
    var plate = true
    /// Seconds since start for the slow drift (burn-in protection), nil = no drift.
    var driftTime: TimeInterval? = nil

    var body: some View {
        GeometryReader { geo in
            let scale = CGFloat(style.size / 100)
            let side = floor(min(geo.size.width, geo.size.height) * scale)
            if plate {
                let d = drift(in: geo.size, side: side)
                ClockPlate(style: style, side: side, date: date, plate: true)
                    .frame(width: side, height: side)
                    .position(x: geo.size.width / 2 + d.width, y: geo.size.height / 2 + d.height)
                    .animation(.linear(duration: 2), value: driftTime)
            } else {
                // Widget: square letter grid in the middle of the tile
                // (the large widget is not quite square)
                let w = floor(geo.size.width * scale), h = floor(geo.size.height * scale)
                ZStack {
                    // The whole tile in the plate colour: iOS 26 draws the widget background
                    // (containerBackground) lighter, which showed as grey bands above and below the plate.
                    if !style.mono { Rectangle().fill(style.frontColor) }
                    ClockPlate(style: style, side: side, date: date, plate: false)
                        .frame(width: side, height: side)
                }
                .frame(width: w, height: h)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}

extension WordClockView {
    /// Drift as in the screen saver: only within the free area around the plate,
    /// at most 6 % of the width and 3 % of the height, periods of 180 and 137 seconds.
    func drift(in size: CGSize, side: CGFloat) -> CGSize {
        guard let t = driftTime else { return .zero }
        let ax = min(max((size.width - side) / 2 - 12, 0), size.width * 0.06)
        let ay = min(max((size.height - side) / 2 - 12, 0), size.height * 0.03)
        return CGSize(width: ax * CGFloat(sin(2 * .pi * t / 180)), height: ay * CGFloat(sin(2 * .pi * t / 137)))
    }
}

private struct ClockPlate: View {
    let style: ClockStyle
    let side: CGFloat
    let date: Date
    let plate: Bool

    var body: some View {
        let t = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = t.hour ?? 0, m = t.minute ?? 0
        let p = ClockFace.phrase(hour24: h, minute: m, language: style.language, intro: style.intro)
        let face = style.language.face
        let on = face.litCells(for: p.words)
        let words = Set(p.words)
        let radius = side * 0.012
        let e = style.edge / 100
        let pt = side * 0.0466 * CGFloat(style.letterScale / 100)
        let g = CGFloat(style.glow / 100)

        ZStack(alignment: .topLeading) {
            if !style.mono { RoundedRectangle(cornerRadius: radius).fill(style.frontColor) }
            if plate {
                // Sheen: subtle gradient from top left to bottom right
                RoundedRectangle(cornerRadius: radius)
                    .fill(LinearGradient(stops: Self.sheen,
                                         startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
                // Edge: fine light border and a highlight at the top (no shadow line at the bottom)
                Rectangle().fill(.white.opacity(e * 0.20))
                    .frame(width: side - 2 * radius, height: 1).offset(x: radius, y: 1)
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.white.opacity(0.03 + e * 0.22), lineWidth: 1)
            }
            letters(face, on: on, words: words, pt: pt, lit: false)
            if g > 0 && !plate {
                // Widgets: the glow as shadows on the single lit letters, without compositing group.
                // A composited group is stored as a bitmap in every timeline entry, which made the
                // timeline of the large Mac widget too large for WidgetKit (11 MB) – it then kept
                // showing an old entry and ignored changed widget settings.
                letters(face, on: on, words: words, pt: pt, lit: true,
                        glow: (main: pt * 0.3 * g * 0.53, halo: pt * 1.1 * g * 0.53))
            } else if g > 0 {
                // Same look as the two shadow layers per glyph in the screen saver (halo and main glow).
                // SwiftUI blurs about twice as wide as Core Animation for the same radius and a bit
                // brighter: radius × 0.53 and opacity × 0.85 match docs/wortuhr.png (measured).
                letters(face, on: on, words: words, pt: pt, lit: true)
                    .compositingGroup()
                    .shadow(color: style.litColor.opacity(0.6 * 0.85), radius: pt * 1.1 * g * 0.53)
                letters(face, on: on, words: words, pt: pt, lit: true)
                    .compositingGroup()
                    .shadow(color: style.litColor.opacity(0.95 * 0.85), radius: pt * 0.3 * g * 0.53)
            } else {
                // Tinted widgets: the lit letters take the accent colour
                letters(face, on: on, words: words, pt: pt, lit: true)
                    .widgetAccentable(style.mono)
            }
            if style.minuteEdges {
                minuteBar(face, level: CGFloat(p.edges) / 4, pt: pt, g: g)
            }
        }
        .frame(width: side, height: side, alignment: .topLeading)
        .animation(style.fade > 0 ? .easeInOut(duration: style.fade) : nil, value: h * 60 + m)
    }

    /// Minutes past the five-minute step: a bar in the minute cell (a square the size of a letter
    /// cell, 20 × 20 units: as wide as an "E" of the letter font, 16 units high, corner radius 1.6). Rail in the colour of the
    /// unlit letters, the part filled from below in the lit colour, one quarter per minute
    /// (full at four minutes).
    private func minuteBar(_ face: ClockFace, level: CGFloat, pt: CGFloat, g: CGFloat) -> some View {
        let gx0 = side * 0.0667, gw = side * 0.8667
        let gy0 = side * 0.07, gh = side * 0.86
        let cw = gw / CGFloat(ClockFace.cols), ch = gh / CGFloat(ClockFace.rows)
        let k = min(cw, ch) / 20
        let rail = RoundedRectangle(cornerRadius: 1.6 * k)
        return ZStack(alignment: .bottom) {
            rail.fill(style.offColor)
            ZStack(alignment: .bottom) {
                Color.clear
                Rectangle().fill(style.litColor).frame(height: 16 * k * level)
            }
            .clipShape(rail)   // rounded at the bottom like the rail, flat on top
            .shadow(color: style.litColor.opacity(g > 0 && plate ? 0.95 * 0.85 : 0), radius: plate ? pt * 0.3 * g * 0.53 : 0)
            .widgetAccentable(style.mono)
        }
        .frame(width: style.glyphWidth("E", size: pt), height: 16 * k)
        .position(x: gx0 + cw * (CGFloat(face.minute.col) + 0.5), y: gy0 + ch * (CGFloat(face.minute.row) + 0.5))
    }

    /// Sheen of the plate: white 5.5 % → clear (45 %) → black 12 %. Core Animation interpolates
    /// colour and alpha separately (the colour turns grey while the alpha rises), SwiftUI
    /// premultiplied – the extra stops reproduce the screen saver's gradient.
    static let sheen: [Gradient.Stop] = [.init(color: .white.opacity(0.055), location: 0)]
        + (0...8).map { i in
            let t = Double(i) / 8
            return .init(color: Color(white: 1 - t).opacity(0.12 * t), location: 0.45 + 0.55 * t)
        }

    /// All letters of the grid. lit = false: every letter in the unlit colour.
    /// lit = true: only the lit letters, in the lit colour (the others transparent, so they fade).
    private func letters(_ face: ClockFace, on: Set<Int>, words: Set<String>, pt: CGFloat, lit: Bool,
                         glow: (main: CGFloat, halo: CGFloat)? = nil) -> some View {
        let gx0 = side * 0.0667, gw = side * 0.8667
        let gy0 = side * 0.07, gh = side * 0.86
        let cols = ClockFace.cols
        let cw = gw / CGFloat(cols), ch = gh / CGFloat(ClockFace.rows)
        let font = style.font(size: pt)
        let cap = style.capHeight(size: pt)
        let color = lit ? style.litColor : style.offColor
        let cell = CGSize(width: cw, height: ch)
        // Widgets (plate == false) do not fade: the lit layers hold only the lit letters, so each
        // timeline entry stays small. The app keeps all letters so that they can fade in and out.
        let lean = lit && !plate
        let all = Array(0..<(ClockFace.rows * cols)).filter { !style.minuteEdges || $0 != face.minuteIndex }
        let cells = lean ? on.sorted() : all
        let marks = face.marks.filter { !lean || words.contains($0.word) }
        return ZStack(alignment: .topLeading) {
            ForEach(cells, id: \.self) { i in
                Glyph(text: face.letter(row: i / cols, col: i % cols), font: font, cap: cap, color: color, cell: cell,
                      glow: glow)
                    .opacity(lit && !on.contains(i) ? 0 : 1)
                    .position(x: gx0 + cw * (CGFloat(i % cols) + 0.5), y: gy0 + ch * (CGFloat(i / cols) + 0.5))
            }
            ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                Glyph(text: mark.glyph, font: font, cap: cap, color: color, cell: cell, glow: glow)
                    .opacity(lit && !words.contains(mark.word) ? 0 : 1)
                    .position(x: gx0 + cw * CGFloat(mark.afterCol + 1), y: gy0 + ch * (CGFloat(mark.row) + 0.5))
            }
        }
        .frame(width: side, height: side, alignment: .topLeading)
    }
}

/// One letter, horizontally centred in its cell, capitals vertically centred.
private struct Glyph: View {
    let text: String
    let font: Font
    let cap: CGFloat
    let color: Color
    let cell: CGSize
    var glow: (main: CGFloat, halo: CGFloat)? = nil

    var body: some View {
        letter
            .fixedSize()
            .alignmentGuide(VerticalAlignment.center) { d in d[.firstTextBaseline] - cap / 2 }
            .frame(width: cell.width, height: cell.height)
    }

    /// The letter, in widgets with its glow as two shadows (main glow and halo).
    @ViewBuilder private var letter: some View {
        if let glow {
            Text(text).font(font).foregroundStyle(color)
                .shadow(color: color.opacity(0.95 * 0.85), radius: glow.main)
                .shadow(color: color.opacity(0.6 * 0.85), radius: glow.halo)
        } else {
            Text(text).font(font).foregroundStyle(color)
        }
    }
}
