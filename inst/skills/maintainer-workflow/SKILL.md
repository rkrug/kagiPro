---
name: maintainer-workflow
description: Use this skill when changing kagiPro internals, tests, docs, release metadata, or endpoint behavior. Covers design principles, naming principles, testing with vcr, and release hygiene.
---

# Maintainer Workflow

Use this skill for package maintenance and implementation changes.

## Scope

Apply this skill when tasks involve any of the following:

- Changes in `R/` implementation.
- Changes in tests, cassettes, or test infrastructure.
- Changes in API behavior, error handling, or output contracts.
- Versioning, changelog/release notes, and documentation synchronization.

For endpoint-only user workflows, use `user-search`, `user-enrich`, `user-summarize`, `user-fastgpt`, or `user-corpus-workflow` instead.

## Required Design Principles

1. Query-first architecture.
   Build endpoint query objects first; execute with `kagi_request()`.
2. Constructor and execution separation.
   Query constructors define intent; request layer handles IO and endpoint execution.
3. JSON is source-of-truth.
   Requests persist JSON artifacts. Treat parquet as derivative.
4. Consistent scaling.
   Constructor outputs must support single and batch execution consistently.
5. Explicit fault tolerance.
   Keep `error_mode = "stop"` and `error_mode = "write_dummy"` coherent and tested.

Read `references/design-principles.md` before modifying request behavior.

## Naming Principles

Enforce these naming rules:

- Query constructors use `query_<endpoint>` names (for example `query_search`, `query_fastgpt`).
- Request executors are generic (`kagi_request`, `kagi_request_parquet`).
- Constructor output contract remains consistent across endpoints.
- Output folders should be explicit and stable in examples/tests.

Read `references/naming-principles.md` before adding or renaming symbols.

## Testing Workflow

Use `testthat` with `vcr` and preserve deterministic cassette structure.

Required checks for relevant changes:

1. Run targeted tests for modified behavior.
2. Ensure cassette location remains `tests/testthat/fixtures/cassettes`.
3. If re-recording, use key retrieval via `keyring::key_get("API_kagi")`.
4. Cover both strict and graceful error modes where request behavior changed.
5. Validate parquet conversion for mixed success/error payloads when relevant.

Read `references/testing-and-cassettes.md` before updating fixtures.

## Release Hygiene Checklist

For release-prep changes, execute this checklist:

1. Bump version in `DESCRIPTION`.
2. Update release notes/changelog (`NES.md`).
3. Confirm docs are synchronized: README, quickstart, endpoint vignettes, man pages.
4. Confirm no stale names, paths, or deprecated references remain.
5. Run regression tests relevant to touched behavior.

Read `references/release-checklist.md` before finalizing.

## Implementation Guardrails

- Do not introduce undocumented behavior in skills or docs.
- Do not claim endpoint capabilities not present in code/tests.
- Keep user-facing docs narrative, but keep this skill imperative and concise.
- If behavior changes, update tests and docs in the same change set.
