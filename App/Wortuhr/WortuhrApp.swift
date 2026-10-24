import SwiftUI

@main
struct WortuhrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 760, height: 760)
        #endif
    }
}

struct ContentView: View {
    @State private var style = ClockStyle.load()

    var body: some View {
        TimelineView(.everyMinute) { context in
            WordClockView(style: style, date: context.date)
        }
        .background(Color.black)
        .ignoresSafeArea()
        #if os(iOS)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        #endif
    }
}
