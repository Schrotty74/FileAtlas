# FileAtlas Project Context

**Status date:** 2026-09-02

The general work, Git, publication, and repository-privacy rules are defined in `AGENTS.md`. This file contains the project-specific technical and product context.

Update this file and `NEXT_STEPS.md` when a significant behavior, persistence format, workflow, or known limitation changes.

## Purpose

FileAtlas is a native macOS application for local file indexing, comparison, organization, backup, and export. It uses Swift 6 and Apple frameworks only. The app is sandboxed and intentionally keeps catalog data on the Mac. Its only automatic network activity is the optional GitHub Releases update check; an optional AI-help action opens a selected website only after a user click.

## Architecture

- `FileAtlas/FileAtlasApp.swift`: app entry point, shared observable state, commands, Settings scene, launch tasks, window lifecycle, and the separate, resizable Storage Analysis window.
- `FileAtlas/ContentView.swift`: root view; chooses the normal three-column workspace or first-launch help and hosts sheets and progress banners.
- `FileAtlas/Engine/`: scanner, duplicate detector, snapshots, ZIP backup writer, and backup engine.
- `FileAtlas/ViewModels/`: application behavior and persistence coordination. `IndexViewModel` owns scanning, filters, snapshots, exports, tags, rules, smart collections, saved locations, and update checks. `BackupManager` coordinates manual and scheduled backups.
- `FileAtlas/Models/`: Codable domain models including `FileEntry`, `Snapshot`, `FilterPreset`, `SmartCollection`, `AlertRule`, and `BackupConfig`.
- `FileAtlas/Views/`: UI grouped by sidebar, file list, detail, backup, filters, insights, snapshots, settings, and toolbar.
- `FileAtlas/Theme/Theme.swift`: appearance tokens and selectable color themes.
- `FileAtlas/Export/`: dependency-free CSV, PDF, and XLSX generation.
- `FileAtlas/Security/KeychainStore.swift`: encrypted-backup password storage.
- `FileAtlas/Resources/`: localization catalog and local AI-service logos.
- `FileAtlasTests/` and `FileAtlasUITests/`: unit and UI test targets.
- `FileAtlas/FileIndexer_Designs/`: old, isolated design explorations. They are not the production UI and must not be treated as shared application code.

## Persistent Data and Formats

- Selected scan locations use security-scoped bookmarks. Preferences such as appearance, language, tags, presets, and view choices use `UserDefaults`. Dev, Beta, and Final use separate bundle identifiers, so their preferences and bookmarks never overlap.
- Snapshots are JSON and retain at most ten entries.
- Presets, alert rules, smart collections, and backup configurations are local JSON files in the app's Application Support area. Dev uses `FileAtlas-dev`, Beta uses `FileAtlas-beta`, and Final uses `FileAtlas`; snapshots, index caches, and encrypted-backup Keychain entries are isolated by the same channel.
- Index backups are JSON metadata exports. Full backups are ZIP archives of one or more selected files/folders; compression and a SHA-256 manifest are optional. Encrypted backup passwords belong in Keychain, never in JSON.
- Exports are CSV, PDF, and XLSX. CSV uses UTF-8 with BOM and semicolon separation; XLSX is generated without an external library.

These formats can contain file names and paths. They are user data: never use real examples, generated exports, backups, snapshots, or manifests in public project material. The repository-wide handling rules are in `AGENTS.md`.

## Implemented Behavior

