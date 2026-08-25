#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
site="$repo_dir/site"

grep -Eq 'See what changed\. Reclaim space safely\.' "$site/index.html"
grep -Eq 'Toolbox-2\.0\.0\.dmg' "$site/index.html"
grep -Eq 'No telemetry' "$site/index.html"
grep -Eq 'Trash' "$site/index.html"
grep -Eq '<main' "$site/index.html"
grep -Eq 'aria-label|aria-labelledby' "$site/index.html"
test -f "$site/privacy.html"
test "$(find "$site/assets" -type f | wc -l | tr -d ' ')" -ge 5

for page in "$site/index.html" "$site/privacy.html"; do
  grep -Eq '<meta name="viewport"' "$page"
  grep -Eq '<title>' "$page"
done

bash "$repo_dir/tests/unsigned_beta_release_test.sh"

echo "PASS: Toolbox site content and accessibility contract"
