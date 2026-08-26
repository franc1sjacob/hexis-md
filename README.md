<p align="center">
  <img src="HexisMD/Assets.xcassets/AppIcon.appiconset/mac256.png" alt="HexisMD icon" width="160" height="160" />
</p>

<h1 align="center">HexisMD</h1>

<p align="center">
  A tiny native macOS app for viewing and lightly editing Markdown files. Think TextEdit, but for <code>.md</code>.
</p>

---

macOS doesn't ship with a simple Markdown viewer, so double-clicking a `.md` usually opens Xcode, TextEdit, or another heavyweight editor. HexisMD is a small SwiftUI app that opens Markdown files fast, shows them cleanly, and gets out of the way.

## Features

- Opens `.md` and `.markdown` files via `File > Open`, drag-and-drop, or as the default app
- **Source**, **Split**, and **Preview** views with a toolbar toggle
- GitHub-flavored Markdown rendering in Preview
- Sidebar with recent documents
- Reload from disk (`⌘R`) for when the file is changed by another process
- Native document model, so `⌘S` saves, multiple windows work, and standard macOS behaviors apply
- No Electron, no bundled runtime, no vault

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16 / Swift 6 toolchain (for building from source)

## Run from source

```sh
git clone https://github.com/franc1sjacob/hexis-md.git
cd hexis-md
open HexisMD.xcodeproj
```

Then hit `⌘R` in Xcode to build and run.

## Build a release

Produce an ad-hoc signed `.zip` suitable for uploading to a GitHub Release:

```sh
./scripts/release.sh              # writes build/HexisMD.zip
./scripts/release.sh --install    # also replaces /Applications/HexisMD.app
```

First-run UX for downloaders: right-click the app and choose **Open** to bypass Gatekeeper (the build is ad-hoc signed, not notarized).

## Roadmap

- Optional syntax highlighting in the source view
- Tabbed mode (multiple documents in a single window)
- Print / export PDF via the standard macOS dialog

## Contributing

Issues and PRs welcome. This is intentionally a small app; features that push it toward being an IDE, vault, or note-taking system are out of scope.

## License

MIT. See [LICENSE](./LICENSE).
