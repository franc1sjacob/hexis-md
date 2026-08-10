#!/usr/bin/env bash
# Build HexisMD.app from the SwiftPM executable.
#
# Usage:
#   ./scripts/bundle.sh              # builds ./build/HexisMD.app
#   ./scripts/bundle.sh --install    # also copies to /Applications
set -euo pipefail

APP_NAME="HexisMD"
BUNDLE_ID="com.francistaino.hexismd"
VERSION="0.1.0"
BUILD_NUMBER="1"
MIN_MACOS="15.0"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT_DIR="$ROOT/build"
APP="$OUT_DIR/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RES_DIR="$CONTENTS/Resources"

echo "==> Building release binary"
swift build -c release

echo "==> Preparing $APP"
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RES_DIR"

echo "==> Copying executable"
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"

echo "==> Copying SwiftPM resource bundles (Textual, our own, etc.)"
# Any *.bundle produced by SwiftPM must sit next to the executable so that
# Bundle.module resolves correctly (SPM's accessor uses Bundle.main.bundleURL,
# and for a Mac .app that's the .app root — but placing them in Contents/MacOS/
# also works because SwiftUI apps get bundleURL == .app package, not Contents).
# We add a minimal Info.plist so codesign --deep accepts them as valid bundles.
for b in .build/release/*.bundle; do
  [ -e "$b" ] || continue
  cp -R "$b" "$MACOS_DIR/"
  bname="$(basename "$b" .bundle)"
  cat > "$MACOS_DIR/$(basename "$b")/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}.resources.${bname}</string>
    <key>CFBundlePackageType</key><string>BNDL</string>
    <key>CFBundleName</key><string>${bname}</string>
</dict>
</plist>
EOF
done

echo "==> Building AppIcon.icns from Assets/AppIcon.appiconset"
ICONSET_TMP="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET_TMP"
SRC_ICONS="$ROOT/Assets/AppIcon.appiconset"
cp "$SRC_ICONS/mac16.png"   "$ICONSET_TMP/icon_16x16.png"
cp "$SRC_ICONS/mac32.png"   "$ICONSET_TMP/icon_16x16@2x.png"
cp "$SRC_ICONS/mac32.png"   "$ICONSET_TMP/icon_32x32.png"
cp "$SRC_ICONS/mac64.png"   "$ICONSET_TMP/icon_32x32@2x.png"
cp "$SRC_ICONS/mac128.png"  "$ICONSET_TMP/icon_128x128.png"
cp "$SRC_ICONS/mac256.png"  "$ICONSET_TMP/icon_128x128@2x.png"
cp "$SRC_ICONS/mac256.png"  "$ICONSET_TMP/icon_256x256.png"
cp "$SRC_ICONS/mac512.png"  "$ICONSET_TMP/icon_256x256@2x.png"
cp "$SRC_ICONS/mac512.png"  "$ICONSET_TMP/icon_512x512.png"
cp "$SRC_ICONS/mac1024.png" "$ICONSET_TMP/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_TMP" -o "$RES_DIR/AppIcon.icns"

echo "==> Writing Info.plist"
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>       <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>        <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>        <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key>           <string>$BUILD_NUMBER</string>
    <key>CFBundleIconFile</key>          <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>    <string>$MIN_MACOS</string>
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSHumanReadableCopyright</key>  <string>Copyright © 2026 Francis Taino</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>      <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>      <string>Editor</string>
            <key>LSHandlerRank</key>         <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>      <string>Plain Text Document</string>
            <key>CFBundleTypeRole</key>      <string>Editor</string>
            <key>LSHandlerRank</key>         <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.plain-text</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"

if [[ "${1:-}" == "--install" ]]; then
  DEST="/Applications/$APP_NAME.app"
  echo "==> Installing to $DEST"
  rm -rf "$DEST"
  cp -R "$APP" "/Applications/"
  echo "==> Installed. Launch with: open '$DEST'"
fi
