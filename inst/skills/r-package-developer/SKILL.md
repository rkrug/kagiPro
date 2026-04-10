---
name: r-package-developer
description: Generic R package developer skill for implementation quality, testing, docs sync, release hygiene, branch governance, and merge safety.
---

# R Package Developer Workflow (Generic)

Use this skill for package maintenance and release work in any R package repository.

## Purpose

- Preserve API and behavior quality.
- Keep docs and generated references synchronized with code.
- Enforce reproducible validation and safe branch/merge governance.

## Maintainer Roles

1. Implementation maintainer:
   - preserve API contracts,
   - keep behavior changes explicit and tested.
2. Documentation maintainer:
   - keep user docs and reference docs synchronized with runtime behavior.
3. Release maintainer:
   - keep versioning/changelog/release notes consistent and complete.
4. Governance maintainer:
   - enforce branch and merge safety rules.

## Required Workflow Phases

1. Understand scope
2. Implement safely
3. Synchronize docs and references
4. Validate and record reproducible evidence
5. Apply governance and merge gates

Use `references/checklist.md` as the execution gate before commit/merge.

## Non-Negotiable Rules

- Breaking changes must be explicit and documented.
- Validation claims must be reproducible (record exact commands and outcomes).
- R code formatting must follow `air`.
- AI-readable docs must remain separate from narrative user docs.
- Branch governance baseline:
  - long-lived branches are `main` and `dev`,
  - do not delete `dev` after PR merges,
  - do not delete any branch unless explicitly requested and confirmed,
  - solo-maintainer bypass on `main` is allowed only for PR merges and must
    not create a direct-push path.

## AI-Readable Docs Policy

- Keep user docs narrative-first (`README`, vignettes).
- Keep machine-oriented docs in dedicated artifacts (for example `llms.txt`,
  `llms-full.txt`, contracts/quick-index pages, skills).
- If code/API/output contracts change, update impacted AI-readable artifacts in
  the same change set.
- For skills in pkgdown, render HTML from include-based vignette wrappers that
  include `inst/skills/*/SKILL.md` and `inst/skills/*/references/*.md`;
  do not duplicate skill/reference text in vignettes.
- Keep one wrapper page per skill (not per reference file). Embed references
  inside the skill wrapper page under a references section.
- Keep navbar compact: one menu item per skill only.
- Keep `_pkgdown.yml` articles index synchronized with the actual skill wrapper
  vignette files.
- Remove obsolete skill-reference wrapper files when moving to single-page
  wrappers.

## Baseline CI Requirement

- Ensure baseline check workflow exists via
  `usethis::use_github_action("check-standard")`.
- As part of release/audit validation, run a local package check using
  `devtools::check()` (preferred in interactive development environments) and
  record outcomes.

## Package Skill Design Standard

- Keep `SKILL.md` thin: policy, workflow phases, non-negotiable rules.
- Keep operational detail in `references/*` files.
- Add section-level reference pointers plus a final references section.
- Avoid duplication between `SKILL.md` and checklist-style execution docs.
- Maintain clear user-skill vs maintainer-skill boundaries.
- When package APIs/workflows change, update impacted skills in the same change
  set and run stale-reference checks before commit.
- Keep skill updates manual and explicit (reviewed edits in-repo); do not
  require automatic self-update behavior.

## Commit Standard

- Use a detailed commit message covering:
  - behavior/API changes,
  - docs/changelog/design updates,
  - validation summary.

## References

Read and apply:
- `references/checklist.md`
- `references/branch-protection-baseline.md`
- `references/commit-template.md`
- `references/check-ai-docs-template.sh`
- `references/skill-design-standard.md`
