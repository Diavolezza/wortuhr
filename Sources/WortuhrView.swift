import ScreenSaver
import QuartzCore
import CoreText
import CoreGraphics

@objc(WortuhrView)
final class WortuhrView: ScreenSaverView {

    var settings = Settings.load()
    private let root = CALayer()
    private let plate = CALayer()
    private let sheen = CAGradientLayer()
    private let rimTop = CALayer()
    private let rimBottom = CALayer()
    private var cellLayers: [CAShapeLayer] = []
    private var dotLayers: [CAShapeLayer] = []
    /// Zusatzzeichen zwischen den Feldern (Apostroph in O'CLOCK) mit ihrem Wort.
    private var markLayers: [(layer: CAShapeLayer, word: String)] = []
    private var lastKey = ""
    private var startDate = Date()
    private var plateCenter = CGPoint.zero
    private var config: ConfigController?
    private var hiddenForActivity = false
    /// true erst nach „didstart“: Nur der echte Bildschirmschoner reagiert auf Eingaben.
    /// (Die Vorschau in den Systemeinstellungen meldet sich unter macOS 26+ fälschlich mit isPreview=false.)
    /// Gilt für den ganzen Prozess: macOS legt nach „didstart“ oft noch eine weitere Ansicht an,
    /// die das Signal sonst nie sähe und dann nicht auf Eingaben reagierte.
    private static var saverRunning = false
    private var saverRunning: Bool {
        get { Self.saverRunning }
        set { Self.saverRunning = newValue }
    }
    /// true nach „willstop“: Der Prozess wird gleich verlassen.
    private static var stopping = false
    /// Echter Bildschirmschoner (nicht die Vorschau): „didstart“ kam, oder der Bildschirm ist
    /// gesperrt. Auf „didstart“ allein ist kein Verlass – es kommt manchmal vor dem Anlegen
    /// der Ansicht und manchmal gar nicht. (Die Größe taugt nicht: Die Vorschau in den
    /// Systemeinstellungen ist intern ebenfalls bildschirmgroß.)
    private var isRealSaver: Bool {
        guard !isPreview, !Self.stopping else { return false }
        return saverRunning || Self.screenIsLocked
    }

    private static var screenIsLocked: Bool {
        let d = CGSessionCopyCurrentDictionary() as? [String: Any]
        return (d?["CGSSessionScreenIsLocked"] as? Bool) ?? false
    }
    /// Feste Uhrzeit (Stunde, Minute) – nur für das Vorschaubild.
    var fixedTime: (Int, Int)?
    private var snapshotScale: CGFloat?
    private var builtSize = CGSize.zero
    /// Eigener Takt statt animateOneFrame: Hinter dem Anmeldefenster ruft macOS
    /// animateOneFrame nicht mehr auf (bzw. stopAnimation), die Uhr bliebe stehen.
    private var ticker: DispatchSourceTimer?

    // MARK: - Lebenszyklus

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    deinit {
        ticker?.cancel()
        DistributedNotificationCenter.default().removeObserver(self)
    }

