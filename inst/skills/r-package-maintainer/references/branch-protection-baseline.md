# Branch Protection Baseline (Generic)

## Branch Model

- Long-lived branches: `main` and `dev`.
- Preferred integration flow: feature work -> `dev` -> PR -> `main`.

## Branch Deletion Rules

- Do not delete `dev` after PR merges.
- Do not delete any branch unless deletion is explicitly requested and explicitly confirmed.

## Protection Ruleset Baseline

### `main`

- protect from deletion
- prevent non-fast-forward (force push)
- require PR-based merge
- require at least one approving review
- require review thread resolution
- require stale review dismissal on push
- require last-push approval
- optional for solo-maintainer repos: add a bypass actor for PR merges only
  when no second reviewer exists
- if bypass is used, keep required checks and PR-only merge requirement active
  (no direct push path)

### `dev`

- protect from deletion
- allow force push unless project policy says otherwise

## Deployment Gates

- Avoid merge-blocking deployment requirements on `main` unless deployment is guaranteed pre-merge in your workflow.
