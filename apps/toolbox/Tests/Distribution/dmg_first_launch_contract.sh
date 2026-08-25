#!/bin/bash
set -euo pipefail

dmg="${1:?Toolbox DMG path required}"
test -f "$dmg"

mount_dir="$(mktemp -d -t toolbox-first-launch-contract)"
mounted=0
cleanup_mount() {
  if [[ "$mounted" -eq 1 ]]; then
    hdiutil detach "$mount_dir" -quiet || true
  fi
  rm -rf "$mount_dir"
}
trap cleanup_mount EXIT

hdiutil attach "$dmg" -nobrowse -readonly -mountpoint "$mount_dir" -quiet
mounted=1

guide="$mount_dir/Open Toolbox - First Launch.html"
test -d "$mount_dir/Toolbox.app"
test -L "$mount_dir/Applications"
test "$(readlink "$mount_dir/Applications")" = "/Applications"
test -f "$guide"
grep -Fq 'Privacy &amp; Security' "$guide"
grep -Fq 'Open Anyway' "$guide"
if grep -En 'xattr .*quarantine|spctl .*disable' "$guide"; then
  echo "First-launch guide must not weaken Gatekeeper" >&2
  exit 1
fi

echo "PASS: DMG contains safe first-launch guidance"
