# Manual checks

Run from the repository root on macOS with Xcode command line tools:

```sh
swift scripts/check-manuals.swift
swift scripts/check-manuals.swift --self-test
```

The checker uses PDFKit, AppKit and CryptoKit included with macOS. It needs no additional packages. Both GitHub workflows and the local release script run the check before publication.

## What it checks

- Both named German and English PDFs must open, contain pages and have matching page counts.
- Each page must be portrait A4, have a predominantly dark background and contain visible light content.
- Page appearance, page count and extracted font families are compared with `manual-baseline.json`. Existing page changes and added pages require review.
- Exact PDF file hashes allow unchanged documents to pass comparison across macOS renderer versions. Changed PDFs use per-page rendered hashes; rendering differences can require a fresh visual review even when the design looks unchanged.

The original manual pages contain rasterized content. Font extraction cannot identify typography inside images; the appearance comparison detects changes there. Light-content detection is only a blank-page/contrast heuristic. It does not prove that text is correct, readable, unclipped or free of overlaps.

## Reviewing a manual update

1. Inspect the existing cover and representative content pages before editing. Preserve their design unless the user authorizes a design change.
2. Render both updated manuals and compare every changed or added page with the original. Check colors, typography, spacing, clipping, overlaps and content. Keep the original available for comparison.
3. Run the checker. Review every reported page difference, including changes to old pages that were not part of the requested edit.
4. Only after that review, explicitly record the reviewed baseline:

```sh
swift scripts/check-manuals.swift --record-reviewed-baseline
swift scripts/check-manuals.swift
```

Commit the baseline with the reviewed PDFs. Never refresh it just to silence a failure. Recording writes the visual reference but still returns failure for light backgrounds, invalid page sizes, blank-looking pages and mismatched language page counts. These failures are not exempted by recording. CI and release scripts never update the baseline automatically.

## Current findings

The existing PDFs have light update pages at pages 22 and 23 in both languages. These four pages fail the dark-background rule even with the initial visual reference recorded. Correct their layout and review the resulting pages before refreshing the baseline. The check intentionally blocks releases until they pass.

The self-test creates temporary synthetic PDFs and checks acceptance of a dark page and rejection of white pages, blank pages, wrong sizes, changed content, new fonts, missing language versions and unreviewed added pages. It does not modify the manuals or application data.
