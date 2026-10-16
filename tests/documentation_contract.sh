#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
default_repo_dir="$(cd "$script_dir/.." && pwd)"
repo_dir="${1:-$default_repo_dir}"
cd "$repo_dir"
markdown_files=()
while IFS= read -r file; do
  [[ -f "$file" ]] && markdown_files+=("$file")
done < <(git ls-files --cached --others --exclude-standard '*.md')
python3 "$script_dir/check_docs.py" "${markdown_files[@]}"
bash "$script_dir/repository_hygiene.sh" "$repo_dir"

stale_current_claims='Public launch remains blocked|no 2[.]0 DMG is published|stable release will be Apple-notarized|v2[.]0[.]0 remains unpublished'
for file in "${markdown_files[@]}"; do
  if [[ "$file" != CHANGELOG.md ]] && grep -niE "$stale_current_claims" "$file"; then
    echo "$file: stale authoritative current claim" >&2
    exit 1
  fi
  if grep -nF 'docs/release-evidence/toolbox-2.0-beta.md' "$file"; then
    echo "$file: removed beta evidence path" >&2
    exit 1
  fi
done

if [[ "$repo_dir" == "$default_repo_dir" ]]; then
  python3 "$script_dir/checker_regressions.py"
fi
echo "PASS: Macinity documentation contract"
