import SwiftUI
import AppKit

/// A curated preset. `""` postScriptName means "system monospaced".
struct FontPreset: Identifiable, Hashable {
    let label: String
    let postScriptName: String
    var id: String { label }
}

let fontPresets: [FontPreset] = [
    .init(label: "System Monospaced", postScriptName: ""),
    .init(label: "SF Mono",           postScriptName: "SFMono-Regular"),
    .init(label: "Menlo",             postScriptName: "Menlo-Regular"),
    .init(label: "Monaco",            postScriptName: "Monaco"),
    .init(label: "Courier",           postScriptName: "Courier"),
]

enum EditorFontResolver {
    static func swiftUIFont(name: String, size: CGFloat) -> Font {
        if name.isEmpty { return .system(size: size, design: .monospaced) }
        return .custom(name, size: size)
    }

    static func nsFont(name: String, size: CGFloat) -> NSFont {
        if name.isEmpty {
            return .monospacedSystemFont(ofSize: size, weight: .regular)
        }
        return NSFont(name: name, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Display label: preset label if it matches, otherwise the PostScript name.
    static func displayLabel(for name: String) -> String {
        fontPresets.first(where: { $0.postScriptName == name })?.label ?? name
    }
}

/// Bridges the AppKit font panel back into our UserDefaults-backed settings.
@MainActor
final class FontPanelBridge: NSObject {
    static let shared = FontPanelBridge()

    func install() {
        NSFontManager.shared.target = self
        NSFontManager.shared.action = #selector(changeFont(_:))
    }

    func openPanel() {
        let size = UserDefaults.standard.double(forKey: "editorSize")
        let name = UserDefaults.standard.string(forKey: "editorFontName") ?? ""
        let current = EditorFontResolver.nsFont(name: name, size: size > 0 ? size : 13)
        NSFontManager.shared.setSelectedFont(current, isMultiple: false)
        NSFontManager.shared.orderFrontFontPanel(nil)
    }

    @objc func changeFont(_ sender: Any?) {
        let manager = NSFontManager.shared
        let size = UserDefaults.standard.double(forKey: "editorSize")
        let name = UserDefaults.standard.string(forKey: "editorFontName") ?? ""
        let current = EditorFontResolver.nsFont(name: name, size: size > 0 ? size : 13)
        let converted = manager.convert(current)
        UserDefaults.standard.set(converted.fontName, forKey: "editorFontName")
        UserDefaults.standard.set(Double(converted.pointSize), forKey: "editorSize")
    }
}

struct FormatCommands: Commands {
    @AppStorage("editorFontName") private var fontName: String = ""
    @AppStorage("editorSize")     private var fontSize: Double = 13

    var body: some Commands {
        CommandMenu("Format") {
            Menu("Font") {
                ForEach(fontPresets) { p in
                    Button {
                        fontName = p.postScriptName
                    } label: {
                        HStack {
                            Text(p.label)
                            if fontName == p.postScriptName {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button("Bigger") { fontSize = min(fontSize + 1, 96) }
                .keyboardShortcut("+", modifiers: .command)
            Button("Smaller") { fontSize = max(fontSize - 1, 8) }
                .keyboardShortcut("-", modifiers: .command)
            Button("Reset Size") { fontSize = 13 }
                .keyboardShortcut("0", modifiers: .command)

            Divider()

            Button("Show Fonts…") {
                FontPanelBridge.shared.openPanel()
            }
            .keyboardShortcut("t", modifiers: .command)
        }
    }
}

struct SettingsView: View {
    @AppStorage("editorFontName")    private var fontName: String = ""
    @AppStorage("editorSize")        private var fontSize: Double = 13
    @AppStorage("editorLineSpacing") private var lineSpacing: Double = 2

    var body: some View {
        Form {
            HStack {
                Text("Font")
                Spacer()
                Text(EditorFontResolver.displayLabel(for: fontName))
                    .foregroundStyle(.secondary)
                Button("Choose…") { FontPanelBridge.shared.openPanel() }
            }

            Picker("Preset", selection: $fontName) {
                ForEach(fontPresets) { p in
                    Text(p.label).tag(p.postScriptName)
                }
                if !fontPresets.contains(where: { $0.postScriptName == fontName }) {
                    Text(fontName).tag(fontName)
                }
            }

            HStack {
                Text("Size")
                Spacer()
                Stepper(value: $fontSize, in: 8...96, step: 1) {
                    Text("\(Int(fontSize)) pt")
                        .monospacedDigit()
                        .frame(minWidth: 50, alignment: .trailing)
                }
            }

            HStack {
                Text("Line spacing")
                Spacer()
                Stepper(value: $lineSpacing, in: 0...12, step: 1) {
                    Text("\(Int(lineSpacing)) pt")
                        .monospacedDigit()
                        .frame(minWidth: 50, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
