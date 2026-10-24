import SwiftUI

/// The word clock: plate, letter grid with glow and minute edges, centred in the available space.
/// SwiftUI port of the screen saver's Core Animation view (Sources/WortuhrView.swift).
struct WordClockView: View {
    var style: ClockStyle
    var date: Date
    /// Rim and sheen of the plate (off in widgets, which bring their own background).
    var plate = true

    var body: some View {
        GeometryReader { geo in
            let side = floor(min(geo.size.width, geo.size.height) * CGFloat(style.size / 100))
            ClockPlate(style: style, side: side, date: date, plate: plate)
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
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
            RoundedRectangle(cornerRadius: radius).fill(style.frontColor)
            if plate {
                // Sheen: subtle gradient from top left to bottom right
                RoundedRectangle(cornerRadius: radius)
                    .fill(LinearGradient(stops: Self.sheen,
                                         startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
                // Edge: fine light border, highlight at the top, shadow at the bottom
                Rectangle().fill(.white.opacity(e * 0.20))
                    .frame(width: side - 2 * radius, height: 1).offset(x: radius, y: 1)
                Rectangle().fill(.black.opacity(0.45))
                    .frame(width: side - 2 * radius, height: 1).offset(x: radius, y: side - 2)
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(.white.opacity(0.03 + e * 0.22), lineWidth: 1)
            }
            letters(face, on: on, words: words, pt: pt, lit: false)
            if g > 0 {
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
                letters(face, on: on, words: words, pt: pt, lit: true)
            }
            if style.minuteEdges {
                MinuteEdges(style: style, side: side, edges: p.edges)
            }
        }
        .frame(width: side, height: side, alignment: .topLeading)
        .animation(style.fade > 0 ? .easeInOut(duration: style.fade) : nil, value: h * 60 + m)
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
    private func letters(_ face: ClockFace, on: Set<Int>, words: Set<String>, pt: CGFloat, lit: Bool) -> some View {
        let gx0 = side * 0.0667, gw = side * 0.8667
        let gy0 = side * 0.07, gh = side * 0.86
        let cols = ClockFace.cols
        let cw = gw / CGFloat(cols), ch = gh / CGFloat(ClockFace.rows)
        let font = style.font(size: pt)
        let cap = style.capHeight(size: pt)
        let color = lit ? style.litColor : style.offColor
        let cell = CGSize(width: cw, height: ch)
        return ZStack(alignment: .topLeading) {
            ForEach(0..<(ClockFace.rows * cols), id: \.self) { i in
                Glyph(text: face.letter(row: i / cols, col: i % cols), font: font, cap: cap, color: color, cell: cell)
                    .opacity(lit && !on.contains(i) ? 0 : 1)
                    .position(x: gx0 + cw * (CGFloat(i % cols) + 0.5), y: gy0 + ch * (CGFloat(i / cols) + 0.5))
            }
            ForEach(Array(face.marks.enumerated()), id: \.offset) { _, mark in
                Glyph(text: mark.glyph, font: font, cap: cap, color: color, cell: cell)
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

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .fixedSize()
            .alignmentGuide(VerticalAlignment.center) { d in d[.firstTextBaseline] - cap / 2 }
            .frame(width: cell.width, height: cell.height)
    }
}

/// Minutes past the five-minute step: the edges of the plate light up one by one
/// (top, right, bottom, left). From outside to inside: halo (optional) – fine bright line –
/// glow fading into the plate; the ends taper off so the corners stay dark.
private struct MinuteEdges: View {
    let style: ClockStyle
    let side: CGFloat
    let edges: Int

    private struct Geometry {
        var inner: CGFloat, outer: CGFloat, thick: CGFloat, margin: CGFloat, len: CGFloat
        var stops: [Gradient.Stop]
    }

    private var geometry: Geometry {
        let (depth, halo) = style.edgeGeometry
        let k = CGFloat(style.edgeStrength / 100)
        let inner = max(3 * max(1, k), side * depth)   // points inside the plate
        let outer = side * halo                         // points outside the plate
        let thick = inner + outer
        let line = 1.5 * max(1, k)
        // Stop positions in points from the outer end, clamped to rising order
        var pos: [CGFloat] = [0, outer - 1, outer, outer + line, outer + line + 1, outer + inner * 0.35, thick]
        for i in 1..<pos.count { pos[i] = min(max(pos[i], pos[i - 1]), thick) }
        let alphas: [CGFloat] = [0, 0.22, 0.9, 0.9, 0.34, 0.10, 0].map { min(1, $0 * k) }
        let stops = zip(alphas, pos).map { Gradient.Stop(color: style.litColor.opacity($0), location: $1 / thick) }
        let margin = side * 0.06
        return Geometry(inner: inner, outer: outer, thick: thick, margin: margin, len: side - 2 * margin, stops: stops)
    }

    var body: some View {
        let geo = geometry
        let trail = style.edgeTrail / 100
        ZStack(alignment: .topLeading) {
            ForEach(0..<4, id: \.self) { i in
                edge(i, geo)
                    .opacity(i >= edges ? 0 : (i == edges - 1 ? 1 : trail))
            }
        }
        .frame(width: side, height: side, alignment: .topLeading)
    }

    private func edge(_ i: Int, _ g: Geometry) -> some View {
        let horizontal = i % 2 == 0
        let size = horizontal ? CGSize(width: g.len, height: g.thick) : CGSize(width: g.thick, height: g.len)
        let origin: CGPoint
        let from: UnitPoint, to: UnitPoint   // across the edge, from the outer end to the inner end
        switch i {
        case 0:  origin = CGPoint(x: g.margin, y: -g.outer);         from = .top;      to = .bottom
        case 1:  origin = CGPoint(x: side - g.inner, y: g.margin);   from = .trailing; to = .leading
        case 2:  origin = CGPoint(x: g.margin, y: side - g.inner);   from = .bottom;   to = .top
        default: origin = CGPoint(x: -g.outer, y: g.margin);         from = .leading;  to = .trailing
        }
        let taper = Gradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.22),
                                     .init(color: .black, location: 0.78), .init(color: .clear, location: 1)])
        return Rectangle()
            .fill(LinearGradient(stops: g.stops, startPoint: from, endPoint: to))
            .mask(LinearGradient(gradient: taper, startPoint: horizontal ? .leading : .top,
                                 endPoint: horizontal ? .trailing : .bottom))
            .frame(width: size.width, height: size.height)
            .position(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }
}
