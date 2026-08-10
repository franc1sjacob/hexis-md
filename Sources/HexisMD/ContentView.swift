import SwiftUI
import Textual

enum ViewMode: String, CaseIterable, Identifiable {
    case source = "Source"
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

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 13, design: .monospaced))
            .lineSpacing(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .textBackgroundColor))
            .scrollContentBackground(.hidden)
    }
}
