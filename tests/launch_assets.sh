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

grep -Eq '^Name: Toolbox$' "$copy"
grep -Eq '^Tagline: Understand Mac changes before you clean them up$' "$copy"
grep -Eq '^Description: .*Not Apple-notarized; first launch requires Open Anyway\.$' "$copy"
grep -Eq '^First comment: .*Toolbox 2\.0 is ad-hoc signed and not notarized by Apple' "$copy"
grep -Eq '^Topics: Developer Tools, Mac, Open Source$' "$copy"
grep -Eq '^Pricing: Free$' "$copy"
if grep -Eqi 'upvote|vote for' "$copy"; then
  echo "Launch copy must request workflow feedback, not votes" >&2
  exit 1
fi
test -f "$assets/demo-script.md"
grep -Eq '^Status: SCHEDULED — August 26, 2026 at 12:01 AM PDT\.$' "$copy"
grep -Eq '^Launch URL: https://www\.producthunt\.com/products/toolbox-14\?launch=toolbox-14$' "$copy"

echo "PASS: Product Hunt copy and asset contracts"
