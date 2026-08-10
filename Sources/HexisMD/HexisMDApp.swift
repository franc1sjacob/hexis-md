import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct HexisMDApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(text: file.$document.text)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
