import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Settings of the app: the clock's look (saved on every change) and "keep the screen on".
@MainActor
@Observable
final class StyleStore {
    var style: ClockStyle {
        didSet { if style != oldValue { style.save() } }
    }

    var keepAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepAwake, forKey: "keepAwake")
            applyKeepAwake()
        }
    }

    #if os(macOS)
    @ObservationIgnored private var activity: NSObjectProtocol?
    #endif

    init() {
        style = ClockStyle.load()
        #if os(macOS)
        let byDefault = false     // a Mac is a work computer: off unless switched on
        #else
        let byDefault = true      // iPhone/iPad as a clock on the desk or in StandBy
        #endif
        keepAwake = UserDefaults.standard.object(forKey: "keepAwake") as? Bool ?? byDefault
    }

    /// iOS: no auto-lock while the app is in front. macOS: the display does not go to sleep.
    func applyKeepAwake() {
        #if os(macOS)
        if keepAwake, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(options: [.idleDisplaySleepDisabled, .userInitiated],
                                                             reason: "Wortuhr shows the time")
        } else if !keepAwake, let a = activity {
            ProcessInfo.processInfo.endActivity(a)
            activity = nil
        }
        #else
        UIApplication.shared.isIdleTimerDisabled = keepAwake
        #endif
    }
}

/// Clipboard on both platforms.
enum Clipboard {
    static var string: String? {
        get {
            #if os(macOS)
            NSPasteboard.general.string(forType: .string)
            #else
            UIPasteboard.general.string
            #endif
        }
        set {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            if let newValue { NSPasteboard.general.setString(newValue, forType: .string) }
            #else
            UIPasteboard.general.string = newValue
            #endif
        }
    }
}
