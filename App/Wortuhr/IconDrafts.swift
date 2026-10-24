#if os(macOS)
import SwiftUI

/// Drafts for the app icon (rendered by `./build.sh --snapshots`): a corner of the real
/// German letter grid, enlarged, with a few lit letters and glowing minute edges.
struct IconDraft: View {
    enum Side { case top, right, bottom, left }

    let rows: [String]
    let lit: Set<Int>          // row * columns + column
    let edges: [Side]
    var style = ClockStyle(language: .de)
    var letterSize: CGFloat = 0.5   // of the cell height
    var margin: CGFloat = 0.13      // of the side

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let cols = rows.first?.count ?? 1
            let margin = side * self.margin
            let cw = (side - 2 * margin) / CGFloat(cols)
            let ch = (side - 2 * margin) / CGFloat(rows.count)
            let pt = ch * letterSize
            let g = CGFloat(style.glow / 100)
            ZStack(alignment: .topLeading) {
                Rectangle().fill(style.frontColor)
                Rectangle().fill(LinearGradient(stops: [.init(color: .white.opacity(0.07), location: 0),
                                                        .init(color: .white.opacity(0), location: 0.5),
                                                        .init(color: .black.opacity(0.18), location: 1)],
                                                startPoint: UnitPoint(x: 0.3, y: 0), endPoint: UnitPoint(x: 0.7, y: 1)))
                grid(cols: cols, margin: margin, cw: cw, ch: ch, pt: pt, onlyLit: false)
                grid(cols: cols, margin: margin, cw: cw, ch: ch, pt: pt, onlyLit: true)
                    .compositingGroup()
                    .shadow(color: style.litColor.opacity(0.6 * 0.85), radius: pt * 1.1 * g * 0.53)
                grid(cols: cols, margin: margin, cw: cw, ch: ch, pt: pt, onlyLit: true)
                    .compositingGroup()
                    .shadow(color: style.litColor.opacity(0.95 * 0.85), radius: pt * 0.3 * g * 0.53)
                ForEach(edges.indices, id: \.self) { i in edge(edges[i], side: side) }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func grid(cols: Int, margin: CGFloat, cw: CGFloat, ch: CGFloat, pt: CGFloat, onlyLit: Bool) -> some View {
        let font = style.font(size: pt)
        let cap = style.capHeight(size: pt)
        return ZStack(alignment: .topLeading) {
            ForEach(0..<(rows.count * cols), id: \.self) { i in
                let r = i / cols, c = i % cols
                let ch1 = String(Array(rows[r])[c])
                let on = lit.contains(i)
                if !onlyLit || on {
                    Text(ch1)
                        .font(font)
                        .foregroundStyle(onlyLit ? style.litColor : style.offColor)
                        .fixedSize()
                        .alignmentGuide(VerticalAlignment.center) { d in d[.firstTextBaseline] - cap / 2 }
                        .frame(width: cw, height: ch)
                        .position(x: margin + cw * (CGFloat(c) + 0.5), y: margin + ch * (CGFloat(r) + 0.5))
                }
            }
        }
    }

    /// Glowing edge: a fine bright line at the border, fading inwards, tapered at the ends.
    private func edge(_ s: Side, side: CGFloat) -> some View {
        let thick = side * 0.035
        let len = side * 0.76
        let horizontal = s == .top || s == .bottom
        let (from, to): (UnitPoint, UnitPoint) = {
            switch s {
            case .top: return (.top, .bottom)
            case .bottom: return (.bottom, .top)
            case .left: return (.leading, .trailing)
            case .right: return (.trailing, .leading)
            }
        }()
        let lit = style.litColor
        let stops: [Gradient.Stop] = [.init(color: lit.opacity(0.95), location: 0), .init(color: lit.opacity(0.9), location: 0.12),
                                      .init(color: lit.opacity(0.3), location: 0.2), .init(color: lit.opacity(0.08), location: 0.5),
                                      .init(color: lit.opacity(0), location: 1)]
        let taper = Gradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.25),
                                     .init(color: .black, location: 0.75), .init(color: .clear, location: 1)])
        let w = horizontal ? len : thick, h = horizontal ? thick : len
        // a little inside the border, so that the rounded icon shape does not cut the line
        let inset = side * 0.03
        let x: CGFloat, y: CGFloat
        switch s {
        case .top:    x = side / 2;                 y = inset + thick / 2
        case .bottom: x = side / 2;                 y = side - inset - thick / 2
        case .left:   x = inset + thick / 2;        y = side / 2
        case .right:  x = side - inset - thick / 2; y = side / 2
        }
        return Rectangle()
            .fill(LinearGradient(stops: stops, startPoint: from, endPoint: to))
            .mask(LinearGradient(gradient: taper, startPoint: horizontal ? .leading : .top,
                                 endPoint: horizontal ? .trailing : .bottom))
            .frame(width: w, height: h)
            .position(x: x, y: y)
    }
}

extension Snapshots {
    /// Icon drafts at 1024 × 1024 pixels.
    @MainActor
    static func iconDrafts(_ dir: URL) {
        func view(_ v: IconDraft) -> some View { v.frame(width: 512, height: 512) }   // × 2 = 1024 px
        var medium = ClockStyle(language: .de)
        medium.weight = 500
        var bold = medium
        bold.weight = 700
        // A real time: "ES IST FÜNF VOR ZWÖLF" with two minute edges = 11:57
        let full = ClockFace.german
        let fullOn = full.litCells(for: ["ES", "IST", "M5", "VOR", "H0"])
        // D: the whole clock, medium weight, more margin
        writeIcon(view(IconDraft(rows: full.grid, lit: fullOn, edges: [.top, .right], style: medium,
                                 letterSize: 0.6, margin: 0.11)), "icon-d.png", dir)
        // D2: the same in bold
        writeIcon(view(IconDraft(rows: full.grid, lit: fullOn, edges: [.top, .right], style: bold,
                                 letterSize: 0.6, margin: 0.11)), "icon-d2.png", dir)
        // E: reduced grid 6 × 6 with the same time
        let e = ["ESRIST", "FÜNFZW", "QTVORM", "HALBXS", "ZWÖLFK", "SECHSR"]
        func cells(_ list: [(Int, Int, Int)], cols: Int) -> Set<Int> {
            var on = Set<Int>()
            for w in list { for i in 0..<w.2 { on.insert(w.0 * cols + w.1 + i) } }
            return on
        }
        writeIcon(view(IconDraft(rows: e, lit: cells([(0, 0, 2), (0, 3, 3), (1, 0, 4), (2, 2, 3), (4, 0, 5)], cols: 6),
                                 edges: [.top, .right], style: medium, letterSize: 0.55, margin: 0.12)), "icon-e.png", dir)
        // F: reduced grid 5 × 5, "ES IST HALB ZWÖLF" (11:31: one edge)
        let f = ["ESIST", "HALBX", "ZWÖLF", "VIERN", "ACHTE"]
        writeIcon(view(IconDraft(rows: f, lit: cells([(0, 0, 2), (0, 2, 3), (1, 0, 4), (2, 0, 5)], cols: 5),
                                 edges: [.top], style: medium, letterSize: 0.55, margin: 0.12)), "icon-f.png", dir)
    }

    @MainActor
    private static func writeIcon(_ view: some View, _ name: String, _ dir: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return }
        try? png.write(to: dir.appendingPathComponent(name))
        print("✓ \(name)")
    }
}
#endif
