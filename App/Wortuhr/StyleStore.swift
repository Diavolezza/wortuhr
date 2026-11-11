import SwiftUI
import WidgetKit
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
        didSet {
            guard style != oldValue else { return }
            style.save()
            reloadWidgets()
        }
    }

    @ObservationIgnored private var widgetReload: Task<Void, Never>?

    /// The widgets show the app's settings: redraw them shortly after the last change
    /// (not on every step of a slider).
    private func reloadWidgets() {
        widgetReload?.cancel()
        widgetReload = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            Diag.log("app: reloadAllTimelines (settings changed)")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @ObservationIgnored private var lastActiveReload = Date.distantPast

    /// The widgets show the time from a timeline prepared in advance. When the app comes to the front
    /// (also after a click on a widget, which opens the app), they get a fresh one right away –
    /// at most once a minute, as every new timeline draws 60 entries (about 3 s of processor time).
    func reloadWidgetsNow(_ reason: String) {
        guard Date().timeIntervalSince(lastActiveReload) >= 60 else {
            Diag.log("app: \(reason), no reload (last one less than a minute ago)")
            return
        }
        lastActiveReload = Date()
        Diag.log("app: reloadAllTimelines (\(reason))")
        WidgetCenter.shared.reloadAllTimelines()
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
        Diag.log("app: launched")
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
