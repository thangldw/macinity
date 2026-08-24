#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
fixture_sha="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
test_dir="$(mktemp -d -t toolbox-cask-test)"
trap 'rm -rf "$test_dir"' EXIT
output="$test_dir/toolbox.rb"

TOOLBOX_CASK_OUTPUT="$output" "$repo_dir/scripts/render_cask.sh" 2.0.0 "$fixture_sha"
grep -Fq 'version "2.0.0"' "$output"
grep -Fq "sha256 \"$fixture_sha\"" "$output"
grep -Fq 'releases/download/v#{version}/Toolbox-#{version}.dmg' "$output"
grep -Fq 'app "Toolbox.app"' "$output"

if TOOLBOX_CASK_OUTPUT="$output" "$repo_dir/scripts/render_cask.sh" v2.0 invalid >/dev/null 2>&1; then
  echo "Malformed cask input was accepted" >&2
  exit 1
fi

echo "PASS: deterministic Homebrew cask rendering"
