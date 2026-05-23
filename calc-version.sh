#!/bin/bash
# Calculate next version based on conventional commits since last tag.
# Outputs "X.Y.Z" or exits with error if nothing to bump.
set -e

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)

if [ -z "$LAST_TAG" ]; then
	# No tags yet — start from 0.0.0
	MAJOR=0
	MINOR=0
	PATCH=0
	COMMITS=$(git log --oneline 2>/dev/null)
else
	# Strip 'v' prefix
	VER="${LAST_TAG#v}"
	IFS='.' read -ra PARTS <<< "$VER"
	MAJOR="${PARTS[0]:-0}"
	MINOR="${PARTS[1]:-0}"
	PATCH="${PARTS[2]:-0}"
	COMMITS=$(git log "${LAST_TAG}..HEAD" --oneline 2>/dev/null)
fi

if [ -z "$COMMITS" ]; then
	echo "Error: no new commits since ${LAST_TAG:-the beginning}" >&2
	exit 1
fi

HAS_BREAKING=false
HAS_FEAT=false
HAS_FIX=false

while IFS= read -r line; do
	msg=$(echo "$line" | sed 's/^[0-9a-f]*\s*//')

	if echo "$msg" | grep -qi "BREAKING CHANGE"; then
		HAS_BREAKING=true
	elif echo "$msg" | grep -qE '^feat(\(.*\))?:'; then
		HAS_FEAT=true
	elif echo "$msg" | grep -qE '^(fix|chore|docs|refactor|perf|test|style|build|ci|revert)(\(.*\))?:'; then
		HAS_FIX=true
	else
		# Unconventional commit — treat as a fix/patch
		HAS_FIX=true
	fi
done <<< "$COMMITS"

if [ "$HAS_BREAKING" = true ]; then
	MAJOR=$((MAJOR + 1))
	MINOR=0
	PATCH=0
elif [ "$HAS_FEAT" = true ]; then
	MINOR=$((MINOR + 1))
	PATCH=0
elif [ "$HAS_FIX" = true ]; then
	PATCH=$((PATCH + 1))
fi

echo "${MAJOR}.${MINOR}.${PATCH}"
