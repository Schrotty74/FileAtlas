# New Codex Chat Template

Use this as the first message in a new FileAtlas development chat:

```text
Work only in the FileAtlas project repository.

Before changing anything, read PROJECT_CONTEXT.md and NEXT_STEPS.md completely.
Then read the relevant specialized documentation: AI_HELP.md for first-launch AI
help, SECURITY.md before public-facing work, and PORTFOLIO_UPDATE.md before a
release or announcement.

Inspect the current Git status and the affected source files before proposing or
making edits. Preserve existing local changes; never reset, discard, overwrite,
commit, push, tag, version, build a release, or publish unless I explicitly ask.

Keep all app data local. Never place real paths, folder contents, exports,
backups, snapshots, passwords, tokens, credentials, private test data, or
personal information in source, documentation, Git history, screenshots, or a
release. Use only Schrotty74 as a public name.

For visible behavior changes, update PROJECT_CONTEXT.md and NEXT_STEPS.md. Also
update both public READMEs and both PDF manuals when their user-facing content
is affected. Do not invent completed tests, bugs, data formats, or release facts.

Use the project's existing Apple-framework architecture and narrow changes. UI
tests may trigger a macOS UI-automation permission/password prompt: explain that
before running them and wait for my confirmation. Run Bash scripts with the
Homebrew Bash rather than the legacy system Bash.
```

