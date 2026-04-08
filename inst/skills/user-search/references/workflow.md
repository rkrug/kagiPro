# Search Workflow (Aligned to Vignette)

Source of truth: `vignettes/search-endpoint.qmd`.

## Sequence

1. Build connection:
   `conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))`
2. Build search query with `search_query()`.
3. Execute with `kagi_request(connection = conn, query = ..., output = ..., overwrite = TRUE)`.
4. For batches, pass a list query and optional `workers`.
5. Convert with `kagi_request_parquet()` if tabular analysis is needed.

## Error Strategy

- Strict mode: `error_mode = "stop"`.
- Graceful mode: `error_mode = "write_dummy"`.

## Constraints

- Keep function names exactly as exported.
- Do not describe unsupported parameters or response fields.

