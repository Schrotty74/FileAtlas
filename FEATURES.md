# FileAtlas – Feature overview

**[Deutsch](FEATURES.de.md)**

This page lists the stable features in detail. For installation and everyday use, see the [English user manual (PDF)](output/pdf/FileAtlas-Manual-EN.pdf) or [German user manual (PDF)](output/pdf/FileAtlas-Handbuch.pdf).

## Indexing and navigation

- Recursively indexes multiple selected folders with live scan progress.
- Keeps access to selected folders across app restarts with security-scoped bookmarks.
- Supports sortable and reorderable Name, Type, Status, Tags, Size, and Modified columns, plus Compact, Normal, and Large row heights.
- Offers a compact list view and a table view, QuickLook with the Space bar, and an inline detail preview.
- Searches names, extensions, and sizes, including queries such as `> 10 MB` and `< 500 KB`.
- Saves include/exclude filter sets, supports ignored folders, bundle recognition, extension whitelists, and subfolder expansion without blocking the interface.
- Provides manually managed quick access to the five most recently scanned folders.

## Analysis and comparison

- Detects duplicates through size grouping and SHA-256 content hashing. Comparisons stay within each saved location by default; cross-location comparison is optional.
- Stores up to ten JSON snapshots per location, compares them with the current scan, and summarizes what changed after a subsequent scan.
- Compares two folders directly.
- Opens a separate, resizable Storage Analysis window with a file-type map, the largest indexed items, duplicate space, and health indicators for unavailable locations, missing backup destinations, and due backups.
- Groups visually similar local images with Apple's on-device Vision feature prints on a bounded set of up to 250 images. Images are never uploaded.

## Organization and automation

- Adds predefined or custom color-coded tags, including extension-based tagging across all saved locations.
- Provides Smart Collections for file type, size, recent changes, duplicates, maximum size, tags, locations, and excluded file types.
- Provides rules for file type, minimum size, and file age, with scan-time notifications and an optional addition to the cleanup queue.
- Uses a reviewable cleanup queue; selected items move to the macOS Trash only after confirmation.
- Renames batches safely with a preview, prefix, suffix, optional sequential numbering, collision checks, and explicit confirmation.
- Shows unavailable saved locations when a drive or folder cannot currently be reached.

## Backups and restore

- Creates index backups as JSON metadata exports, full ZIP backups, incremental ZIP backups after an initial full backup, or ZIP backups of selected files and folders.
- Supports optional ZIP compression, AES-256 encryption with passwords stored in Keychain, and optional SHA-256 manifests.
- Inspects archive contents, validates ZIP structure and optional SHA-256 manifest contents, and restores selected archived entries.
- Schedules backups per location as Off, Daily, or Weekly. Due backups run only while FileAtlas is open or when it starts; the app is not a background daemon.
- Keeps per-location backup history and can retain the last 3, 5, or 10 FileAtlas archives, or keep all archives.

## Export, interface, and preferences

- Exports scan data as Excel (`.xlsx`), PDF, or CSV. CSV uses UTF-8 with BOM and semicolon separation; XLSX is generated without an external library.
- Shows app bundle metadata including name, version, developer, and bundle identifier in the detail panel.
- Offers independent Light, Dark, and System appearance modes, plus Midnight Teal, Retro, Graphite Lime, Autumn, Winter, and Glass themes.
- The Glass theme uses a full-window translucent AppKit background; the sidebar does not add a separate material layer.
- Provides optional tooltips, a Reduce Motion preference that respects macOS accessibility settings, and an optional scan on app launch.
- Starts in English and offers German with the DACH language rule for `de_AT`, `de_DE`, and `de_CH`.
- Includes a Settings window with sidebar navigation, appearance controls, cache clearing, generic-icon fallback, and an Info & Contact section.

## Privacy and safety

- Uses Apple frameworks only and has no third-party dependencies.
- Stores scan data and preferences locally on the Mac.
- Optional startup update checks can be enabled for Final-only or Beta-and-Final GitHub Releases; a visible in-app notice opens an available release only after a click.
- When a filter set is active, location rows show matching files out of the complete indexed total and identify the applied filter.
- Restore last cached folders immediately shows the most recently saved local index on launch without an automatic rescan. Filter Sets can optionally restore the last active set after relaunch.
- Shows first-launch help only when no saved locations, recents, or indexed entries exist. Its AI-help buttons copy a fixed, data-minimal prompt with a public manual link and open the selected service only after a click; local file data is never sent automatically.
- Does not publish or require private data, API keys, certificates, accounts, analytics, or cloud sync.
