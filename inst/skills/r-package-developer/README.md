# R Package Developer Skill

This repository provides a reusable skill for R package development workflows.

# AI Statement
This skill has been build by Codex for usage in Codex, Claude Code, and similar coding agents using a consistent,
reviewable process.

It is therefore optimised by Codex for AI usage.

## Recommended Layout

Use this structure:

- `README.md` (this file, user-facing overview in repo root)
- `skills/r-package-developer/SKILL.md`
- `skills/r-package-developer/references/*`
- `skills/r-package-developer/scripts/*` (optional helpers)

## How To Use

1. Put the skill under `skills/r-package-developer/` in your target repository.
2. Ask your coding agent to read and follow `skills/r-package-developer/SKILL.md`.
3. Request the concrete task (for example, create a package skeleton, implement a feature, or run a release sync).

Example prompt:

```text
Read and follow skills/r-package-developer/SKILL.md, then create a complete R package skeleton in this repository.
```

## What You Should Expect

For scaffold requests, the result should be a usable package baseline, typically including:

- `DESCRIPTION`, `NAMESPACE`
- `R/`, `man/`
- `tests/testthat/`
- `.Rbuildignore`, `.gitignore`
- `README.md`, `NEWS.md`
- `_pkgdown.yml`
- CI workflow files
- starter vignettes/docs

## Governance

- `SKILL.md` is the executable agent policy.
- `references/checklist.md` is the commit/merge execution gate.
- Skill updates are manual and explicit.
