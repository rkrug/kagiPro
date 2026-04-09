# Corpus Pipeline Contracts

## File Layout

- `<project>/<endpoint>/parquet`
- `<project>/<endpoint>/content/query=<query>`
- `<project>/<endpoint>/markdown/query=<query>`
- `<project>/<endpoint>/abstract/query=<query>`

## Data Contracts

- Join key: `id + query`
- Abstract field: `abstract` (lowercase)
- Multi-selector behavior:
  - `endpoint = NULL` expands across supported endpoints.
  - `query_name = NULL` expands across all queries.

## Failure Contracts

- Per-row failures should yield status/error outputs.
- Pipeline should avoid whole-run termination for single-record extraction/summarization failures unless strict mode is explicitly requested.
