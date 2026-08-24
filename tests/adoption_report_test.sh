#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
fixture='[
  {"published_at":"2026-09-01T00:00:00Z","assets":[
    {"name":"Toolbox-2.0.0.dmg","download_count":7},
    {"name":"Toolbox-2.0.0.dmg.sha256","download_count":2}
  ]},
  {"published_at":"2026-09-18T00:00:00Z","assets":[
    {"name":"Toolbox-2.0.1.dmg","download_count":5}
  ]},
  {"published_at":"2026-10-02T00:00:00Z","assets":[
    {"name":"legacy.zip","download_count":99}
  ]}
]'

actual="$(printf '%s' "$fixture" | "$repo_dir/scripts/adoption_report.sh" --stdin --asset-regex '^Toolbox-.*\.dmg$')"
printf '%s\n' "$actual" | grep -Eq '^2026-09[[:space:]]+12$'
printf '%s\n' "$actual" | grep -Eq '^TOTAL[[:space:]]+12$'
printf '%s\n' "$actual" | grep -Fq 'download events, not unique users'

echo "PASS: adoption report counts DMGs only"
