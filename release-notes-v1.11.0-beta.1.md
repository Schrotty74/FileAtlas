## Beta Notes

- Fixed archive and bundle discovery so APP, DMG, PKG, ZIP, and ISO entries are found by their final filename extension without indexing package contents.
- Fixed search and scoped Filter Sets so active filters remain selected across locations while applying only where configured.
- Added optional restoration of the active Filter Set after restarting FileAtlas.
- Added cached-index restoration on launch, configurable GitHub update checks for Final-only or Beta-and-Final releases, and a clear release-opening action.
- Improved scan responsiveness by deferring expensive location counts during active scans.
- Fixed Snapshot comparisons that incorrectly reported unchanged files as changed because of timestamp precision.
