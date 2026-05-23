#!/bin/bash
# Build .deb package for Simple Pic Viewer
#
# Usage:
#   ./makedeb.sh              — build using docker (рекомендуется)
#   ./makedeb.sh local BINARY — использовать готовый бинарник
#
set -e

PKG_NAME="simple-pic-viewer"
PKG_VERSION="1.1.3"
PKG_ARCH="amd64"
DEB_FILE="${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY_SRC="${2:-}"
PACKAGING_DIR="${SCRIPT_DIR}/packaging"

if [ "${1:-}" = "local" ] && [ -n "$BINARY_SRC" ]; then
	echo "==> Using local binary: ${BINARY_SRC}"
	cp "${BINARY_SRC}" "${PACKAGING_DIR}/usr/bin/simple-pic-viewer"
else
	echo "==> Building binary via Docker..."
	docker build --network host -f Dockerfile.ubuntu -t simple-pic-viewer-builder "${SCRIPT_DIR}"
	docker run --rm --network host -v "${SCRIPT_DIR}:/app" simple-pic-viewer-builder
	cp "${SCRIPT_DIR}/simple-pic-viewer" "${PACKAGING_DIR}/usr/bin/simple-pic-viewer"
fi

echo "==> Stripping binary"
strip "${PACKAGING_DIR}/usr/bin/simple-pic-viewer"

echo "==> Generating dependency list..."
# План: использовать dpkg-shlibdeps для автоматического определения зависимостей.
# Пока — фиксированный список на основе libgtk-3-0.
cat > "${PACKAGING_DIR}/DEBIAN/control" << CTRL
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: graphics
Priority: optional
Architecture: ${PKG_ARCH}
Depends: libgtk-3-0 (>= 3.24), libgdk-pixbuf-2.0-0 (>= 2.42)
Maintainer: Simple Pic Viewer Team
Description: Minimal GTK3 image viewer with keyboard navigation
 Supports PNG, JPEG, TIFF images. Left/right navigation,
 copy-to-folder (link/move), configurable target dirs.
CTRL

echo "==> Building .deb..."
fakeroot dpkg-deb --build "${PACKAGING_DIR}" "${SCRIPT_DIR}/${DEB_FILE}"

echo "==> Done: ${DEB_FILE}"
echo "    Install: sudo dpkg -i ${DEB_FILE}"
echo "    Fix deps if needed: sudo apt-get install -f"
