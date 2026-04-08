# Naming Principles

## Function Names

- Query constructors use `*_query` naming.
- Core execution functions are `kagi_request()` and `kagi_request_parquet()`.
- Endpoint-specific helpers must use explicit endpoint terms (`search`, `enrich`, `summarize`, `fastgpt`).

## Output and Object Conventions

- Constructor outputs are named lists.
- Output directories should reflect endpoint/run intent (`search_batch`, `summarize_mixed`).
- Avoid ambiguous or overloaded names in new helpers.

## Documentation Naming Consistency

- Use the same function names in code, docs, tests, and cassettes.
- Remove stale aliases/references when names change.
- Keep vignette terminology aligned with exported function names.

