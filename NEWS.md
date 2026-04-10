# kagiPro 0.4.1

## Documentation

- Externalized the generic `r-package-developer` skill from package content to
  repository-level `skills/r-package-developer`.
- Updated skill discovery guidance to clearly distinguish package-bundled skills
  (`inst/skills`) from the external generic developer skill.
- Added explicit policy text: if the external skill is missing, suggest
  installation, but only install with explicit developer approval and never
  automatically.
- Removed the pkgdown wrapper page for the external developer skill and updated
  pkgdown article/menu configuration accordingly.

# kagiPro 0.4.0

## Features

- Added `kagi_fetch()` as a high-level project-folder workflow helper with
  endpoint-scoped outputs (`<project>/<endpoint>/json` and
  `<project>/<endpoint>/parquet`).
- Added endpoint-specific query support for FastGPT via `query_fastgpt()`.
- Added modular corpus enrichment pipeline for search-like corpora:
  - `download_content()`
  - `content_markdown()`
  - `markdown_abstract()`
  with endpoint/query partitioned output under
  `<project>/<endpoint>/{content,markdown,abstract}`.
- Added pluggable text summarization backends:
  - `summarize_with_openai()`
  - `summarize_with_kagi()` (text-based summarizer usage).
- Added `read_corpus()` with optional abstract linking (`abstracts = TRUE`) by
  `id + query`.
- Standardized query constructor outputs to named lists across endpoints.
- Extended `kagi_request()` with `error_mode` (`"stop"`, `"write_dummy"`) for strict vs resilient execution modes.
- Improved handling of mixed query lists so long batch runs can continue with structured dummy outputs on failure.
- Kept JSON-to-parquet as a first-class path via `kagi_request_parquet()` for downstream analytics.
- Added low-level `00_in.progress` marker lifecycle to request/parquet runs for
  folder-state visibility during long jobs.
- Added metadata persistence in `kagi_request()` for replayable query runs:
  - per-query `_query_meta.json`
- Added `kagi_update_query()` to rerun by `query_name` across matching
  endpoints and refresh only touched parquet `query=<name>` partitions.
- Added `clean_request()` to remove JSON request artifacts project-wide while
  preserving `_query_meta.json` per query (with `dry_run` space estimates).
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

- Renamed query constructors to `query_<endpoint>` for discoverability:
  - `search_query()` -> `query_search()`
  - `enrich_web_query()` -> `query_enrich_web()`
  - `enrich_news_query()` -> `query_enrich_news()`
  - `summarize_query()` -> `query_summarize()`
  - `fastgpt_query()` -> `query_fastgpt()`
- Removed `add_sbstract_to_parquet()`. Abstract creation is now handled only
  via the modular content pipeline (`download_content()` ->
  `content_markdown()` -> `markdown_abstract()`).
- `kagi_request_parquet()` is JSON-to-parquet conversion only and no longer
  accepts abstract-augmentation arguments.
- Query constructors consistently return named lists. Code that previously assumed a bare single query object may require `[[1]]` indexing in some direct calls.
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
- Added AI-readable artifact index files (`llms.txt`, `llms-full.txt`) and
  mirrored pkgdown extras.
- Added AI-focused vignettes:
  - `agent-quick-index`
  - `api-contracts`
- Added rendered Skills pages in pkgdown using include-based wrappers
  (`vignettes/skills-*.qmd`) with one page per skill and embedded references.

## Maintenance

- Added CI workflow for package checks on pull requests to `main` and pushes to `dev`.
- Removed unused legacy package assets from `inst/` (`extdata`, `plantuml`, `query_test.R`).
- Added AI-doc consistency check script (`scripts/check-ai-docs.sh`) and wired
  it into CI (`R-CMD-check`).
- Added generic reusable maintainer skill `r-package-developer` with:
  - branch protection baseline,
  - release/validation checklist,
  - commit template,
  - skill design standard.
- Standardized all skill files to a unified structure with a dedicated
  `## References` section.
