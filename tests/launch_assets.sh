#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test -f "$repo_dir/docs/launch/orven-3.0.0.md"
grep -Fq 'Orven 3.0.0' "$repo_dir/docs/launch/orven-3.0.0.md"
grep -Fq 'not notarized' "$repo_dir/docs/launch/orven-3.0.0.md"
echo "PASS: Orven release notes and trust disclosure"
