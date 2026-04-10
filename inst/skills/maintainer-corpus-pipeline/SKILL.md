---
name: maintainer-corpus-pipeline
description: Use this skill when changing content download, markdown extraction, abstract generation, summarizer providers, or corpus-read linking behavior.
---

# Maintainer Corpus Pipeline

Use this skill for internals of the modular corpus pipeline.

## Scope

Apply when changing any of:

- `download_content()`
- `content_markdown()`
- `markdown_abstract()`
- `summarize_with_openai()`
- `summarize_with_kagi()`
- `read_corpus(abstracts = TRUE)` linking behavior

## Required Contracts

1. Preserve folder layout by endpoint and query partition.
2. Keep `id + query` as the abstract linking key.
3. Keep abstract schema with lowercase `abstract`.
4. Keep row-level status/error reporting for partial failures.
5. Keep provider functions pluggable via function argument.


## Retry and Concurrency Rules

- OpenAI provider should default to conservative request concurrency.
- Retry behavior must remain explicit and documented.
- Progress output should reflect file-level work, not only worker completion.


## Documentation Sync Rules

When behavior changes, update together:

- `README.md` pipeline section
- `vignettes/corpus-workflow.qmd`
- `PROJECT_DESIGN.md`
- this skill’s references

## References

Read and apply:
- `references/contracts.md`
- `references/testing.md`
