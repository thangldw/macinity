#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
default_repo_dir="$(cd "$script_dir/.." && pwd)"
repo_dir="${1:-$default_repo_dir}"
repo_dir="$(cd "$repo_dir" && pwd)"
cd "$repo_dir"

markdown_files=()
while IFS= read -r file; do
  markdown_files+=("$file")
done < <(git ls-files '*.md')
python3 "$script_dir/check_docs.py" "${markdown_files[@]}"

if [[ "$repo_dir" == "$default_repo_dir" ]]; then
  python3 "$script_dir/checker_regressions.py"
fi

require_text() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    echo "$file: missing required text: $expected" >&2
    exit 1
  fi
}

require_text README.md 'v2.0.0'
require_text README.md 'not notarized'
require_text README.md 'Open Anyway'
require_text README.md 'docs/ARCHITECTURE.md'
require_text SECURITY.md 'ad-hoc-signed'
require_text SECURITY.md 'unnotarized exception'
require_text docs/OPERATIONS-RELEASE.md 'c60367d84cdf06a93fe95c65e2ebe110ab3f70bb'
require_text docs/release-evidence/toolbox-2.0.0.md 'ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba'
require_text docs/ARCHITECTURE.md 'docs/diagrams/toolbox-architecture.html'
require_text docs/OPERATIONS.md 'install-trace-sequence.html'
require_text docs/OPERATIONS.md 'review-recovery-state.html'

historical_records=(
  docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md
  docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md
  docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md
  docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md
)
for record in "${historical_records[@]}"; do
  require_text "$record" 'Status: completed'
  if grep -nE '^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+\[ \]' "$record"; then
    echo "$record: unchecked checklist item" >&2
    exit 1
  fi
done

is_historical_claim_record() {
  case "$1" in
    CHANGELOG.md | \
      docs/launch/toolbox-2.0.0-beta.1.md | \
      docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md)
      return 0
      ;;
  esac
  return 1
}

stale_current_claims='Public launch remains blocked|no 2[.]0 DMG is published|stable release will be Apple-notarized|v2[.]0[.]0 remains unpublished'
current_plan='docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'
product_hunt_record='docs/launch/product-hunt.md'
allowed_stale_scan="if rg -n 'toolbox-2\\.0-beta\\.md|Public launch remains blocked|no 2\\.0 DMG is published' . --glob '!docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'; then exit 1; fi"
for file in "${markdown_files[@]}"; do
  if is_historical_claim_record "$file"; then
    continue
  fi
  if [[ "$file" == "$current_plan" ]]; then
    while IFS= read -r occurrence; do
      if [[ "${occurrence#*:}" != "$allowed_stale_scan" ]]; then
        echo "$file: stale authoritative current claim" >&2
        exit 1
      fi
    done < <(grep -niE "$stale_current_claims" "$file" || true)
    continue
  fi
  if grep -niE "$stale_current_claims" "$file"; then
    echo "$file: stale authoritative current claim" >&2
    exit 1
  fi
done

