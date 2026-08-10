# Markdown Viewer

A tiny native macOS app for viewing `.md` files as rendered documents or raw source.

## Run

```sh
swift run
```

Requires macOS 13+ and Xcode command line tools.

## Prototype scope

- SwiftUI `DocumentGroup` app
- Open `.md` / `.markdown` via `File > Open` or by dropping onto the app
- Toggle between Preview and Source in the toolbar
- Preview uses `AttributedString(markdown:)` per block, with basic heading and fenced-code handling

See `~/notes/personal/notes/native-markdown-viewer-swiftui.md` for full spec.