    private func setUp() {
        animationTimeInterval = 0.25
        // Layer-hosting: eigene Layer-Hierarchie, kein draw(_:)
        layer = root
        wantsLayer = true
        root.backgroundColor = NSColor.black.cgColor
        root.addSublayer(plate)
        plate.addSublayer(sheen)
        plate.addSublayer(rimTop)
        plate.addSublayer(rimBottom)

        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenSaverDidStart(_:)),
                        name: Notification.Name("com.apple.screensaver.didstart"), object: nil)
        dnc.addObserver(self, selector: #selector(screenSaverWillStop(_:)),
                        name: Notification.Name("com.apple.screensaver.willstop"), object: nil)
        rebuild()
    }

    /// Der echte Bildschirmschoner läuft: ab jetzt auf Maus und Tastatur reagieren.
    @objc private func screenSaverDidStart(_ note: Notification) {
        Log.n("Bildschirmschoner gestartet")
        saverRunning = true
        startDate = Date()
        startTicker()
        if hiddenForActivity {
            hiddenForActivity = false
            setClockVisible(true)
        }
    }

    /// Seit macOS 14 beendet sich legacyScreenSaver nach dem Bildschirmschoner nicht mehr.
    /// Ohne diesen Ausstieg laufen alte Instanzen im Hintergrund weiter.
    @objc private func screenSaverWillStop(_ note: Notification) {
        saverRunning = false
        if !isPreview { Self.stopping = true }
        guard !isPreview else { return }
        Log.n("Bildschirmschoner beendet → Prozess wird verlassen")
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        plate.opacity = 0
        CATransaction.commit()
        stopTicker()
        stopAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { exit(0) }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        rebuild()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        rebuild()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        rebuild()
    }

    override func startAnimation() {
        super.startAnimation()
        plate.opacity = 1
        hiddenForActivity = false
        startDate = Date()
        updateTime(animated: false)
        startTicker()
    }

    override func stopAnimation() {
        super.stopAnimation()
        // Der echte Bildschirmschoner bekommt stopAnimation auch, wenn nur das
        // Anmeldefenster erscheint – dann weiterlaufen. Beendet wird über willstop.
        if !isRealSaver {
            stopTicker()
        } else {
            Log.n("stopAnimation während der Bildschirmschoner läuft → Uhr läuft weiter")
        }
    }

    override func animateOneFrame() {
        // Leer: Die Arbeit macht tick().
    }

    private func startTicker() {
        guard ticker == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: animationTimeInterval, leeway: .milliseconds(50))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        ticker = t
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        // Manche macOS-Versionen ändern die Größe, ohne setFrameSize aufzurufen.
        if bounds.size != builtSize { rebuild() }
        checkActivity()
        updateTime(animated: true)
        if settings.drift { moveDrift() }
    }

    // MARK: - Aufbau

    private var backingScale: CGFloat {
        snapshotScale ?? window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
    }

    private func rebuild() {
        let b = bounds
        guard b.width > 0, b.height > 0 else { return }
        builtSize = b.size
        let s = settings
        let scale = backingScale

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        root.frame = b
        root.contentsScale = scale
        root.backgroundColor = (s.flat ? s.front : NSColor.black).cgColor

        // Platte
        let side = floor(min(b.width, b.height) * CGFloat(s.size / 100))
        plateCenter = CGPoint(x: b.midX, y: b.midY)
        plate.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        plate.position = plateCenter
        plate.contentsScale = scale
        plate.cornerRadius = side * 0.012
        plate.backgroundColor = s.flat ? nil : s.front.cgColor

        // Kante: feiner heller Rand + Lichtkante oben, Schattenkante unten
        let e = CGFloat(s.edge / 100)
        plate.borderWidth = s.flat ? 0 : 1
        plate.borderColor = NSColor(white: 1, alpha: 0.03 + e * 0.22).cgColor
        let inset = plate.cornerRadius
        rimTop.frame = CGRect(x: inset, y: side - 2, width: side - 2 * inset, height: 1)
        rimTop.backgroundColor = NSColor(white: 1, alpha: e * 0.20).cgColor
        rimBottom.frame = CGRect(x: inset, y: 1, width: side - 2 * inset, height: 1)
        rimBottom.backgroundColor = NSColor(white: 0, alpha: 0.45).cgColor
        rimTop.isHidden = s.flat
        rimBottom.isHidden = s.flat

        // Glanz: leichter Verlauf von oben links nach unten rechts
        sheen.frame = plate.bounds
        sheen.cornerRadius = plate.cornerRadius
        sheen.masksToBounds = true
        sheen.colors = [NSColor(white: 1, alpha: 0.055).cgColor,
                        NSColor(white: 1, alpha: 0).cgColor,
                        NSColor(white: 0, alpha: 0.12).cgColor]
        sheen.locations = [0, 0.45, 1]
        sheen.startPoint = CGPoint(x: 0.33, y: 1)
        sheen.endPoint = CGPoint(x: 0.67, y: 0)
        sheen.isHidden = s.flat

        // Buchstaben
        cellLayers.forEach { $0.removeFromSuperlayer() }
        cellLayers.removeAll()
        markLayers.forEach { $0.layer.removeFromSuperlayer() }
        markLayers.removeAll()
        let face = s.language.face
        let font = s.makeFont(size: side * 0.043 * CGFloat(s.letterScale / 100))
        let ctFont = font as CTFont
        let capHeight = font.capHeight
        let gx0 = side * 0.10, gw = side * 0.80
        let gy0 = side * 0.105, gh = side * 0.79
        let cw = gw / CGFloat(ClockFace.cols), ch = gh / CGFloat(ClockFace.rows)
        let glowRadius = font.pointSize * 0.35 * CGFloat(s.glow / 100)

        /// Zeichen mittig über x, Grundlinie wie alle Buchstaben der Zeile r.
        func glyphLayer(_ letter: String, x: CGFloat, row r: Int) -> CAShapeLayer {
            let l = CAShapeLayer()
            l.contentsScale = scale
            let glyph = glyphPath(letter, font: ctFont)
            let cy = side - (gy0 + ch * (CGFloat(r) + 0.5))   // Layer-Koordinaten: y nach oben
            let bb = glyph.boundingBoxOfPath
            var t = CGAffineTransform(translationX: x - bb.midX, y: cy - capHeight / 2)
            l.path = glyph.copy(using: &t)
            l.shadowColor = s.lit.cgColor
            l.shadowOffset = .zero
            l.shadowRadius = glowRadius
            l.shadowOpacity = 0
            l.fillColor = s.offColor.cgColor
            plate.addSublayer(l)
            return l
        }
        for r in 0..<ClockFace.rows {
            for c in 0..<ClockFace.cols {
                let cx = gx0 + cw * (CGFloat(c) + 0.5)
                cellLayers.append(glyphLayer(face.letter(row: r, col: c), x: cx, row: r))
            }
        }
        for mark in face.marks {
            let x = gx0 + cw * CGFloat(mark.afterCol + 1)
            markLayers.append((glyphLayer(mark.glyph, x: x, row: mark.row), mark.word))
        }

        // Minutenpunkte: 1 oben links, 2 oben rechts, 3 unten rechts, 4 unten links
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()
        let d = side * 0.0105
        let m = side * 0.05 + d / 2
        let centers = [CGPoint(x: m, y: side - m), CGPoint(x: side - m, y: side - m),
                       CGPoint(x: side - m, y: m), CGPoint(x: m, y: m)]
        for p in centers {
            let l = CAShapeLayer()
            l.contentsScale = scale
            l.path = CGPath(ellipseIn: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d), transform: nil)
            l.shadowColor = s.lit.cgColor
            l.shadowOffset = .zero
            l.shadowRadius = side * 0.008 * CGFloat(s.glow / 100) + 0.5
            l.shadowOpacity = 0
            l.fillColor = s.offColor.cgColor
            l.isHidden = !s.dots
            plate.addSublayer(l)
            dotLayers.append(l)
        }

        CATransaction.commit()
        lastKey = ""
        updateTime(animated: false)
    }

    private func glyphPath(_ letter: String, font: CTFont) -> CGPath {
        var chars = Array(letter.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        guard !chars.isEmpty,
              CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count),
              let path = CTFontCreatePathForGlyph(font, glyphs[0], nil)
        else { return CGMutablePath() }
        return path
    }

    // MARK: - Zeit

    private func updateTime(animated: Bool) {
        guard !cellLayers.isEmpty else { return }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let h = fixedTime?.0 ?? now.hour ?? 0, m = fixedTime?.1 ?? now.minute ?? 0
        let key = "\(h):\(m)"
        if key == lastKey { return }
        lastKey = key

        let s = settings
        let p = ClockFace.phrase(hour24: h, minute: m, language: s.language, intro: s.intro)
        let on = s.language.face.litCells(for: p.words)
        let litColor = s.lit.cgColor
        let offColor = s.offColor.cgColor
        let glowOpacity: Float = s.glow > 0 ? 0.9 : 0

        CATransaction.begin()
        if animated && s.fade > 0 {
            CATransaction.setAnimationDuration(s.fade)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        for (i, l) in cellLayers.enumerated() {
            let lit = on.contains(i)
            l.fillColor = lit ? litColor : offColor
            l.shadowOpacity = lit ? glowOpacity : 0
        }
        for (l, word) in markLayers {
            let lit = p.words.contains(word)
            l.fillColor = lit ? litColor : offColor
            l.shadowOpacity = lit ? glowOpacity : 0
        }
        for (i, l) in dotLayers.enumerated() {
            let lit = i < p.dots
            l.fillColor = lit ? litColor : offColor
            l.shadowOpacity = lit ? glowOpacity : 0
        }
        CATransaction.commit()
    }

    // MARK: - Anmeldebildschirm

    /// Sekunden seit der letzten Eingabe (Maus, Tastatur, Trackpad).
    private func secondsSinceInput() -> Double {
        let types: [CGEventType] = [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown,
                                    .scrollWheel, .flagsChanged, .leftMouseDragged]
        return types.map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }.min() ?? .infinity
    }

    /// Seit Sonoma läuft der Bildschirmschoner hinter dem Anmeldefenster weiter, bis man
    /// sich angemeldet hat. Sobald Maus oder Tastatur benutzt werden, blendet die Uhr aus,
    /// damit das Anmeldefenster auf ruhigem Schwarz steht. Nach 30 s ohne Eingabe blendet
    /// macOS das Anmeldefenster wieder aus („standard timeout of: 30“) – dann kommt die Uhr zurück.
    /// So lange zeigt macOS das Anmeldefenster ohne Eingabe, dann wieder den Bildschirmschoner.
    private static let loginTimeout: Double = 30

    private func checkActivity() {
        guard isRealSaver else { return }
        let idle = secondsSinceInput()
        let running = Date().timeIntervalSince(startDate)
        if !hiddenForActivity && running > 2 && idle < 1.0 {
            Log.n("Eingabe erkannt → Uhr ausblenden")
            hiddenForActivity = true
            setClockVisible(false)
        } else if hiddenForActivity && idle > Self.loginTimeout {
            Log.n("\(Int(Self.loginTimeout)) s keine Eingabe → Uhr wieder einblenden")
            hiddenForActivity = false
            setClockVisible(true)
        }
    }

    private func setClockVisible(_ visible: Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(visible ? 1.0 : 0.3)
        plate.opacity = visible ? 1 : 0
        root.backgroundColor = (visible && settings.flat ? settings.front : NSColor.black).cgColor
        CATransaction.commit()
    }

    // MARK: - Vorschaubild

    /// Baut die Uhr für eine Momentaufnahme ohne Fenster auf (siehe Tools/main.swift).
    func prepareSnapshot(scale: CGFloat) {
        snapshotScale = scale
        rebuild()
    }

    /// Einbrennschutz: die Uhr wandert langsam, aber nur im freien Bereich.
    /// Oben und unten bleibt immer ein Rand sichtbar.
    private func moveDrift() {
        let b = bounds
        let side = plate.bounds.width
        let ax = min(max((b.width - side) / 2 - 12, 0), b.width * 0.06)
        let ay = min(max((b.height - side) / 2 - 12, 0), b.height * 0.03)
        let t = Date().timeIntervalSince(startDate)
        let target = CGPoint(x: plateCenter.x + ax * CGFloat(sin(2 * .pi * t / 180)),
                             y: plateCenter.y + ay * CGFloat(sin(2 * .pi * t / 137)))
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationTimeInterval)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        plate.position = target
        CATransaction.commit()
    }

    // MARK: - Optionen

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        let c = ConfigController(settings: settings) { [weak self] s in
            self?.settings = s
            self?.rebuild()
        }
        config = c
        return c.window
    }
}
