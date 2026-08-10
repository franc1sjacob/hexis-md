import SwiftUI
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

    var body: some View {
        Group {
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