- Recursive local scans of multiple folders, live progress, ignored folders, bundle recognition, folder expansion, filters, tags, smart collections, cleanup queue, rules, snapshots, folder comparison, storage analysis, and duplicate detection. Recognized bundles and archives are indexed as one entry without inspecting their contents; the scanner skips descendants only for directory bundles, never after a regular archive file. Format filters and smart collections match their final filename extension (for example `.app`, `.dmg`, `.pkg`, `.zip`, or `.iso`). A filterset is activated and cleared explicitly, and changing locations never reactivates a cleared filter. An active filter remains visibly selected across locations but applies only within its configured scope. It can optionally be restored after an app restart. Location rows show filtered matches as a count out of the complete indexed total and name the active filter. The cached-folder launch mode loads the most recent matching snapshot immediately instead of automatically rescanning it.
- Backups support index-only, full ZIP, incremental ZIP, and selected items; optional encryption, compression, SHA-256 manifests with archive-content verification, archive inspection, selected-entry restore, cancellation, daily/weekly schedules, per-location history, and retention. A schedule is evaluated while the app runs or starts; it is not a background daemon.
- Storage analysis is a separate movable and resizable macOS window. It includes a responsive file-type grid, health indicators, and an entry point to similar image analysis. Similar-image analysis uses Apple's local Vision feature prints on a bounded candidate set; it never uploads images.
- Rules can add matching items to the reviewable cleanup queue. Smart collections additionally support maximum size, tags, saved locations, and excluded file types. Saved locations display an unavailable state when they cannot be reached.
- Batch rename provides a previewable prefix/suffix rule with optional sequential numbering. It refuses invalid or colliding targets, requires confirmation, and rescans after a successful rename.
- English/German localization with the DACH German rule, independent light/dark/system appearance, six color themes, optional tooltips, and Reduce Motion.
- The Glass theme is one full-window AppKit visual-effect background with shared translucent foreground surfaces. Do not add a separate material or glow layer to the sidebar while this theme is active.
- First-launch help is visible only without saved locations, recents, or indexed entries. AI-service buttons copy a fixed, data-minimal prompt and open the chosen website; they never transmit local data automatically. Update checks can be enabled for app launch and configured for Final-only or Beta-and-Final GitHub Releases; an available update is announced in the app and opens its GitHub Release only after a click.

## Build, Test, and Release

- Open `FileAtlas.xcodeproj` in Xcode. The production target is `FileAtlas`; deployment target is macOS 26.5 and Swift version is 6.0.
- There are no Swift Package Manager, CocoaPods, Carthage, or other external package dependencies in this repository.
- User-facing local build artifacts use a stable project-relative layout: the current Dev app is `Build/dev/FileAtlas.app`; Beta and Final artifacts are retained separately in `Build/beta/<version>/` and `Build/final/<version>/`. `build-release.sh` derives the versioned directory from the release version and can use `FILEATLAS_ARTIFACTS_ROOT` when a release worktree must place artifacts in another stable project directory. Do not use a temporary release worktree as the user-facing artifact location. Temporary Xcode derived data belongs in ignored `.build/`. `build-development.sh` creates the Dev build.
- Unit tests are in the `FileAtlas` scheme and run in GitHub CI. Existing source coverage includes index-backup output, archive-manifest verification, batch rename safety, duplicate marking, first-launch prompt URLs/privacy, and appearance/motion/tooltip preference persistence. A test result is only current when the tests were actually run for the relevant state.
- `FileAtlasUITests` is separate. It uses macOS UI automation and can request user permission or a password; this must be considered before running it.
- `build-release.sh` builds, checks for private paths, signs ad hoc, creates DMG/ZIP, and creates a GitHub release. It is a publication action and is governed by `AGENTS.md`.
- GitHub CI performs an unsigned Debug build on push/PR. The release workflow is manual; the local release script is the documented primary release path.
- Bash scripts require a compatible current Bash environment. A specific local installation path is not a project requirement unless a script explicitly depends on it.

## Documentation and Release Rules

- Public README files are bilingual. Update both when public behavior changes.
- README files provide a concise feature selection and link to the grouped `FEATURES.md` / `FEATURES.de.md` reference pages. Keep those reference pages aligned with stable implemented behavior.
- Keep both PDF manuals in `output/pdf/` aligned with visible behavior. A versioned PDF-source generator is currently not present in this repository; determine a reproducible generation method before a substantial manual rewrite.
- Do not repeat a release title in the release-note body. The release script removes a leading duplicate title.
- Write GitHub release notes and changelogs in English.
- Beta release notes are generated directly by GitHub from the changelog; do not create repository-local `release-notes-*.md` files. A Final release note is generated from every published Beta release with the same version. Do not omit an earlier Beta when preparing a Final.
- Public documentation must follow the repository-wide privacy and naming rules from `AGENTS.md`.

## Known Constraints and Current State

- The app's base Xcode marketing version is `1.0`; the release build supplies the requested marketing version. `CFBundleVersion` comes from the project's `CURRENT_PROJECT_VERSION` (currently `1`). Confirm both bundle version fields before publishing.
- The UI test target exists, but a current repeatable UI-test result is not recorded in repository documentation. Treat it as unverified until run with user-approved UI automation.
- The PDF manuals are tracked artifacts, but their original generator is not tracked here. Do not assume an external generator or regenerate blindly.
- No confirmed unresolved product defect is documented as of this status date.
