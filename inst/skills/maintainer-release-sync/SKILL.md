---
name: maintainer-release-sync
description: Use this skill before release/PR merge to synchronize versioning, changelog, design docs, vignettes, README, and skills with implemented behavior.
---

# Maintainer Release Sync

Use this skill for final consistency checks before release or merge.

## Required Sync Targets

- `DESCRIPTION` version and description text
- `NEWS.md` and `NES.md`
- `PROJECT_DESIGN.md`
- `README.md`
- `vignettes/*.qmd`
- `inst/skills/**`
- `man/*.Rd` and `NAMESPACE` (via `devtools::document()`)

## Required Checks

1. No stale function names or removed APIs in docs/skills.
2. Examples use current constructor names and workflow order.
3. Breaking changes are explicitly listed in changelog.
4. Skills align 1:1 with vignette terminology for user workflows.
5. Release docs reflect current folder contracts and schema contracts.
6. Before commit/merge, confirm the following are reviewed and updated if needed:
   - `NEWS.md`
   - `PROJECT_DESIGN.md`
   - `README.md`
   - `vignettes/*.qmd`
7. Use a detailed commit message that includes:
   - summary of behavioral changes,
   - documentation and skills updates,
   - test/check validation outcomes.

Read `references/checklist.md` before final release actions.
