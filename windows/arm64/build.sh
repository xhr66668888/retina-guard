#!/usr/bin/env bash
# Build the Windows arm64 executable.

set -euo pipefail
cd "$(dirname "$0")"

OUT="retina-guard-windows-arm64.exe"

if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is required to build the Windows arm64 executable." >&2
    exit 1
fi

GOOS=windows GOARCH=arm64 CGO_ENABLED=0 \
    go build -trimpath -ldflags "-H windowsgui -s -w" -o "$OUT" .

file "$OUT"

