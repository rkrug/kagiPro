# Generic R Package Developer Checklist

## Pre-Implementation

1. Classify change scope: API, behavior, docs, tests, release metadata, or governance.
2. Identify impacted public interfaces and compatibility risk.
3. Decide whether change is additive, behavioral, or breaking.

## Implementation

1. Keep behavior changes explicit in code and tests.
2. Preserve existing interfaces unless breaking change is intentional.
3. Keep naming consistent across code, docs, and examples.

## Documentation Sync

1. Update `README.md` for user-facing behavior changes.
2. Update changelog (`NEWS.md` and any additional release notes files).
3. Update design/architecture docs when architecture or conventions change.
4. Update relevant vignettes.
5. Regenerate reference docs (`devtools::document()`) when roxygen/signatures/imports change.

## AI Docs Sync

1. Verify user-doc readability is preserved (no machine-oriented schema/contract
   dumps in narrative-first sections).
2. Verify machine-oriented artifacts are updated when API/contracts/output
   schema/folder contracts changed.
3. Verify links/index references to machine artifacts are valid.
4. Verify dedicated machine pages exist and are indexed (for example: API
   contracts page and quick function index page).
5. If skills are exposed in pkgdown, verify wrapper vignettes use includes from
   `inst/skills/*/SKILL.md` and `inst/skills/*/references/*.md` (single source,
   no copied skill/reference text).
6. Verify one-wrapper-per-skill convention:
   - each skill has one `vignettes/skills-<skill>.qmd`,
   - references are embedded in that wrapper,
   - no orphan `skills-*-ref-*.qmd` files remain unless explicitly intended.
7. Verify `_pkgdown.yml` keeps a compact skills menu (one entry per skill) and
   that all skill wrappers are listed under articles.
8. If skill wrapper pages are pkgdown-only (not package vignettes), ensure they
   are excluded via `.Rbuildignore` (for example `^vignettes/skills-.*\\.qmd$`)
   to avoid vignette-engine check notes.

## Validation

1. Run targeted tests for touched modules.
2. Run package checks appropriate to change risk.
3. Ensure baseline CI check workflow is present:
   - initialize/refresh with `usethis::use_github_action("check-standard")`.
4. Run a local package check with `devtools::check()` and record outcome.
   Use `R CMD check` only when explicitly needed for tarball-level parity.
5. Confirm no stale references to removed/renamed APIs in docs/tests.
6. Confirm touched R files conform to `air` formatting rules.
7. Pre-commit AI gate:
   - if code changed, AI-readable artifacts were checked and updated where
     needed.
8. Reproducibility gate:
   - record exact validation commands and outcomes in commit/PR notes.
9. Run AI-doc consistency checks (script or equivalent CI gate) and confirm pass.
10. Run `pkgdown::build_site()` and confirm skills pages render without article
   index or navbar errors.

## Release/Merge

1. Ensure branch policy and branch protections are respected.
2. If solo-maintainer bypass is configured, confirm it is scoped to PR merges
   only and does not allow direct pushes to `main`.
3. Ensure detailed commit message is used.
4. Ensure PR description reflects behavior, docs, tests, and breaking changes.
5. Generated-artifact gate:
   - commit `NAMESPACE` and `man/*.Rd` when regenerated,
   - do not commit build artifacts (for example `_site/`, check/temp outputs).
