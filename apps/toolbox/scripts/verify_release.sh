#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$project_dir/dist/Toolbox.app"
allow_adhoc=0

if [[ "${1:-}" == "--allow-adhoc" ]]; then
  allow_adhoc=1
elif [[ $# -ne 0 ]]; then
  echo "usage: $0 [--allow-adhoc]" >&2
  exit 64
fi

"$project_dir/Tests/Distribution/release_contract.sh" "$app"

dmg="$project_dir/dist/Toolbox-2.0.0.dmg"
checksum="$dmg.sha256"
if [[ -f "$dmg" || -f "$checksum" ]]; then
  test -f "$dmg"
  test -f "$checksum"
  (cd "$(dirname "$dmg")" && shasum -a 256 -c "$(basename "$checksum")")
fi

if [[ "$allow_adhoc" -eq 1 ]]; then
  echo "SKIP: notarization and Gatekeeper checks (explicit --allow-adhoc)"
  exit 0
fi

xcrun stapler validate "$app"
test -f "$dmg"
xcrun stapler validate "$dmg"
spctl --assess --type execute --verbose=4 "$app"

echo "PASS: notarized Toolbox release"
