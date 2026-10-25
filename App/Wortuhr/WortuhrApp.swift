import SwiftUI

@main
struct WortuhrApp: App {
    @State private var store = StyleStore()

    init() {
        #if os(macOS)
        MainActor.assumeIsolated {
            Snapshots.runIfRequested()
            // One window, no tabs: removes "Show Tab Bar" and "Show All Tabs" from the View menu
            NSWindow.allowsAutomaticWindowTabbing = false
            // No text input anywhere: no "Start Dictation" and "Emoji & Symbols" in the Edit menu
            UserDefaults.standard.set(true, forKey: "NSDisabledDictationMenuItem")
            UserDefaults.standard.set(true, forKey: "NSDisabledCharacterPaletteMenuItem")
        }
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        // One clock window, like Calculator: no "New Window", no "Close" (the app menu has "Quit"),
        // so the File menu disappears; closing the window quits the app (single Window scene)
        Window("Wortuhr", id: "clock") {
            ContentView()
                .environment(store)
        }
        .defaultSize(width: 760, height: 760)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .saveItem) {}
            // Edit menu: nothing to undo or to edit as text; Copy / Paste transfer the settings
            // (the same as the buttons in the settings and in the screen saver's options)
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .pasteboard) {
                let t = Texts.for(store.style.language.ui)
                Button(t.copy) { Clipboard.string = store.style.exchange.text }
                    .keyboardShortcut("c")
                Button(t.paste) {
                    if let text = Clipboard.string, let x = SettingsExchange(text: text) {
                        store.style.apply(x)
                    } else {
                        NSSound.beep()
                    }
                }
                .keyboardShortcut("v")
            }
            // Help: the support page instead of "Help isn't available"
            CommandGroup(replacing: .help) {
                let ui = store.style.language.ui
                let german = ui == .de || ui == .deCH
                Button(AppTexts.for(ui).help) {
                    NSWorkspace.shared.open(URL(string: "https://diavolezza.github.io/wortuhr/support.html"
                                                + (german ? "#de" : "#en"))!)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(store)
                .frame(width: 520, height: 700)
        }
        #else
        WindowGroup {
            ContentView()
                .environment(store)
        }
        #endif
    }
}

/// The clock on black. iOS: tap for the settings. macOS: double-click for full screen,
/// settings with ⌘, or the context menu.
struct ContentView: View {
    @Environment(StyleStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()
    @State private var showSettings = false

    var body: some View {
        let a = AppTexts.for(store.style.language.ui)
        orientedClock
            .background(Color.black)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onAppear { store.applyKeepAwake() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { store.applyKeepAwake() }
            }
            #if os(iOS)
            .onTapGesture { showSettings = true }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .navigationTitle(a.settings)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(a.done) { showSettings = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
            #else
            .background(WindowFrameSaver())
            .onTapGesture(count: 2) { NSApp.keyWindow?.toggleFullScreen(nil) }
            .contextMenu {
                SettingsLink { Text(a.settings + " …") }
                Button(a.fullScreen) { NSApp.keyWindow?.toggleFullScreen(nil) }
            }
            #endif
    }

    @ViewBuilder private var orientedClock: some View {
        #if os(iOS)
        UprightClock { clock }
        #else
        clock
        #endif
    }

    /// Minute steps; with "drift" every two seconds, so the plate moves smoothly.
    @ViewBuilder private var clock: some View {
        if store.style.drift {
            TimelineView(.periodic(from: .now, by: 2)) { context in
                let minute = Calendar.current.dateInterval(of: .minute, for: context.date)?.start ?? context.date
                WordClockView(style: store.style, date: minute, driftTime: context.date.timeIntervalSince(start))
            }
        } else {
            TimelineView(.everyMinute) { context in
                WordClockView(style: store.style, date: context.date)
            }
        }
    }
}

#if os(iOS)
/// iPhones with Face ID do not turn the interface upside down. When the device is held upside
/// down, the clock is turned by hand so that it stays upright (the system keeps the last layout).
struct UprightClock<Content: View>: View {
    private let content: Content
    @State private var angle: Double = 0

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let quarter = Int(angle) % 180 != 0
            content
                .frame(width: quarter ? geo.size.height : geo.size.width,
                       height: quarter ? geo.size.width : geo.size.height)
                .rotationEffect(.degrees(angle))
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            update()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            update()
        }
    }

    /// Turn = interface angle − device angle (clockwise from portrait), only when upside down.
    private func update() {
        let device = UIDevice.current.orientation
        guard device.isValidInterfaceOrientation else { return }   // flat on the table: keep
        guard device == .portraitUpsideDown else {
            angle = 0
            return
        }
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let ui: Double
        switch scene?.interfaceOrientation ?? .portrait {
        case .landscapeLeft:      ui = 90     // home side left: device turned clockwise
        case .landscapeRight:     ui = -90
        case .portraitUpsideDown: ui = 180    // the system did turn it: nothing to do
        default:                  ui = 0
        }
        var a = ui - 180
        if a <= -180 { a += 360 }
        withAnimation(.easeInOut(duration: 0.3)) { angle = a }
    }
}
#endif

#if os(macOS)
/// Remembers position and size of the clock window, also when macOS closes the windows on quit
/// ("Close windows when quitting an application") – otherwise it always opened on the same display.
struct WindowFrameSaver: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { FrameView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class FrameView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, window.frameAutosaveName.isEmpty else { return }
            _ = window.setFrameAutosaveName("WortuhrClock")
        }
    }
}
#endif
