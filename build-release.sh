#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# FileAtlas — Lokales Release-Skript
# Baut die App, prüft auf private Daten, erstellt DMG + ZIP
# und lädt beides als GitHub Release hoch.
#
# Voraussetzung: gh CLI installiert (https://cli.github.com)
# Aufruf: ./build-release.sh v1.0.1
# ---------------------------------------------------------------------------

VERSION=${1:-}
if [ -z "$VERSION" ]; then
  echo "Verwendung: ./build-release.sh v1.0.0"
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build-release"
APP_NAME="FileAtlas"

echo "=== FileAtlas Release Build $VERSION ==="
echo ""

# Aufräumen
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# --- Build ---
echo "[1/5] Baue App mit Xcode..."
xcodebuild \
  -project "$PROJECT_DIR/FileAtlas.xcodeproj" \
  -scheme FileAtlas \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/derived" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_SWIFT_SYMBOLS=YES \
  DEPLOYMENT_POSTPROCESSING=YES \
  | grep -E "^(Build|error:|warning: |CompileSwift|Ld )" || true

APP_PATH=$(find "$BUILD_DIR/derived/Build/Products/Release" -name "*.app" -maxdepth 1 -type d | head -1)
if [ -z "$APP_PATH" ]; then
  echo "FEHLER: .app nicht gefunden. Build fehlgeschlagen?"
  exit 1
fi
echo "App gefunden: $APP_PATH"

# --- Security Check ---
echo ""
echo "[2/5] Sicherheitsprüfung..."
BINARY="$APP_PATH/Contents/MacOS/$APP_NAME"

if strings "$BINARY" | grep -E "/Users/[a-zA-Z0-9_]+" | grep -v "/Users/runner" | grep -q .; then
  echo "FEHLER: Lokale Benutzerpfade im Binary gefunden!"
  strings "$BINARY" | grep -E "/Users/[a-zA-Z0-9_]+" | grep -v "/Users/runner"
  exit 1
fi

if find "$APP_PATH" -name "*.dSYM" | grep -q .; then
  echo "FEHLER: Debug-Symbole (.dSYM) im .app gefunden!"
  exit 1
fi

echo "Sicherheitsprüfung bestanden — keine privaten Daten gefunden."

# --- ZIP ---
echo ""
echo "[3/5] Erstelle ZIP..."
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "ZIP: $ZIP_PATH"

# --- DMG ---
echo ""
echo "[4/5] Erstelle DMG..."
DMG_STAGING="$BUILD_DIR/dmg_src"
mkdir -p "$DMG_STAGING"
cp -r "$APP_PATH" "$DMG_STAGING/"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$DMG_PATH" > /dev/null
echo "DMG: $DMG_PATH"

# --- GitHub Release ---
echo ""
echo "[5/5] Erstelle GitHub Release $VERSION..."

if ! command -v gh &> /dev/null; then
  echo ""
  echo "gh CLI nicht gefunden. Installiere es mit: brew install gh"
  echo "Danach einmalig: gh auth login"
  echo ""
  echo "Dateien zum manuellen Upload:"
  echo "  DMG: $DMG_PATH"
  echo "  ZIP: $ZIP_PATH"
  exit 0
fi

gh release create "$VERSION" \
  "$DMG_PATH#FileAtlas.dmg" \
  "$ZIP_PATH#FileAtlas.zip" \
  --title "FileAtlas $VERSION" \
  --generate-notes \
  --repo Schrotty74/FileAtlas

echo ""
echo "=== Fertig! Release $VERSION ist auf GitHub verfügbar. ==="
