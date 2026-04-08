# Design Principles

## Canonical Workflow

1. Build query objects with endpoint-specific constructors.
2. Create one `kagi_connection()`.
3. Execute with `kagi_request()` into JSON output directories.
4. Optionally convert with `kagi_request_parquet()`.

## Architecture Rules

- Keep constructor logic endpoint-specific.
- Keep request execution generic where possible.
- Keep JSON writing deterministic and explicit.
- Keep graceful error handling predictable and structured.

## Error-Handling Contract

- `error_mode = "stop"` must fail fast with actionable errors.
- `error_mode = "write_dummy"` must warn and write endpoint-compatible fallback JSON.
- Dummy outputs must remain convertible by parquet conversion paths.

## Data Contract Priorities

- Preserve stable fields where feasible.
- Avoid hidden coercions in constructor output.
- Preserve consistency between single and batch query execution.

