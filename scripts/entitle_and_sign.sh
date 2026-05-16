#!/bin/bash
set -euo pipefail

APP_NAME="VoiceTyper"
SCRIPT_DIR="$(cd "$(dirname "$0")" \&\& pwd)"
ENTITLEMENTS="$SCRIPT_DIR/../$APP_NAME.entitlements"
BUILD_DIR="$SCRIPT_DIR/../.build"

APP_PATH=$(find "$BUILD_DIR" -type d -name "${APP_NAME}.app" -path '*/debug/*' 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find ${APP_NAME}.app"
    echo "   Run: swift build"
    exit 1
fi

BUNDLE_ID="com.vklusov.VoiceTyper"

echo "🔧 Bundle ID → $BUNDLE_ID"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_PATH/Contents/Info.plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$APP_PATH/Contents/Info.plist"

echo "🔏 Signing with entitlements..."
codesign --force --sign -     --entitlements "$ENTITLEMENTS"     --options runtime     "$APP_PATH"

echo "✅ Done: $APP_PATH"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Entitlements: $ENTITLEMENTS"
