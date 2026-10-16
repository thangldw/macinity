#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$project_dir/dist/Macinity.app"
dmg="$project_dir/dist/Macinity-3.1.0.dmg"
checksum="$dmg.sha256"

test -d "$app"
"$project_dir/Tests/Distribution/release_contract.sh" "$app"

staging_dir="$(mktemp -d -t toolbox-dmg)"
trap 'rm -rf "$staging_dir"' EXIT

ditto "$app" "$staging_dir/Macinity.app"
cp "$project_dir/Resources/Open Macinity - First Launch.html" "$staging_dir/"
ln -s /Applications "$staging_dir/Applications"
rm -f "$dmg" "$checksum"
hdiutil create \
  -volname "Macinity" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg"

(cd "$(dirname "$dmg")" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$checksum")")
echo "Created: $dmg"
echo "Checksum: $checksum"
