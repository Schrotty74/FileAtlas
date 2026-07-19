# FileAtlas

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![License: GPLv3](https://img.shields.io/badge/License-GPLv3-green) ![Security: Clean](https://img.shields.io/badge/Security-Clean-brightgreen) [![Discord](https://img.shields.io/badge/Discord-Join%20Community-5865F2?logo=discord&logoColor=white)](https://discord.gg/RbsvqRCPQ)

<p align="center">
  <img src="FileAtlas/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="150" alt="FileAtlas App Icon">
</p>

FileAtlas is a native macOS file indexing and comparison app built with pure Apple frameworks. It helps scan folders, inspect metadata, detect duplicates, compare snapshots, export reports, and manage backups without external dependencies.

> **Security:** No private data, API keys, or certificates have been published in this repository. FileAtlas stores scan data locally. If update checks are enabled, the app only contacts GitHub Releases to look for a newer version. See [SECURITY.md](SECURITY.md) for the full audit.


[🇩🇪 Deutsche Beschreibung](README.de.md)

## Manual

Read the complete English usage guide: [FileAtlas Manual (PDF)](output/pdf/FileAtlas-Manual-EN.pdf).
Die deutsche Ausgabe findest du hier: [FileAtlas Handbuch (PDF)](output/pdf/FileAtlas-Handbuch.pdf).

## First-Launch Help

When FileAtlas has no saved locations or indexed entries yet, a start screen offers a local folder picker, the manual, and optional help from ChatGPT, Google Gemini, or Claude. Selecting a service copies a general, privacy-safe question with the public manual link to the clipboard and then opens that service; FileAtlas never sends local file data or other user data automatically. See [AI help and privacy notes](AI_HELP.md).

## Features

- Local file indexing with recursive folder scan and live progress (AsyncStream)
- Scan multiple folders simultaneously
- Security-Scoped Bookmarks (access persists after app restart)
- Liquid Glass sidebar (desktop shines through)
- Light / Dark / System appearance switcher (independent of macOS setting)
- Purposeful interface motion: live scan results with loading placeholders, animated navigation and filter chips, backup completion feedback, analysis and comparison transitions; includes a Reduce Motion setting that also follows macOS accessibility
- DE/EN localization with DACH rule (de_AT, de_DE, de_CH always German)
- Sortable, reorderable columns (Name, Type, Status, Tags, Size, Modified)
- Adjustable row height (Compact / Normal / Large)
- QuickLook preview (Space bar) with inline file preview in detail panel
- Compact list view mode, switchable with table view
- Quick search by name, extension, size (`> 10 MB`, `< 500 KB`)
- Saveable filter sets with include/exclude lists
- Ignored folders (skipped during scan, shown as single entry with total size)
- Bundle recognition (`.app`, `.framework`, `.xcodeproj` treated as single entries, descendants skipped)
- Extension whitelist filter (only index specific file types)
- No auto-rescan if folder is already indexed
- Duplicate detection (size grouping -> SHA-256 hash, gold badge)
- Snapshots after each scan (max. 10, JSON) with diff comparison and delete
- Automatic "what changed?" summary after each follow-up scan
- Storage analysis for largest indexed items, file types and duplicates
- Safe cleanup queue: review items first, then move them to the macOS Trash with confirmation
- Rules for file type, minimum size and file age, with scan-time match notifications
- Smart Collections: saved dynamic views for file type, size, recent changes and duplicates
- Folder comparison (two folders directly)
- Tags (predefined + custom, color-coded pills, extension-based and applied globally across all folders)
- Subfolder expansion in sidebar (multi-level, lazy-loaded without UI freeze)
- Quick access (last 5 scanned folders in sidebar, manually managed)
- Export: Excel (`.xlsx`), PDF, CSV
- Backup: Index backup (JSON), full backup, or selected files and folders (ZIP, optional AES-256, password in Keychain)
- Backup schedule: Off / Daily / Weekly per location
- Settings panel with sidebar navigation (macOS System Settings style)
- Info & Contact section in Settings
- Clear cache option in Settings
- Real system icons for files, apps and folders, with a toggle for fast generic icons in Settings
- App bundle metadata (name, version, developer, bundle ID) shown in detail panel
- Auto-scan on launch option in Settings
- Update check notification via published GitHub Releases, including betas
- Privacy-safe first-launch AI help with local ChatGPT, Gemini and Claude logos
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

1. Double-click `FileAtlas.app` — macOS will block it and show a warning
2. Click **Done**
3. Open **System Settings → Privacy & Security**
4. Scroll down and click **Open Anyway** next to FileAtlas
5. Confirm by clicking **Open** in the final dialog

macOS remembers your choice — this step is only required once.

> If macOS shows **"FileAtlas.app is damaged"** instead of the security warning, open Terminal and run:
> ```bash
> xattr -cr FileAtlas.app
> ```
> Then try opening the app again.

## Community

Questions, feedback and discussions are welcome on [Discord](https://discord.gg/RbsvqRCPQ).

## License

FileAtlas is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full license text.
