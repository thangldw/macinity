#!/bin/bash
set -euo pipefail

repo="thangldw/toolbox"
asset_regex='^Toolbox-[0-9]+\.[0-9]+\.[0-9]+\.dmg$'
read_stdin=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stdin)
      read_stdin=1
      shift
      ;;
    --asset-regex)
      asset_regex="${2:?--asset-regex requires a value}"
      shift 2
      ;;
    --repo)
      repo="${2:?--repo requires owner/name}"
      shift 2
      ;;
    *)
      echo "usage: $0 [--stdin] [--asset-regex REGEX] [--repo OWNER/NAME]" >&2
      exit 64
      ;;
  esac
done

if [[ "$read_stdin" -eq 1 ]]; then
  payload="$(command cat)"
else
  command -v gh >/dev/null
  command -v jq >/dev/null
  payload="$(gh api --paginate "repos/$repo/releases?per_page=100" | jq -s 'add')"
fi

printf 'MONTH\tDOWNLOAD_EVENTS\n'
printf '%s' "$payload" | jq -r --arg regex "$asset_regex" '
  def releases:
    if type == "array" and length > 0 and (.[0] | type) == "array" then add else . end;

  releases
  | [
      .[]
      | select(.published_at != null)
      | . as $release
      | {
          month: $release.published_at[0:7],
          count: ([
            $release.assets[]?
            | select(.name | test($regex))
            | (.download_count // 0)
          ] | add // 0)
        }
      | select(.count > 0)
    ]
  | group_by(.month)
  | map({month: .[0].month, count: (map(.count) | add)})
  | sort_by(.month)
  | . as $rows
  | ($rows[] | "\(.month)\t\(.count)"),
    "TOTAL\t\($rows | map(.count) | add // 0)"
'
printf 'NOTE\tdownload events, not unique users\n'
