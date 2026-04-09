# Corpus Workflow

1. Build queries with endpoint constructors.
2. Fetch to project folders (`kagi_fetch`) or request + parquet manually.
3. Download source content (`download_content`).
4. Convert content to markdown (`content_markdown`).
5. Summarize markdown to abstract parquet (`markdown_abstract`).
6. Read datasets with optional abstract linking (`read_corpus(abstracts = TRUE)`).

## Folder Contract

- `<project>/<endpoint>/json`
- `<project>/<endpoint>/parquet`
- `<project>/<endpoint>/content/query=<query>`
- `<project>/<endpoint>/markdown/query=<query>`
- `<project>/<endpoint>/abstract/query=<query>`

## Provider Guidance

- Prefer `summarize_with_openai()` for general text quality.
- Use `summarize_with_kagi()` when staying inside Kagi API stack.
- Use conservative concurrency for OpenAI due to rate limits.
