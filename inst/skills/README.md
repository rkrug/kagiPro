# kagiPro Skills Index

This folder contains AI-agent skills for working with `kagiPro`.
Preferred high-level project workflow: `kagi_fetch()`.

## Skills

- `maintainer-workflow`
  Use when updating package behavior, tests, docs, release metadata, or cassettes.
- `maintainer-corpus-pipeline`
  Use when changing `download_content()`, `content_markdown()`, `markdown_abstract()`, summarizer providers, or abstract-link contracts.
- `maintainer-release-sync`
  Use before release/merge to synchronize versioning, changelog, docs, vignettes, and skills.
- `r-package-maintainer`
  Generic R-package maintainer baseline skill (portable across repos) for workflow, validation, branch governance, and commit standards.
- `user-search`
  Use for Search endpoint workflows aligned with `vignettes/search-endpoint.qmd`.
- `user-enrich`
  Use for Enrich endpoint workflows aligned with `vignettes/enrich-endpoint.qmd`.
- `user-summarize`
  Use for Summarize endpoint workflows aligned with `vignettes/summarize-endpoint.qmd`.
- `user-fastgpt`
  Use for FastGPT endpoint workflows aligned with `vignettes/fastgpt-endpoint.qmd`.
- `user-corpus-workflow`
  Use for the full corpus pipeline aligned with `vignettes/corpus-workflow.qmd`.

## Selection Rule

1. If the task is endpoint-specific, choose the corresponding `user-*` skill.
2. If the task changes package internals, tests, release docs, or conventions, use `maintainer-workflow`.
3. If the task changes corpus pipeline internals, use `maintainer-corpus-pipeline` (and `maintainer-workflow` when broader API/docs are affected).
4. If the task is release-finalization, use `maintainer-release-sync`.
5. If the task is generic/package-governance work (not package-specific internals), use `r-package-maintainer`.
6. If a task spans endpoint usage and package changes, load the relevant maintainer skill plus the matching `user-*` skill.

## Non-goal

These skills do not replace package docs. They encode actionable workflows and guardrails for coding agents.

## Branch Policy (Maintainer)

- Long-lived branches are `main` and `dev`.
- `dev` must remain on origin after pull request merges.
- No branch deletion unless explicitly requested and explicitly confirmed by the user.
