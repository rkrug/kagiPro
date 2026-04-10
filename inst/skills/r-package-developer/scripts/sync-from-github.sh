#!/usr/bin/env bash
set -euo pipefail

# Sync r-package-developer skill directly from a GitHub repository.
# No local intermediate canonical folder required.
#
# Usage:
#   bash inst/skills/r-package-developer/scripts/sync-from-github.sh
#
# Optional configuration:
#   RPKG_SKILL_GH_REPO="owner/repo"                  (default: rkrug/r-package-developer-skill)
#   RPKG_SKILL_GH_REF="main"                         (default: main)
#   RPKG_SKILL_GH_PATH="inst/skills/r-package-developer" (default shown)
#
# Example:
#   RPKG_SKILL_GH_REPO="org/r-package-developer-skill" \
#   RPKG_SKILL_GH_REF="v0.1.2" \
#   bash inst/skills/r-package-developer/scripts/sync-from-github.sh

show_help() {
  cat <<'EOF'
sync-from-github.sh
-------------------
Syncs inst/skills/r-package-developer from a GitHub repository/archive.

Usage:
  bash inst/skills/r-package-developer/scripts/sync-from-github.sh
  bash inst/skills/r-package-developer/scripts/sync-from-github.sh --help

Environment variables:
  RPKG_SKILL_GH_REPO   GitHub repo in owner/name format
                       default: rkrug/r-package-developer-skill
  RPKG_SKILL_GH_REF    Branch, tag, or commit ref to download
                       default: main
  RPKG_SKILL_GH_PATH   Path in the source repo containing SKILL.md + references/
                       default: inst/skills/r-package-developer

Examples:
  bash inst/skills/r-package-developer/scripts/sync-from-github.sh

  RPKG_SKILL_GH_REPO="org/r-package-developer-skill" \
  RPKG_SKILL_GH_REF="v0.1.2" \
  bash inst/skills/r-package-developer/scripts/sync-from-github.sh

Exit codes:
  0  success
  1  source layout/path invalid, download failed, or sync failed
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
target_dir="${repo_root}/inst/skills/r-package-developer"

gh_repo="${RPKG_SKILL_GH_REPO:-rkrug/r-package-developer-skill}"
gh_ref="${RPKG_SKILL_GH_REF:-main}"
gh_path="${RPKG_SKILL_GH_PATH:-inst/skills/r-package-developer}"

archive_url="https://codeload.github.com/${gh_repo}/tar.gz/${gh_ref}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "[skill-sync] Downloading ${archive_url}"
curl -fsSL "${archive_url}" -o "${tmp_dir}/source.tar.gz"

tar -xzf "${tmp_dir}/source.tar.gz" -C "${tmp_dir}"
root_dir="$(tar -tzf "${tmp_dir}/source.tar.gz" | head -n1 | cut -d/ -f1)"
source_dir="${tmp_dir}/${root_dir}/${gh_path}"

if [[ ! -f "${source_dir}/SKILL.md" || ! -d "${source_dir}/references" ]]; then
  echo "[skill-sync] Source layout invalid in downloaded archive: ${source_dir}" >&2
  echo "[skill-sync] Expected SKILL.md and references/ under path ${gh_path}" >&2
  exit 1
fi

mkdir -p "${target_dir}/references"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude '.DS_Store' \
    --exclude '*.swp' \
    --exclude '*.tmp' \
    "${source_dir}/" "${target_dir}/"
else
  rm -rf "${target_dir:?}/"*
  cp -R "${source_dir}/." "${target_dir}/"
fi

echo "[skill-sync] Synced r-package-developer skill"
echo "[skill-sync] Source: ${gh_repo}@${gh_ref}:${gh_path}"
echo "[skill-sync] Target: ${target_dir}"
