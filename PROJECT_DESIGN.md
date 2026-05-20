# kagiPro Design Philosophy and Project Context (for AI Coding Agents)

## Purpose

`kagiPro` is an R-first client for Kagi APIs designed for reproducible data workflows.

The package is optimized for users who want to:

- Build structured API requests from R scripts.
- Run single and batch requests in a uniform way.
- Persist raw API responses as JSON for traceability.
- Convert JSON outputs to parquet for analytics pipelines.

This document is intended for AI assistants (for example Codex, Claude Code, and similar tools) so changes stay aligned with project intent.

## Core Design Principles

1. Query-first architecture.
   Users should construct explicit query objects first, then execute them. Query construction and execution are separate concerns.

2. Endpoint-specific constructors, shared execution engine.
   Constructors encode endpoint semantics; `kagi_request()` executes all supported query objects.

3. Reproducibility over implicit behavior.
   Requests write JSON files to disk. File-based outputs are treated as source-of-truth artifacts.
   Query replay metadata is persisted per query (`_query_meta.json`) to support
   deterministic re-runs.

4. Predictable scaling from single to batch.
   Constructors return named lists consistently so one-query and many-query workflows use the same calling pattern.

5. Pragmatic fault tolerance.
   `error_mode = "stop"` for strict runs; `error_mode = "write_dummy"` for long pipelines where partial completion is preferred.

6. Analysis handoff as a first-class workflow.
   `kagi_request_parquet()` converts JSON collections to parquet for downstream processing.
7. Modular enrichment pipeline.
   Content download, markdown extraction, and abstract generation are separate
   steps (`download_content()` -> `content_markdown()` -> `markdown_abstract()`).

## Public Workflow Contract

Expected user flow:

1. Create a connection with `kagi_connection()`.
2. Build query objects using endpoint-specific constructors.
3. Preferred: execute with `kagi_fetch()` into endpoint-scoped project folders.
4. Low-level alternative: `kagi_request()` + `kagi_request_parquet()`.

This contract should remain stable across releases.

## Endpoint Coverage and Query Constructors

Current endpoint constructors (Kagi v1 API):

- `kagi_query_search()` — search with workflows
- `kagi_query_extract()` — URL → markdown
- `kagi_fetch()` (high-level orchestrator)

All constructors should:

- Return named lists.
- Preserve endpoint-specific parameters without hidden coercion.
- Be accepted directly by `kagi_request()`.

## Error Handling Model

`kagi_request()` supports two modes:

- `error_mode = "stop"`:
  Fail fast and raise an error.
- `error_mode = "write_dummy"`:
  Emit a warning and write a structured dummy JSON payload.

Dummy payload requirements:

- Include metadata about the failed request.
- Keep endpoint shape as compatible as possible.
- Use empty/`null` data fields for missing payloads.
- Remain convertible by `kagi_request_parquet()`.

## JSON and Parquet Philosophy

JSON files are audit artifacts. Parquet is a derivative format for analysis.

Design implications:

- Never require parquet conversion for core package usage.
- Prefer non-lossy conversion where possible.
- Handle partial failures and dummy payloads without breaking conversion.
- Keep query partitions (`query=<name>`) independently refreshable.

## Testing Philosophy

Testing is cassette-driven with `vcr` to ensure deterministic API behavior in CI and local re-runs.

Priorities:

- Cover all exported constructors and request paths.
- Include failure-path tests, especially dummy-write mode.
- Validate parquet conversion on mixed success/error outputs.
- Keep fixture layout consistent (`tests/testthat/fixtures/cassettes`).

## Documentation Philosophy

Documentation must be user-oriented and narrative, not just code snippets.

Required doc layers:

- README for onboarding and package overview.
- Quickstart vignette for first end-to-end run.
- Endpoint vignettes for deep usage patterns.
- Changelog-style document for release deltas.

Narrative guidelines:

- Explain why and when before showing code.
- Keep examples realistic and pipeline-oriented.
- Include error-handling and production guidance.

