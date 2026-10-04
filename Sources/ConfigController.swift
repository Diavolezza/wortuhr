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
    private let cancel = NSButton(title: "", target: nil, action: nil)
    private let ok = NSButton(title: "", target: nil, action: nil)
    /// Link to the support page (Ko-fi), shown like a hyperlink
    private let support = NSButton(title: "", target: nil, action: nil)
    static let supportURL = URL(string: "https://ko-fi.com/diavolezza")!
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
        cancel.target = self; cancel.action = #selector(cancelSheet)
        cancel.keyEquivalent = "\u{1b}"
        ok.target = self; ok.action = #selector(okSheet)
        ok.keyEquivalent = "\r"
        support.target = self; support.action = #selector(openSupport)
        support.isBordered = false
        support.toolTip = Self.supportURL.absoluteString
        let buttons = NSStackView(views: [reset, support, NSView(), cancel, ok])
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
        cancel.title = t.cancel
        ok.title = t.ok
        support.attributedTitle = NSAttributedString(string: t.support, attributes: [
            .foregroundColor: NSColor.linkColor,
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize + 1),
        ])

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

    @objc private func cancelSheet() {
        onChange(original)
        close()
    }

    /// Opens the support page in the browser.
    @objc private func openSupport() {
        NSWorkspace.shared.open(Self.supportURL)
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

extension Language {
    /// Entry in the language list: flag and name in its own language.
    var menuTitle: String {
        switch self {
        case .de:      return "🇩🇪 Deutsch – Hochdeutsch (viertel nach drei)"
        case .deCH:    return "🇨🇭 Deutsch – Schwiizerdütsch (viertel ab drü)"
        case .deSouth: return "🇩🇪 Deutsch – Süddeutsch (viertel vier)"
        case .en:      return "🇬🇧 English – UK (a quarter past three)"
        case .us:      return "🇺🇸 English – US (a quarter after three)"
        case .es:      return "🇪🇸 Español (las tres y cuarto)"
        case .fr:      return "🇫🇷 Français (trois heures et quart)"
        case .it:      return "🇮🇹 Italiano (le tre e un quarto)"
        }
    }
}

/// Texts of the options dialog.
struct Texts {
    let sectionTime, language, intro: String
    let sectionColors, front, lit, dim, glow, edge, custom: String
    let sectionFont, font, weight, letterScale, systemFont: String
    let sectionLook, size, fade, minuteEdges, edgeStrength, edgeSpread, edgeTrail, drift, mainScreenOnly: String
    let reset, cancel, ok, support: String
    /// Colour names in the order of Settings.frontPresets / Settings.litPresets
    let frontNames, litNames: [String]
    let decimalComma: Bool

    static func `for`(_ ui: UILanguage) -> Texts {
        switch ui {
        case .de:   return de
        case .deCH: return deCH
        case .enGB: return enGB
        case .enUS: return enUS
        case .fr:   return fr
        case .it:   return it
        case .es:   return es
        }
    }

    static let de = Texts(
        sectionTime: "Zeitansage", language: "Sprache:", intro: "„ES IST“ immer anzeigen",
        sectionColors: "Farben", front: "Front:", lit: "Leuchtfarbe:", dim: "Unbeleuchtet:",
        glow: "Leuchten:", edge: "Rand:", custom: "Eigene",
        sectionFont: "Schrift", font: "Schrift:", weight: "Schnitt:", letterScale: "Buchstabengröße:",
        systemFont: "SF Pro (Systemschrift)",
        sectionLook: "Darstellung",
        size: "Größe:", fade: "Überblendung:", minuteEdges: "Minuten an den Kanten anzeigen",
        edgeStrength: "Kantenlicht:", edgeSpread: "Ausbreitung:", edgeTrail: "Nachglühen:",
        drift: "Langsam wandern (Einbrennschutz)", mainScreenOnly: "Nur auf dem Hauptbildschirm",
        reset: "Standard", cancel: "Abbrechen", ok: "OK", support: "Wortuhr unterstützen …",
        frontNames: ["Tiefschwarz", "Graphit", "Nachtblau", "Tannengrün", "Ziegelrot", "Kalkweiß"],
        litNames: ["Warmweiß", "Kaltweiß", "Bernstein", "Eisblau", "Mint", "Anthrazit"],
        decimalComma: true)

    // Swiss Standard German: ss instead of ß, «» quotes, decimal point
    static let deCH = Texts(
        sectionTime: "Zeitansage", language: "Sprache:", intro: "«ES ISCH» immer anzeigen",
        sectionColors: "Farben", front: "Front:", lit: "Leuchtfarbe:", dim: "Unbeleuchtet:",
        glow: "Leuchten:", edge: "Rand:", custom: "Eigene",
        sectionFont: "Schrift", font: "Schrift:", weight: "Schnitt:", letterScale: "Buchstabengrösse:",
        systemFont: "SF Pro (Systemschrift)",
        sectionLook: "Darstellung",
        size: "Grösse:", fade: "Überblendung:", minuteEdges: "Minuten an den Kanten anzeigen",
        edgeStrength: "Kantenlicht:", edgeSpread: "Ausbreitung:", edgeTrail: "Nachglühen:",
        drift: "Langsam wandern (Einbrennschutz)", mainScreenOnly: "Nur auf dem Hauptbildschirm",
        reset: "Standard", cancel: "Abbrechen", ok: "OK", support: "Wortuhr unterstützen …",
        frontNames: ["Tiefschwarz", "Graphit", "Nachtblau", "Tannengrün", "Ziegelrot", "Kalkweiss"],
        litNames: ["Warmweiss", "Kaltweiss", "Bernstein", "Eisblau", "Mint", "Anthrazit"],
        decimalComma: false)

    static let enGB = Texts(
        sectionTime: "Time", language: "Language:", intro: "Always show “IT IS”",
        sectionColors: "Colours", front: "Faceplate:", lit: "Lit colour:", dim: "Unlit letters:",
        glow: "Glow:", edge: "Rim:", custom: "Custom",
        sectionFont: "Typeface", font: "Typeface:", weight: "Weight:", letterScale: "Letter size:",
        systemFont: "SF Pro (system font)",
        sectionLook: "Appearance",
        size: "Size:", fade: "Cross-fade:", minuteEdges: "Show minutes at the edges",
        edgeStrength: "Edge light:", edgeSpread: "Spread:", edgeTrail: "Afterglow:",
        drift: "Drift slowly (burn-in protection)", mainScreenOnly: "Main display only",
        reset: "Defaults", cancel: "Cancel", ok: "OK", support: "Support Wortuhr…",
        frontNames: ["Deep black", "Graphite", "Midnight blue", "Forest green", "Brick red", "Chalk white"],
        litNames: ["Warm white", "Cool white", "Amber", "Ice blue", "Mint", "Charcoal"],
        decimalComma: false)

    static let enUS = Texts(
        sectionTime: "Time", language: "Language:", intro: "Always show “IT IS”",
        sectionColors: "Colors", front: "Faceplate:", lit: "Lit color:", dim: "Unlit letters:",
        glow: "Glow:", edge: "Rim:", custom: "Custom",
        sectionFont: "Typeface", font: "Typeface:", weight: "Weight:", letterScale: "Letter size:",
        systemFont: "SF Pro (system font)",
        sectionLook: "Appearance",
        size: "Size:", fade: "Cross-fade:", minuteEdges: "Show minutes at the edges",
        edgeStrength: "Edge light:", edgeSpread: "Spread:", edgeTrail: "Afterglow:",
        drift: "Drift slowly (burn-in protection)", mainScreenOnly: "Main display only",
        reset: "Defaults", cancel: "Cancel", ok: "OK", support: "Support Wortuhr…",
        frontNames: ["Deep black", "Graphite", "Midnight blue", "Forest green", "Brick red", "Chalk white"],
        litNames: ["Warm white", "Cool white", "Amber", "Ice blue", "Mint", "Charcoal"],
        decimalComma: false)

    // French: narrow no-break space before the colon
    static let fr = Texts(
        sectionTime: "Heure", language: "Langue\u{202F}:", intro: "Toujours afficher «\u{202F}IL EST\u{202F}»",
        sectionColors: "Couleurs", front: "Façade\u{202F}:", lit: "Couleur de l’éclairage\u{202F}:",
        dim: "Lettres éteintes\u{202F}:", glow: "Halo\u{202F}:", edge: "Liseré\u{202F}:", custom: "Personnalisée",
        sectionFont: "Police", font: "Police\u{202F}:", weight: "Graisse\u{202F}:",
        letterScale: "Taille des lettres\u{202F}:", systemFont: "SF Pro (police système)",
        sectionLook: "Affichage",
        size: "Taille\u{202F}:", fade: "Fondu\u{202F}:", minuteEdges: "Afficher les minutes sur les bords",
        edgeStrength: "Lumière des bords\u{202F}:", edgeSpread: "Diffusion\u{202F}:", edgeTrail: "Rémanence\u{202F}:",
        drift: "Déplacement lent (anti-marquage)", mainScreenOnly: "Écran principal uniquement",
        reset: "Par défaut", cancel: "Annuler", ok: "OK", support: "Soutenir Wortuhr…",
        frontNames: ["Noir profond", "Graphite", "Bleu nuit", "Vert sapin", "Rouge brique", "Blanc craie"],
        litNames: ["Blanc chaud", "Blanc froid", "Ambre", "Bleu glacier", "Menthe", "Anthracite"],
        decimalComma: true)

    static let it = Texts(
        sectionTime: "Ora", language: "Lingua:", intro: "Mostra sempre «SONO» / «È»",
        sectionColors: "Colori", front: "Frontale:", lit: "Colore della luce:", dim: "Lettere spente:",
        glow: "Bagliore:", edge: "Profilo:", custom: "Personalizzato",
        sectionFont: "Carattere", font: "Carattere:", weight: "Peso:", letterScale: "Dimensione delle lettere:",
        systemFont: "SF Pro (font di sistema)",
        sectionLook: "Aspetto",
        size: "Dimensione:", fade: "Dissolvenza:", minuteEdges: "Mostra i minuti sui bordi",
        edgeStrength: "Luce dei bordi:", edgeSpread: "Diffusione:", edgeTrail: "Persistenza:",
        drift: "Spostamento lento (anti burn-in)", mainScreenOnly: "Solo sullo schermo principale",
        reset: "Predefiniti", cancel: "Annulla", ok: "OK", support: "Sostieni Wortuhr…",
        frontNames: ["Nero profondo", "Grafite", "Blu notte", "Verde abete", "Rosso mattone", "Bianco gesso"],
        litNames: ["Bianco caldo", "Bianco freddo", "Ambra", "Blu ghiaccio", "Menta", "Antracite"],
        decimalComma: true)

    static let es = Texts(
        sectionTime: "Hora", language: "Idioma:", intro: "Mostrar siempre «SON» / «ES»",
        sectionColors: "Colores", front: "Frontal:", lit: "Color de luz:", dim: "Letras apagadas:",
        glow: "Resplandor:", edge: "Contorno:", custom: "Personalizado",
        sectionFont: "Tipografía", font: "Tipografía:", weight: "Grosor:", letterScale: "Tamaño de letra:",
        systemFont: "SF Pro (fuente del sistema)",
        sectionLook: "Aspecto",
        size: "Tamaño:", fade: "Fundido:", minuteEdges: "Mostrar los minutos en los bordes",
        edgeStrength: "Luz de los bordes:", edgeSpread: "Difusión:", edgeTrail: "Estela:",
        drift: "Desplazamiento lento (antiquemado)", mainScreenOnly: "Solo en la pantalla principal",
        reset: "Restablecer", cancel: "Cancelar", ok: "Aceptar", support: "Apoyar Wortuhr…",
        frontNames: ["Negro profundo", "Grafito", "Azul noche", "Verde abeto", "Rojo ladrillo", "Blanco tiza"],
        litNames: ["Blanco cálido", "Blanco frío", "Ámbar", "Azul hielo", "Menta", "Antracita"],
        decimalComma: true)
}
