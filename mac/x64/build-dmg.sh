#!/usr/bin/env bash
# Build the Intel Mac (x86_64) Retina Guard macOS package.

set -euo pipefail
cd "$(dirname "$0")"

APP="RetinaGuard.app"
APP_BIN="$APP/Contents/MacOS/retina-guard"
SOURCE="main.m"
PLIST="Info.plist"
ICON="Resources/AppIcon.icns"
DMG="RetinaGuard-mac-x64.dmg"
ARCHIVE="RetinaGuard-mac-x64.tar.gz"
VOL="Retina Guard x64"
ARCH="x86_64"
MIN_MACOS="10.13"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: macOS is required to build the Retina Guard DMG." >&2
    exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
    echo "Error: $SOURCE not found." >&2
    exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$PLIST" "$APP/Contents/Info.plist"
if [[ -f "$ICON" ]]; then
    cp "$ICON" "$APP/Contents/Resources/AppIcon.icns"
fi

/usr/libexec/PlistBuddy -c "Delete :LSArchitecturePriority" "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :LSArchitecturePriority array" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSArchitecturePriority:0 string x86_64" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $MIN_MACOS" "$APP/Contents/Info.plist"

echo "Building Retina Guard for Intel macOS ($ARCH) ..."
clang \
    -arch "$ARCH" \
    -mmacosx-version-min="$MIN_MACOS" \
    -fobjc-arc \
    -framework Cocoa \
    -o "$APP_BIN" \
    "$SOURCE"

if ! file "$APP_BIN" | grep -q "x86_64"; then
    echo "Error: $APP_BIN is not an x86_64 Mach-O binary." >&2
    file "$APP_BIN" >&2
    exit 1
fi

if command -v codesign >/dev/null 2>&1; then
    if [[ "$SIGN_IDENTITY" == "-" ]]; then
        echo "Ad-hoc signing $APP ..."
        codesign --force --deep --sign - "$APP"
    else
        echo "Signing $APP with $SIGN_IDENTITY ..."
        codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP"
    fi
fi

rm -f "$DMG" "$ARCHIVE"
rm -rf dmg-staging
mkdir dmg-staging
ditto "$APP" "dmg-staging/$APP"
ln -s /Applications dmg-staging/Applications

hdiutil create \
    -volname "$VOL" \
    -srcfolder dmg-staging \
    -ov \
    -format UDZO \
    "$DMG"

tar -czf "$ARCHIVE" "$APP"
rm -rf dmg-staging

echo "Done: $DMG ($(du -h "$DMG" | cut -f1))"
echo "Done: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"

