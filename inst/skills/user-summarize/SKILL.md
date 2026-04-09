---
name: user-summarize
description: Use this skill for kagiPro Summarize endpoint workflows, including URL/text query modes, graceful handling of short-input failures, and parquet conversion.
---

# User Summarize Workflow

Use this skill for Summarize tasks aligned with `vignettes/summarize-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build summarize queries with `query_summarize()`.
3. Prefer `kagi_fetch()` for project-folder workflows.
4. Use `kagi_request()` + `kagi_request_parquet()` for low-level control.

## Allowed Function Set

- `kagi_connection()`
- `query_summarize()`
- `kagi_fetch()`
- `kagi_request()`
- `kagi_request_parquet()`

## Summarize-Specific Rules

- Support both URL and text input modes.
- Explicitly mention short-input failure risk.
- For robust pipelines, recommend `error_mode = "write_dummy"`.
- Keep mixed success/error batch guidance aligned with existing vignette behavior.

Read `references/workflow.md` and `references/examples.md`.
