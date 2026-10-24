import SwiftUI
import WidgetKit

@main
struct WortuhrWidgets: WidgetBundle {
    var body: some Widget {
        WortuhrWidget()
    }
}

struct ClockEntry: TimelineEntry {
    let date: Date
    let style: ClockStyle
}

struct Provider: TimelineProvider {
    /// Widgets show the whole plate; the widget background has the plate colour.
    private var style: ClockStyle {
        var s = ClockStyle()
        s.size = 100
        return s
    }

    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, style: style)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// One entry per minute for the next two hours, then WidgetKit asks again.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let start = Calendar.current.dateInterval(of: .minute, for: .now)?.start ?? .now
        let entries = (0..<120).map { ClockEntry(date: start.addingTimeInterval(Double($0) * 60), style: style) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct WortuhrWidgetView: View {
    let entry: ClockEntry

    var body: some View {
        WordClockView(style: entry.style, date: entry.date, plate: false)
            .containerBackground(entry.style.frontColor, for: .widget)
    }
}

struct WortuhrWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Wortuhr", provider: Provider()) { entry in
            WortuhrWidgetView(entry: entry)
        }
        .configurationDisplayName("Wortuhr")
        .description("Die Uhrzeit in Worten.")
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}
