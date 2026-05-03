#!/usr/bin/env bash
# Build both Windows 64-bit executables.

set -euo pipefail
cd "$(dirname "$0")"

(cd x64 && ./build.sh)
(cd arm64 && ./build.sh)

cp x64/retina-guard-windows-x64.exe retina-guard.exe

echo "Done: windows/x64/retina-guard-windows-x64.exe"
echo "Done: windows/arm64/retina-guard-windows-arm64.exe"
echo "Legacy root artifact kept as x64: windows/retina-guard.exe"

