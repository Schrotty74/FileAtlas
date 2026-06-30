# CLAUDE.md — Projekt-Hinweise für zukünftige Sessions

## GitHub Actions — Release Workflow

### Wichtiger Fix: Fehlende Permission für Release-Erstellung

Beim Erstellen von GitHub Releases via `softprops/action-gh-release` muss zwingend folgende Permission gesetzt sein, sonst schlägt der Workflow mit **403 Resource not accessible by integration** fehl:

```yaml
permissions:
  contents: write
```

Vollständiges Beispiel:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  build:
    runs-on: macos-latest
    steps:
      ...
```

### macOS App ohne Apple-Zertifikat bauen

Für unsigned Builds folgende xcodebuild-Flags verwenden:

```
CODE_SIGNING_ALLOWED=NO
CODE_SIGNING_REQUIRED=NO
CODE_SIGN_IDENTITY=""
STRIP_INSTALLED_PRODUCT=YES
STRIP_SWIFT_SYMBOLS=YES
DEPLOYMENT_POSTPROCESSING=YES
```

### Tag neu setzen (nach Workflow-Fix)

Wenn ein Tag bereits auf einen fehlerhaften Commit zeigt:

```bash
git push origin :refs/tags/v1.0.0   # altes Tag löschen
git tag -d v1.0.0                    # lokal löschen
git tag v1.0.0                       # neu setzen (auf aktuellen Commit)
git push origin v1.0.0               # pushen
```

## Gatekeeper-Hinweis

Unsigned macOS Apps immer mit einem Gatekeeper-Hinweis in der README versehen:
- Rechtsklick → Öffnen → Öffnen bestätigen
- Nur einmalig notwendig

## Sicherheitsprüfung

Vor jedem Release prüfen:
- Keine hardcodierten Passwörter / API-Keys
- Keine privaten Pfade (`/Users/name/...`)
- `DEVELOPMENT_TEAM` leer lassen (`""`)
- `.dSYM`-Dateien nicht im `.app`-Bundle
