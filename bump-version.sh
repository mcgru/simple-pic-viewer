#!/bin/bash
# Bump version string in all places that reference it.
#
# Usage:
#   ./bump-version.sh 1.0.1
#   ./bump-version.sh 1.2.0
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OLD_VER=$(grep '^PKG_VERSION=' "${SCRIPT_DIR}/makedeb.sh" | sed 's/^PKG_VERSION="\(.*\)"$/\1/')
NEW_VER="${1:-}"

if [ -z "$NEW_VER" ]; then
	echo "Usage: $0 <new-version>"
	echo "Current version: ${OLD_VER}"
	exit 1
fi

# Validate: semver-like (X.Y.Z or X.Y.Z-anything)
if ! echo "$NEW_VER" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+([-_\.].+)?)?$'; then
	echo "Error: '${NEW_VER}' does not look like a version number (expected X.Y.Z)"
	exit 1
fi

echo "Bumping version: ${OLD_VER} → ${NEW_VER}"
echo

# Update makedeb.sh
sed -i 's/^PKG_VERSION="'"${OLD_VER}"'"$/PKG_VERSION="'"${NEW_VER}"'"/' "${SCRIPT_DIR}/makedeb.sh"
echo "  makedeb.sh: PKG_VERSION=\"${NEW_VER}\""

# Update packaging/DEBIAN/control
sed -i 's/^Version: '"${OLD_VER}"'$/Version: '"${NEW_VER}"'/' "${SCRIPT_DIR}/packaging/DEBIAN/control"
echo "  packaging/DEBIAN/control: Version: ${NEW_VER}"

# Update version.v
sed -i "s/^pub const app_version = '${OLD_VER}'$/pub const app_version = '${NEW_VER}'/" "${SCRIPT_DIR}/version.v"
echo "  version.v: app_version = ${NEW_VER}"

# Commit and tag
echo
echo "==> Committing version bump..."
cd "${SCRIPT_DIR}"
git add -A
git commit -m "chore: bump version to ${NEW_VER}"

echo "==> Tagging v${NEW_VER}..."
git tag -a "v${NEW_VER}" -m "version ${NEW_VER}"

echo
echo "Done."
echo "Verify with: grep -rn '${OLD_VER}\\|${NEW_VER}' version.v makedeb.sh packaging/DEBIAN/control"
