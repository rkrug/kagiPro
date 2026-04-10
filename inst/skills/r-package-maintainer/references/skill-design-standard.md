# Package Skill Design Standard (Generic)

## Goal

Define a maintainable structure for package-local skills so agents and humans can
use them consistently without bloating user-facing docs.

## Structure

1. Keep `SKILL.md` compact:
   - purpose,
   - scope,
   - workflow phases,
   - non-negotiable rules,
   - pointers to references.
2. Put detailed procedures in `references/*`.
3. Keep reusable scripts/templates in `references/` or a dedicated helper path.
4. For pkgdown exposure, use one wrapper vignette per skill
   (`vignettes/skills-<skill>.qmd`) and include both `SKILL.md` and reference
   files from `inst/skills`.

## Linking Rules

1. Include a final `References` section in `SKILL.md`.
2. Add section-level pointers ("See also") where a specific reference is
   required.
3. Ensure every referenced file exists and is current.
4. In `_pkgdown.yml`, keep skill pages indexed and linked via wrapper vignette
   HTML pages.

## Duplication Control

1. Do not duplicate detailed checklist items in `SKILL.md`.
2. Keep execution gates in checklist docs.
3. Keep commit evidence format in commit-template docs.
4. Do not create duplicate per-reference wrappers when references are embedded
   in the single skill wrapper page.

## Skill Taxonomy

1. Separate user workflow skills from maintainer/internal skills.
2. Keep naming clear and intention-revealing (for example `user-*`,
   `maintainer-*`).
3. Maintain an index file with selection rules.

## Sync Rules (Required)

When code/API/workflow changes:

1. Update impacted skills in the same change set.
2. Update the skill index if skills are added/renamed/retired.
3. Run stale-reference checks (old function names, removed APIs, path drift).
4. Verify references and examples still match current package behavior.
5. Keep `_pkgdown.yml` skills menu compact (one entry per skill) and keep the
   articles index synchronized with actual wrapper files.
6. Remove obsolete `skills-*-ref-*.qmd` wrappers after migration to one-page
   skill wrappers.
7. If wrapper pages are pkgdown-only, exclude them in `.Rbuildignore` to avoid
   vignette-engine notes during package checks.

## Readability Guardrails

1. Keep user docs narrative-first.
2. Keep machine/agent-specific operational details in skills and machine docs,
   not in narrative user guides.
3. Keep skills concise and imperative; keep long rationale in references.

## Validation Gate

Before commit/merge:

1. Confirm skill references resolve.
2. Confirm no stale API names remain in skills.
3. Confirm checklist/commit-template still reflect current governance.
4. Confirm `pkgdown::build_site()` succeeds after skills/docs changes.
