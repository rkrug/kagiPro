# Release Checklist

## Version and Metadata

1. Update `DESCRIPTION` version.
2. Verify package metadata and URLs are current.

## Changelog and Design Docs

1. Update `NES.md` (features, fixes, breaking changes, docs).
2. Update `PROJECT_DESIGN.md` when architecture or conventions changed.

## Documentation Sync

1. Sync README examples with current function names.
2. Sync quickstart and endpoint vignettes with runtime behavior.
3. Regenerate man docs if roxygen comments changed.

## Test and Validation Gate

1. Run targeted tests for changed modules.
2. Validate cassette integrity if HTTP behavior changed.
3. Confirm no stale references remain (legacy names, old fixture paths).

## Pre-Commit Quality Gate

- No contradictory behavior across code, tests, and docs.
- No unreviewed placeholder text in new docs.
- All new skills/reference files are discoverable from `inst/skills/README.md`.
- Branch policy is respected:
  - keep `main` and `dev` as long-lived branches,
  - never delete `dev` after PR merge.
