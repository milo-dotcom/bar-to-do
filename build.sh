#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

VERSION="1.2.0"
BUILD_NUMBER="4"
APP="dist/Bar To Do.app"
ARCH="${ARCH:-arm64}"
BUNDLE_ID="${BUNDLE_ID:-local.tododesk.app}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
case "$ARCH" in arm64|x86_64) ;; *) echo "ARCH must be arm64 or x86_64" >&2; exit 1 ;; esac
case "$BUNDLE_ID" in *[!a-zA-Z0-9.-]*|'') echo "Invalid BUNDLE_ID" >&2; exit 1 ;; esac

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" .build/module-cache
xcrun swiftc Source/BarToDo.swift \
  -o "$APP/Contents/MacOS/BarToDo" \
  -framework Cocoa -framework WebKit \
  -target "$ARCH-apple-macos14.0" \
  -module-cache-path .build/module-cache \
  -O
cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>BarToDo</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>Bar To Do</string>
<key>CFBundleDisplayName</key><string>Bar To Do</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Milosz Durzynski. MIT License. Not affiliated with Microsoft.</string>
</dict></plist>
PLIST
cp LICENSE "$APP/Contents/Resources/LICENSE"
cp PRIVACY.md "$APP/Contents/Resources/PRIVACY.md"
if [ "$SIGNING_IDENTITY" = "-" ]; then
  codesign --force --sign - "$APP"
else
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP"
fi
codesign --verify --deep --strict "$APP"
printf 'Built %s (%s)\n' "$APP" "$ARCH"
