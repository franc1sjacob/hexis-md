import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct HexisMDApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        FontPanelBridge.shared.install()
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            NSApplication.shared.applicationIconImage = image
        }
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
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
