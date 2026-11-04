#!/bin/bash
# build.sh — builds HandoffClean.app (Apple Silicon Mac, Xcode Command Line Tools required)
set -e
cd "$(dirname "$0")"

APP="HandoffClean.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "Compiling…"
swiftc -O -o "$APP/Contents/MacOS/HandoffClean" HandoffClean.swift -framework Cocoa

echo "Copying icon…"
cp AppIcon.icns "$APP/Contents/Resources/"

echo "Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HandoffClean</string>
    <key>CFBundleIdentifier</key>
    <string>com.tonynehihi.handoffclean</string>
    <key>CFBundleName</key>
    <string>HandoffClean</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

echo "Built: $APP"
