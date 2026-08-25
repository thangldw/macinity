#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_dir"

markdown_files=()
while IFS= read -r file; do
  markdown_files+=("$file")
done < <(git ls-files '*.md')
python3 tests/check_docs.py "${markdown_files[@]}"

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
  if grep -nE '^[[:space:]]*(?:[-*+]|[0-9]+[.)])[[:space:]]+\[ \]' "$record"; then
    echo "$record: unchecked checklist item" >&2
    exit 1
  fi
done

echo "PASS: Toolbox documentation contract"
