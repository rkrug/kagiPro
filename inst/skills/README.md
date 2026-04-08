# rkagi Skills Index

This folder contains AI-agent skills for working with `rkagi`.

## Skills

- `maintainer-workflow`
  Use when updating package behavior, tests, docs, release metadata, or cassettes.
- `user-search`
  Use for Search endpoint workflows aligned with `vignettes/search-endpoint.qmd`.
- `user-enrich`
  Use for Enrich endpoint workflows aligned with `vignettes/enrich-endpoint.qmd`.
- `user-summarize`
  Use for Summarize endpoint workflows aligned with `vignettes/summarize-endpoint.qmd`.
- `user-fastgpt`
  Use for FastGPT endpoint workflows aligned with `vignettes/fastgpt-endpoint.qmd`.

## Selection Rule

1. If the task is endpoint-specific, choose the corresponding `user-*` skill.
2. If the task changes package internals, tests, release docs, or conventions, use `maintainer-workflow`.
3. If a task spans endpoint usage and package changes, load `maintainer-workflow` plus the relevant `user-*` skill.

## Non-goal

These skills do not replace package docs. They encode actionable workflows and guardrails for coding agents.

