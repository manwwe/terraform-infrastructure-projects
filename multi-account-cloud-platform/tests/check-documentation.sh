#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$project_root"

if rg -n --glob '*.md' '(TBD|TODO|FIXME)' .; then
  echo "Documentation contains unfinished placeholders."
  exit 1
fi

required_files=(
  "README.md"
  "docs/architecture.md"
  "docs/deployment-workflow.md"
  "docs/naming-and-tagging.md"
  "docs/security-and-operations.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -s "$file" ]]; then
    echo "Missing or empty documentation file: $file"
    exit 1
  fi
done

echo "Documentation checks passed."
