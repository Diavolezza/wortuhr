import AppKit

/// Options dialog (System Settings → Screen Saver → Options …).
/// Changes apply to the preview immediately; "Cancel" restores the previous state.
/// Colours as pop-up lists instead of NSColorWell: the colour panel (NSColorPanel) is
/// unreliable in the sandboxed legacyScreenSaver process.
@MainActor
final class ConfigController: NSObject {

    let window: NSWindow
    private let original: Settings
    private var s: Settings
    private let onChange: (Settings) -> Void

    private let language = NSPopUpButton()
    private let intro = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let front = NSPopUpButton()
    private let lit = NSPopUpButton()
    private let dim = NSSlider(value: 0, minValue: 0, maxValue: 40, target: nil, action: nil)
    private let glow = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let edge = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let font = NSPopUpButton()
    private let weight = NSPopUpButton()
    private let letterScale = NSSlider(value: 100, minValue: 70, maxValue: 140, target: nil, action: nil)
    private let size = NSSlider(value: 92, minValue: 40, maxValue: 100, target: nil, action: nil)
    private let fade = NSSlider(value: 0.8, minValue: 0, maxValue: 3, target: nil, action: nil)
    private let minuteEdges = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let edgeStrength = NSSlider(value: 100, minValue: 10, maxValue: 200, target: nil, action: nil)
    private let edgeSpread = NSSlider(value: 50, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let edgeTrail = NSSlider(value: 40, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let drift = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let mainScreenOnly = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let reset = NSButton(title: "", target: nil, action: nil)
    private let copyButton = NSButton(title: "", target: nil, action: nil)
    private let pasteButton = NSButton(title: "", target: nil, action: nil)
    private let cancel = NSButton(title: "", target: nil, action: nil)
    private let ok = NSButton(title: "", target: nil, action: nil)
    /// Labels whose text depends on the language: field -> key path in Texts
    private var labels: [(NSTextField, KeyPath<Texts, String>, Bool)] = []
    private var ui: UILanguage = .de
    private var t: Texts { Texts.for(ui) }

    private let dimValue = NSTextField(labelWithString: "")
    private let glowValue = NSTextField(labelWithString: "")
    private let edgeValue = NSTextField(labelWithString: "")
    private let letterScaleValue = NSTextField(labelWithString: "")
    private let sizeValue = NSTextField(labelWithString: "")
    private let fadeValue = NSTextField(labelWithString: "")
    private let edgeStrengthValue = NSTextField(labelWithString: "")
    private let edgeSpreadValue = NSTextField(labelWithString: "")
    private let edgeTrailValue = NSTextField(labelWithString: "")

    init(settings: Settings, onChange: @escaping (Settings) -> Void) {
        self.original = settings
        self.s = settings
        self.onChange = onChange
        self.window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                               styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        self.ui = settings.language.ui
        super.init()
        buildUI()
        fill()
    }

    // MARK: - Layout

    private func buildUI() {
        // Languages always in their own language, with a flag
        language.addItems(withTitles: Language.allCases.map { $0.menuTitle })
        weight.addItems(withTitles: Settings.weights.map { $0.0 })

        let controls: [NSControl] = [language, intro, front, lit, dim, glow, edge, font, weight,
                                     letterScale, size, fade, minuteEdges, edgeStrength, edgeSpread,
                                     edgeTrail, drift, mainScreenOnly]
        for c in controls {
            c.target = self
            c.action = #selector(changed(_:))
        }
        for sl in [dim, glow, edge, letterScale, size, fade, edgeStrength, edgeSpread, edgeTrail] {
            sl.isContinuous = true
            sl.translatesAutoresizingMaskIntoConstraints = false
            sl.widthAnchor.constraint(equalToConstant: 220).isActive = true
        }
        for v in [dimValue, glowValue, edgeValue, letterScaleValue, sizeValue, fadeValue,
                  edgeStrengthValue, edgeSpreadValue, edgeTrailValue] {
            v.textColor = .secondaryLabelColor
            v.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize + 1, weight: .regular)
        }

        func label(_ k: KeyPath<Texts, String>) -> NSTextField {
            let l = NSTextField(labelWithString: "")
            l.alignment = .right
            labels.append((l, k, false))
            return l
        }
        func section(_ k: KeyPath<Texts, String>) -> NSTextField {
            let l = NSTextField(labelWithString: "")
            l.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            l.textColor = .secondaryLabelColor
            labels.append((l, k, true))
            return l
        }
        let e = { NSGridCell.emptyContentView }

        let grid = NSGridView(views: [
            [section(\.sectionTime), e(), e()],
            [label(\.language), language, e()],
            [e(), intro, e()],
            [section(\.sectionColors), e(), e()],
            [label(\.front), front, e()],
            [label(\.lit), lit, e()],
            [label(\.dim), dim, dimValue],
            [label(\.glow), glow, glowValue],
            [label(\.edge), edge, edgeValue],
            [section(\.sectionFont), e(), e()],
            [label(\.font), font, e()],
            [label(\.weight), weight, e()],
            [label(\.letterScale), letterScale, letterScaleValue],
            [section(\.sectionLook), e(), e()],
            [label(\.size), size, sizeValue],
            [label(\.fade), fade, fadeValue],
            [e(), minuteEdges, e()],
            [label(\.edgeStrength), edgeStrength, edgeStrengthValue],
            [label(\.edgeSpread), edgeSpread, edgeSpreadValue],
            [label(\.edgeTrail), edgeTrail, edgeTrailValue],
            [e(), drift, e()],
            [e(), mainScreenOnly, e()],
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 2).width = 52
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 10
        for i in [3, 9, 13] { grid.row(at: i).topPadding = 10 }

        reset.target = self; reset.action = #selector(resetDefaults)
        copyButton.target = self; copyButton.action = #selector(copySettings)
        pasteButton.target = self; pasteButton.action = #selector(pasteSettings)
        cancel.target = self; cancel.action = #selector(cancelSheet)
        cancel.keyEquivalent = "\u{1b}"
        ok.target = self; ok.action = #selector(okSheet)
        ok.keyEquivalent = "\r"
        let buttons = NSStackView(views: [reset, copyButton, pasteButton, NSView(), cancel, ok])
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
        applyTexts()
    }

    /// Sets all labels in the dialog's language and adjusts the window size.
    private func applyTexts() {
        let t = self.t
        for (l, k, isSection) in labels {
            l.stringValue = isSection ? t[keyPath: k].uppercased() : t[keyPath: k]
        }
        intro.title = t.intro
        minuteEdges.title = t.minuteEdges
        drift.title = t.drift
        mainScreenOnly.title = t.mainScreenOnly
        reset.title = t.reset
        copyButton.title = t.copy
        pasteButton.title = t.paste
        cancel.title = t.cancel
        ok.title = t.ok

        let fontIndex = max(font.indexOfSelectedItem, 0)
        font.removeAllItems()
        font.addItems(withTitles: Settings.fonts.map { $0 == "System" ? t.systemFont : $0 })
        font.selectItem(at: fontIndex)
        fillColors(front, Settings.frontPresets, t.frontNames, current: s.front)
        fillColors(lit, Settings.litPresets, t.litNames, current: s.lit)

        if let content = window.contentView {
            content.layoutSubtreeIfNeeded()
            let fit = content.fittingSize
            if fit.width > 100 && fit.height > 100 { window.setContentSize(fit) }
        }
    }

    // MARK: - Values

    private func swatch(_ hex: String) -> NSImage {
        let c = NSColor(hex: hex)
        return NSImage(size: NSSize(width: 14, height: 14), flipped: false) { r in
            let p = NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1))
            c.setFill(); p.fill()
            NSColor.gray.withAlphaComponent(0.7).setStroke(); p.lineWidth = 1; p.stroke()
            return true
        }
    }

