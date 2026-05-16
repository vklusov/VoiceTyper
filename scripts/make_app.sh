#!/bin/bash
set -euo pipefail

APP_NAME="VoiceTyper"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
BIN_PATH="$PROJECT_DIR/.build/debug/$APP_NAME"
BUNDLE_ID="com.vklusov.VoiceTyper"

if [ ! -f "$BIN_PATH" ]; then
    echo "❌ Binary not found at $BIN_PATH"
    echo "   Run: swift build"
    exit 1
fi

APP_DIR="$PROJECT_DIR/${APP_NAME}.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>VoiceTyper needs microphone access for speech-to-text.</string>
</dict>
</plist>
PLIST

echo "🔏 Signing with entitlements..."
codesign --force --sign - \
    --entitlements "$PROJECT_DIR/${APP_NAME}.entitlements" \
    --options runtime \
    "$APP_DIR"

echo "✅ App bundle created: $APP_DIR"
echo "   Bundle ID: $BUNDLE_ID"
