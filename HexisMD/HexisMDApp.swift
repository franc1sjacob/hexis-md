import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct HexisMDApp: App {
    init() {
        FontPanelBridge.shared.install()
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(text: file.$document.text, fileURL: file.fileURL)
        }
        .commands {
            FormatCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