# Markdown backticks are literal parts of the exact allowed lines.
# shellcheck disable=SC2016
allowed_product_hunt_stale_copy_lines=(
  'Description: The visible description said Toolbox is free and open source; traces installer changes; finds known rebuildable output only in user-chosen folders; records Trash-backed cleanup; and runs locally without an account, telemetry, a privileged helper, or automatic deletion. It still called the current build a public beta, which conflicts with the stable GitHub release identity recorded below. Not Apple-notarized; first launch requires Open Anyway.'
  'First comment: The visible maker comment still called the release a first public beta. Its workflow and trust content remained accurate: Install Trace compares filesystem metadata around the normal installer flow; Projects finds known rebuildable output only inside selected roots; Recovery retains evidence for Trash-backed cleanup; processing is local; the build is ad-hoc signed and not notarized; the safe exception is Open Anyway; checksum and source are available. It asks what evidence developers need before cleaning a path, which confirmation or recovery step is unclear, and which project artifact Toolbox should recognize next; feedback must omit private paths and files. The stable-aligned repository copy is: Toolbox 2.0 is a stable product release, but it is ad-hoc signed and not notarized by Apple. Do not disable Gatekeeper or remove quarantine attributes. Report reproducible issues at https://github.com/thangldw/toolbox/issues without private paths or files.'
  'The words “public beta” and “first public beta” are retained here only as observed stale Product Hunt copy. They do not define the current release channel. The higher-authority GitHub record shows `v2.0.0`, published `2026-08-25T12:33:04Z`, non-draft, non-prerelease, from `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.'
  'Description: Description hiển thị nói Toolbox miễn phí và mã nguồn mở; trace thay đổi của installer; chỉ tìm known rebuildable output trong folder người dùng chọn; ghi nhận cleanup qua Trash; và chạy local không account, telemetry, privileged helper hoặc automatic deletion. Description vẫn gọi build hiện tại là public beta, mâu thuẫn với stable GitHub release identity ghi bên dưới. Chưa Apple-notarized; lần mở đầu yêu cầu Open Anyway.'
  'First comment: Maker comment hiển thị vẫn gọi release là first public beta. Nội dung workflow và trust vẫn chính xác: Install Trace so sánh filesystem metadata quanh luồng installer bình thường; Projects chỉ tìm known rebuildable output trong selected root; Recovery giữ evidence cho cleanup qua Trash; xử lý ở local; build ký ad-hoc và chưa notarize; exception an toàn là Open Anyway; checksum và source có sẵn. Comment hỏi developer cần evidence nào trước khi clean một path, confirmation hoặc recovery step nào chưa rõ và Toolbox nên nhận diện project artifact nào tiếp theo; feedback phải bỏ private path và file. Stable-aligned repository copy là: Toolbox 2.0 is a stable product release, but it is ad-hoc signed and not notarized by Apple. Do not disable Gatekeeper or remove quarantine attributes. Report reproducible issues at https://github.com/thangldw/toolbox/issues without private paths or files.'
  'Các từ “public beta” và “first public beta” chỉ được giữ ở đây như stale Product Hunt copy đã quan sát. Chúng không định nghĩa current release channel. GitHub record có authority cao hơn cho thấy `v2.0.0`, publish lúc `2026-08-25T12:33:04Z`, non-draft, non-prerelease, từ `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.'
  'Description: 表示 description は、Toolbox が free/open source であり、installer change を trace し、user-selected folder 内だけで known rebuildable output を検出し、Trash-backed cleanup を記録し、account、telemetry、privileged helper、automatic deletion なしで local 実行することを説明していました。Current build を public beta と呼ぶ部分は、下記 stable GitHub release identity と矛盾します。Apple-notarized ではなく、first launch には Open Anyway が必要です。'
  'First comment: 表示 maker comment は release を first public beta と呼んでいました。Workflow/trust content は正確なままです。Install Trace は通常 installer flow の前後で filesystem metadata を比較し、Projects は selected root 内の known rebuildable output だけを検出し、Recovery は Trash-backed cleanup の evidence を保持します。Processing は local で、build は ad-hoc signed/not notarized、安全な exception は Open Anyway、checksum/source は公開済みです。Cleanup 前に developer が必要とする evidence、不明瞭な confirmation/recovery step、次に認識すべき project artifact を質問し、feedback から private path/file を除くよう求めています。Stable-aligned repository copy は次です: Toolbox 2.0 is a stable product release, but it is ad-hoc signed and not notarized by Apple. Do not disable Gatekeeper or remove quarantine attributes. Report reproducible issues at https://github.com/thangldw/toolbox/issues without private paths or files.'
  '“public beta” と “first public beta” は、観測した stale Product Hunt copy としてのみ保持します。Current release channel を定義しません。より高 authority の GitHub record は、`v2.0.0` が `2026-08-25T12:33:04Z` に publish され、non-draft、non-prerelease、source は `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` であることを示します。'
)

while IFS= read -r occurrence; do
  claim="${occurrence#*:}"
  allowed=false
  for allowed_claim in "${allowed_product_hunt_stale_copy_lines[@]}"; do
    if [[ "$claim" == "$allowed_claim" ]]; then
      allowed=true
      break
    fi
  done
  if [[ "$allowed" != true ]]; then
    echo "$product_hunt_record: stale Product Hunt beta wording outside observed-copy allowlist" >&2
    exit 1
  fi
done < <(grep -niE 'public beta' "$product_hunt_record" || true)

removed_beta_path='docs/release-evidence/toolbox-2.0-beta.md'
for file in "${markdown_files[@]}"; do
  if [[ "$file" == "$current_plan" ]]; then
    continue
  fi
  if grep -nF "$removed_beta_path" "$file"; then
    echo "$file: removed beta evidence path" >&2
    exit 1
  fi
done

while IFS= read -r occurrence; do
  if ! printf '%s\n' "$occurrence" | grep -Eq '^[0-9]+:- Rename: docs/release-evidence/toolbox-2[.]0-beta[.]md to docs/release-evidence/toolbox-2[.]0[.]0[.]md$'; then
    echo "$current_plan: removed beta evidence path is allowed only in the documented rename instruction" >&2
    exit 1
  fi
done < <(grep -nF "$removed_beta_path" "$current_plan" || true)

echo "PASS: Toolbox documentation contract"
