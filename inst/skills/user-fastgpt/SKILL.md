---
name: user-fastgpt
description: Use this skill for rkagi FastGPT endpoint workflows, including prompt query sets, batch execution, error-mode strategy, and parquet conversion.
---

# User FastGPT Workflow

Use this skill for FastGPT tasks aligned with `vignettes/fastgpt-endpoint.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build query objects with `fastgpt_query()`.
3. Execute with `kagi_request()`.
4. Optionally convert with `kagi_request_parquet()`.

## Allowed Function Set

- `kagi_connection()`
- `fastgpt_query()`
- `kagi_request()`
- `kagi_request_parquet()`

## FastGPT-Specific Rules

- Keep prompts concise and task-specific.
- Use list query sets for repeatable prompt batches.
- Recommend `error_mode = "write_dummy"` for unattended runs.

Read `references/workflow.md` and `references/examples.md`.

