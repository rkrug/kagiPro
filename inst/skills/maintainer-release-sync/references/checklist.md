# Release Sync Checklist

1. Run grep for stale identifiers (removed APIs, old constructor names).
2. Regenerate docs (`devtools::document()`).
3. Re-run key tests for changed modules.
4. Ensure README and vignettes show current preferred workflow.
5. Ensure `PROJECT_DESIGN.md` reflects actual architecture.
6. Ensure skills index lists all active skills.
7. Update `NEWS.md`/`NES.md` with features, bug fixes, breaking changes, docs.
