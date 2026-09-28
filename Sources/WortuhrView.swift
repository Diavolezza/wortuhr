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
    /// Extra glyphs between cells (apostrophe in O'CLOCK) with the word they light up with.
    private var markLayers: [(layer: CAShapeLayer, word: String)] = []
    private var lastKey = ""
    private var startDate = Date()
    private var plateCenter = CGPoint.zero
    private var config: ConfigController?
    private var hiddenForActivity = false
    /// Secondary display with "main display only" switched on: stays black.
    private var blankedDisplay = false
    /// True only after "didstart": only the real screen saver reacts to input.
    /// (On macOS 26+ the preview in System Settings wrongly reports isPreview = false.)
    /// Process-wide: after "didstart" macOS often creates another view, which would
    /// otherwise never see the notification and would ignore input.
    private static var saverRunning = false
    private var saverRunning: Bool {
        get { Self.saverRunning }
        set { Self.saverRunning = newValue }
    }
    /// True after "willstop": the process is about to exit.
    private static var stopping = false
    /// Real screen saver (not the preview): "didstart" arrived, or the screen is locked.
    /// "didstart" alone is unreliable – it sometimes arrives before the view is created and
    /// sometimes not at all. (The size is no indicator: the System Settings preview is
    /// screen-sized internally as well.)
    private var isRealSaver: Bool {
        guard !isPreview, !Self.stopping else { return false }
        return saverRunning || Self.screenIsLocked
    }

    private static var screenIsLocked: Bool {
        let d = CGSessionCopyCurrentDictionary() as? [String: Any]
        return (d?["CGSSessionScreenIsLocked"] as? Bool) ?? false
    }
    /// Fixed time (hour, minute) – only for the thumbnail.
    var fixedTime: (Int, Int)?
    private var snapshotScale: CGFloat?
    private var builtSize = CGSize.zero
    /// Own timer instead of animateOneFrame: behind the login window macOS stops calling
    /// animateOneFrame (or calls stopAnimation), and the clock would freeze.
    private var ticker: DispatchSourceTimer?

    // MARK: - Lifecycle

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
        // Layer hosting: own layer tree, no draw(_:)
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

    /// The real screen saver is running: react to mouse and keyboard from now on.
    @objc private func screenSaverDidStart(_ note: Notification) {
        Log.n("Screen saver started")
        saverRunning = true
        startDate = Date()
        startTicker()
        if hiddenForActivity {
            hiddenForActivity = false
            setClockVisible(true)
        }
    }

    /// Since macOS 14, legacyScreenSaver no longer exits after the screen saver ends.
    /// Without this exit, old instances keep running in the background.
    @objc private func screenSaverWillStop(_ note: Notification) {
        saverRunning = false
        if !isPreview { Self.stopping = true }
        guard !isPreview else { return }
        Log.n("Screen saver stopped → exiting process")
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
        hiddenForActivity = false
        blankedDisplay = shouldBlankDisplay
        plate.opacity = blankedDisplay ? 0 : 1
        startDate = Date()
        updateTime(animated: false)
        startTicker()
    }

    override func stopAnimation() {
        super.stopAnimation()
        // The real screen saver also gets stopAnimation when only the login window
        // appears – keep running then. It ends via willstop.
        if !isRealSaver {
            stopTicker()
        } else {
            Log.n("stopAnimation while the screen saver is running → clock keeps running")
        }
    }

    override func animateOneFrame() {
        // Empty: tick() does the work.
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
        let blank = shouldBlankDisplay
        if blank != blankedDisplay {
            blankedDisplay = blank
            setClockVisible(!hiddenForActivity)
        }
        // Some macOS versions change the size without calling setFrameSize.
        if bounds.size != builtSize { rebuild() }
        checkActivity()
        updateTime(animated: true)
        if settings.drift { moveDrift() }
    }

    // MARK: - Layout

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
        root.backgroundColor = (s.flat && !blankedDisplay && !hiddenForActivity ? s.front : NSColor.black).cgColor

        // Plate
        let side = floor(min(b.width, b.height) * CGFloat(s.size / 100))
        plateCenter = CGPoint(x: b.midX, y: b.midY)
        plate.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        plate.position = plateCenter
        plate.contentsScale = scale
        plate.cornerRadius = side * 0.012
        plate.backgroundColor = s.flat ? nil : s.front.cgColor

        // Edge: fine light border, highlight at the top, shadow at the bottom
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

        // Sheen: subtle gradient from top left to bottom right
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

        // Letters
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

        /// Glyph centred on x, on the same baseline as all letters of row r.
        func glyphLayer(_ letter: String, x: CGFloat, row r: Int) -> CAShapeLayer {
            let l = CAShapeLayer()
            l.contentsScale = scale
            let glyph = glyphPath(letter, font: ctFont)
            let cy = side - (gy0 + ch * (CGFloat(r) + 0.5))   // layer coordinates: y points up
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

        // Minute dots: 1 top left, 2 top right, 3 bottom right, 4 bottom left
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

    // MARK: - Time

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

    // MARK: - Login window

    /// Seconds since the last input (mouse, keyboard, trackpad).
    private func secondsSinceInput() -> Double {
        let types: [CGEventType] = [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown,
                                    .scrollWheel, .flagsChanged, .leftMouseDragged]
        return types.map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }.min() ?? .infinity
    }

    /// Since Sonoma the screen saver keeps running behind the login window until the user
    /// logs in. As soon as mouse or keyboard are used, the clock fades out so the login window
    /// sits on plain black. After 30 s without input macOS hides the login window again
    /// ("standard timeout of: 30") – then the clock comes back.
    /// How long macOS shows the login window without input before returning to the screen saver.
    private static let loginTimeout: Double = 30

    private func checkActivity() {
        guard isRealSaver else { return }
        let idle = secondsSinceInput()
        let running = Date().timeIntervalSince(startDate)
        if !hiddenForActivity && running > 2 && idle < 1.0 {
            Log.n("Input detected → hiding clock")
            hiddenForActivity = true
            setClockVisible(false)
        } else if hiddenForActivity && idle > Self.loginTimeout {
            Log.n("No input for \(Int(Self.loginTimeout)) s → showing clock again")
            hiddenForActivity = false
            setClockVisible(true)
        }
    }

    /// "Main display only": the real screen saver on any display other than the one with the
    /// menu bar stays black. The preview in System Settings always shows the clock.
    private var shouldBlankDisplay: Bool {
        guard settings.mainScreenOnly, isRealSaver, NSScreen.screens.count > 1,
              let screen = window?.screen else { return false }
        return screen != NSScreen.screens.first
    }

    private func setClockVisible(_ requested: Bool) {
        let visible = requested && !blankedDisplay
        CATransaction.begin()
        CATransaction.setAnimationDuration(visible ? 1.0 : 0.3)
        plate.opacity = visible ? 1 : 0
        root.backgroundColor = (visible && settings.flat ? settings.front : NSColor.black).cgColor
        CATransaction.commit()
    }

    // MARK: - Thumbnail

    /// Builds the clock for a snapshot without a window (see Tools/main.swift).
    func prepareSnapshot(scale: CGFloat) {
        snapshotScale = scale
        rebuild()
    }

    /// Burn-in protection: the clock drifts slowly, but only within the free area.
    /// A margin always stays visible at the top and bottom.
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

    // MARK: - Options

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
