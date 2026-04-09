# FastGPT Workflow (Aligned to Vignette)

Source of truth: `vignettes/fastgpt-endpoint.qmd`.

## Sequence

1. Build connection.
2. Build query sets with `query_fastgpt()`.
3. Preferred: execute end-to-end with `kagi_fetch(project_folder = ...)`.
4. Low-level path: execute with `kagi_request()`.
5. Use list queries for batch prompt runs.
6. Convert with `kagi_request_parquet()` when needed.

## Error Strategy

- Use strict defaults for controlled runs.
- Use `error_mode = "write_dummy"` for unattended batches.

## Constraints

- Keep prompts concise in examples.
- Keep behavior statements aligned with current docs/tests.
