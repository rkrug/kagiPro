# Search Workflow (Aligned to Vignette)

Source of truth: `vignettes/search-endpoint.qmd`.

## Sequence

1. Build connection:
   `conn <- kagi_connection(api_key = function() keyring::key_get("API_kagi"))`
2. Build search query with `query_search()`.
3. Preferred: execute end-to-end with `kagi_fetch(connection = conn, query = ..., project_folder = ...)`.
4. Low-level path: `kagi_request(connection = conn, query = ..., output = ..., overwrite = TRUE)`.
5. For batches, pass a list query and optional `workers`.
6. Convert with `kagi_request_parquet()` if tabular analysis is needed.

## Error Strategy

- Strict mode: `error_mode = "stop"`.
- Graceful mode: `error_mode = "write_dummy"`.

## Constraints

- Keep function names exactly as exported.
- Do not describe unsupported parameters or response fields.