    private func fillColors(_ popup: NSPopUpButton, _ presets: [String], _ names: [String], current: NSColor) {
        popup.removeAllItems()
        let cur = current.hexString
        for (hex, name) in zip(presets, names) {
            popup.addItem(withTitle: name)
            popup.lastItem?.image = swatch(hex)
            popup.lastItem?.representedObject = hex
        }
        if let i = presets.firstIndex(of: cur) {
            popup.selectItem(at: i)
        } else {
            popup.addItem(withTitle: "\(t.custom) (\(cur))")
            popup.lastItem?.image = swatch(cur)
            popup.lastItem?.representedObject = cur
            popup.selectItem(at: presets.count)
        }
    }

    private func fill() {
        language.selectItem(at: Language.allCases.firstIndex(of: s.language) ?? 0)
        intro.state = s.intro ? .on : .off
        fillColors(front, Settings.frontPresets, t.frontNames, current: s.front)
        fillColors(lit, Settings.litPresets, t.litNames, current: s.lit)
        dim.doubleValue = s.dim
        glow.doubleValue = s.glow
        edge.doubleValue = s.edge
        font.selectItem(at: Settings.fonts.firstIndex(of: s.font) ?? 0)
        weight.selectItem(at: Settings.weights.firstIndex { $0.1 == s.weight } ?? 1)
        letterScale.doubleValue = s.letterScale
        size.doubleValue = s.size
        fade.doubleValue = s.fade
        minuteEdges.state = s.minuteEdges ? .on : .off
        edgeStrength.doubleValue = s.edgeStrength
        edgeSpread.doubleValue = s.edgeSpread
        edgeTrail.doubleValue = s.edgeTrail
        drift.state = s.drift ? .on : .off
        mainScreenOnly.state = s.mainScreenOnly ? .on : .off
        updateLabels()
    }

