import SwiftUI
import AppKit
import Textual

enum ViewMode: String, CaseIterable, Identifiable {
    case source = "Source"
    case split = "Split"
    case preview = "Preview"
    var id: String { rawValue }
}

struct ContentView: View {
    @Binding var text: String
    @State private var mode: ViewMode = .source
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var recents: [URL] = []

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            RecentsSidebar(recents: recents)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            editor
                .frame(minWidth: 480, minHeight: 320)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Picker("View", selection: $mode) {
                            ForEach(ViewMode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
        }
        .task { refreshRecents() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshRecents()
        }
    }

    @ViewBuilder
    private var editor: some View {
        switch mode {
        case .preview:
            PreviewView(text: text)
        case .source:
            SourceView(text: $text)
        case .split:
            HSplitView {
                SourceView(text: $text)
                    .frame(minWidth: 240)
                PreviewView(text: text)
                    .frame(minWidth: 240)
            }
        }
    }

    private func refreshRecents() {
        recents = NSDocumentController.shared.recentDocumentURLs
    }
}

struct RecentsSidebar: View {
    let recents: [URL]

    var body: some View {
        List {
            Section("Recents") {
                if recents.isEmpty {
                    Text("No recent files")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(recents, id: \.self) { url in
                        Button {
                            open(url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                    Text(url.deletingLastPathComponent().path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func open(_ url: URL) {
        NSDocumentController.shared.openDocument(
            withContentsOf: url,
            display: true
        ) { _, _, _ in }
    }
}

struct PreviewView: View {
    let text: String

    var body: some View {
        ScrollView {
            StructuredText(markdown: text)
                .textual.structuredTextStyle(.gitHub)
                .frame(maxWidth: 720, alignment: .leading)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct SourceView: View {
    @Binding var text: String

    @AppStorage("editorFontName")    private var fontName: String = ""
    @AppStorage("editorSize")        private var fontSize: Double = 13
    @AppStorage("editorLineSpacing") private var lineSpacing: Double = 2

    var body: some View {
        TextEditor(text: $text)
            .font(EditorFontResolver.swiftUIFont(name: fontName, size: fontSize))
            .lineSpacing(lineSpacing)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .textBackgroundColor))
            .scrollContentBackground(.hidden)
    }
}
