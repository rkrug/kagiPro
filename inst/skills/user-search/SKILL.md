---
name: user-search
description: Use this skill for kagiPro Search endpoint workflows, including query construction, batch execution, error_mode selection, and parquet conversion.
---

# User Search Workflow

Use this skill for Search endpoint tasks aligned with `vignettes/search-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build query objects with `query_search()`.
3. Prefer `kagi_fetch()` for project-folder workflows.
4. Use `kagi_request()` + `kagi_request_parquet()` for low-level control.

Do not skip steps in guidance unless the user already provides a reusable connection.

## Allowed Function Set

- `kagi_connection()`
- `query_search()`
- `open_search_query()`
- `kagi_fetch()`
- `kagi_request()`
- `kagi_request_parquet()`

## Error Handling Rules

- Use `error_mode = "stop"` for strict/CI-like guidance.
- Use `error_mode = "write_dummy"` for long batch runs.
- Keep explanation consistent with search vignette wording.

## Output and Batching Rules

- Prefer named output directories.
- Use list-style query execution for batch workloads.
- Mention `workers` when describing parallel execution.

Read `references/workflow.md` for canonical flow and `references/examples.md` for endpoint-aligned snippets.
