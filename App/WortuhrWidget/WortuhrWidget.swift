import AppIntents
import SwiftUI
import WidgetKit

@main
struct WortuhrWidgets: WidgetBundle {
    var body: some Widget {
        WortuhrWidget()
    }
}

// MARK: - Configuration ("Edit Widget")

/// Each widget shows the app's settings; language and colours can differ per widget.
struct ClockWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Word clock"
    static let description = IntentDescription("Shows the time in words.")

    @Parameter(title: "Language", default: .app)
    var language: WidgetLanguage

    @Parameter(title: "Faceplate", default: .app)
    var front: WidgetFront

    @Parameter(title: "Lit colour", default: .app)
    var lit: WidgetLit
}

enum WidgetLanguage: String, AppEnum {
    case app, de, deCH, deSouth, en, us, es, fr, it

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Language"
    // Languages in their own language, as in the app's language list
    static let caseDisplayRepresentations: [WidgetLanguage: DisplayRepresentation] = [
        .app: "Same as the app",
        .de: "🇩🇪 Deutsch – Hochdeutsch",
        .deCH: "🇨🇭 Deutsch – Schwiizerdütsch",
        .deSouth: "🇩🇪 Deutsch – Süddeutsch",
        .en: "🇬🇧 English – UK",
        .us: "🇺🇸 English – US",
        .es: "🇪🇸 Español",
        .fr: "🇫🇷 Français",
        .it: "🇮🇹 Italiano",
    ]

    var value: Language? { Language(rawValue: rawValue) }
}

/// Order and colours as ClockStyle.frontPresets.
enum WidgetFront: String, AppEnum {
    case app, black, graphite, midnight, forest, brick, chalk

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Faceplate"
    static let caseDisplayRepresentations: [WidgetFront: DisplayRepresentation] = [
        .app: "Same as the app", .black: "Deep black", .graphite: "Graphite", .midnight: "Midnight blue",
        .forest: "Forest green", .brick: "Brick red", .chalk: "Chalk white",
    ]

    var hex: String? {
        guard let i = Self.allCases.firstIndex(of: self), i > 0 else { return nil }
        return ClockStyle.frontPresets[i - 1]
    }
}

/// Order and colours as ClockStyle.litPresets.
enum WidgetLit: String, AppEnum {
    case app, warm, cool, amber, ice, mint, charcoal

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Lit colour"
    static let caseDisplayRepresentations: [WidgetLit: DisplayRepresentation] = [
        .app: "Same as the app", .warm: "Warm white", .cool: "Cool white", .amber: "Amber",
        .ice: "Ice blue", .mint: "Mint", .charcoal: "Charcoal",
    ]

    var hex: String? {
        guard let i = Self.allCases.firstIndex(of: self), i > 0 else { return nil }
        return ClockStyle.litPresets[i - 1]
    }
}

// MARK: - Timeline

struct ClockEntry: TimelineEntry {
    let date: Date
    let style: ClockStyle
}

struct Provider: AppIntentTimelineProvider {
    private func style(_ config: ClockWidgetIntent?) -> ClockStyle {
        var s = ClockStyle.load()
        if let config {
            if let v = config.language.value { s.language = v }
            if let v = config.front.hex { s.front = v }
            if let v = config.lit.hex { s.lit = v }
        }
        return s
    }

    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, style: style(nil))
    }

    func snapshot(for configuration: ClockWidgetIntent, in context: Context) async -> ClockEntry {
        ClockEntry(date: .now, style: style(configuration))
    }

    /// One entry per minute for the next two hours, then WidgetKit asks again.
    func timeline(for configuration: ClockWidgetIntent, in context: Context) async -> Timeline<ClockEntry> {
        let s = style(configuration)
        let start = Calendar.current.dateInterval(of: .minute, for: .now)?.start ?? .now
        let entries = (0..<120).map { ClockEntry(date: start.addingTimeInterval(Double($0) * 60), style: s) }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - View

struct WortuhrWidgetView: View {
    let entry: ClockEntry
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let style = entry.style.forWidget(mono: renderingMode != .fullColor)
        WordClockView(style: style, date: entry.date, plate: false)
            .containerBackground(for: .widget) { style.frontColor }
    }
}

struct WortuhrWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "Wortuhr", intent: ClockWidgetIntent.self, provider: Provider()) { entry in
            WortuhrWidgetView(entry: entry)
        }
        .configurationDisplayName("Wortuhr")
        .description("Shows the time in words.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
