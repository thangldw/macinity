#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$project_dir/dist/Toolbox.app"
dmg="$project_dir/dist/Toolbox-2.0.0.dmg"
checksum="$dmg.sha256"

test -d "$app"
"$project_dir/Tests/Distribution/release_contract.sh" "$app"

staging_dir="$(mktemp -d -t toolbox-dmg)"
trap 'rm -rf "$staging_dir"' EXIT

ditto "$app" "$staging_dir/Toolbox.app"
cp "$project_dir/Resources/Open Toolbox - First Launch.html" "$staging_dir/"
ln -s /Applications "$staging_dir/Applications"
rm -f "$dmg" "$checksum"
hdiutil create \
  -volname "Toolbox" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg"

(cd "$(dirname "$dmg")" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$checksum")")
echo "Created: $dmg"
echo "Checksum: $checksum"
