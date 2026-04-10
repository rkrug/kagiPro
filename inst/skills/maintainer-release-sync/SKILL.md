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

1. Enforce branch policy:
   - long-lived branches are `main` and `dev`;
   - `dev` must not be deleted after PR merge.
   - do not delete any branch unless deletion is explicitly requested and explicitly confirmed by the user.
2. No stale function names or removed APIs in docs/skills.
3. Examples use current constructor names and workflow order.
4. Breaking changes are explicitly listed in changelog.
5. Skills align 1:1 with vignette terminology for user workflows.
6. Release docs reflect current folder contracts and schema contracts.
7. Before commit/merge, confirm the following are reviewed and updated if needed:
   - `NEWS.md`
   - `PROJECT_DESIGN.md`
   - `README.md`
   - `vignettes/*.qmd`
8. Use a detailed commit message that includes:
   - summary of behavioral changes,
   - documentation and skills updates,
   - test/check validation outcomes.

Read `references/checklist.md` before final release actions.
