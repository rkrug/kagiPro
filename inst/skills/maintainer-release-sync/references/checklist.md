# Release Sync Checklist

1. Run grep for stale identifiers (removed APIs, old constructor names).
2. Regenerate docs (`devtools::document()`).
3. Re-run key tests for changed modules.
4. Ensure README and vignettes show current preferred workflow.
5. Ensure `PROJECT_DESIGN.md` reflects actual architecture.
6. Ensure skills index lists all active skills.
7. Update `NEWS.md`/`NES.md` with features, bug fixes, breaking changes, docs.
8. Pre-commit sync gate:
   - verify `NEWS.md`, `PROJECT_DESIGN.md`, `README.md`, and relevant `vignettes/*.qmd` are updated for behavior changes.
9. Commit message gate:
   - use a detailed message with sections for behavior changes, docs/skills sync, and test/check outcomes.
10. Branch gate:
   - keep both `main` and `dev` on origin; do not delete `dev` after merge.
   - do not delete any branch unless explicitly requested and explicitly confirmed by the user.
