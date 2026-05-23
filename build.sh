#!/bin/bash
# Build script for Simple Pic Viewer
#
# Required packages: libgtk-3-dev
#   (automatically pulls in: libglib2.0-dev, libpango1.0-dev,
#    libcairo2-dev, libgdk-pixbuf-2.0-dev, libatk1.0-dev)
#
# Usage:
#   ./build.sh          — dynamically linked binary
#   ./build.sh static   — statically linked binary
#
set -e

CFLAGS=$(pkg-config --cflags gtk+-3.0)
LIBS=$(pkg-config --libs gtk+-3.0)

if [ "${1:-}" = "static" ]; then
	echo "Building static binary..."
	echo "  (requires static libraries: libgtk-3-dev built with --enable-static,"
	echo "   or distro packages: libglib2.0-static-dev, libpango1.0-static-dev, ...)"
	v -enable-globals \
		-cflags "$CFLAGS" \
		-ldflags "-static $LIBS" \
		-o simple-pic-viewer .
else
	v -enable-globals \
		-cflags "$CFLAGS" \
		-ldflags "$LIBS" \
		-o simple-pic-viewer .
fi
