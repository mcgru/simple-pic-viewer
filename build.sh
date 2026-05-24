#!/bin/bash
# Build script for Simple Pic Viewer
#
# Usage:
#   ./build.sh          — dynamically linked binary
#   ./build.sh static   — statically linked binary
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HINT_FILE="${SCRIPT_DIR}/howto.libs.md"

show_hint() {
	echo ""
	echo "=== Build dependencies missing? ==="
	if [ -f "$HINT_FILE" ]; then
		sed -n '/^## TLDR/,/^## /p' "$HINT_FILE" | grep 'sudo apt'
	else
		echo "  sudo apt install build-essential pkg-config git libgtk-3-dev"
	fi
	echo ""
}

# Check pkg-config is installed
if ! command -v pkg-config &>/dev/null; then
	echo "Error: pkg-config not found — required for GTK3 build flags"
	show_hint
	exit 1
fi

# Check GTK3 dev headers are available
CFLAGS=$(pkg-config --cflags gtk+-3.0) || {
	echo "Error: GTK3 development headers not found (libgtk-3-dev)"
	show_hint
	exit 1
}
LIBS=$(pkg-config --libs gtk+-3.0)

if [ "${1:-}" = "static" ]; then
	echo "Building static binary..."
	echo "  (requires static libraries: libgtk-3-dev built with --enable-static,"
	echo "   or distro packages: libglib2.0-static-dev, libpango1.0-static-dev, ...)"
fi

v -enable-globals \
	-cflags "$CFLAGS" \
	-ldflags "$LIBS" \
	-o simple-pic-viewer . || {
	rc=$?
	echo ""
	echo "Error: v compilation failed (exit code ${rc})"
	show_hint
	exit ${rc}
}
