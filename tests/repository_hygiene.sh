#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="${1:-$(cd "$script_dir/.." && pwd)}"

failures=0

while IFS= read -r tracked_file; do
  case "$tracked_file" in
    docs/superpowers/* | \
      docs/design-concepts/* | \
      docs/design-evidence/* | \
      docs/launch/*beta* | \
      *.dmg | \
      *.zip | \
      *.tmp | \
      *.bak | \
      */.DS_Store | \
      */.build/* | \
      */DerivedData/*)
      printf '%s\n' "obsolete tracked artifact: $tracked_file" >&2
      failures=$((failures + 1))
      ;;
  esac
done < <(git -C "$repo_dir" ls-files)

if (( failures > 0 )); then
  printf 'FAIL: %d repository hygiene violation(s)\n' "$failures" >&2
  exit 1
fi

printf '%s\n' 'PASS: repository hygiene contract'
