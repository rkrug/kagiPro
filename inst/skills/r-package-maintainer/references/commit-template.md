# Detailed Commit Template (Generic)

Use this structure for maintainer/release commits:

## Subject

- Short imperative summary (single line).

## Body

### Behavior/API changes
- List functional changes and contract impacts.
- Explicitly call out breaking changes.

### Documentation and metadata updates
- List updated docs (README/changelog/vignettes/design docs).
- Mention regenerated reference artifacts (`NAMESPACE`, `man/*.Rd`) if applicable.
- Explicitly list AI-readable artifact updates, or state:
  - `No AI-doc changes required` + short reason.
- State generated-artifact handling:
  - confirm package-standard artifacts were committed (`NAMESPACE`, `man/*.Rd`
    when regenerated),
  - confirm build artifacts were not committed.

### Validation
- List tests/checks executed.
- Note any remaining non-actionable warnings/notes.
- Add AI-doc sync check:
  - pass/fail + what was verified.
- List exact validation commands (copyable) so results are reproducible.

### Scope note (optional)
- Clarify inclusions/exclusions when commit intentionally bundles or excludes areas.
