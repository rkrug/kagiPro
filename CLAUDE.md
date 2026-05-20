# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`kagiPro` — an R package (R >= 4.2) client for the Kagi API (`v1`). Built around a query-first architecture where users construct typed query objects with `kagi_query_*()` constructors and execute them through a shared engine. The legacy `v0` beta API was retired in 0.5.0.

## Commands

R-package workflow (run from the repo root in R):

```r
devtools::document()           # regenerate NAMESPACE + man/*.Rd from roxygen
devtools::load_all()           # in-place loading for iteration
devtools::test()               # run all tests
devtools::test_active_file()   # run currently open test file
testthat::test_file("tests/testthat/test-v1.R")   # run one test file
devtools::check()              # full R CMD check — default audit
```

AI-doc / release sync check (must pass before release):

```bash
bash scripts/check-ai-docs.sh
```

This verifies `llms.txt` ↔ `pkgdown/extra/llms.txt`, `llms-full.txt` ↔ `pkgdown/extra/llms-full.txt`, and that `_pkgdown.yml` and `README.md` reference the AI-doc artifacts and `api-contracts` / `agent-quick-index` vignettes.

## Architecture (read these together)

The package separates **query construction** from **execution**. Understanding this split is the entry point to everything else.

1. **Connection** — `kagi_connection(api_version = "v1")` builds an S3 list carrying base URL, auth header (`Bearer <key>`), and the API version. The `api_version` arg is kept only as a forward-compat hook; `"v1"` is the only accepted value today. The retry policy retries on `408/429/500/502/503/504` with a capped exponential backoff (max 10s per attempt).

2. **Query constructors** return named lists of S3-classed query objects, one element per query (so single and batch flows share the same call shape):
   - `kagi_query_search()` — class `kagi_query_search`, subclasses `list`. Workflows: `search`, `images`, `videos`, `news`, `podcasts`. Optional `lens`, `filters`, `extract`, `personalizations`, `safe_search`, `page`, `limit`, etc.
   - `kagi_query_extract()` — class `kagi_query_extract`. Auto-chunks URL vectors into batches of up to 10 (`/extract` API per-request maximum).
   - Class → endpoint mapping lives in [R/utils.R](R/utils.R) (`endpoint_from_query_class`, `endpoint_path_from_query_class`, `kagi_query_classes`, `serialize_query_payload`, `reconstruct_query_from_meta`). When adding an endpoint, update these dispatch tables.

3. **Execution** — two layers:
   - High-level: `kagi_fetch()` ([R/kagi_fetch.R](R/kagi_fetch.R)) is the preferred entrypoint. It writes endpoint-scoped folders `<project_folder>/<endpoint>/json` and `<project_folder>/<endpoint>/parquet`, then (for `kagi_query_search`) optionally materialises a corpus via `as_corpus_parquet()`. Endpoints today are `search` and `extract`.
   - Low-level: `kagi_request()` ([R/kagi_request.R](R/kagi_request.R)) dispatches on query class via a `switch()`, writes raw JSON, and persists a `_query_meta.json` replay record per query. The `pages` argument (1–10) drives body-paginated fetches — each iteration sets `body$page` and writes a separate `search_<page>.json`. `kagi_request_parquet()` converts JSON pages to Hive-partitioned parquet (`query=<name>/type=<type>` for search; `query=<name>` for extract). With `combine = TRUE` (default for `kagi_fetch()`) the partitions are union-merged into a single `combined.parquet` and the partition dirs are removed. Parquet dispatch keys on the persisted query class in `_query_meta.json`.

4. **Error model** — `kagi_request()` supports `error_mode = "stop"` and `error_mode = "write_dummy"`. Errors are unpacked from the httr2 condition (`e$resp`) so the full envelope (HTTP status + Kagi `error[].code` / `error[].msg` + raw body) reaches the message and the dummy payload. Dummy payloads keep endpoint shape and flow through parquet conversion intact. Both paths must remain tested.

5. **Corpus pipeline** — independent, sequential stages (each idempotent per query partition):
   `download_content()` → `content_markdown()` → `markdown_abstract()` → `read_corpus(..., abstracts = TRUE)`. Abstract linking key is `id + query`; the abstract column is lowercase `abstract`. Summarizer plug: `summarize_with_openai()`.

6. **Replay / refresh** — every request writes `_query_meta.json`. `kagi_update_query(query_name = ...)` reruns a single stored query and refreshes only its parquet partition. `clean_request()` deletes raw JSON while preserving replay metadata.

## Testing

Tests live in [tests/testthat/test-v1.R](tests/testthat/test-v1.R) and exercise pure R behaviour (constructor validation, query bodies, class assertions, OpenAPI spec presence). They do not hit the network. The `vcr` plumbing (`setup-vcr.R`, `teardown-vcr.R`, `helper_kagi.R`) is retained for future cassette-backed tests — `helper_kagi.R` resolves the API key from `keyring::key_get("API_kagi")` or `KAGI_API_KEY`. When adding network-touching tests for a new endpoint: success path, failure / dummy-write path, parquet conversion on mixed outputs.

## Conventions specific to this repo

- Long-lived branches are `main` and `dev`. **Do not delete `dev`** after PR merges.
- Default audit before merging non-trivial changes is `devtools::check()` (full R CMD check), not just `test()`.
- Never edit `NAMESPACE` or `man/*.Rd` by hand — they are regenerated by `devtools::document()` from roxygen blocks above each function.
- `llms.txt` / `llms-full.txt` at the repo root and their mirrors under `pkgdown/extra/` must stay byte-identical (the AI-docs check enforces `cmp -s`).
- Keep `inst/skills/` (bundled agent skills) and the corresponding `vignettes/skills-*.qmd` wrappers in sync. The wrappers are include-based — skill text is single-source in `inst/skills/`.
- The generic `skills/r-package-developer/` skill is maintained externally and is `.Rbuildignore`d; do not auto-install it without explicit user approval.
- Query objects subclass `list`. Class name matches the constructor function name (`kagi_query_search`, `kagi_query_extract`). Preserve this when adding constructors so existing class checks (`identical(query_class, "kagi_query_search")`, etc.) stay correct.

## Reference material

- [PROJECT_DESIGN.md](PROJECT_DESIGN.md) — design philosophy and stability contract.
- [inst/skills/README.md](inst/skills/README.md) — agent skill selection rules per workflow phase.
- [inst/api_specs/openapi.yaml](inst/api_specs/openapi.yaml) — Kagi API contract used for v1 validation bounds.
- [llms-full.txt](llms-full.txt) — extended API contract / maintenance conventions.
