#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# FileAtlas — Lokales Release-Skript
# Baut die App, prüft auf private Daten, erstellt DMG + ZIP
# und lädt beides als GitHub Release hoch.
#
# Voraussetzung: gh CLI installiert (https://cli.github.com)
# Aufruf: ./build-release.sh v1.0.1
# Beta:   ./build-release.sh v1.0.1-beta.1
# ---------------------------------------------------------------------------

VERSION=${1:-}
if [ -z "$VERSION" ]; then
  echo "Verwendung: ./build-release.sh v1.0.0"
  exit 1
fi
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-beta\.[0-9]+)?$ ]]; then
  echo "FEHLER: Ungueltiges Versionsformat: '$VERSION'"
  echo "Erwartet: vX.Y.Z oder vX.Y.Z-beta.N (z. B. v1.8.1 oder v1.9.0-beta.1)"
  exit 1
fi
APP_VERSION="${VERSION#v}"
RELEASE_VERSION="${APP_VERSION%%-beta.*}"
IS_PRERELEASE=false
RELEASE_TITLE="FileAtlas $VERSION"
RELEASE_CREATE_ARGS=()
if [[ "$VERSION" =~ -beta\.([0-9]+)$ ]]; then
  IS_PRERELEASE=true
  BETA_NUMBER="${BASH_REMATCH[1]}"
  RELEASE_TITLE="FileAtlas $RELEASE_VERSION Beta $BETA_NUMBER"
  RELEASE_CREATE_ARGS+=(--prerelease)
fi

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS_ROOT="${FILEATLAS_ARTIFACTS_ROOT:-$PROJECT_DIR/Build}"
BUILD_CHANNEL="final"
PRODUCT_BUNDLE_IDENTIFIER="app.fileatlas.FileAtlas"
if [ "$IS_PRERELEASE" = true ]; then
  BUILD_CHANNEL="beta"
  PRODUCT_BUNDLE_IDENTIFIER="app.fileatlas.FileAtlas.beta"
fi
BUILD_DIR="$ARTIFACTS_ROOT/$BUILD_CHANNEL/$VERSION"
PRODUCTS_DIR="$BUILD_DIR/products"
APP_NAME="FileAtlas"

echo "=== FileAtlas Release Build $VERSION ==="
echo "App-Version: $APP_VERSION"
echo ""

# Der Zielordner ist versionsspezifisch; ältere Beta- oder Final-Artefakte
# bleiben dadurch erhalten.
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
  SYMROOT="$PRODUCTS_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  STRIP_INSTALLED_PRODUCT=YES \
  STRIP_SWIFT_SYMBOLS=YES \
  DEPLOYMENT_POSTPROCESSING=YES \
  MARKETING_VERSION="$APP_VERSION" \
  PRODUCT_BUNDLE_IDENTIFIER="$PRODUCT_BUNDLE_IDENTIFIER" \
  | grep -E "^(Build|error:|warning: |CompileSwift|Ld )" || true

APP_PATH=$(find "$PRODUCTS_DIR/Release" -name "*.app" -maxdepth 1 -type d | head -1)
if [ -z "$APP_PATH" ]; then
  echo "FEHLER: .app nicht gefunden. Build fehlgeschlagen?"
  exit 1
fi
echo "App gefunden: $APP_PATH"

BUILT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
if [ "$BUILT_VERSION" != "$APP_VERSION" ]; then
  echo "FEHLER: App-Version ist $BUILT_VERSION, erwartet $APP_VERSION"
  exit 1
fi
echo "Bundle-Version geprüft: $BUILT_VERSION"

BUILT_BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist")
if [ "$BUILT_BUNDLE_IDENTIFIER" != "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
  echo "FEHLER: Bundle-ID ist $BUILT_BUNDLE_IDENTIFIER, erwartet $PRODUCT_BUNDLE_IDENTIFIER"
  exit 1
fi
echo "Bundle-ID geprüft: $BUILT_BUNDLE_IDENTIFIER"

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

# --- Ad-hoc Signatur ---
echo ""
echo "[2b/5] Ad-hoc Signatur (verhindert 'beschädigt'-Meldung)..."
codesign --force --deep --sign - "$APP_PATH"
echo "Signatur gesetzt."

# --- ZIP ---
echo ""
echo "[3/5] Erstelle ZIP..."
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl "$APP_PATH" "$ZIP_PATH"
echo "ZIP: $ZIP_PATH"

# --- DMG ---
echo ""
echo "[4/5] Erstelle DMG..."
DMG_STAGING="$BUILD_DIR/dmg_src"
mkdir -p "$DMG_STAGING"
cp -r "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$DMG_PATH" > /dev/null
echo "DMG: $DMG_PATH"

# --- Prüfsummen ---
echo ""
echo "[4b/5] Erstelle SHA-256-Prüfsummen..."
CHECKSUM_PATH="$BUILD_DIR/SHA256SUMS.txt"
(
  cd "$BUILD_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" "$(basename "$ZIP_PATH")"
) > "$CHECKSUM_PATH"
echo "SHA-256: $CHECKSUM_PATH"

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

NOTES_ARGS=()
if [ "$IS_PRERELEASE" = false ]; then
  NOTES_PATH="$BUILD_DIR/release-notes.md"
  echo "Generiere Final Release Notes aus den veröffentlichten Betas..."
  "$PROJECT_DIR/generate-final-release-notes.sh" "$VERSION" "$NOTES_PATH"
  NOTES_ARGS=(--notes-file "$NOTES_PATH")
else
  # GitHub erstellt die Beta-Notes direkt aus den Änderungen seit dem letzten Release.
  # Dadurch sind keine lokalen release-notes-*.md-Dateien nötig.
  NOTES_ARGS=(--generate-notes)
fi

gh release create "$VERSION" \
  "$DMG_PATH#FileAtlas.dmg" \
  "$ZIP_PATH#FileAtlas.zip" \
  "$CHECKSUM_PATH#SHA256SUMS.txt" \
  --title "$RELEASE_TITLE" \
  "${NOTES_ARGS[@]}" \
  --repo Schrotty74/FileAtlas \
  "${RELEASE_CREATE_ARGS[@]}"

echo ""
echo "=== Fertig! Release $VERSION ist auf GitHub verfügbar. ==="
