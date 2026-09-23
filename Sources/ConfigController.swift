import AppKit

/// Optionen-Dialog (Systemeinstellungen → Bildschirmschoner → Optionen …).
/// Änderungen wirken sofort auf die Vorschau; „Abbrechen“ stellt den alten Stand wieder her.
/// Farben als Auswahllisten statt NSColorWell: das Farbfenster (NSColorPanel) ist im
/// abgeschotteten legacyScreenSaver-Prozess unzuverlässig.
@MainActor
final class ConfigController: NSObject {

    let window: NSWindow
    private let original: Settings
    private var s: Settings
    private let onChange: (Settings) -> Void

    private let dialect = NSPopUpButton()
    private let esIst = NSButton(checkboxWithTitle: "„ES IST“ immer anzeigen", target: nil, action: nil)
    private let front = NSPopUpButton()
    private let lit = NSPopUpButton()
    private let dim = NSSlider(value: 0, minValue: 0, maxValue: 40, target: nil, action: nil)
    private let glow = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let edge = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let font = NSPopUpButton()
    private let weight = NSPopUpButton()
    private let letterScale = NSSlider(value: 100, minValue: 70, maxValue: 140, target: nil, action: nil)
    private let look = NSPopUpButton()
    private let size = NSSlider(value: 92, minValue: 40, maxValue: 100, target: nil, action: nil)
    private let fade = NSSlider(value: 0.8, minValue: 0, maxValue: 3, target: nil, action: nil)
    private let dots = NSButton(checkboxWithTitle: "Minutenpunkte", target: nil, action: nil)
    private let drift = NSButton(checkboxWithTitle: "Langsam wandern (Einbrennschutz)", target: nil, action: nil)

    private let dimValue = NSTextField(labelWithString: "")
    private let glowValue = NSTextField(labelWithString: "")
    private let edgeValue = NSTextField(labelWithString: "")
    private let letterScaleValue = NSTextField(labelWithString: "")
    private let sizeValue = NSTextField(labelWithString: "")
    private let fadeValue = NSTextField(labelWithString: "")

    init(settings: Settings, onChange: @escaping (Settings) -> Void) {
        self.original = settings
        self.s = settings
        self.onChange = onChange
        self.window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                               styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        super.init()
        buildUI()
        fill()
    }

    // MARK: - Aufbau

    private func buildUI() {
        dialect.addItems(withTitles: ["Hochdeutsch (viertel nach drei)", "Süddeutsch (viertel vier)"])
        font.addItems(withTitles: Settings.fonts.map { $0.0 })
        weight.addItems(withTitles: Settings.weights.map { $0.0 })
        look.addItems(withTitles: ["Frontplatte", "Vollflächig"])

        let controls: [NSControl] = [dialect, esIst, front, lit, dim, glow, edge, font, weight,
                                     letterScale, look, size, fade, dots, drift]
        for c in controls {
            c.target = self
            c.action = #selector(changed(_:))
        }
        for sl in [dim, glow, edge, letterScale, size, fade] {
            sl.isContinuous = true
            sl.translatesAutoresizingMaskIntoConstraints = false
            sl.widthAnchor.constraint(equalToConstant: 220).isActive = true
        }
        for v in [dimValue, glowValue, edgeValue, letterScaleValue, sizeValue, fadeValue] {
            v.textColor = .secondaryLabelColor
            v.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .regular)
        }

        func label(_ t: String) -> NSTextField {
            let l = NSTextField(labelWithString: t)
            l.alignment = .right
            return l
        }
        func section(_ t: String) -> NSTextField {
            let l = NSTextField(labelWithString: t.uppercased())
            l.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            l.textColor = .secondaryLabelColor
            return l
        }
        let e = { NSGridCell.emptyContentView }

