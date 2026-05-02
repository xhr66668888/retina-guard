#!/bin/bash
# Build a DMG from the .app bundle on macOS
# Usage: ./build-dmg.sh

set -e
cd "$(dirname "$0")"

APP="RetinaGuard.app"
DMG="RetinaGuard.dmg"
VOL="Retina Guard"

if [ ! -d "$APP" ]; then
    echo "Error: $APP not found. Run this script from the mac/ folder."
    exit 1
fi

echo "Building $DMG ..."

# Clean up
rm -f "$DMG"
rm -rf dmg-staging
mkdir dmg-staging
cp -R "$APP" dmg-staging/
ln -s /Applications dmg-staging/Applications

hdiutil create \
    -volname "$VOL" \
    -srcfolder dmg-staging \
    -ov \
    -format UDZO \
    "$DMG"

rm -rf dmg-staging

echo "Done: $DMG ($(du -h "$DMG" | cut -f1))"
