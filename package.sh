#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' 'dist/Bar To Do.app/Contents/Info.plist')
ARCH="${ARCH:-arm64}"
ARCHIVE="Bar-To-Do-${VERSION}-macOS-${ARCH}.zip"
ditto -c -k --keepParent 'dist/Bar To Do.app' "dist/$ARCHIVE"
(cd dist && shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")
printf 'Packaged dist/%s\n' "$ARCHIVE"
