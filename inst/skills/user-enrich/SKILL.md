---
name: user-enrich
description: Use this skill for kagiPro Enrich endpoint workflows across web and news, including batch execution, error handling, and parquet conversion.
---

# User Enrich Workflow

Use this skill for Enrich tasks aligned with `vignettes/enrich-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build query objects with `query_enrich_web()` or `query_enrich_news()`.
3. Prefer `kagi_fetch()` for project-folder workflows.
4. Use `kagi_request()` + `kagi_request_parquet()` for low-level control.

## Allowed Function Set

- `kagi_connection()`
- `query_enrich_web()`
- `query_enrich_news()`
- `kagi_fetch()`
- `kagi_request()`
- `kagi_request_parquet()`

## Error Handling Rules

- Use strict behavior by default.
- Recommend `error_mode = "write_dummy"` for recurring batch collection jobs.
- Keep dummy-output explanations consistent with current package behavior.

## Enrich-Specific Rules

- Keep web and news workflows separated when presenting output layout.
- Use batch enrich examples for thematic monitoring.

Read `references/workflow.md` and `references/examples.md`.
