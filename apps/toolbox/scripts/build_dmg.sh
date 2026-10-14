#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$project_dir/dist/Orven.app"
dmg="$project_dir/dist/Orven-3.0.0.dmg"
checksum="$dmg.sha256"

test -d "$app"
"$project_dir/Tests/Distribution/release_contract.sh" "$app"

staging_dir="$(mktemp -d -t toolbox-dmg)"
trap 'rm -rf "$staging_dir"' EXIT

ditto "$app" "$staging_dir/Orven.app"
cp "$project_dir/Resources/Open Orven - First Launch.html" "$staging_dir/"
ln -s /Applications "$staging_dir/Applications"
rm -f "$dmg" "$checksum"
hdiutil create \
  -volname "Orven" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg"

(cd "$(dirname "$dmg")" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$checksum")")
echo "Created: $dmg"
echo "Checksum: $checksum"
