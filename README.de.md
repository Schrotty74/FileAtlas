# FileAtlas

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![Lizenz: GPLv3](https://img.shields.io/badge/Lizenz-GPLv3-green) ![Sicherheit: Sauber](https://img.shields.io/badge/Sicherheit-Sauber-brightgreen)

<p align="center">
  <img src="FileAtlas/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="150" alt="FileAtlas App Icon">
</p>

[English](README.md) · **Deutsch**

📘 **[Benutzerhandbuch (PDF)](output/pdf/FileAtlas-Handbuch.pdf)** – Scannen, Organisation, Backups, Exporte und Datenschutz ausführlich erklärt.

## Überblick

FileAtlas ist eine native macOS-App zum Indizieren und Vergleichen von Dateien, entwickelt ausschliesslich mit Apple-Frameworks. Die App hilft beim Scannen von Ordnern, Pruefen von Metadaten, Finden von Duplikaten, Vergleichen von Snapshots, Exportieren von Berichten und Verwalten von Backups ohne externe Abhaengigkeiten.

> **Sicherheit:** Es wurden keine privaten Daten, API-Keys oder Zertifikate veroeffentlicht. FileAtlas speichert Scan-Daten lokal. Wenn Update-Checks aktiviert sind, kontaktiert die App ausschliesslich GitHub Releases, um nach einer neueren Version zu suchen. Siehe [SECURITY.md](SECURITY.md) fuer den vollstaendigen Audit.

## Hilfe beim Erststart

Solange FileAtlas noch keine gespeicherten Orte oder indizierten Eintraege hat, bietet die Startansicht eine Ordnerauswahl, das Handbuch und optionale Hilfe von ChatGPT, Google Gemini oder Claude. Beim Auswaehlen eines Dienstes kopiert FileAtlas eine allgemeine, datensparsame Frage mit dem oeffentlichen Handbuch-Link in die Zwischenablage und oeffnet danach den Dienst. Lokale Dateidaten oder andere Nutzerdaten werden niemals automatisch uebertragen. Details stehen in [KI-Hilfe und Datenschutzhinweise](AI_HELP.md).

## Neu

- APP-Bundles sowie DMG-, PKG-, ZIP- und ISO-Dateien werden anhand ihrer tatsächlichen Endung gefunden und als einzelne Einträge indexiert.
- Die Cache-Wiederherstellung kann den zuletzt gespeicherten Index beim Start sofort anzeigen, ohne automatisch erneut zu scannen.
- Filtersets bleiben innerhalb ihres konfigurierten Bereichs über Ortswechsel aktiv und können optional nach einem Neustart wiederhergestellt werden.
- Optionale Update-Prüfungen beim Start können aktiviert werden und zeigen verfügbare Releases erst nach einer Nutzeraktion.
- Snapshot-Vergleiche melden unveränderte Dateien nicht mehr fälschlich als geändert, wenn sich nur Sekundenbruchteile im Zeitstempel unterscheiden.

## Funktionen

- Private lokale Indizierung mehrerer Ordner mit dauerhaftem Zugriff, Live-Fortschritt, Suche, Filtern, Tags und QuickLook-Vorschau.
- Duplikaterkennung, Snapshots, Ordnervergleich, Speicheranalyse und lokale Analyse aehnlicher Bilder.
- Sichere Organisation mit Stapel-Umbenennen, pruefbarer Aufraeumwarteschlange, Regeln, Smart Collections und Schnellzugriff auf zuletzt verwendete Orte.
- Flexible Backups: Index, Vollbackup, inkrementelle oder gezielt ausgewaehlte ZIP-Backups mit optionaler AES-256-Verschluesselung, SHA-256-Pruefung, Archivinspektion, selektiver Wiederherstellung, Zeitplan und Aufbewahrung.
- Export nach Excel, PDF und CSV.
- Deutsche und englische Oberflaeche, Hell/Dunkel/System-Darstellung, sechs Themes, Reduce Motion und konfigurierbare Tooltips.
- Datenschutzbewusste Erststart-Hilfe und optionale Update-Pruefungen: Ein gefundenes Release wird erst nach einem Klick geöffnet. FileAtlas hat keine externen Abhaengigkeiten.
- Der zuletzt gespeicherte Index kann beim Start sofort wiederhergestellt werden; das aktive Filterset bleibt auf Wunsch auch nach einem Neustart aktiv.

Siehe die vollständige, gruppierte [Funktionsübersicht](FEATURES.de.md).

## Voraussetzungen

- macOS 26.5+
- Xcode mit Swift-6-Unterstuetzung
- Keine externen Abhaengigkeiten

## Installation

1. Repository klonen.
2. `FileAtlas.xcodeproj` in Xcode oeffnen.
3. App bauen und starten.

Alternativ das aktuelle DMG oder ZIP von der [Releases](../../releases)-Seite herunterladen.

## macOS Gatekeeper Hinweis

FileAtlas ist nicht mit einem Apple-Entwicklerzertifikat signiert. Beim ersten Start kann macOS die App mit der Meldung *„FileAtlas kann nicht geoeffnet werden, weil es von einem nicht verifizierten Entwickler stammt."* blockieren.

**So oeffnest du die App dennoch:**

1. `FileAtlas.app` doppelklicken — macOS blockiert sie und zeigt eine Warnung
2. **Fertig** klicken
3. **Systemeinstellungen → Datenschutz & Sicherheit** oeffnen
4. Nach unten scrollen und neben FileAtlas auf **Trotzdem oeffnen** klicken
5. Im letzten Dialog mit **Oeffnen** bestaetigen

macOS merkt sich die Entscheidung — dieser Schritt ist nur einmalig notwendig.

> Falls macOS **„FileAtlas.app ist beschaedigt"** anzeigt statt der Sicherheitswarnung, Terminal oeffnen und eingeben:
> ```bash
> xattr -cr FileAtlas.app
> ```
> Danach die App normal oeffnen.

## Community

Fragen, Feedback und Diskussionen sind auf [Discord](https://discord.gg/Zy93AaYFaj) willkommen.

## Lizenz

FileAtlas ist unter der GNU General Public License v3.0 lizenziert. Der vollstaendige Lizenztext steht in [LICENSE](LICENSE).
