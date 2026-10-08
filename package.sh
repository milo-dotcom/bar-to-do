#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' 'dist/To Do Desk.app/Contents/Info.plist')
ARCH="${ARCH:-arm64}"
ARCHIVE="To-Do-Desk-${VERSION}-macOS-${ARCH}.zip"
ditto -c -k --keepParent 'dist/To Do Desk.app' "dist/$ARCHIVE"
(cd dist && shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")
printf 'Packaged dist/%s\n' "$ARCHIVE"
