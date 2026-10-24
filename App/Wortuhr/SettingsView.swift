import SwiftUI

/// Settings of the app: the same options as the screen saver's dialog, plus the app's own.
/// Every change shows on the clock at once (iOS: sheet above the clock, macOS: settings window).
struct SettingsView: View {
    @Environment(StyleStore.self) private var store
    @State private var message: String?

    var body: some View {
        @Bindable var store = store
        let ui = store.style.language.ui
        let t = Texts.for(ui)
        let a = AppTexts.for(ui)
        let percent: (Double) -> String = { "\(Int($0.rounded())) %" }
        let seconds: (Double) -> String = {
            let s = String(format: "%.1f s", $0)
            return t.decimalComma ? s.replacingOccurrences(of: ".", with: ",") : s
        }

        Form {
            Section(t.sectionTime) {
                Picker(t.language.plain, selection: $store.style.language) {
                    ForEach(Language.allCases, id: \.self) { Text($0.menuTitle).tag($0) }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif
                Toggle(t.intro, isOn: $store.style.intro)
            }

            Section(t.sectionColors) {
                Swatches(title: t.front.plain, presets: ClockStyle.frontPresets, names: t.frontNames,
                         custom: t.custom, hex: $store.style.front)
                Swatches(title: t.lit.plain, presets: ClockStyle.litPresets, names: t.litNames,
                         custom: t.custom, hex: $store.style.lit)
                ValueSlider(t.dim.plain, $store.style.dim, 0...40, step: 1, text: percent)
                ValueSlider(t.glow.plain, $store.style.glow, 0...100, step: 5, text: percent)
                ValueSlider(t.edge.plain, $store.style.edge, 0...100, step: 5, text: percent)
            }

            Section(t.sectionFont) {
                Picker(t.font.plain, selection: $store.style.font) {
                    ForEach(ClockStyle.fonts, id: \.self) { f in Text(f == "System" ? t.systemFont : f).tag(f) }
                }
                Picker(t.weight.plain, selection: $store.style.weight) {
                    ForEach(ClockStyle.weights.indices, id: \.self) { i in
                        Text(ClockStyle.weights[i].0).tag(ClockStyle.weights[i].1)
                    }
                }
                ValueSlider(t.letterScale.plain, $store.style.letterScale, 70...140, step: 5, text: percent)
            }

            Section(t.sectionLook) {
                ValueSlider(t.size.plain, $store.style.size, 40...100, step: 2, text: percent)
                ValueSlider(t.fade.plain, $store.style.fade, 0...3, step: 0.1, text: seconds)
                Toggle(t.minuteEdges, isOn: $store.style.minuteEdges)
                Group {
                    ValueSlider(t.edgeStrength.plain, $store.style.edgeStrength, 10...200, step: 5, text: percent)
                    ValueSlider(t.edgeSpread.plain, $store.style.edgeSpread, 0...100, step: 5, text: percent)
                    ValueSlider(t.edgeTrail.plain, $store.style.edgeTrail, 0...100, step: 5, text: percent)
                }
                .disabled(!store.style.minuteEdges)
                Toggle(t.drift, isOn: $store.style.drift)
            }

            Section(a.sectionApp) {
                Toggle(a.keepAwake, isOn: $store.keepAwake)
                Link(a.screenSaver, destination: URL(string: "https://github.com/Diavolezza/wortuhr")!)
            }

            Section {
                Button(t.copy) {
                    Clipboard.string = store.style.exchange.text
                    message = a.copied
                }
                Button(t.paste) {
                    if let text = Clipboard.string, let x = SettingsExchange(text: text) {
                        store.style.apply(x)
                        message = nil
                    } else {
                        message = a.pasteFailed
                    }
                }
                Button(t.reset) {
                    // Default values – the chosen language is kept (as in the screen saver)
                    var s = ClockStyle()
                    s.language = store.style.language
                    store.style = s
                    message = nil
                }
            } header: {
                Text(a.sectionShare)
            } footer: {
                Text(message ?? a.shareFooter)
            }
        }
        .formStyle(.grouped)
    }
}

/// Slider with its value, rounded to the step (like the screen saver's dialog).
private struct ValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let text: (Double) -> String

    init(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, step: Double,
         text: @escaping (Double) -> String) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.text = text
    }

    private var rounded: Binding<Double> {
        Binding(get: { value },
                set: { value = min(max(($0 / step).rounded() * step, range.lowerBound), range.upperBound) })
    }

    var body: some View {
        #if os(macOS)
        LabeledContent(title) {
            HStack {
                Slider(value: rounded, in: range)
                Text(text(value)).monospacedDigit().foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }
        }
        #else
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(text(value)).monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: rounded, in: range)
        }
        #endif
    }
}

/// Colour presets as round swatches, plus the system colour picker for a custom colour.
private struct Swatches: View {
    let title: String
    let presets: [String]
    let names: [String]
    let custom: String
    @Binding var hex: String

    var body: some View {
        #if os(macOS)
        LabeledContent(title) { row }
        #else
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            row
        }
        #endif
    }

    private var row: some View {
        HStack(spacing: 10) {
            ForEach(presets.indices, id: \.self) { i in
                let preset = presets[i], name = i < names.count ? names[i] : preset
                Button { hex = preset } label: {
                    Circle()
                        .fill(Color(hex: preset))
                        .overlay(Circle().strokeBorder(.gray.opacity(0.6), lineWidth: 1))
                        .padding(3)
                        .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 2)
                            .opacity(preset == hex.lowercased() ? 1 : 0))
                        .frame(width: 30, height: 30)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
                .help(name)
            }
            ColorPicker(custom, selection: Binding(get: { Color(hex: hex) }, set: { hex = $0.hexString }),
                        supportsOpacity: false)
                .labelsHidden()
                .help(custom)
        }
    }
}