    private func read() {
        s.language = Language.allCases[max(language.indexOfSelectedItem, 0)]
        s.intro = intro.state == .on
        if let hex = front.selectedItem?.representedObject as? String { s.front = NSColor(hex: hex) }
        if let hex = lit.selectedItem?.representedObject as? String { s.lit = NSColor(hex: hex) }
        s.dim = dim.doubleValue.rounded()
        s.glow = (glow.doubleValue / 5).rounded() * 5
        s.edge = (edge.doubleValue / 5).rounded() * 5
        s.font = Settings.fonts[max(font.indexOfSelectedItem, 0)]
        s.weight = Settings.weights[max(weight.indexOfSelectedItem, 0)].1
        s.letterScale = (letterScale.doubleValue / 5).rounded() * 5
        s.size = (size.doubleValue / 2).rounded() * 2
        s.fade = (fade.doubleValue * 10).rounded() / 10
        s.minuteEdges = minuteEdges.state == .on
        s.edgeStrength = (edgeStrength.doubleValue / 5).rounded() * 5
        s.edgeSpread = (edgeSpread.doubleValue / 5).rounded() * 5
        s.edgeTrail = (edgeTrail.doubleValue / 5).rounded() * 5
        s.drift = drift.state == .on
        s.mainScreenOnly = mainScreenOnly.state == .on
    }

    private func updateLabels() {
        dimValue.stringValue = "\(Int(s.dim)) %"
        glowValue.stringValue = "\(Int(s.glow)) %"
        edgeValue.stringValue = "\(Int(s.edge)) %"
        letterScaleValue.stringValue = "\(Int(s.letterScale)) %"
        sizeValue.stringValue = "\(Int(s.size)) %"
        edgeStrengthValue.stringValue = "\(Int(s.edgeStrength)) %"
        edgeSpreadValue.stringValue = "\(Int(s.edgeSpread)) %"
        edgeTrailValue.stringValue = "\(Int(s.edgeTrail)) %"
        edgeStrength.isEnabled = s.minuteEdges
        edgeSpread.isEnabled = s.minuteEdges
        edgeTrail.isEnabled = s.minuteEdges
        let f = String(format: "%.1f s", s.fade)
        fadeValue.stringValue = t.decimalComma ? f.replacingOccurrences(of: ".", with: ",") : f
    }

    // MARK: - Actions

    @objc private func changed(_ sender: Any?) {
        read()
        if s.language.ui != ui {
            ui = s.language.ui
            applyTexts()
        }
        updateLabels()
        onChange(s)
    }

    /// Default values – the chosen language is kept.
    @objc private func resetDefaults() {
        let keep = s.language
        s = Settings()
        s.language = keep
        fill()
        onChange(s)
    }

    /// Settings as a line of text on the clipboard – can be pasted into the app (and back).
    @objc private func copySettings() {
        read()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s.exchange.text, forType: .string)
    }

    @objc private func pasteSettings() {
        guard let text = NSPasteboard.general.string(forType: .string),
              let x = SettingsExchange(text: text) else {
            NSSound.beep()
            return
        }
        s.apply(x)
        if s.language.ui != ui {
            ui = s.language.ui
            applyTexts()
        }
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
