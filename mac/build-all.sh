#!/usr/bin/env bash
# Build both macOS 64-bit packages.

set -euo pipefail
cd "$(dirname "$0")"

(cd arm64 && ./build-dmg.sh)
(cd x64 && ./build-dmg.sh)

rm -rf RetinaGuard.app
ditto arm64/RetinaGuard.app RetinaGuard.app
cp arm64/RetinaGuard-mac-arm64.dmg RetinaGuard.dmg
cp arm64/RetinaGuard-mac-arm64.tar.gz RetinaGuard-mac.tar.gz

echo "Done: mac/arm64/RetinaGuard-mac-arm64.dmg"
echo "Done: mac/x64/RetinaGuard-mac-x64.dmg"
echo "Legacy root artifact kept as arm64: mac/RetinaGuard.dmg"

