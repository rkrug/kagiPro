---
name: user-search
description: Use this skill for rkagi Search endpoint workflows, including query construction, batch execution, error_mode selection, and parquet conversion.
---

# User Search Workflow

Use this skill for Search endpoint tasks aligned with `vignettes/search-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build query objects with `search_query()`.
3. Execute with `kagi_request()`.
4. Optionally convert with `kagi_request_parquet()`.

Do not skip steps in guidance unless the user already provides a reusable connection.

## Allowed Function Set

- `kagi_connection()`
- `search_query()`
- `open_search_query()`
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

