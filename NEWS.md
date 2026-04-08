# rkagi 0.3.0

## Features

- Added endpoint-specific query support for FastGPT via `fastgpt_query()`.
- Standardized query constructor outputs to named lists across endpoints.
- Extended `kagi_request()` with `error_mode` (`"stop"`, `"write_dummy"`) for strict vs resilient execution modes.
- Improved handling of mixed query lists so long batch runs can continue with structured dummy outputs on failure.
- Kept JSON-to-parquet as a first-class path via `kagi_request_parquet()` for downstream analytics.
- Added AI-agent skill scaffolding under `inst/skills`:
  - `maintainer-workflow`
  - `user-search`, `user-enrich`, `user-summarize`, `user-fastgpt`

## Bug Fixes

- Fixed inconsistent request handling between single-query and list-query execution paths.
- Fixed recursive/list request execution to propagate request options (including error handling mode) correctly.
- Fixed output path behavior so single-item list requests do not create unexpected nested output directories.
- Removed redundant API key resolution calls in connection flow where applicable.
- Fixed fixture-location inconsistencies in tests by using a single cassette location.

## Breaking Changes

- Query constructors now consistently return named lists. Code that previously assumed a bare single query object may require `[[1]]` indexing in some direct calls.
- Error behavior can now be configured explicitly; strict failure remains default, but resilient mode writes dummy payloads and warnings instead of stopping.

## Documentation

- Updated package docs to align with current function names and design principles.
- Reworked `kagi_request` documentation to remove outdated references and clarify endpoint behavior.
- Expanded vignette set:
  - Quickstart guide
  - Search endpoint guide
  - Enrich endpoint guide
  - Summarize endpoint guide
  - FastGPT endpoint guide
- Shifted vignettes toward user-oriented narrative style while retaining runnable code examples.
- Updated pkgdown article structure for clearer endpoint-based navigation.
- Added project-level design/context documentation for maintainers and AI coding agents (`PROJECT_DESIGN.md`).
- Added README disclaimer and AI-assisted development notice.

## Maintenance

- Added CI workflow for package checks on pull requests to `main` and pushes to `dev`.
- Removed unused legacy package assets from `inst/` (`extdata`, `plantuml`, `query_test.R`).
