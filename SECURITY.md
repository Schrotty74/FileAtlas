# Security Policy

[Deutsch](SECURITY.de.md)

## Security Review

FileAtlas is designed as a local-first macOS file indexer. Scan data, snapshots, filter presets and backups remain local. The app uses Apple frameworks and no external package dependencies. Its optional update check contacts GitHub Releases only to determine whether a newer version exists.

Passwords for encrypted backups are stored in the macOS Keychain and are not stored as plain text.

## Reporting a Vulnerability

Please do not publish sensitive vulnerability details in a public GitHub issue. Contact the repository owner privately. Include the FileAtlas and macOS versions, reproduction steps and relevant logs or screenshots after removing private filenames, paths and backup contents.

## Scope

Relevant reports include folder scanning and indexing, file metadata handling, duplicate detection, snapshots and comparisons, batch rename and cleanup operations, ZIP backups and restore, AES-256 encrypted backups, SHA-256 verification, exports, QuickLook integration, Keychain handling and the optional GitHub release check.

Reports involving unintended file modification or deletion, path handling, archive extraction, backup integrity or exposure of indexed local data are especially important.

Thank you for helping keep FileAtlas and its users secure.
