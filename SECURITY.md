# Security

## Security Audit

FileAtlas has been audited for exposed private data. The audit covers all commits, source files, configuration files, and git history.

| Check | Result |
|---|---|
| Hardcoded passwords / secrets | ✅ None found |
| API keys (AWS, GitHub, Google, OpenAI, etc.) | ✅ None found |
| Private keys / certificates | ✅ None found |
| Real email addresses in source code | ✅ None — only anonymous relay addresses |
| Apple Developer Team ID | ✅ Empty — not committed |
| Hardcoded file system paths | ✅ None found |
| Sensitive files in git history | ✅ Never committed |

**Result: No private data has been published. The repository is clean.**

## App Safety

FileAtlas is built exclusively with Apple frameworks and requires no external dependencies. User data stays local on your Mac: snapshots, backups, filter presets, scan results, bookmarks and tags are stored locally.

The only intended network access is the optional GitHub Releases update check, which contacts GitHub to determine whether a newer FileAtlas release is available. FileAtlas does not upload scanned file metadata or private user data.

Passwords for encrypted backups are stored in the macOS Keychain — never in plain text.

## Reporting a Vulnerability

If you discover a security issue, please open an issue in this repository.
