#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_ROOT="$(mktemp -d "$PROJECT_DIR/.build/fileatlas-tests.XXXXXX")"
PRODUCTS_DIR="$TEST_ROOT/products"
RESULT_BUNDLE="$TEST_ROOT/FileAtlasTests.xcresult"

xcodebuild \
  -project "$PROJECT_DIR/FileAtlas.xcodeproj" \
  -scheme FileAtlas \
  -configuration Debug \
  -derivedDataPath "$TEST_ROOT/derived" \
  CONFIGURATION_BUILD_DIR="$PRODUCTS_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  -resultBundlePath "$RESULT_BUNDLE" \
  test

echo "Test result: $RESULT_BUNDLE"
