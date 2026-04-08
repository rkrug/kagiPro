# FastGPT Workflow (Aligned to Vignette)

Source of truth: `vignettes/fastgpt-endpoint.qmd`.

## Sequence

1. Build connection.
2. Build query sets with `fastgpt_query()`.
3. Execute with `kagi_request()`.
4. Use list queries for batch prompt runs.
5. Convert with `kagi_request_parquet()` when needed.

## Error Strategy

- Use strict defaults for controlled runs.
- Use `error_mode = "write_dummy"` for unattended batches.

## Constraints

- Keep prompts concise in examples.
- Keep behavior statements aligned with current docs/tests.

