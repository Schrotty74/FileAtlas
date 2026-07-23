# FileAtlas Project Context

**Status date:** 2026-07-23
**Audience:** new development chats and maintainers. Read this file before changing code.

## Read Order

1. Read this file and [NEXT_STEPS.md](NEXT_STEPS.md).
2. Read [AI_HELP.md](AI_HELP.md) before changing first-launch AI help or its assets.
3. Read [SECURITY.md](SECURITY.md) before a public build or publication.
4. Read [PORTFOLIO_UPDATE.md](PORTFOLIO_UPDATE.md) before public announcements or releases.
5. Use [README.md](README.md), [README.de.md](README.de.md), and the PDFs in `output/pdf/` for public-facing documentation.

Update this file and `NEXT_STEPS.md` when a significant behavior, persistence format,
workflow, or known limitation changes.

## Purpose

FileAtlas is a native macOS application for local file indexing, comparison,
organization, backup, and export. It uses Swift 6 and Apple frameworks only.
The app is sandboxed and intentionally keeps catalog data on the Mac. Its only
automatic network activity is the optional GitHub Releases update check; an
optional AI-help action opens a selected website only after a user click.

## Architecture

- `FileAtlas/FileAtlasApp.swift`: app entry point, shared observable state,
  commands, Settings scene, launch tasks, and window lifecycle.
- `FileAtlas/ContentView.swift`: root view; chooses the normal three-column
  workspace or first-launch help and hosts sheets and progress banners.
- `FileAtlas/Engine/`: scanner, duplicate detector, snapshots, ZIP backup
  writer, and backup engine.
- `FileAtlas/ViewModels/`: application behavior and persistence coordination.
  `IndexViewModel` owns scanning, filters, snapshots, exports, tags, rules,
  smart collections, saved locations, and update checks. `BackupManager`
  coordinates manual and scheduled backups.
- `FileAtlas/Models/`: Codable domain models including `FileEntry`, `Snapshot`,
  `FilterPreset`, `SmartCollection`, `AlertRule`, and `BackupConfig`.
- `FileAtlas/Views/`: UI grouped by sidebar, file list, detail, backup,
  filters, insights, snapshots, settings, and toolbar.
- `FileAtlas/Theme/Theme.swift`: appearance tokens and selectable color themes.
- `FileAtlas/Export/`: dependency-free CSV, PDF, and XLSX generation.
- `FileAtlas/Security/KeychainStore.swift`: encrypted-backup password storage.
- `FileAtlas/Resources/`: localization catalog and local AI-service logos.
- `FileAtlasTests/` and `FileAtlasUITests/`: unit and UI test targets.
- `FileAtlas/FileIndexer_Designs/`: old, isolated design explorations. They
  are not the production UI and must not be treated as shared application code.

## Persistent Data and Formats

- Selected scan locations use security-scoped bookmarks. Preferences such as
  appearance, language, tags, presets, and view choices use `UserDefaults`.
- Snapshots are JSON and retain at most ten entries.
- Presets, alert rules, smart collections, and backup configurations are local
  JSON files in the app's Application Support area.
- Index backups are JSON metadata exports. Full backups are ZIP archives of one
  or more selected files/folders; compression and a SHA-256 manifest are
  optional. Encrypted backup passwords belong in Keychain, never in JSON.
- Exports are CSV, PDF, and XLSX. CSV uses UTF-8 with BOM and semicolon
  separation; XLSX is generated without an external library.

These formats can contain file names and paths. They are user data: never add
real examples, generated exports, backups, snapshots, or manifests to Git or
public documentation.

## Implemented Behavior

- Recursive local scans of multiple folders, live progress, ignored folders,
  bundle recognition, folder expansion, filters, tags, smart collections,
  cleanup queue, rules, snapshots, folder comparison, storage analysis, and
  duplicate detection.
- Backups support index-only, full ZIP, and selected items; optional encryption,
  compression, hash manifests, cancellation, and daily/weekly schedules. A
  schedule is evaluated while the app runs or starts; it is not a background
  daemon.
- English/German localization with the DACH German rule, independent light/dark/
  system appearance, six color themes, optional tooltips, and Reduce Motion.
- The Glass theme is one full-window AppKit visual-effect background with shared
  translucent foreground surfaces. Do not add a separate material or glow layer
  to the sidebar while this theme is active.
- First-launch help is visible only without saved locations, recents, or indexed
  entries. AI-service buttons copy a fixed, data-minimal prompt and open the
  chosen website; they never transmit local data automatically.

## Build, Test, and Release

- Open `FileAtlas.xcodeproj` in Xcode. The production target is `FileAtlas`;
  deployment target is macOS 26.5 and Swift version is 6.0.
- There are no Swift Package Manager, CocoaPods, Carthage, or other external
  package dependencies in this repository.
- A regular unsigned local build can use the `FileAtlas` scheme with code
  signing disabled and a disposable derived-data directory.
- Unit tests are in the `FileAtlas` scheme. Existing source coverage includes
  index-backup output, duplicate marking, first-launch prompt URLs/privacy, and
  appearance/motion/tooltip preference persistence. Do not claim tests passed
  unless they were run in the current task.
- `FileAtlasUITests` is separate. It uses macOS UI automation and can request
  user permission or a password. Explain this and obtain confirmation before
  running it.
- `build-release.sh` builds, checks for private paths, signs ad hoc, creates
  DMG/ZIP, and creates a GitHub release. It is a publication action: run it only
  after an explicit request. On this development setup, invoke Bash scripts with
  the Homebrew Bash, not the legacy system Bash.
- GitHub CI performs an unsigned Debug build on push/PR. The release workflow is
  manual; the local release script is the documented primary release path.

## Documentation and Release Rules

- Public README files are bilingual. Update both when public behavior changes.
- Keep both PDF manuals in `output/pdf/` aligned with visible behavior. A
  versioned PDF-source generator is currently not present in this repository;
  determine a reproducible generation method before a substantial manual rewrite.
- Do not repeat a release title in the release-note body. The release script
  removes a leading duplicate title.
- Do not create a version, tag, commit, push, release, or portfolio update unless
  the user explicitly requests it.
- Use only `Schrotty74` as a public name. Do not document personal names, local
  paths, credentials, tokens, private test data, backups, exports, or license
  material.

## Known Constraints and Current State

- The app's base Xcode marketing version is `1.0`; the release script supplies
  the requested release version during a release build. Confirm version behavior
  before changing versioning or publishing.
- The UI test target exists, but a current repeatable UI-test result is not
  recorded in repository documentation. Treat it as unverified until run with
  user-approved UI automation.
- The PDF manuals are tracked artifacts, but their original generator is not
  tracked here. Do not assume an external generator or regenerate blindly.
- At the start of this documentation update, the working tree had intentional
  uncommitted changes in `FileAtlas/FileAtlasApp.swift` and both manual PDFs.
  Preserve them; do not reset or discard them without explicit instruction.
