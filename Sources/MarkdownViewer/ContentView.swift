import SwiftUI

enum ViewMode: String, CaseIterable, Identifiable {
    case preview = "Preview"
    case source = "Source"
    var id: String { rawValue }
}

struct ContentView: View {
    let document: MarkdownDocument
    @State private var mode: ViewMode = .preview

    var body: some View {
        Group {
            switch mode {
            case .preview:
                PreviewView(text: document.text)
            case .source:
                SourceView(text: document.text)
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
            renderedMarkdown
                .textSelection(.enabled)
                .frame(maxWidth: 720, alignment: .leading)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var renderedMarkdown: some View {
        let blocks = text.components(separatedBy: "\n\n")
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: String) -> some View {
        let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("### ") {
            Text(trimmed.dropFirst(4)).font(.title3).bold()
        } else if trimmed.hasPrefix("## ") {
            Text(trimmed.dropFirst(3)).font(.title2).bold()
        } else if trimmed.hasPrefix("# ") {
            Text(trimmed.dropFirst(2)).font(.title).bold()
        } else if trimmed.hasPrefix("```") {
            let inner = trimmed
                .split(separator: "\n", omittingEmptySubsequences: false)
                .dropFirst()
                .dropLast()
                .joined(separator: "\n")
            Text(inner)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(6)
        } else {
            if let attributed = try? AttributedString(
                markdown: trimmed,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attributed)
            } else {
                Text(trimmed)
            }
        }
    }
}

struct SourceView: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
    }
}
