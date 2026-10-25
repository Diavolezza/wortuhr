import Foundation

/// Texts of the app that the screen saver's dialog does not have (see Shared/Texts.swift).
/// The app's settings appear in the language of the clock, like the screen saver's options.
struct AppTexts {
    let settings, done, fullScreen: String
    let sectionApp, keepAwake, screenSaver: String
    let sectionShare, shareFooter, copied, pasteFailed: String
    /// Help menu (Mac): opens the support page
    let help: String

    static func `for`(_ ui: UILanguage) -> AppTexts {
        switch ui {
        case .de, .deCH: return de
        case .enGB:      return enGB
        case .enUS:      return enUS
        case .fr:        return fr
        case .it:        return it
        case .es:        return es
        }
    }

    static let de = AppTexts(
        settings: "Einstellungen", done: "Fertig", fullScreen: "Vollbild",
        sectionApp: "App", keepAwake: "Bildschirm nicht abschalten",
        screenSaver: "Wortuhr als Bildschirmschoner für den Mac",
        sectionShare: "Einstellungen übertragen",
        shareFooter: "Kopiert die Einstellungen als Text oder übernimmt sie aus der Zwischenablage – auch zwischen App und Bildschirmschoner (Optionen …).",
        copied: "Die Einstellungen sind in der Zwischenablage.",
        pasteFailed: "Die Zwischenablage enthält keine Wortuhr-Einstellungen.",
        help: "Wortuhr-Hilfe")

    static let enGB = AppTexts(
        settings: "Settings", done: "Done", fullScreen: "Full screen",
        sectionApp: "App", keepAwake: "Keep the screen on",
        screenSaver: "Wortuhr as a screen saver for the Mac",
        sectionShare: "Transfer settings",
        shareFooter: "Copies the settings as text or takes them from the clipboard – also between the app and the screen saver (Options …).",
        copied: "The settings are on the clipboard.",
        pasteFailed: "The clipboard contains no Wortuhr settings.",
        help: "Wortuhr Help")

    static let enUS = AppTexts(
        settings: "Settings", done: "Done", fullScreen: "Full Screen",
        sectionApp: "App", keepAwake: "Keep the screen on",
        screenSaver: "Wortuhr as a screen saver for the Mac",
        sectionShare: "Transfer settings",
        shareFooter: "Copies the settings as text or takes them from the clipboard – also between the app and the screen saver (Options …).",
        copied: "The settings are on the clipboard.",
        pasteFailed: "The clipboard contains no Wortuhr settings.",
        help: "Wortuhr Help")

    static let fr = AppTexts(
        settings: "Réglages", done: "OK", fullScreen: "Plein écran",
        sectionApp: "App", keepAwake: "Garder l’écran allumé",
        screenSaver: "Wortuhr comme économiseur d’écran pour Mac",
        sectionShare: "Transférer les réglages",
        shareFooter: "Copie les réglages sous forme de texte ou les reprend du presse-papiers – aussi entre l’app et l’économiseur d’écran (Options…).",
        copied: "Les réglages sont dans le presse-papiers.",
        pasteFailed: "Le presse-papiers ne contient aucun réglage Wortuhr.",
        help: "Aide de Wortuhr")

    static let it = AppTexts(
        settings: "Impostazioni", done: "Fine", fullScreen: "Schermo intero",
        sectionApp: "App", keepAwake: "Mantieni lo schermo acceso",
        screenSaver: "Wortuhr come salvaschermo per il Mac",
        sectionShare: "Trasferisci le impostazioni",
        shareFooter: "Copia le impostazioni come testo o le riprende dagli appunti – anche tra l’app e il salvaschermo (Opzioni…).",
        copied: "Le impostazioni sono negli appunti.",
        pasteFailed: "Gli appunti non contengono impostazioni di Wortuhr.",
        help: "Guida di Wortuhr")

    static let es = AppTexts(
        settings: "Ajustes", done: "OK", fullScreen: "Pantalla completa",
        sectionApp: "App", keepAwake: "Mantener la pantalla encendida",
        screenSaver: "Wortuhr como salvapantallas para Mac",
        sectionShare: "Transferir los ajustes",
        shareFooter: "Copia los ajustes como texto o los toma del portapapeles – también entre la app y el salvapantallas (Opciones…).",
        copied: "Los ajustes están en el portapapeles.",
        pasteFailed: "El portapapeles no contiene ajustes de Wortuhr.",
        help: "Ayuda de Wortuhr")
}

extension String {
    /// Dialog label without the trailing colon ("Sprache:" → "Sprache") for SwiftUI forms.
    var plain: String {
        var s = self
        while let last = s.last, last == ":" || last == "\u{202F}" || last == " " { s.removeLast() }
        return s
    }
}
