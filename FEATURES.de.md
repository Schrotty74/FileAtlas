# FileAtlas – Funktionsübersicht

[English](FEATURES.md)

Diese Seite beschreibt die stabilen Funktionen ausführlich. Installation und tägliche Nutzung erklären das [deutsche Handbuch (PDF)](output/pdf/FileAtlas-Handbuch.pdf) und das [englische Manual (PDF)](output/pdf/FileAtlas-Manual-EN.pdf).

## Indizierung und Navigation

- Indiziert mehrere ausgewählte Ordner rekursiv mit Live-Fortschritt.
- Behält den Zugriff auf ausgewählte Ordner über App-Neustarts hinweg mit Security-Scoped Bookmarks.
- Bietet sortierbare und neu anordenbare Spalten für Name, Typ, Status, Tags, Größe und Geändert sowie kompakte, normale und große Zeilenhöhen.
- Bietet eine kompakte Listenansicht und eine Tabellenansicht, QuickLook mit der Leertaste sowie eine Inline-Vorschau im Detailbereich.
- Durchsucht Namen, Endungen und Größen, einschließlich Abfragen wie `> 10 MB` und `< 500 KB`.
- Speichert Filter mit Ein- und Ausschlusslisten und unterstützt ignorierte Ordner, Bundle-Erkennung, Endungs-Whitelists und Unterordneranzeige ohne die Oberfläche zu blockieren.
- Bietet einen manuell verwalteten Schnellzugriff auf die fünf zuletzt gescannten Ordner.

## Analyse und Vergleich

- Erkennt Duplikate über Größengruppierung und SHA-256-Inhaltshashes. Vergleiche bleiben standardmäßig innerhalb jedes gespeicherten Orts; ein ortsübergreifender Vergleich ist optional.
- Speichert bis zu zehn JSON-Snapshots pro Ort, vergleicht sie mit dem aktuellen Scan und fasst Änderungen nach einem weiteren Scan zusammen.
- Vergleicht zwei Ordner direkt.
- Öffnet ein separates, größenveränderbares Fenster für die Speicheranalyse mit Dateityp-Karte, den größten indizierten Einträgen, Duplikatspeicher und Statushinweisen für nicht verfügbare Orte, fehlende Backup-Ziele und fällige Backups.
- Gruppiert lokal ähnliche Bilder mit Apples Vision-Feature-Prints auf dem Gerät in einer begrenzten Auswahl von bis zu 250 Bildern. Bilder werden niemals hochgeladen.

## Organisation und Automatisierung

- Fügt vordefinierte oder eigene farbcodierte Tags hinzu, einschließlich endungsbasierter Tags über alle gespeicherten Orte.
- Bietet Smart Collections für Dateityp, Größe, letzte Änderungen, Duplikate, maximale Größe, Tags, Orte und ausgeschlossene Dateitypen.
- Bietet Regeln für Dateityp, Mindestgröße und Dateialter mit Benachrichtigungen beim Scan und optionaler Aufnahme in die Aufräumwarteschlange.
- Verwendet eine prüfbare Aufräumwarteschlange; ausgewählte Elemente werden erst nach Bestätigung in den macOS-Papierkorb verschoben.
- Benennt Stapel sicher mit Vorschau, Präfix, Suffix, optionaler fortlaufender Nummerierung, Kollisionsprüfung und ausdrücklicher Bestätigung um.
- Kennzeichnet gespeicherte Orte als nicht verfügbar, wenn ein Laufwerk oder Ordner momentan nicht erreichbar ist.

## Backups und Wiederherstellung

- Erstellt Index-Backups als JSON-Metadatenexport, vollständige ZIP-Backups, inkrementelle ZIP-Backups nach einer ersten Vollsicherung oder ZIP-Backups ausgewählter Dateien und Ordner.
- Unterstützt optionale ZIP-Komprimierung, AES-256-Verschlüsselung mit im Schlüsselbund gespeicherten Passwörtern und optionale SHA-256-Manifeste.
- Prüft Archiv-Inhalte, validiert ZIP-Struktur und optionale SHA-256-Manifestinhalte und stellt ausgewählte archivierte Einträge wieder her.
- Plant Backups je Ort als Aus, Täglich oder Wöchentlich. Fällige Backups laufen nur während FileAtlas geöffnet ist oder beim Start; die App ist kein Hintergrunddienst.
- Führt einen Backup-Verlauf je Ort und kann die letzten 3, 5 oder 10 FileAtlas-Archive behalten oder alle Archive aufbewahren.

## Export, Oberfläche und Einstellungen

- Exportiert Scan-Daten als Excel (`.xlsx`), PDF oder CSV. CSV verwendet UTF-8 mit BOM und Semikolon-Trennung; XLSX wird ohne externe Bibliothek erzeugt.
- Zeigt App-Bundle-Metadaten wie Name, Version, Entwickler und Bundle-Kennung im Detailbereich.
- Bietet unabhängige Darstellungsmodi Hell, Dunkel und System sowie die Themes Midnight Teal, Retro, Graphite Lime, Herbst, Winter und Glas.
- Das Glas-Theme verwendet einen vollflächigen transparenten AppKit-Hintergrund; die Seitenleiste fügt keine separate Materialebene hinzu.
- Bietet optionale Tooltips, eine Reduce-Motion-Einstellung mit Beachtung der macOS-Bedienungshilfen und optionales Scannen beim App-Start.
- Startet auf Englisch und bietet Deutsch mit der DACH-Sprachregel für `de_AT`, `de_DE` und `de_CH`.
- Enthält ein Einstellungsfenster mit Seitenleistennavigation, Darstellungsoptionen, Cache-Leerung, Umschalter für generische Icons sowie einem Info-&-Kontakt-Bereich.

## Datenschutz und Sicherheit

- Verwendet ausschließlich Apple-Frameworks und keine Drittanbieter-Abhängigkeiten.
- Speichert Scan-Daten und Einstellungen lokal auf dem Mac.
- Prüft GitHub Releases nur auf Updates, wenn die optionale Update-Prüfung aktiviert ist.
- Zeigt Erststart-Hilfe nur ohne gespeicherte Orte, zuletzt verwendete Orte und indizierte Einträge. Die KI-Hilfe kopiert eine feste, datensparsame Frage mit einem öffentlichen Handbuch-Link und öffnet den gewählten Dienst erst nach einem Klick; lokale Dateidaten werden nie automatisch übertragen.
- Veröffentlicht und benötigt keine privaten Daten, API-Keys, Zertifikate, Konten, Analysedienste oder Cloud-Synchronisation.
