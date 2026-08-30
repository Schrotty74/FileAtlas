#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-}
OUTPUT_PATH=${2:-}
ADDITIONAL_NOTES_PATH=${3:-}

if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Expected a final version in the form vX.Y.Z." >&2
  exit 64
fi
if [ -z "$OUTPUT_PATH" ]; then
  echo "ERROR: An output path is required." >&2
  exit 64
fi
if [ -n "$ADDITIONAL_NOTES_PATH" ] && [ ! -f "$ADDITIONAL_NOTES_PATH" ]; then
  echo "ERROR: Additional notes file not found: $ADDITIONAL_NOTES_PATH" >&2
  exit 66
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI (gh) is required to collect beta release notes." >&2
  exit 69
fi

RELEASE_VERSION="${VERSION#v}"
BETA_PREFIX="${VERSION}-beta."
PREVIOUS_FINAL_TAG=$(gh release list --repo Schrotty74/FileAtlas --limit 100 --json tagName,isPrerelease --jq '.[] | select(.isPrerelease == false) | .tagName' \
  | awk -v current="$VERSION" '$0 != current { print; exit }')
BETA_TAGS=$(gh release list --repo Schrotty74/FileAtlas --limit 100 --json tagName,isPrerelease --jq '.[] | select(.isPrerelease == true) | .tagName' \
  | awk -v prefix="$BETA_PREFIX" 'index($0, prefix) == 1 { print }' \
  | awk -F 'beta.' '{ print $2 "\t" $0 }' \
  | sort -n \
  | cut -f2-)

if [ -z "$BETA_TAGS" ]; then
  echo "ERROR: No published beta releases found for $VERSION." >&2
  exit 65
fi
if [ -z "$PREVIOUS_FINAL_TAG" ]; then
  echo "ERROR: No previous Final release found for $VERSION." >&2
  exit 65
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
{
  echo "## Changes included from beta releases"
  echo
  while IFS= read -r beta_tag; do
    [ -z "$beta_tag" ] && continue
    beta_number="${beta_tag##*.}"
    echo "### FileAtlas $RELEASE_VERSION Beta $beta_number"
    echo
    gh release view "$beta_tag" --repo Schrotty74/FileAtlas --json body --jq .body | sed 's/^## /#### /'
    echo
  done <<< "$BETA_TAGS"

  if [ -n "$ADDITIONAL_NOTES_PATH" ]; then
    echo "## Additional release notes"
    echo
    cat "$ADDITIONAL_NOTES_PATH"
    echo
  fi

  echo "**Full Changelog**: https://github.com/Schrotty74/FileAtlas/compare/$PREVIOUS_FINAL_TAG...$VERSION"
} > "$OUTPUT_PATH"
