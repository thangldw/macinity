#!/bin/bash
set -euo pipefail

version="${1:?version required}"
sha256="${2:?sha256 required}"
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
output="${TOOLBOX_CASK_OUTPUT:-$repo_dir/Casks/toolbox.rb}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "version must use MAJOR.MINOR.PATCH" >&2
  exit 64
fi
if [[ ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "sha256 must contain exactly 64 lowercase hexadecimal characters" >&2
  exit 64
fi
mkdir -p "$(dirname "$output")"

{
  printf 'cask "toolbox" do\n'
  printf '  version "%s"\n' "$version"
  printf '  sha256 "%s"\n' "$sha256"
  printf '  url "https://github.com/thangldw/toolbox/releases/download/v#{version}/Toolbox-#{version}.dmg"\n'
  printf '  name "Toolbox"\n'
  printf '  desc "See what changed and reclaim developer storage safely"\n'
  printf '  homepage "https://thangldw.github.io/toolbox/"\n'
  printf '  app "Toolbox.app"\n'
  printf 'end\n'
} > "$output"

echo "Created: $output"
