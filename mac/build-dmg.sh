#!/usr/bin/env bash
# Compatibility wrapper: build both macOS 64-bit packages.

set -euo pipefail
cd "$(dirname "$0")"

./build-all.sh
