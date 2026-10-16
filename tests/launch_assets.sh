#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test -f "$repo_dir/docs/launch/macinity-3.1.0.md"
grep -Fq 'Macinity 3.1.0' "$repo_dir/docs/launch/macinity-3.1.0.md"
grep -Fq 'not notarized' "$repo_dir/docs/launch/macinity-3.1.0.md"
echo "PASS: Macinity release notes and trust disclosure"
