# rkagi Design Philosophy and Project Context (for AI Coding Agents)

## Purpose

`rkagi` is an R-first client for Kagi APIs designed for reproducible data workflows.

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

4. Predictable scaling from single to batch.
   Constructors return named lists consistently so one-query and many-query workflows use the same calling pattern.

5. Pragmatic fault tolerance.
   `error_mode = "stop"` for strict runs; `error_mode = "write_dummy"` for long pipelines where partial completion is preferred.

6. Analysis handoff as a first-class workflow.
   `kagi_request_parquet()` converts JSON collections to parquet for downstream processing.

## Public Workflow Contract

Expected user flow:

1. Create a connection with `kagi_connection()`.
2. Build query objects using endpoint-specific constructors.
3. Execute with `kagi_request()` into an output directory.
4. Optionally convert with `kagi_request_parquet()`.

This contract should remain stable across releases.

## Endpoint Coverage and Query Constructors

Current endpoint constructors:

- `search_query()`
- `enrich_web_query()`
- `enrich_news_query()`
- `summarize_query()`
- `fastgpt_query()`

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
- Endpoint user skills (`user-search`, `user-enrich`, `user-summarize`, `user-fastgpt`) mirror the endpoint vignettes.

Skills are intended to be strict execution guidance for coding agents and must remain aligned with package behavior and vignette examples.

## Recent Change Summary (toward 0.3.0)

Key project-level changes reflected in this cycle:

- Standardized query constructor behavior to named lists.
- Added/expanded FastGPT endpoint support via `fastgpt_query()`.
- Added graceful fallback behavior in `kagi_request()` with dummy outputs.
- Ensured dummy outputs can flow through parquet conversion.
- Strengthened tests around mixed success/failure request lists.
- Consolidated cassette location and vcr helper setup.
- Updated quickstart and added endpoint-focused vignettes.
- Aligned pkgdown output and article organization.
- Added AI-agent skills under `inst/skills` for maintainer and endpoint-specific workflows.
- Added standard disclaimer and AI-assisted development notice to README.
- Removed unused legacy assets from `inst/` (old extdata, plantuml diagrams, query_test script).

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
