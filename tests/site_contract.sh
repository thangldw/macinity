#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
site="$repo_dir/site"

rg -q 'See what changed\. Reclaim space safely\.' "$site/index.html"
rg -q 'Toolbox-2\.0\.0\.dmg' "$site/index.html"
rg -q 'No telemetry' "$site/index.html"
rg -q 'Trash' "$site/index.html"
rg -q '<main' "$site/index.html"
rg -q 'aria-label|aria-labelledby' "$site/index.html"
test -f "$site/privacy.html"
test "$(find "$site/assets" -type f | wc -l | tr -d ' ')" -ge 5

for page in "$site/index.html" "$site/privacy.html"; do
  rg -q '<meta name="viewport"' "$page"
  rg -q '<title>' "$page"
done

echo "PASS: Toolbox site content and accessibility contract"
