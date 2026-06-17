#!/bin/zsh
set -euo pipefail

swift build -c release

app=".build/Termer.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
mkdir -p "$app/Contents/Resources"
cp ".build/release/Termer" "$app/Contents/MacOS/Termer"
cp ".build/release/TermerRunner" "$app/Contents/MacOS/TermerRunner"
cp "icons/macos/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
# SwiftPM resource bundle (holds AppIcon.icns for Bundle.module); Bundle.module fatalErrors if absent.
cp -R ".build/release/Termer_Termer.bundle" "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Termer</string>
  <key>CFBundleIdentifier</key><string>local.termer</string>
  <key>CFBundleName</key><string>Termer</string>
  <key>CFBundleDisplayName</key><string>Termer</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
PLIST
codesign --force --options runtime --timestamp --sign "${TERMER_SIGN_IDENTITY:--}" "$app/Contents/MacOS/TermerRunner" >/dev/null
codesign --force --options runtime --timestamp --sign "${TERMER_SIGN_IDENTITY:--}" "$app" >/dev/null
echo "$PWD/$app"
