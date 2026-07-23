# FileAtlas Next Steps

**Last reviewed:** 2026-07-23

This is the current handoff list, not a product wishlist. Update it after
significant implementation or workflow changes.

## Priority 0: Preserve Current Work

- The working tree contains uncommitted application and manual changes. Before
  any future commit, release, or reset, inspect the diff and decide their scope
  explicitly. Do not discard them as cleanup.

## Priority 1: Documentation Process

- Establish and version a reproducible source/generation workflow for the German
  and English PDF manuals. The repository currently contains the final PDFs but
  no versioned generator. Until this is resolved, verify every manual edit by
  rendering the PDFs and checking both languages.

## Priority 2: Verification Gaps

- Expand focused automated coverage only when changing these areas: scan and
  persistence restoration, snapshot retention/diffs, full/selected backup and
  cancellation, backup schedules, exports, and cleanup queue behavior.
- Before relying on `FileAtlasUITests`, run it only after explaining the macOS UI
  automation permission prompt. Its current repeatable execution status is not
  documented here.

## Constraints to Recheck Before Publication

- Confirm the final bundle version, manual version text, README feature summary,
  and privacy scan before any beta or final release.
- Update both manuals and both READMEs whenever visible user behavior changes.
- Review `PORTFOLIO_UPDATE.md` only when a public release, announcement, or
  public project information changes.

## No Confirmed Product Bugs Recorded Here

No unresolved functional defect is documented in the repository at this review.
Do not convert an unverified observation into a known bug; reproduce it first
and record the smallest useful evidence.