## Skills Layer

Agent-oriented operational guidance is packaged in `inst/skills`.

- `maintainer-workflow` covers implementation conventions, tests/cassettes, naming, and release hygiene.
- `maintainer-corpus-pipeline` covers content/markdown/abstract internals and
  corpus-link contracts.
- `maintainer-release-sync` covers pre-release consistency checks across code,
  docs, vignettes, skills, and changelog.
- `r-package-developer` provides a generic, reusable R-package governance
  baseline (workflow, branch policy, validation, commit standard, and skill
  design rules).
- `user-search` mirrors the Search/Extract workflows aligned with
  `vignettes/quickstart.qmd` and `vignettes/v1-api-and-corpus.qmd`.
- `user-corpus-workflow` mirrors the end-to-end corpus vignette
  (`vignettes/corpus-workflow.qmd`).

Skills are intended to be strict execution guidance for coding agents and must remain aligned with package behavior and vignette examples.

## Skill Mapping

Preferred skill by workflow phase:

1. Endpoint query construction and request execution:
   use `user-search` (covers both `kagi_query_search()` and `kagi_query_extract()`).
2. End-to-end corpus build (`parquet` -> `content` -> `markdown` -> `abstract`):
   use `user-corpus-workflow`.
3. Internal pipeline changes (download/extraction/summarization/linking):
   use `maintainer-corpus-pipeline`.
4. Cross-cutting package changes (API behavior, tests, docs contracts):
   use `maintainer-workflow`.
5. Generic package-maintenance governance workflows (portable pattern):
   use `r-package-developer`.
6. Pre-release / merge final synchronization:
   use `maintainer-release-sync`.

## Skills in pkgdown

Skills are rendered in pkgdown via include-based wrapper vignettes
(`vignettes/skills-*.qmd`) so skill text remains single-source in
`inst/skills` for package-bundled skills.

The generic cross-repo developer skill (`r-package-developer`) is maintained
externally at `skills/r-package-developer` and is not packaged as part of the
R package contents.

Contract:

- one wrapper page per skill,
- references embedded within the same skill page,
- compact Skills menu (one entry per skill),
- no duplicated copied skill/reference text in vignettes.

## Recent Change Summary (0.5.0)

- Retired the Kagi v0 API entirely. v1 is the only supported API.
- Removed v0 query constructors (`query_search`, `query_enrich_web`,
  `query_enrich_news`, `query_summarize`, `query_fastgpt`) and the v0-only
  `summarize_with_kagi()` helper.
- Renamed v1 constructors so the `_v1` suffix is no longer needed:
  `query_search_v1()` → `kagi_query_search()`,
  `query_extract()` → `kagi_query_extract()`. S3 class names match.
- `kagi_connection()` keeps the `api_version` argument for forward
  compatibility but accepts only `"v1"`; auth is always `Bearer`.
- `kagi_fetch()` writes search output to `<project>/search/` (was
  `<project>/search_v1/`). Existing folders need a rename.
- `kagi_request()` adds a `pages` argument (1–10) so callers can request
  multiple body-paginated pages per query.

## Earlier change history

See [NEWS.md](NEWS.md) for the per-version changelog.

## Agent Guidance for Future Changes

When modifying this repository, AI agents should:

1. Preserve the query-constructor -> request-execution separation.
2. Avoid introducing endpoint-specific logic into generic file/IO paths unless required.
3. Keep strict and graceful error behavior both tested.
4. Prefer additive changes to query schema; flag breaking parameter renames explicitly.
5. Update tests, vignettes, and changelog in the same change set.
6. Treat JSON output compatibility as a stability concern.

## Open Design Questions (Track Explicitly)

Potential next items to evaluate:

- Additional Kagi endpoints beyond current coverage.
- More explicit schema versioning for dummy payloads.
- Optional validation helpers for API key / endpoint health checks.
- Tighter invariants for parquet schema across endpoint versions.
