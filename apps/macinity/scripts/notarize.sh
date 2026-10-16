#!/bin/bash
set -euo pipefail

: "${MACINITY_CODESIGN_IDENTITY:?Set Developer ID Application identity}"
: "${MACINITY_NOTARY_PROFILE:?Set notarytool keychain profile}"

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$project_dir/dist/Macinity.app"
archive="$project_dir/dist/Macinity-3.1.0-app.zip"
dmg="$project_dir/dist/Macinity-3.1.0.dmg"
checksum="$dmg.sha256"

test -d "$app"
"$project_dir/Tests/Distribution/release_contract.sh" "$app"
rm -f "$archive"
trap 'rm -f "$archive"' EXIT

codesign \
  --force \
  --deep \
  --options runtime \
  --timestamp \
  --sign "$MACINITY_CODESIGN_IDENTITY" \
  "$app"
codesign --verify --deep --strict --verbose=2 "$app"

ditto -c -k --keepParent "$app" "$archive"
xcrun notarytool submit "$archive" \
  --keychain-profile "$MACINITY_NOTARY_PROFILE" \
  --wait
xcrun stapler staple "$app"
xcrun stapler validate "$app"

"$project_dir/scripts/build_dmg.sh"
xcrun notarytool submit "$dmg" \
  --keychain-profile "$MACINITY_NOTARY_PROFILE" \
  --wait
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
(cd "$(dirname "$dmg")" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$checksum")")

"$project_dir/scripts/verify_release.sh"
echo "PASS: signed and notarized Macinity 3.1.0"
