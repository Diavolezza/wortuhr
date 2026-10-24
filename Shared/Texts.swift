import Foundation

// Texts of the screen saver's options dialog, also used by the app's settings.

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
    let reset, cancel, ok: String
    /// Copy / paste the settings as text (exchange between screen saver and app)
    let copy, paste: String
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
        reset: "Standard", cancel: "Abbrechen", ok: "OK",
        copy: "Kopieren", paste: "Einfügen",
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
        reset: "Standard", cancel: "Abbrechen", ok: "OK",
        copy: "Kopieren", paste: "Einfügen",
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
        reset: "Defaults", cancel: "Cancel", ok: "OK",
        copy: "Copy", paste: "Paste",
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
        reset: "Defaults", cancel: "Cancel", ok: "OK",
        copy: "Copy", paste: "Paste",
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
        reset: "Par défaut", cancel: "Annuler", ok: "OK",
        copy: "Copier", paste: "Coller",
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
        reset: "Predefiniti", cancel: "Annulla", ok: "OK",
        copy: "Copia", paste: "Incolla",
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
        reset: "Restablecer", cancel: "Cancelar", ok: "Aceptar",
        copy: "Copiar", paste: "Pegar",
        frontNames: ["Negro profundo", "Grafito", "Azul noche", "Verde abeto", "Rojo ladrillo", "Blanco tiza"],
        litNames: ["Blanco cálido", "Blanco frío", "Ámbar", "Azul hielo", "Menta", "Antracita"],
        decimalComma: true)
}
