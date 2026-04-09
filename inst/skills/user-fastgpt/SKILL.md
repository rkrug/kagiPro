---
name: user-fastgpt
description: Use this skill for kagiPro FastGPT endpoint workflows, including prompt query sets, batch execution, error-mode strategy, and parquet conversion.
---

# User FastGPT Workflow

Use this skill for FastGPT tasks aligned with `vignettes/fastgpt-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build query objects with `query_fastgpt()`.
3. Prefer `kagi_fetch()` for project-folder workflows.
4. Use `kagi_request()` + `kagi_request_parquet()` for low-level control.

## Allowed Function Set

- `kagi_connection()`
- `query_fastgpt()`
- `kagi_fetch()`
- `kagi_request()`
- `kagi_request_parquet()`

## FastGPT-Specific Rules

- Keep prompts concise and task-specific.
- Use list query sets for repeatable prompt batches.
- Recommend `error_mode = "write_dummy"` for unattended runs.

Read `references/workflow.md` and `references/examples.md`.
