#!/usr/bin/env bash
set -euo pipefail

echo "[ai-docs] Checking required machine-readable artifacts..."
required=(
  "llms.txt"
  "llms-full.txt"
  "pkgdown/extra/llms.txt"
  "pkgdown/extra/llms-full.txt"
  "vignettes/api-contracts.qmd"
  "vignettes/agent-quick-index.qmd"
)
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "[ai-docs] Missing required file: $f" >&2
    exit 1
  fi
done

echo "[ai-docs] Checking llms mirrors..."
cmp -s llms.txt pkgdown/extra/llms.txt || {
  echo "[ai-docs] pkgdown/extra/llms.txt is out of sync with llms.txt" >&2
  exit 1
}
cmp -s llms-full.txt pkgdown/extra/llms-full.txt || {
  echo "[ai-docs] pkgdown/extra/llms-full.txt is out of sync with llms-full.txt" >&2
  exit 1
}

echo "[ai-docs] Checking pkgdown navigation/index links..."
grep -q "href: llms.txt" _pkgdown.yml || {
  echo "[ai-docs] _pkgdown.yml is missing llms.txt navbar link" >&2
  exit 1
}
grep -q "href: llms-full.txt" _pkgdown.yml || {
  echo "[ai-docs] _pkgdown.yml is missing llms-full.txt navbar link" >&2
  exit 1
}
grep -q -- "- api-contracts" _pkgdown.yml || {
  echo "[ai-docs] _pkgdown.yml is missing api-contracts article entry" >&2
  exit 1
}
grep -q -- "- agent-quick-index" _pkgdown.yml || {
  echo "[ai-docs] _pkgdown.yml is missing agent-quick-index article entry" >&2
  exit 1
}

echo "[ai-docs] Checking README pointers..."
grep -q "llms.txt" README.md || {
  echo "[ai-docs] README.md does not reference llms.txt" >&2
  exit 1
}
grep -q "llms-full.txt" README.md || {
  echo "[ai-docs] README.md does not reference llms-full.txt" >&2
  exit 1
}

echo "[ai-docs] All AI-doc checks passed."
