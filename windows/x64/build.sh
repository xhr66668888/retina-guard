#!/usr/bin/env bash
# Build the Windows x64 executable.

set -euo pipefail
cd "$(dirname "$0")"

OUT="retina-guard-windows-x64.exe"

if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is required to build the Windows x64 executable." >&2
    exit 1
fi

GOOS=windows GOARCH=amd64 CGO_ENABLED=0 \
    go build -trimpath -ldflags "-H windowsgui -s -w" -o "$OUT" .

file "$OUT"

