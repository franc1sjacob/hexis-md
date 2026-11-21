import SwiftUI
import WebKit
import Textual

/// Renders ```mermaid fenced blocks as diagrams and defers every other code block
/// to the GitHub style.
struct MermaidAwareCodeBlockStyle: StructuredText.CodeBlockStyle {
    let fontSize: Double

    func makeBody(configuration: Configuration) -> some View {
        if configuration.languageHint?.lowercased() == "mermaid",
           let source = Self.source(of: configuration.codeBlock) {
            MermaidBlock(source: source, fontSize: fontSize) {
                StructuredText.GitHubCodeBlockStyle().makeBody(configuration: configuration)
            }
            .textual.blockSpacing(.init(top: 0, bottom: 16))
        } else {
            StructuredText.GitHubCodeBlockStyle().makeBody(configuration: configuration)
        }
    }

    /// Textual keeps the block's text private, so read it reflectively. Returns nil
    /// (falling back to a plain code block) if the library layout ever changes.
    private static func source(of proxy: StructuredText.CodeBlockProxy) -> String? {
        let content = Mirror(reflecting: proxy).children.first { $0.label == "content" }?.value
        guard let substring = content as? AttributedSubstring else { return nil }
        return String(substring.characters)
    }
}

private struct MermaidBlock<Fallback: View>: View {
    let source: String
    let fontSize: Double
    @ViewBuilder let fallback: () -> Fallback

    @Environment(\.colorScheme) private var colorScheme
    @State private var height: CGFloat = 0
    @State private var error: String?

    var body: some View {
        content.onChange(of: source) { _, _ in error = nil }
    }

    @ViewBuilder
    private var content: some View {
        if let error {
            VStack(alignment: .leading, spacing: 6) {
                fallback()
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        } else {
            MermaidWebView(
                source: source,
                dark: colorScheme == .dark,
                fontSize: fontSize,
                height: $height,
                error: $error
            )
            .frame(height: max(height, 1))
            .frame(maxWidth: .infinity)
        }
    }
}

private struct MermaidWebView: NSViewRepresentable {
    let source: String
    let dark: Bool
    let fontSize: Double
    @Binding var height: CGFloat
    @Binding var error: String?

    private static let library: String? = Bundle.main
        .url(forResource: "mermaid.min", withExtension: "js")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> PassthroughWebView {
        let controller = WKUserContentController()
        if let library = Self.library {
            controller.addUserScript(WKUserScript(source: library, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        controller.add(context.coordinator, name: "mermaid")
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        let webView = PassthroughWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        context.coordinator.render()
        return webView
    }

    func updateNSView(_ webView: PassthroughWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render()
    }

    static func dismantleNSView(_ webView: PassthroughWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "mermaid")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: MermaidWebView
        weak var webView: WKWebView?
        private var renderedKey: String?

        init(_ parent: MermaidWebView) { self.parent = parent }

        func render() {
            let key = "\(parent.dark)|\(parent.fontSize)|\(parent.source)"
            guard key != renderedKey, let webView else { return }
            renderedKey = key
            if Self.library == nil {
                report(error: "Mermaid library missing from app bundle")
                return
            }
            webView.loadHTMLString(Self.page(source: parent.source, dark: parent.dark, fontSize: parent.fontSize), baseURL: nil)
        }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            if let height = body["height"] as? Double {
                let value = CGFloat(height.rounded(.up))
                if abs(value - parent.height) > 0.5 { parent.height = value }
            } else if let error = body["error"] as? String {
                report(error: error)
            }
        }

        private func report(error: String) {
            let firstLine = error.split(separator: "\n").first.map(String.init) ?? error
            DispatchQueue.main.async { self.parent.error = "Mermaid: \(firstLine)" }
        }

        private static var library: String? { MermaidWebView.library }

        private static func page(source: String, dark: Bool, fontSize: Double) -> String {
            let encoded = (try? JSONEncoder().encode(source)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
            return """
            <!doctype html>
            <html><head><meta charset="utf-8">
            <style>
              html, body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
              #diagram { display: flex; justify-content: center; }
              #diagram svg { max-width: 100%; height: auto; }
            </style></head>
            <body><div id="diagram"></div>
            <script>
              const post = (msg) => window.webkit.messageHandlers.mermaid.postMessage(msg);
              const report = () => post({ height: document.getElementById('diagram').getBoundingClientRect().height });
              mermaid.initialize({
                startOnLoad: false,
                securityLevel: 'strict',
                theme: \(dark ? "'dark'" : "'default'"),
                fontSize: \(fontSize),
                themeVariables: { fontSize: '\(fontSize)px' }
              });
              mermaid.render('m', \(encoded))
                .then(({ svg }) => {
                  document.getElementById('diagram').innerHTML = svg;
                  new ResizeObserver(report).observe(document.getElementById('diagram'));
                  report();
                })
                .catch((e) => post({ error: String(e && e.message || e) }));
            </script></body></html>
            """
        }
    }
}

/// A web view that never scrolls itself, so wheel events reach the preview's ScrollView.
final class PassthroughWebView: WKWebView {
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}
