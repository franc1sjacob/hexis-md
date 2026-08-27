import SwiftUI
import AppKit
import Textual

enum ViewMode: String, CaseIterable, Identifiable {
    case source = "Source"
    case split = "Split"
    case preview = "Preview"
    var id: String { rawValue }
}

enum FocusedPane {
    case source
    case preview
}

struct ContentView: View {
    @Binding var text: String
    let fileURL: URL?
    @State private var mode: ViewMode = .source
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var recents: [URL] = []
    @State private var showReloadConfirm = false
    @AppStorage("previewFontSize") private var previewFontSize: Double = PreviewZoom.defaultSize
    @State private var focusedPane: FocusedPane = .source

    private var previewVisible: Bool { mode == .preview || mode == .split }

    private var sourceActive: Bool {
        switch mode {
        case .source: return true
        case .preview: return false
        case .split: return focusedPane == .source
        }
    }

    private var previewActive: Bool {
        switch mode {
        case .source: return false
        case .preview: return true
        case .split: return focusedPane == .preview
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            RecentsSidebar(recents: recents)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            editor
                .frame(minWidth: 480, minHeight: 320)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            NSDocumentController.shared.newDocument(nil)
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .help("New Document")
                    }
                    ToolbarItem(placement: .navigation) {
                        Button {
                            attemptReload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .keyboardShortcut("r", modifiers: .command)
                        .disabled(fileURL == nil)
                        .help("Reload from Disk")
                    }
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
        .task { registerAndRefresh() }
        .onChange(of: fileURL) { _, _ in registerAndRefresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshRecents()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            refreshRecents()
        }
        .confirmationDialog(
            "Reload from disk? Unsaved changes will be lost.",
            isPresented: $showReloadConfirm,
            titleVisibility: .visible
        ) {
            Button("Reload", role: .destructive) { reloadFromDisk() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func attemptReload() {
        guard let url = fileURL,
              let document = NSDocumentController.shared.document(for: url) else { return }
        if document.isDocumentEdited {
            showReloadConfirm = true
        } else {
            reloadFromDisk()
        }
    }

    private func reloadFromDisk() {
        guard let url = fileURL,
              let document = NSDocumentController.shared.document(for: url) else { return }
        let typeName = (try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier)
            ?? document.fileType
            ?? "public.plain-text"
        do {
            try document.revert(toContentsOf: url, ofType: typeName)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func registerAndRefresh() {
        if let url = fileURL {
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        }
        refreshRecents()
    }

    @ViewBuilder
    private var editor: some View {
        switch mode {
        case .preview:
            PreviewView(text: text, fontSize: $previewFontSize, shortcutsActive: previewActive)
        case .source:
            SourceView(text: $text, shortcutsActive: sourceActive)
        case .split:
            HSplitView {
                SourceView(text: $text, shortcutsActive: sourceActive)
                    .frame(minWidth: 240)
                    .simultaneousGesture(TapGesture().onEnded { focusedPane = .source })
                PreviewView(text: text, fontSize: $previewFontSize, shortcutsActive: previewActive)
                    .frame(minWidth: 240)
                    .simultaneousGesture(TapGesture().onEnded { focusedPane = .preview })
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

struct ZoomConfig {
    let minSize: Double
    let maxSize: Double
    let defaultSize: Double

    func clamp(_ value: Double) -> Double {
        min(maxSize, max(minSize, value))
    }

    func percent(_ size: Double) -> Int {
        Int((size / defaultSize * 100).rounded())
    }

    static let preview = ZoomConfig(minSize: 10, maxSize: 32, defaultSize: 15)
    static let source = ZoomConfig(minSize: 9, maxSize: 32, defaultSize: 13)
}

enum PreviewZoom {
    static let defaultSize = ZoomConfig.preview.defaultSize
}

enum SourceZoom {
    static let defaultSize = ZoomConfig.source.defaultSize
}

struct PreviewView: View {
    let text: String
    @Binding var fontSize: Double
    var shortcutsActive: Bool = true

    var body: some View {
        ScrollView {
            StructuredText(markdown: text)
                .textual.structuredTextStyle(.gitHub)
                .font(.system(size: fontSize))
                .frame(maxWidth: 720 * (fontSize / PreviewZoom.defaultSize), alignment: .leading)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .modifier(ZoomOverlay(fontSize: $fontSize, config: .preview, shortcutsActive: shortcutsActive))
    }
}

struct SourceView: View {
    @Binding var text: String
    var shortcutsActive: Bool = true

    @AppStorage("editorFontName")    private var fontName: String = ""
    @AppStorage("editorSize")        private var fontSize: Double = SourceZoom.defaultSize
    @AppStorage("editorLineSpacing") private var lineSpacing: Double = 2

    var body: some View {
        TextEditor(text: $text)
            .font(EditorFontResolver.swiftUIFont(name: fontName, size: fontSize))
            .lineSpacing(lineSpacing)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .textBackgroundColor))
            .scrollContentBackground(.hidden)
            .modifier(ZoomOverlay(fontSize: $fontSize, config: .source, shortcutsActive: shortcutsActive))
    }
}

struct ZoomOverlay: ViewModifier {
    @Binding var fontSize: Double
    let config: ZoomConfig
    var shortcutsActive: Bool = true

    @State private var hoveringCorner = false
    @State private var recentActivity = false
    @State private var activityHideTask: Task<Void, Never>?
    @State private var hoverHideTask: Task<Void, Never>?

    private var pillVisible: Bool { hoveringCorner || recentActivity }

    func body(content: Content) -> some View {
        content
            .background {
                if shortcutsActive {
                    VStack {
                        Button("Zoom In") { bump(1) }
                            .keyboardShortcut("=", modifiers: .command)
                        Button("Zoom In") { bump(1) }
                            .keyboardShortcut("+", modifiers: .command)
                        Button("Zoom Out") { bump(-1) }
                            .keyboardShortcut("-", modifiers: .command)
                        Button("Actual Size") { reset() }
                            .keyboardShortcut("0", modifiers: .command)
                    }
                    .hidden()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    Color.clear
                        .contentShape(Rectangle())
                    ZoomControl(
                        fontSize: fontSize,
                        config: config,
                        onZoomIn: { bump(1) },
                        onZoomOut: { bump(-1) },
                        onReset: reset
                    )
                    .padding(24)
                    .opacity(pillVisible ? 1 : 0)
                    .allowsHitTesting(pillVisible)
                    .animation(.easeInOut(duration: 0.18), value: pillVisible)
                }
                .frame(width: 220, height: 100)
                .onHover { hovering in
                    hoverHideTask?.cancel()
                    if hovering {
                        hoveringCorner = true
                    } else {
                        hoverHideTask = Task {
                            try? await Task.sleep(nanoseconds: 250_000_000)
                            if !Task.isCancelled {
                                await MainActor.run { hoveringCorner = false }
                            }
                        }
                    }
                }
            }
    }

    private func bump(_ delta: Double) {
        fontSize = config.clamp(fontSize + delta)
        flashActivity()
    }

    private func reset() {
        fontSize = config.defaultSize
        flashActivity()
    }

    private func flashActivity() {
        recentActivity = true
        activityHideTask?.cancel()
        activityHideTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if !Task.isCancelled {
                await MainActor.run { recentActivity = false }
            }
        }
    }
}

struct ZoomControl: View {
    let fontSize: Double
    let config: ZoomConfig
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onZoomOut) {
                Image(systemName: "minus")
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(fontSize <= config.minSize)
            .help("Zoom Out")

            Button(action: onReset) {
                Text("\(config.percent(fontSize))%")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .frame(minWidth: 44, minHeight: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Reset Zoom")

            Button(action: onZoomIn) {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(fontSize >= config.maxSize)
            .help("Zoom In")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.separator.opacity(0.5)))
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }
}
