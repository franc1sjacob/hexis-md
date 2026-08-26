#!/usr/bin/env bash
# Build an ad-hoc signed HexisMD.zip for GitHub Releases.
#
# Usage:
#   ./scripts/release.sh             # builds build/HexisMD.zip
#   ./scripts/release.sh --install   # also replaces /Applications/HexisMD.app
#
# First-run UX for users: right-click the app -> Open (Gatekeeper will warn
# once because there's no Developer ID signature).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DD="build/dd"
APP="$DD/Build/Products/Release/HexisMD.app"
ZIP="build/HexisMD.zip"

rm -rf build
mkdir -p build

echo "==> Building Release (unsigned)"
xcodebuild -project HexisMD.xcodeproj -scheme HexisMD \
  -configuration Release \
  -derivedDataPath "$DD" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP"

echo "==> Zipping"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Done: $ZIP"

if [[ "${1:-}" == "--install" ]]; then
  DEST="/Applications/HexisMD.app"
  echo "==> Installing to $DEST"
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  echo "==> Installed. Launch with: open '$DEST'"
fi