        let grid = NSGridView(views: [
            [section("Zeitansage"), e(), e()],
            [label("Sprache:"), dialect, e()],
            [e(), esIst, e()],
            [section("Farben"), e(), e()],
            [label("Front:"), front, e()],
            [label("Leuchtfarbe:"), lit, e()],
            [label("Unbeleuchtet:"), dim, dimValue],
            [label("Leuchten:"), glow, glowValue],
            [label("Rand:"), edge, edgeValue],
            [section("Schrift"), e(), e()],
            [label("Schrift:"), font, e()],
            [label("Schnitt:"), weight, e()],
            [label("Buchstabengröße:"), letterScale, letterScaleValue],
            [section("Darstellung"), e(), e()],
            [label("Darstellung:"), look, e()],
            [label("Größe:"), size, sizeValue],
            [label("Überblendung:"), fade, fadeValue],
            [e(), dots, e()],
            [e(), drift, e()],
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 2).width = 52
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 10
        for i in [3, 9, 13] { grid.row(at: i).topPadding = 10 }

        let reset = NSButton(title: "Standard", target: self, action: #selector(resetDefaults))
        let cancel = NSButton(title: "Abbrechen", target: self, action: #selector(cancelSheet))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: "OK", target: self, action: #selector(okSheet))
        ok.keyEquivalent = "\r"
        let buttons = NSStackView(views: [reset, NSView(), cancel, ok])
        buttons.orientation = .horizontal
        buttons.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 600))
        content.addSubview(grid)
        content.addSubview(buttons)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            buttons.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 20),
            buttons.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])
        window.contentView = content
        let fit = content.fittingSize
        if fit.width > 100 && fit.height > 100 { window.setContentSize(fit) }
    }

    // MARK: - Werte

    private func swatch(_ hex: String) -> NSImage {
        let c = NSColor(hex: hex)
        return NSImage(size: NSSize(width: 14, height: 14), flipped: false) { r in
            let p = NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1))
            c.setFill(); p.fill()
            NSColor.gray.withAlphaComponent(0.7).setStroke(); p.lineWidth = 1; p.stroke()
            return true
        }
    }

    private func fillColors(_ popup: NSPopUpButton, _ presets: [(String, String)], current: NSColor) {
        popup.removeAllItems()
        let cur = current.hexString
        for (name, hex) in presets {
            popup.addItem(withTitle: name)
            popup.lastItem?.image = swatch(hex)
            popup.lastItem?.representedObject = hex
        }
        if let i = presets.firstIndex(where: { $0.1 == cur }) {
            popup.selectItem(at: i)
        } else {
            popup.addItem(withTitle: "Eigene (\(cur))")
            popup.lastItem?.image = swatch(cur)
            popup.lastItem?.representedObject = cur
            popup.selectItem(at: presets.count)
        }
    }

    private func fill() {
        dialect.selectItem(at: s.dialect == .hoch ? 0 : 1)
        esIst.state = s.esIst ? .on : .off
        fillColors(front, Settings.frontPresets, current: s.front)
        fillColors(lit, Settings.litPresets, current: s.lit)
        dim.doubleValue = s.dim
        glow.doubleValue = s.glow
        edge.doubleValue = s.edge
        font.selectItem(at: Settings.fonts.firstIndex { $0.1 == s.font } ?? 0)
        weight.selectItem(at: Settings.weights.firstIndex { $0.1 == s.weight } ?? 1)
        letterScale.doubleValue = s.letterScale
        look.selectItem(at: s.flat ? 1 : 0)
        size.doubleValue = s.size
        fade.doubleValue = s.fade
        dots.state = s.dots ? .on : .off
        drift.state = s.drift ? .on : .off
        updateLabels()
    }

    private func read() {
        s.dialect = dialect.indexOfSelectedItem == 1 ? .sued : .hoch
        s.esIst = esIst.state == .on
        if let hex = front.selectedItem?.representedObject as? String { s.front = NSColor(hex: hex) }
        if let hex = lit.selectedItem?.representedObject as? String { s.lit = NSColor(hex: hex) }
        s.dim = dim.doubleValue.rounded()
        s.glow = (glow.doubleValue / 5).rounded() * 5
        s.edge = (edge.doubleValue / 5).rounded() * 5
        s.font = Settings.fonts[max(font.indexOfSelectedItem, 0)].1
        s.weight = Settings.weights[max(weight.indexOfSelectedItem, 0)].1
        s.letterScale = (letterScale.doubleValue / 5).rounded() * 5
        s.flat = look.indexOfSelectedItem == 1
        s.size = (size.doubleValue / 2).rounded() * 2
        s.fade = (fade.doubleValue * 10).rounded() / 10
        s.dots = dots.state == .on
        s.drift = drift.state == .on
    }

    private func updateLabels() {
        dimValue.stringValue = "\(Int(s.dim)) %"
        glowValue.stringValue = "\(Int(s.glow)) %"
        edgeValue.stringValue = "\(Int(s.edge)) %"
        letterScaleValue.stringValue = "\(Int(s.letterScale)) %"
        sizeValue.stringValue = "\(Int(s.size)) %"
        fadeValue.stringValue = String(format: "%.1f s", s.fade).replacingOccurrences(of: ".", with: ",")
    }

    // MARK: - Aktionen

    @objc private func changed(_ sender: Any?) {
        read()
        updateLabels()
        onChange(s)
    }

    @objc private func resetDefaults() {
        s = Settings()
        fill()
        onChange(s)
    }

    @objc private func cancelSheet() {
        onChange(original)
        close()
    }

    @objc private func okSheet() {
        read()
        s.save()
        onChange(s)
        close()
    }

    private func close() {
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.orderOut(nil)
        }
    }
}
