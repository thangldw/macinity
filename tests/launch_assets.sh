#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
assets="$repo_dir/site/assets"
copy="$repo_dir/docs/launch/product-hunt.md"

test "$(sips -g pixelWidth "$assets/product-hunt-thumbnail.png" | awk '/pixelWidth/ {print $2}')" = "512"
test "$(sips -g pixelHeight "$assets/product-hunt-thumbnail.png" | awk '/pixelHeight/ {print $2}')" = "512"
for image in home projects trace recovery; do
  file="$assets/product-hunt-$image.png"
  test "$(sips -g pixelWidth "$file" | awk '/pixelWidth/ {print $2}')" = "1270"
  test "$(sips -g pixelHeight "$file" | awk '/pixelHeight/ {print $2}')" = "760"
done

rg -q '^Name: Toolbox$' "$copy"
rg -q '^Tagline: See what changed\. Reclaim developer storage safely\.$' "$copy"
rg -q '^Description:' "$copy"
rg -q '^First comment:' "$copy"
rg -q '^Topics: Developer Tools, Mac, Open Source$' "$copy"
rg -q '^Pricing: Free$' "$copy"
if rg -qi 'upvote|vote for' "$copy"; then
  echo "Launch copy must request workflow feedback, not votes" >&2
  exit 1
fi
test -f "$assets/demo-script.md"

echo "PASS: Product Hunt copy and asset contracts"
