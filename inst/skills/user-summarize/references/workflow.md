# Summarize Workflow (Aligned to Vignette)

Source of truth: `vignettes/summarize-endpoint.qmd`.

## Sequence

1. Build connection.
2. Build query objects with `query_summarize()` (URL mode or text mode).
3. Preferred: execute end-to-end with `kagi_fetch(project_folder = ...)`.
4. Low-level path: execute with `kagi_request()`.
5. For mixed batches, pass explicit query lists.
6. Convert with `kagi_request_parquet()` if needed.

## Error Strategy

- Be explicit about short-input failure risk.
- Use `error_mode = "write_dummy"` for robust pipelines.

## Constraints

- Keep guidance aligned with documented summarize behavior.
- Do not imply unsupported summarize options.
