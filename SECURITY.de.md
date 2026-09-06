# Sicherheitsrichtlinie

[English](SECURITY.md)

## Unterstützte Versionen

| Version | Unterstützt |
| --- | --- |
| 1.10.x | Ja |
| 1.9.x und älter | Nein |

Die aktuelle stabile Version ist 1.10.1.

## Sicherheitsmodell

FileAtlas ist als lokal ausgerichteter macOS-Dateiindexer konzipiert. Scan-Daten, Snapshots, Filtervorgaben und Backups bleiben lokal. Die App verwendet Apple-Frameworks und keine externen Paketabhängigkeiten. Die optionale Update-Prüfung kontaktiert ausschließlich GitHub Releases. Passwörter für verschlüsselte Backups werden im macOS-Schlüsselbund gespeichert und nicht im Klartext abgelegt.

## Sicherheitslücke melden

Bitte veröffentliche sensible Details zu Sicherheitslücken nicht in einem öffentlichen GitHub-Issue. Kontaktiere den Repository-Inhaber privat. Nenne die FileAtlas- und macOS-Version, Schritte zum Reproduzieren und relevante Logs oder Screenshots, nachdem private Dateinamen, Pfade und Backup-Inhalte entfernt wurden.

## Geltungsbereich

Relevante Meldungen umfassen unter anderem Ordner-Scanning und Indexierung, Dateimetadaten, Duplikaterkennung, Snapshots und Vergleiche, Stapelumbenennung und Bereinigungsaktionen, ZIP-Backups und Wiederherstellung, AES-256-verschlüsselte Backups, SHA-256-Prüfung, Exporte, QuickLook-Integration, Schlüsselbund-Verarbeitung und die optionale GitHub-Release-Prüfung.

Besonders wichtig sind Meldungen über unbeabsichtigte Dateiänderungen oder Löschungen, Pfadverarbeitung, Archivextraktion, Backup-Integrität oder die Offenlegung indexierter lokaler Daten.

Vielen Dank, dass du dabei hilfst, FileAtlas und seine Nutzer sicher zu halten.
