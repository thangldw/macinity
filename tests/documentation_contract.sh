#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
default_repo_dir="$(cd "$script_dir/.." && pwd)"
repo_dir="${1:-$default_repo_dir}"
repo_dir="$(cd "$repo_dir" && pwd)"
cd "$repo_dir"

markdown_files=()
while IFS= read -r file; do
  markdown_files+=("$file")
done < <(git ls-files '*.md')
python3 "$script_dir/check_docs.py" "${markdown_files[@]}"

if [[ "$repo_dir" == "$default_repo_dir" ]]; then
  python3 "$script_dir/checker_regressions.py"
fi

require_text() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    echo "$file: missing required text: $expected" >&2
    exit 1
  fi
}

require_text README.md 'v2.0.0'
require_text README.md 'not notarized'
require_text README.md 'Open Anyway'
require_text README.md 'docs/ARCHITECTURE.md'
require_text SECURITY.md 'ad-hoc-signed'
require_text SECURITY.md 'unnotarized exception'
require_text docs/OPERATIONS-RELEASE.md 'c60367d84cdf06a93fe95c65e2ebe110ab3f70bb'
require_text docs/release-evidence/toolbox-2.0.0.md 'ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba'
require_text docs/ARCHITECTURE.md 'docs/diagrams/toolbox-architecture.html'
require_text docs/OPERATIONS.md 'install-trace-sequence.html'
require_text docs/OPERATIONS.md 'review-recovery-state.html'

historical_records=(
  docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md
  docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md
  docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md
  docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md
)
for record in "${historical_records[@]}"; do
  require_text "$record" 'Status: completed'
  if grep -nE '^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+\[ \]' "$record"; then
    echo "$record: unchecked checklist item" >&2
    exit 1
  fi
done

is_historical_claim_record() {
  case "$1" in
    CHANGELOG.md | \
      docs/launch/product-hunt.md | \
      docs/launch/toolbox-2.0.0-beta.1.md | \
      docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md)
      return 0
      ;;
  esac
  return 1
}

stale_current_claims='Public launch remains blocked|no 2[.]0 DMG is published|stable release will be Apple-notarized|v2[.]0[.]0 remains unpublished'
current_plan='docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'
allowed_stale_scan="if rg -n 'toolbox-2\\.0-beta\\.md|Public launch remains blocked|no 2\\.0 DMG is published' . --glob '!docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'; then exit 1; fi"
for file in "${markdown_files[@]}"; do
  if is_historical_claim_record "$file"; then
    continue
  fi
  if [[ "$file" == "$current_plan" ]]; then
    while IFS= read -r occurrence; do
      if [[ "${occurrence#*:}" != "$allowed_stale_scan" ]]; then
        echo "$file: stale authoritative current claim" >&2
        exit 1
      fi
    done < <(grep -niE "$stale_current_claims" "$file" || true)
    continue
  fi
  if grep -niE "$stale_current_claims" "$file"; then
    echo "$file: stale authoritative current claim" >&2
    exit 1
  fi
done

removed_beta_path='docs/release-evidence/toolbox-2.0-beta.md'
for file in "${markdown_files[@]}"; do
  if [[ "$file" == "$current_plan" ]]; then
    continue
  fi
  if grep -nF "$removed_beta_path" "$file"; then
    echo "$file: removed beta evidence path" >&2
    exit 1
  fi
done

while IFS= read -r occurrence; do
  if ! printf '%s\n' "$occurrence" | grep -Eq '^[0-9]+:- Rename: docs/release-evidence/toolbox-2[.]0-beta[.]md to docs/release-evidence/toolbox-2[.]0[.]0[.]md$'; then
    echo "$current_plan: removed beta evidence path is allowed only in the documented rename instruction" >&2
    exit 1
  fi
done < <(grep -nF "$removed_beta_path" "$current_plan" || true)

echo "PASS: Toolbox documentation contract"
