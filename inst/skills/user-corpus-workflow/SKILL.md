---
name: user-corpus-workflow
description: Use this skill for the end-to-end corpus pipeline in kagiPro: search results to parquet, content download, markdown extraction, abstract generation, and corpus reading with optional abstract linking.
---

# User Corpus Workflow

Use this skill for corpus-building tasks aligned with `vignettes/corpus-workflow.qmd`.

## Required Workflow Order

1. Create `kagi_connection()`.
2. Build one or more endpoint queries (typically `query_search()`).
3. Run `kagi_fetch()` (or `kagi_request()` + `kagi_request_parquet()`).
4. Run `download_content()`.
5. Run `content_markdown()`.
6. Run `markdown_abstract()`.
7. Read with `read_corpus(abstracts = TRUE)` when needed.

## Allowed Function Set

- `kagi_connection()`
- `query_search()`
- `kagi_fetch()`
- `kagi_request()`
- `kagi_request_parquet()`
- `download_content()`
- `content_markdown()`
- `markdown_abstract()`
- `summarize_with_openai()`
- `summarize_with_kagi()`
- `read_corpus()`

## Selector Rules

- `endpoint = NULL` means process all supported endpoints.
- `query_name = NULL` means process all queries in selected endpoint(s).
- Keep file layout explicit: `<project>/<endpoint>/{json,parquet,content,markdown,abstract}`.

## Error Handling Rules

- Keep row-level failures as status/error outputs where supported.
- Use strict mode in CI-like runs; resilient mode for long batches.
- Do not invent fallback extraction behavior beyond package implementation.

Read `references/workflow.md` for canonical order and `references/examples.md` for copy-ready snippets.
