---
name: user-summarize
description: Use this skill for rkagi Summarize endpoint workflows, including URL/text query modes, graceful handling of short-input failures, and parquet conversion.
---

# User Summarize Workflow

Use this skill for Summarize tasks aligned with `vignettes/summarize-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build summarize queries with `summarize_query()`.
3. Execute with `kagi_request()`.
4. Optionally convert with `kagi_request_parquet()`.

## Allowed Function Set

- `kagi_connection()`
- `summarize_query()`
- `kagi_request()`
- `kagi_request_parquet()`

## Summarize-Specific Rules

- Support both URL and text input modes.
- Explicitly mention short-input failure risk.
- For robust pipelines, recommend `error_mode = "write_dummy"`.
- Keep mixed success/error batch guidance aligned with existing vignette behavior.

Read `references/workflow.md` and `references/examples.md`.

