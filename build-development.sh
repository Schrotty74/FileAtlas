#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS_ROOT="${FILEATLAS_ARTIFACTS_ROOT:-$PROJECT_DIR/Build}"
BUILD_DIR="$ARTIFACTS_ROOT/dev"
DERIVED_DATA_DIR="$PROJECT_DIR/.build/dev"
APP_NAME="FileAtlas"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$DERIVED_DATA_DIR"

xcodebuild \
  -project "$PROJECT_DIR/FileAtlas.xcodeproj" \
  -scheme FileAtlas \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

APP_PATH=$(find "$DERIVED_DATA_DIR/Build/Products/Debug" -maxdepth 1 -type d -name "*.app" | head -1)
if [ -z "$APP_PATH" ]; then
  echo "ERROR: App bundle not found after build." >&2
  exit 1
fi

ditto "$APP_PATH" "$BUILD_DIR/$APP_NAME.app"
echo "$BUILD_DIR/$APP_NAME.app"
