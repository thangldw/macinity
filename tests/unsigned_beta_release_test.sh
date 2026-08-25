#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
tag="v2.0.0-beta.1"
dmg_url="https://github.com/thangldw/toolbox/releases/download/$tag/Toolbox-2.0.0.dmg"
checksum_url="$dmg_url.sha256"
notes="$repo_dir/docs/launch/toolbox-2.0.0-beta.1.md"

grep -Fq "$dmg_url" "$repo_dir/site/index.html"
grep -Fq "$checksum_url" "$repo_dir/site/index.html"
if grep -Fq 'releases/download/v2.0.0/Toolbox-2.0.0.dmg' "$repo_dir/site/index.html"; then
  echo "Stable download URL must not be advertised before notarized v2.0.0 exists" >&2
  exit 1
fi

for file in "$repo_dir/site/index.html" "$repo_dir/README.md" "$notes"; do
  grep -Fq 'Open Anyway' "$file"
done

grep -Fq 'Unnotarized beta' "$repo_dir/site/index.html"
grep -Fq 'not notarized' "$repo_dir/README.md"
grep -Fq 'chưa notarize' "$repo_dir/README.md"
grep -Fq 'notarize されていません' "$repo_dir/README.md"
grep -Fq "$tag" "$repo_dir/CHANGELOG.md"
grep -Fq "$tag" "$repo_dir/docs/OPERATIONS-RELEASE.md"
grep -Fq 'GitHub pre-release' "$notes"

if grep -ERn 'xattr .*quarantine|spctl .*disable' \
  "$repo_dir/README.md" "$repo_dir/site" "$notes"; then
  echo "Unsigned beta instructions must not disable or strip Gatekeeper" >&2
  exit 1
fi

echo "PASS: unsigned beta download and Gatekeeper disclosure contract"
