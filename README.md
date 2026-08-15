# FileAtlas for macOS – File Indexer, Duplicate Finder & Folder Comparison

FileAtlas is a native, privacy-focused macOS file indexer and duplicate finder for scanning folders, inspecting metadata, comparing folder snapshots, analyzing storage, exporting reports and managing local backups.

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green) ![Security: Clean](https://img.shields.io/badge/Security-Clean-brightgreen) [![Discord](https://img.shields.io/badge/Discord-Join%20Community-5865F2?logo=discord&logoColor=white)](https://discord.gg/RbsvqRCPQ)

<p align="center"><img src="FileAtlas/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="150" alt="FileAtlas macOS file indexer and duplicate finder app icon"></p>

FileAtlas is built with pure Apple frameworks. It helps scan folders, inspect metadata, detect duplicate files, compare snapshots and folders, find large indexed items, export reports, and manage backups without external dependencies.

> **Security:** No private data, API keys, or certificates have been published in this repository. FileAtlas stores scan data locally. If update checks are enabled, the app only contacts GitHub Releases to look for a newer version. See [SECURITY.md](SECURITY.md) for the full audit.

[🇩🇪 Deutsche Beschreibung](README.de.md)

## Highlights

- Recursive local file indexing with live progress
- Duplicate file detection using SHA-256
- Folder and snapshot comparison with automatic "what changed?" summaries
- Storage analysis for largest indexed items, file types and duplicates
- Quick search and saveable filters by name, extension and size
- Smart Collections, tags, rules and safe cleanup queue
- Excel, PDF and CSV report export
- Local JSON and ZIP backups with optional AES-256 protection
- QuickLook previews and native macOS file/app icons
- German and English interface
- No external dependencies; pure Apple frameworks

## Manual

Read the complete English usage guide: [FileAtlas Manual (PDF)](output/pdf/FileAtlas-Manual-EN.pdf).  
Die deutsche Ausgabe findest du hier: [FileAtlas Handbuch (PDF)](output/pdf/FileAtlas-Handbuch.pdf).

## Requirements

- macOS 26.5+
- Xcode with Swift 6 support
- No external dependencies

## Installation

1. Clone the repository.
2. Open `FileAtlas.xcodeproj` in Xcode.
3. Build and run the app.

Alternatively, download the latest DMG or ZIP from the [Releases](../../releases) page.

## Privacy

FileAtlas indexes user-selected folders locally. Scan data stays on the Mac. Optional update checks contact only GitHub Releases. The first-launch AI help copies only a general privacy-safe question and public manual link; it never sends local file data automatically.

## Community

Questions, feedback and discussions are welcome on [Discord](https://discord.gg/RbsvqRCPQ).

## License

FileAtlas is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
