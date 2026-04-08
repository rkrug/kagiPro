# Summarize Workflow (Aligned to Vignette)

Source of truth: `vignettes/summarize-endpoint.qmd`.

## Sequence

1. Build connection.
2. Build query objects with `summarize_query()` (URL mode or text mode).
3. Execute with `kagi_request()`.
4. For mixed batches, pass explicit query lists.
5. Convert with `kagi_request_parquet()` if needed.

## Error Strategy

- Be explicit about short-input failure risk.
- Use `error_mode = "write_dummy"` for robust pipelines.

## Constraints

- Keep guidance aligned with documented summarize behavior.
- Do not imply unsupported summarize options.

