# Enrich Workflow (Aligned to Vignette)

Source of truth: `vignettes/enrich-endpoint.qmd`.

## Sequence

1. Build connection.
2. Build web queries with `enrich_web_query()` and/or news queries with `enrich_news_query()`.
3. Execute with `kagi_request()`.
4. For recurring monitoring, run batch query lists.
5. Convert with `kagi_request_parquet()`.

## Error Strategy

- Default strict behavior for small controlled runs.
- `error_mode = "write_dummy"` for long batch collection.

## Constraints

- Keep web/news outputs separated in examples.
- Keep language consistent with endpoint guide.

