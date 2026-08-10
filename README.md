# HexisMD

A tiny native macOS app for viewing and lightly editing Markdown files. Think TextEdit, but for `.md`.

macOS doesn't ship with a simple Markdown viewer, so double-clicking a `.md` usually opens Xcode, TextEdit, or another heavyweight editor. HexisMD is a small SwiftUI app that opens Markdown files fast, shows them cleanly, and gets out of the way.

## Features

- Open `.md` and `.markdown` files via `File > Open` or drag-and-drop
- **Source** view: editable monospaced text (like TextEdit)
- **Preview** view: GitHub-flavored Markdown rendering
- Toolbar toggle between the two
- Native document model, so `Cmd+S` saves, multiple windows work, and standard macOS behaviors apply
- No Electron, no bundled runtime, no vault

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16 / Swift 6 toolchain

## Run from source

```sh
git clone https://github.com/franc1sjacob/hexis-md.git
cd hexis-md
swift run
```

## Roadmap

- Register as a proper Markdown file handler (`.app` bundle with Info.plist) so `open file.md` routes here
- Optional syntax highlighting in the source view
- Reload when the file changes on disk
- Print / export PDF via the standard macOS dialog

## Contributing

Issues and PRs welcome. This is intentionally a small app; features that push it toward being an IDE, vault, or note-taking system are out of scope.

## License

MIT. See [LICENSE](./LICENSE).
