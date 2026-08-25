#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
tag="v2.0.0"
dmg_url="https://github.com/thangldw/toolbox/releases/download/$tag/Toolbox-2.0.0.dmg"
checksum_url="$dmg_url.sha256"
notes="$repo_dir/docs/launch/toolbox-2.0.0.md"
guide="$repo_dir/apps/toolbox/Resources/Open Toolbox - First Launch.html"

grep -Fq "$dmg_url" "$repo_dir/site/index.html"
grep -Fq "$checksum_url" "$repo_dir/site/index.html"
grep -Fq '<section id="install"' "$repo_dir/site/index.html"

for file in "$repo_dir/site/index.html" "$repo_dir/README.md" "$notes" "$guide"; do
  grep -Fq 'Open Anyway' "$file"
done

grep -Fq 'Unnotarized release' "$repo_dir/site/index.html"
grep -Fq 'not notarized' "$repo_dir/README.md"
grep -Fq 'chưa notarize' "$repo_dir/README.md"
grep -Fq 'notarize されていません' "$repo_dir/README.md"
grep -Fq "$tag" "$repo_dir/CHANGELOG.md"
grep -Fq "$tag" "$repo_dir/docs/OPERATIONS-RELEASE.md"
grep -Fq 'GitHub release' "$notes"
grep -Fq 'The explicit exception for `v2.0.0`' "$repo_dir/docs/OPERATIONS.md"
grep -Fq '`v2.0.0` is an explicit ad-hoc-signed, unnotarized exception' "$repo_dir/SECURITY.md"
grep -Fq 'exact ad-hoc-signed, unnotarized `v2.0.0` public release' "$repo_dir/site/assets/demo-script.md"

if grep -ERni 'public beta|unnotarized beta|download beta' \
  "$repo_dir/site/index.html" "$repo_dir/README.md" "$notes"; then
  echo "Current user-facing install paths must identify v2.0.0 as a stable release" >&2
  exit 1
fi

if grep -ERn 'xattr .*quarantine|spctl .*disable' \
  "$repo_dir/README.md" "$repo_dir/site" "$notes" "$guide"; then
  echo "Unsigned release instructions must not disable or strip Gatekeeper" >&2
  exit 1
fi

echo "PASS: unsigned stable download and Gatekeeper disclosure contract"
