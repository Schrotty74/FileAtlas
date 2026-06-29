# FileAtlas

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green) ![Security: Clean](https://img.shields.io/badge/Security-Clean-brightgreen)

<p align="center">
  <img src="FileAtlas/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="150" alt="FileAtlas App Icon">
</p>

FileAtlas is a native macOS file indexing and comparison app built with pure Apple frameworks. It helps scan folders, inspect metadata, detect duplicates, compare snapshots, export reports, and manage backups without external dependencies.

> **Security:** No private data, API keys, or certificates have been published in this repository. The app makes no network requests and stores all data locally. See [SECURITY.md](SECURITY.md) for the full audit.


[🇩🇪 Deutsche Beschreibung](README.de.md)

## Features

- Local file indexing with recursive folder scan and live progress (AsyncStream)
- Scan multiple folders simultaneously
- Security-Scoped Bookmarks (access persists after app restart)
- Liquid Glass sidebar (desktop shines through)
- Light / Dark / System appearance switcher (independent of macOS setting)
- DE/EN localization with DACH rule (de_AT, de_DE, de_CH always German)
- Sortable, reorderable columns (Name, Type, Status, Tags, Size, Modified)
- Adjustable row height (Compact / Normal / Large)
- QuickLook preview (Space bar)
- Quick search by name, extension, size (`> 10 MB`, `< 500 KB`)
- Saveable filter sets with include/exclude lists
- Ignored folders (skipped during scan, shown as single entry with total size)
- Bundle recognition (`.app`, `.framework`, `.xcodeproj` treated as single entries, descendants skipped)
- Extension whitelist filter (only index specific file types)
- No auto-rescan if folder is already indexed
- Duplicate detection (size grouping -> SHA-256 hash, gold badge)
- Snapshots after each scan (max. 10, JSON) with diff comparison and delete
- Folder comparison (two folders directly)
- Tags (predefined + custom, color-coded pills)
- Quick access (last 5 scanned folders in sidebar, manually managed)
- Export: Excel (`.xlsx`), PDF, CSV
- Backup: Index backup (JSON) and full backup (ZIP, optional AES-256, password in Keychain)
- Backup schedule: Off / Daily / Weekly per location
- Settings panel with sidebar navigation (macOS System Settings style)
- No external dependencies - pure Apple frameworks only

## Requirements

- macOS 26.5+
- Xcode with Swift 6 support
- No external dependencies

## Installation

1. Clone the repository.
2. Open `FileAtlas.xcodeproj` in Xcode.
3. Build and run the app.

Alternatively, download the latest DMG or ZIP from the [Releases](../../releases) page.

## macOS Gatekeeper Notice

FileAtlas is not signed with an Apple Developer certificate. On first launch macOS may block the app with the message *"FileAtlas cannot be opened because it is from an unidentified developer."*

**To open the app anyway:**

1. Right-click (or Control-click) `FileAtlas.app`
2. Select **Open**
3. Click **Open** in the dialog that appears

macOS remembers your choice — this step is only required once.

## License

FileAtlas is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full license text.
