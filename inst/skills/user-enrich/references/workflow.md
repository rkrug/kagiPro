# Enrich Workflow (Aligned to Vignette)

Source of truth: `vignettes/enrich-endpoint.qmd`.

## Sequence

1. Build connection.
2. Build web queries with `query_enrich_web()` and/or news queries with `query_enrich_news()`.
3. Preferred: execute end-to-end with `kagi_fetch(project_folder = ...)`.
4. Low-level path: execute with `kagi_request()`.
5. For recurring monitoring, run batch query lists.
6. Convert with `kagi_request_parquet()`.

## Error Strategy

- Default strict behavior for small controlled runs.
- `error_mode = "write_dummy"` for long batch collection.

## Constraints

- Keep web/news outputs separated in examples.
- Keep language consistent with endpoint guide.
