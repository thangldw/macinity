# Toolbox Documentation Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** Rewrite every Toolbox Markdown document as a complete English/Vietnamese/Japanese engineering reference, replace stale release evidence, and add three branded accessible diagrams.

**Architecture:** Source, executable tests, workflow results, and published artifacts form the evidence hierarchy. Each document has one responsibility; old implementation plans become as-built records; dependency-free repository checks enforce language, links, release claims, and accessible static diagrams.

**Tech Stack:** Markdown, Bash, Python 3 standard library, standalone HTML with inline SVG/CSS, SwiftPM, GitHub Actions, GitHub CLI.

**Spec:** docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md

## Global Constraints

- Cover all 18 baseline Markdown files, the redesign spec, and this plan.
- Every tracked Markdown file has complete English, Vietnamese, and Japanese sections in that order.
- Commands, identifiers, paths, URLs, tags, SHAs, bundle IDs, and checksums remain untranslated.
- Current claims follow source/tests, exact workflow evidence, and published artifacts in that order.
- Historical records remain historical and never define current policy.
- v2.0.0 remains ad-hoc signed and not Apple-notarized. Gatekeeper rejection is expected; Open Anyway is the safe first-launch path.
- Never claim Developer ID, notarization, stapling, Homebrew, unique users, or physical Intel execution without direct evidence.
- Diagrams use the thangldw profile, doc-wide size, engineer audience, static HTML, and no animation.
- Application behavior and website design are outside scope.

---

## English

### Status, context, and global constraints

Status: Tasks 1 through 6 and Task 7 Steps 1 through 4 were implemented locally through `7132bb513e9f46ee56de4ab37376786f392e667c`; controller-owned push and exact-head verification remain unexecuted. The final whole-branch review authorized one documentation/test-only correction commit before any controller integration action.

Goal: Rewrite every Toolbox Markdown document as a complete English/Vietnamese/Japanese engineering reference, replace stale release evidence, and add three branded accessible diagrams.

Architecture: Source, executable tests, workflow results, and published artifacts form the evidence hierarchy. Each document has one responsibility; old implementation plans become as-built records; dependency-free repository checks enforce language, links, release claims, and accessible static diagrams.

Tech Stack: Markdown, Bash, Python 3 standard library, standalone HTML with inline SVG/CSS, SwiftPM, GitHub Actions, GitHub CLI.

Spec: docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md

- Cover all 18 baseline Markdown files, the redesign spec, and this plan.
- Every tracked Markdown file has complete English, Vietnamese, and Japanese sections in that order.
- Commands, identifiers, paths, URLs, tags, SHAs, bundle IDs, and checksums remain untranslated.
- Current claims follow source/tests, exact workflow evidence, and published artifacts in that order.
- Historical records remain historical and never define current policy.
- v2.0.0 remains ad-hoc signed and not Apple-notarized. Gatekeeper rejection is expected; Open Anyway is the safe first-launch path.
- Never claim Developer ID, notarization, stapling, Homebrew, unique users, or physical Intel execution without direct evidence.
- Diagrams use the thangldw profile, doc-wide size, engineer audience, static HTML, and no animation.
- Application behavior and website design are outside scope.

Execution note: `/.worktrees/` was added to `.gitignore` solely to isolate this implementation worktree. That delta is a documented workspace-scope decision and does not change Toolbox application behavior or website design.

Controller rulings: task-by-task commits replaced the original single Tasks 1–6 commit boundary to satisfy the selected SDD workflow; `/Users/thang/.agents/skills/diagram-design/scripts/verify-geometry.py` was unavailable and therefore was not claimed, with packaged self-check, repository diagram checks, desktop/390 px visual inspection, and source/DOM geometry checks used instead; Task 7 Steps 5–6 remain controller-owned after final review, so this final fix must not merge or push.

### File map

| File or group | Responsibility |
| --- | --- |
| .diagram-design | Pin the saved thangldw profile. |
| tests/check_docs.py | Validate language-section order and local Markdown links. |
| tests/documentation_contract.sh | Validate current terminology, stable evidence, as-built state, and diagram links. |
| tests/check_diagrams.py | Validate accessible static HTML diagrams in CI. |
| Root Markdown | Entry point, contribution, privacy, security, and release history. |
| docs/ARCHITECTURE.md | Modules, dependency direction, durable data, integrations, and trust. |
| docs/OPERATIONS*.md | Development/runtime and release operations. |
| Launch/evidence Markdown | Time-bounded beta, stable, Product Hunt, release, visual, and demo evidence. |
| Existing docs/superpowers files | Trilingual as-built engineering records. |
| docs/diagrams/*.html | Architecture, sequence, and state-machine diagrams. |
| .github/workflows/ci.yml | Portable documentation checks on pushes and pull requests. |

### Task 1: Add documentation contracts and pin the profile

**Files:**
- Create: .diagram-design
- Create: tests/check_docs.py
- Create: tests/documentation_contract.sh
- Create: tests/check_diagrams.py

**Interfaces:**
- Consumes: repository-relative Markdown and HTML paths.
- Produces: three dependency-free checks returning zero only when their contracts pass.

- [ ] **Step 1: Write the Markdown checker**

Implement tests/check_docs.py using argparse, pathlib, re, sys, and urllib.parse. Require exactly one heading in this order:

~~~python
LANGUAGE_HEADINGS = ("## English", "## Tiếng Việt", "## 日本語")
EXTERNAL_SCHEMES = ("http://", "https://", "mailto:")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
~~~

Reject missing files, absolute local paths, links escaping the repository, and missing local link targets. Print one path/message per failure and return one when any failure exists.

- [ ] **Step 2: Write the content contract**

Implement tests/documentation_contract.sh with set -euo pipefail. Resolve repo_dir from the script location, collect tracked Markdown with git ls-files, call check_docs.py, and assert:

~~~text
README.md -> v2.0.0, not notarized, Open Anyway, docs/ARCHITECTURE.md
SECURITY.md -> ad-hoc-signed, unnotarized exception
docs/OPERATIONS-RELEASE.md -> c60367d84cdf06a93fe95c65e2ebe110ab3f70bb
docs/release-evidence/toolbox-2.0.0.md -> ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba
docs/ARCHITECTURE.md -> docs/diagrams/toolbox-architecture.html
docs/OPERATIONS.md -> install-trace-sequence.html and review-recovery-state.html
~~~

Require the four original historical docs/superpowers records to contain Status: completed and reject unchecked boxes in those records.

- [ ] **Step 3: Write the diagram checker**

Implement tests/check_diagrams.py with html.parser.HTMLParser and pathlib. Require one SVG with role=img, resolving aria-labelledby, first SVG child title, non-empty desc, unique prefixed IDs, viewBox 0 0 1280 720, and no external image/script source, writing-mode, JetBrains Mono, or script element.

- [ ] **Step 4: Confirm the expected red state**

~~~bash
python3 tests/check_docs.py $(git ls-files '*.md')
bash tests/documentation_contract.sh
~~~

Expected: failure because several Markdown files lack complete languages and the renamed evidence/diagrams do not exist.

- [ ] **Step 5: Pin the profile**

Write exactly:

~~~text
profile: thangldw
~~~

to .diagram-design. Do not copy profile contents into the repository.

- [ ] **Step 6: Validate checker behavior**

Use good and bad fixtures inside a validated mktemp directory. Require good fixtures to pass and bad fixtures to fail; clean only that directory. Run:

~~~bash
python3 -m py_compile tests/check_docs.py tests/check_diagrams.py
git diff --check
~~~

- [ ] **Step 7: Keep Task 1 uncommitted**

The final contract intentionally stays red while Tasks 2 through 5 rewrite documents. Commit it only when Task 6 turns the whole repository green.

Controller ruling: SDD task-by-task commits superseded this original single-commit boundary without changing delivered scope.

### Task 2: Rewrite the entry point and root policies

**Files:**
- Modify: README.md
- Modify: CONTRIBUTING.md
- Modify: PRIVACY.md
- Modify: SECURITY.md
- Modify: CHANGELOG.md

**Interfaces:**
- Consumes: current source behavior and stable release evidence.
- Produces: five complete trilingual documents with distinct ownership.

- [ ] **Step 1: Audit facts**

~~~bash
rg -n 'api.github.com|trashItem|FSEvent|scheduled-scan|Application Support/Toolbox|Full Disk Access|Open Anyway' apps/toolbox .github tests
gh api repos/thangldw/toolbox/releases/latest --jq '[.tag_name,.target_commitish,.html_url] | @tsv'
gh run view 32851142681 --repo thangldw/toolbox --json headSha,status,conclusion,url
~~~

- [ ] **Step 2: Rewrite README**

In all languages use: product boundary; install v2.0.0; Gatekeeper; core workflows; safety/privacy; build/validation; diagrams/documentation; v1 history; license.

- [ ] **Step 3: Rewrite root policies**

Keep exact ownership:

~~~text
CONTRIBUTING -> workflow, review evidence, localization, accessibility
PRIVACY -> local data, reads, stores, permissions, exports, network, migration
SECURITY -> support, private reporting, safety, release trust, incidents
CHANGELOG -> release history, including missing Japanese v2.0.0 stable entry
~~~

- [ ] **Step 4: Verify the group**

~~~bash
python3 tests/check_docs.py README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md
bash tests/unsigned_stable_release_test.sh
git diff --check
~~~

Review git diff --word-diff=plain. Keep the group uncommitted until Task 6.

### Task 3: Rewrite canonical architecture and operations

**Files:**
- Modify: docs/ARCHITECTURE.md
- Modify: docs/OPERATIONS.md
- Modify: docs/OPERATIONS-RELEASE.md

**Interfaces:**
- Consumes: Package.swift, source, scripts, workflows, and exact stable evidence.
- Produces: canonical module/trust and development/runtime/release references.

- [ ] **Step 1: Audit ownership**

~~~bash
find apps/toolbox/Sources -maxdepth 2 -type f -print | sort
sed -n '1,220p' apps/toolbox/Package.swift
rg -n 'struct .*Store|actor .*Store|trashItem|FSEvent|LaunchAgent|releases/latest' apps/toolbox/Sources
sed -n '1,180p' .github/workflows/ci.yml
sed -n '1,220p' .github/workflows/release.yml
~~~

- [ ] **Step 2: Rewrite architecture**

Cover target ownership, dependency direction, coordination, durable stores, atomic/quarantine behavior, macOS integrations, network boundary, safety, and migration.

- [ ] **Step 3: Rewrite development/runtime operations**

Cover toolchain, validation, XCTest boundary, scheduled-scan bootstrap/rollback, update checks, data, recovery, redacted export, and escalation.

- [ ] **Step 4: Rewrite release operations**

Separate v2.0.0 historical exception, future notarized default, and immutable post-publication checks. Tie v2.0.0 to:

~~~text
source commit: c60367d84cdf06a93fe95c65e2ebe110ab3f70bb
release run: 32847772209
Pages run: 32847688077
SHA-256: ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba
~~~

- [ ] **Step 5: Verify the group**

~~~bash
python3 tests/check_docs.py docs/ARCHITECTURE.md docs/OPERATIONS.md docs/OPERATIONS-RELEASE.md
bash tests/unsigned_stable_release_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
~~~

### Task 4: Rewrite launch and evidence records

**Files:**
- Modify: docs/launch/product-hunt.md
- Modify: docs/launch/toolbox-2.0.0-beta.1.md
- Modify: docs/launch/toolbox-2.0.0.md
- Rename: docs/release-evidence/toolbox-2.0-beta.md to docs/release-evidence/toolbox-2.0.0.md
- Modify: docs/design-evidence/toolbox-site-fidelity.md
- Modify: site/assets/demo-script.md
- Modify: every reference to the renamed evidence file

**Interfaces:**
- Consumes: live Product Hunt, GitHub release/run data, public checksum, and visual fixtures.
- Produces: time-bounded trilingual records without stale candidate gates.

- [ ] **Step 1: Refresh external state**

Verify Product Hunt in the authenticated browser. Capture visible status, URL, date, tagline, description, and maker comment. Run:

~~~bash
gh release view v2.0.0 --repo thangldw/toolbox --json tagName,isDraft,isPrerelease,publishedAt,url,assets
gh run view 32847772209 --repo thangldw/toolbox --json headSha,status,conclusion,url
gh run view 32847688077 --repo thangldw/toolbox --json headSha,status,conclusion,url
curl -fsSL https://thangldw.github.io/toolbox/ | rg -n 'Toolbox|not notarized|Open Anyway'
~~~

Never infer votes, users, or downloads.

- [ ] **Step 2: Rename and rewrite stable evidence**

Use git mv. Replace candidate placeholders with published evidence. Separate universal slices from physical Intel execution and ad-hoc signature structure from Apple trust.

- [ ] **Step 3: Rewrite release/launch records**

Mark beta historical, stable current for v2.0.0, and Product Hunt an observed record. Preserve safe Gatekeeper and issue-report privacy guidance.

- [ ] **Step 4: Rewrite fidelity/demo evidence**

Keep dimensions, fixture disclosure, recording constraints, and no-private-path rules. Remove blocked-launch claims contradicted by live state.

- [ ] **Step 5: Verify the group**

~~~bash
python3 tests/check_docs.py docs/launch/product-hunt.md docs/launch/toolbox-2.0.0-beta.1.md docs/launch/toolbox-2.0.0.md docs/release-evidence/toolbox-2.0.0.md docs/design-evidence/toolbox-site-fidelity.md site/assets/demo-script.md
bash tests/launch_assets.sh
bash tests/unsigned_stable_release_test.sh
if rg -n 'toolbox-2\.0-beta\.md|Public launch remains blocked|no 2\.0 DMG is published' . --glob '!docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'; then exit 1; fi
git diff --check
~~~

### Task 5: Convert original spec and plans into as-built records

**Files:**
- Modify: docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md
- Modify: redesign spec only when renamed evidence links require it

**Interfaces:**
- Consumes: Git history, final source, exact release evidence, and approved product decisions.
- Produces: Status: completed records without unchecked tasks or future launch gates.

- [ ] **Step 1: Build evidence map**

~~~bash
git log --oneline --decorate --reverse 6a177e2..v2.0.0
git show --stat --oneline 6a177e2 f060306 e780df5 2c1eb1d 91c7147 50f5118 f88c934 da8c4cf f16edf6 e3f1a29 cefced3 37de5fc c60367d
~~~

- [ ] **Step 2: Rewrite the product design as built**

Preserve goals, non-goals, target user, boundaries, Reclaim Space, Install Trace, safety/privacy, migration, errors, localization/accessibility, and verification. Add final evidence; remove superseded promises.

- [ ] **Step 3: Rewrite each old plan**

Use: status/release identity; objective; implemented file map; contracts/failure modes; execution record; verification evidence; deferred/unproven boundaries. Replace checkbox tasks with dated prose and tables.

- [ ] **Step 4: Verify the group**

~~~bash
python3 tests/check_docs.py docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md
if rg -n '^- \[ \]' docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md; then exit 1; fi
git diff --check
~~~

### Task 6: Draw and validate three diagrams

**Files:**
- Create: docs/diagrams/toolbox-architecture.html
- Create: docs/diagrams/install-trace-sequence.html
- Create: docs/diagrams/review-recovery-state.html
- Modify: README.md
- Modify: docs/ARCHITECTURE.md
- Modify: docs/OPERATIONS.md

**Interfaces:**
- Consumes: thangldw profile, selected Diagram Design references, and canonical docs.
- Produces: three static 1280 by 720 HTML diagrams with accessible SVG, trilingual interpretation, and canonical links.

- [ ] **Step 1: Resolve profile/template**

Validate .diagram-design, read /Users/thang/.diagram-design/profiles/thangldw.md, and use /Users/thang/.agents/skills/diagram-design/assets/template.html as structure. Do not reuse example colors.

- [ ] **Step 2: Draw architecture**

Use Secure paved road plus Architecture, at most three zones, eight components, ten paths, two blocked paths, and one privileged gate. Show GUI ingress, app shell, Core/Storage/Changes, local stores, macOS services, user-initiated GitHub Releases, blocked automatic upload/unreviewed mutation, and audit records. Use orthogonal routes and one focal element.

- [ ] **Step 3: Draw Install Trace sequence**

Use five lifelines: User, GUI, coordinator, snapshot/FSEvents, installer. Keep twelve messages maximum and one opt cancel/interruption fragment. Use dashed filled returns and one accent success response.

- [ ] **Step 4: Draw review/recovery state machine**

Use seven states maximum. Show candidate, review/confirmation, immediate revalidation, Trash mutation, recovery eligibility, conflict-safe restore, and blocked outcome. Merge review/confirmation if required. Label each transition and accent one state.

- [ ] **Step 5: Add trilingual interpretation and links**

Below each SVG, add complete EN/VI/JA explanations of content, exclusions, and safety boundary. Link from README, architecture, and operations.

- [ ] **Step 6: Run diagram and browser checks**

~~~bash
diagram_skill_dir='/Users/thang/.agents/skills/diagram-design'
python3 "$diagram_skill_dir/scripts/self_check.py" docs/diagrams/toolbox-architecture.html docs/diagrams/install-trace-sequence.html docs/diagrams/review-recovery-state.html
python3 "$diagram_skill_dir/scripts/verify-geometry.py" docs/diagrams/toolbox-architecture.html docs/diagrams/install-trace-sequence.html docs/diagrams/review-recovery-state.html
python3 tests/check_diagrams.py docs/diagrams/*.html
python3 tests/check_docs.py README.md docs/ARCHITECTURE.md docs/OPERATIONS.md
git diff --check
~~~

Open all diagrams at desktop and narrow widths. Reject clipping, overlapping connectors, hidden legends, page overflow, missing static meaning, or absent CJK fallback.

Controller ruling: `/Users/thang/.agents/skills/diagram-design/scripts/verify-geometry.py` did not exist in the installed package. Its command remains above as the approved-plan instruction, but execution used `self_check.py`, `tests/check_diagrams.py`, desktop and exact 390 px browser inspection, and source/DOM geometry checks; no `verify-geometry.py` pass is claimed.

- [ ] **Step 7: Make the global contract green and commit Tasks 1 through 6**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
git diff --check
git add .diagram-design README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md docs site/assets/demo-script.md tests/check_docs.py tests/check_diagrams.py tests/documentation_contract.sh
git commit -m "docs: rebuild Toolbox engineering documentation"
~~~

Do not add build output or unrelated changes.

Controller ruling: per-task commits replaced this original Tasks 1–6 commit boundary so each SDD review range remained exact.

### Task 7: Add CI, run full gates, push, verify exact head

**Files:**
- Modify: .github/workflows/ci.yml
- Modify: contract tests only if exact CI exposes a real portability defect

**Interfaces:**
- Consumes: green documentation and diagrams.
- Produces: exact-head CI evidence and verified public documentation/release links.

- [ ] **Step 1: Add docs job**

Add a root-level ubuntu-latest job with checkout, Python version, bash tests/documentation_contract.sh, and python3 tests/check_diagrams.py docs/diagrams/*.html. CI must not require the installed Diagram Design skill.

- [ ] **Step 2: Run documentation/release gates**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
bash tests/launch_assets.sh
bash tests/unsigned_stable_release_test.sh
bash tests/render_cask_test.sh
bash tests/adoption_report_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
~~~

- [ ] **Step 3: Run supported local Swift gates**

From apps/toolbox:

~~~bash
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
~~~

Run swift test separately. If Command Line Tools reports no such module XCTest, record that environmental failure and require exact-head macos-15 CI evidence.

- [ ] **Step 4: Commit CI**

~~~bash
git add .github/workflows/ci.yml tests/documentation_contract.sh
git commit -m "ci: validate Toolbox documentation contracts"
git status --short -uall
~~~

Expected: clean status.

Controller ruling: the Task 7 implementer owned Steps 1–4 only. Steps 5–6 below remain controller-owned after final whole-branch review; the final correction agent must not execute them.

- [ ] **Step 5: Push without rewriting history**

~~~bash
git pull --ff-only origin main
git push origin main
final_sha="$(git rev-parse HEAD)"
test "$final_sha" = "$(git ls-remote origin refs/heads/main | awk '{print $1}')"
~~~

Stop on divergence; never force-push.

- [ ] **Step 6: Verify exact-head CI and public contracts**

~~~bash
gh run list --repo thangldw/toolbox --commit "$final_sha" --workflow CI --json databaseId,headSha,status,conclusion,url
gh release view v2.0.0 --repo thangldw/toolbox --json tagName,isDraft,isPrerelease,url,assets
curl -fsSL https://thangldw.github.io/toolbox/ | rg -q 'Toolbox'
~~~

Require the matching CI documentation and Toolbox jobs to succeed. Report final commit, CI URL, document/diagram list, checksum, local XCTest boundary, and retained historical limitations.

### Acceptance criteria

- Run every command in the corresponding task without alteration, subject only to the recorded unavailable `verify-geometry.py` ruling.
- Every Markdown file passes tests/check_docs.py.
- Every diagram passes Diagram Design self-check and tests/check_diagrams.py; geometry evidence is the recorded substitute, not a `verify-geometry.py` claim.
- Stable evidence contains commit c60367d84cdf06a93fe95c65e2ebe110ab3f70bb and SHA-256 ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba.
- Do not describe local swift test as passing when XCTest is unavailable; exact-head macos-15 CI supplies that evidence after controller push.
- At controller completion, remote main equals the local SHA, CI succeeds, and git status is clean.

### Plan self-review

- Spec coverage: all Markdown groups, profile, three diagrams, portable checks, CI, push, and external verification have task ownership.
- Placeholder scan: every task names files, interfaces, commands, expected outcomes, and commit boundaries.
- Type consistency: checker names and diagram filenames are identical across tasks and languages.
- Scope consistency: no application behavior or website redesign is introduced.

## Tiếng Việt

### Trạng thái, bối cảnh và ràng buộc toàn cục

Trạng thái: Task 1 đến Task 6 và Task 7 Steps 1–4 đã được implement local đến `7132bb513e9f46ee56de4ab37376786f392e667c`; phần push và exact-head verification do controller sở hữu chưa được thực hiện. Final whole-branch review đã cho phép một commit sửa documentation/test-only trước mọi integration action của controller.

Mục tiêu: Viết lại mọi tài liệu Markdown của Toolbox thành engineering reference đầy đủ bằng English/Vietnamese/Japanese, thay release evidence lỗi thời và thêm ba diagram branded, accessible.

Kiến trúc: Source, executable test, workflow result và published artifact tạo thành evidence hierarchy. Mỗi document có một responsibility; implementation plan cũ trở thành as-built record; repository check không dependency enforce language, link, release claim và accessible static diagram.

Tech Stack: Markdown, Bash, Python 3 standard library, standalone HTML with inline SVG/CSS, SwiftPM, GitHub Actions, GitHub CLI.

Spec: docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md

- Bao phủ toàn bộ 18 file Markdown baseline, redesign spec và plan này.
- Mỗi file Markdown được track có đầy đủ phần English, Vietnamese và Japanese theo thứ tự đó.
- Command, identifier, path, URL, tag, SHA, bundle ID và checksum giữ nguyên, không dịch.
- Current claim tuân theo source/test, exact workflow evidence và published artifact theo thứ tự đó.
- Historical record giữ nguyên tính historical và không định nghĩa current policy.
- v2.0.0 vẫn ký ad-hoc và chưa Apple-notarized. Gatekeeper dự kiến từ chối; Open Anyway là first-launch path an toàn.
- Không claim Developer ID, notarization, stapling, Homebrew, unique user hoặc physical Intel execution khi không có evidence trực tiếp.
- Diagram dùng profile thangldw, size doc-wide, audience engineer, static HTML và không animation.
- Application behavior và website design nằm ngoài scope.

Ghi chú thực thi: `/.worktrees/` được thêm vào `.gitignore` chỉ để cô lập implementation worktree này. Delta đó là quyết định về workspace scope đã được ghi lại và không thay đổi Toolbox application behavior hoặc website design.

Ruling của controller: commit theo từng task thay original single Tasks 1–6 commit boundary để tuân theo SDD workflow đã chọn; `/Users/thang/.agents/skills/diagram-design/scripts/verify-geometry.py` không available nên không được claim, thay vào đó dùng packaged self-check, repository diagram check, desktop/390 px visual inspection và source/DOM geometry check; Task 7 Steps 5–6 vẫn thuộc controller sau final review, vì vậy final fix này không được merge hoặc push.

### Bản đồ file

| File hoặc nhóm | Responsibility |
| --- | --- |
| .diagram-design | Pin profile thangldw đã lưu. |
| tests/check_docs.py | Validate thứ tự language section và local Markdown link. |
| tests/documentation_contract.sh | Validate terminology hiện tại, stable evidence, as-built state và diagram link. |
| tests/check_diagrams.py | Validate accessible static HTML diagram trong CI. |
| Root Markdown | Entry point, contribution, privacy, security và release history. |
| docs/ARCHITECTURE.md | Module, dependency direction, durable data, integration và trust. |
| docs/OPERATIONS*.md | Development/runtime và release operation. |
| Launch/evidence Markdown | Evidence beta, stable, Product Hunt, release, visual và demo có time boundary. |
| Existing docs/superpowers files | As-built engineering record ba ngôn ngữ. |
| docs/diagrams/*.html | Architecture, sequence và state-machine diagram. |
| .github/workflows/ci.yml | Portable documentation check trên push và pull request. |

### Task 1: Thêm documentation contract và pin profile

**Files:**
- Create: .diagram-design
- Create: tests/check_docs.py
- Create: tests/documentation_contract.sh
- Create: tests/check_diagrams.py

**Interfaces:**
- Consumes: repository-relative Markdown and HTML paths.
- Produces: three dependency-free checks returning zero only when their contracts pass.

- [ ] **Step 1: Viết Markdown checker**

Implement tests/check_docs.py bằng argparse, pathlib, re, sys và urllib.parse. Yêu cầu đúng một heading theo thứ tự sau:

~~~python
LANGUAGE_HEADINGS = ("## English", "## Tiếng Việt", "## 日本語")
EXTERNAL_SCHEMES = ("http://", "https://", "mailto:")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
~~~

Reject file bị thiếu, absolute local path, link thoát repository và local link target không tồn tại. In một path/message cho mỗi failure và return one khi có bất kỳ failure nào.

- [ ] **Step 2: Viết content contract**

Implement tests/documentation_contract.sh với set -euo pipefail. Resolve repo_dir từ vị trí script, collect tracked Markdown bằng git ls-files, gọi check_docs.py và assert:

~~~text
README.md -> v2.0.0, not notarized, Open Anyway, docs/ARCHITECTURE.md
SECURITY.md -> ad-hoc-signed, unnotarized exception
docs/OPERATIONS-RELEASE.md -> c60367d84cdf06a93fe95c65e2ebe110ab3f70bb
docs/release-evidence/toolbox-2.0.0.md -> ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba
docs/ARCHITECTURE.md -> docs/diagrams/toolbox-architecture.html
docs/OPERATIONS.md -> install-trace-sequence.html and review-recovery-state.html
~~~

Yêu cầu bốn original historical docs/superpowers record chứa Status: completed và reject unchecked box trong các record đó.

- [ ] **Step 3: Viết diagram checker**

Implement tests/check_diagrams.py bằng html.parser.HTMLParser và pathlib. Yêu cầu một SVG với role=img, aria-labelledby resolve được, first SVG child là title, desc không rỗng, prefixed ID unique, viewBox 0 0 1280 720, và không có external image/script source, writing-mode, JetBrains Mono hoặc script element.

- [ ] **Step 4: Xác nhận expected red state**

~~~bash
python3 tests/check_docs.py $(git ls-files '*.md')
bash tests/documentation_contract.sh
~~~

Expected: failure vì một số file Markdown thiếu language đầy đủ và renamed evidence/diagram chưa tồn tại.

- [ ] **Step 5: Pin profile**

Ghi đúng nội dung sau:

~~~text
profile: thangldw
~~~

vào .diagram-design. Không copy profile content vào repository.

- [ ] **Step 6: Validate checker behavior**

Dùng good/bad fixture trong validated mktemp directory. Yêu cầu good fixture pass và bad fixture fail; chỉ clean directory đó. Chạy:

~~~bash
python3 -m py_compile tests/check_docs.py tests/check_diagrams.py
git diff --check
~~~

- [ ] **Step 7: Giữ Task 1 chưa commit**

Final contract cố ý giữ red trong khi Tasks 2 đến 5 viết lại document. Chỉ commit khi Task 6 làm toàn repository green.

Ruling của controller: SDD commit theo từng task supersede original single-commit boundary này mà không thay delivered scope.

### Task 2: Viết lại entry point và root policy

**Files:**
- Modify: README.md
- Modify: CONTRIBUTING.md
- Modify: PRIVACY.md
- Modify: SECURITY.md
- Modify: CHANGELOG.md

**Interfaces:**
- Consumes: current source behavior and stable release evidence.
- Produces: five complete trilingual documents with distinct ownership.

- [ ] **Step 1: Audit fact**

~~~bash
rg -n 'api.github.com|trashItem|FSEvent|scheduled-scan|Application Support/Toolbox|Full Disk Access|Open Anyway' apps/toolbox .github tests
gh api repos/thangldw/toolbox/releases/latest --jq '[.tag_name,.target_commitish,.html_url] | @tsv'
gh run view 32851142681 --repo thangldw/toolbox --json headSha,status,conclusion,url
~~~

- [ ] **Step 2: Viết lại README**

Trong mọi language dùng: product boundary; install v2.0.0; Gatekeeper; core workflow; safety/privacy; build/validation; diagram/documentation; v1 history; license.

- [ ] **Step 3: Viết lại root policy**

Giữ exact ownership:

~~~text
CONTRIBUTING -> workflow, review evidence, localization, accessibility
PRIVACY -> local data, reads, stores, permissions, exports, network, migration
SECURITY -> support, private reporting, safety, release trust, incidents
CHANGELOG -> release history, including missing Japanese v2.0.0 stable entry
~~~

- [ ] **Step 4: Verify nhóm**

~~~bash
python3 tests/check_docs.py README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md
bash tests/unsigned_stable_release_test.sh
git diff --check
~~~

Review git diff --word-diff=plain. Giữ nhóm chưa commit đến Task 6.

### Task 3: Viết lại canonical architecture và operations

**Files:**
- Modify: docs/ARCHITECTURE.md
- Modify: docs/OPERATIONS.md
- Modify: docs/OPERATIONS-RELEASE.md

**Interfaces:**
- Consumes: Package.swift, source, scripts, workflows, and exact stable evidence.
- Produces: canonical module/trust and development/runtime/release references.

- [ ] **Step 1: Audit ownership**

~~~bash
find apps/toolbox/Sources -maxdepth 2 -type f -print | sort
sed -n '1,220p' apps/toolbox/Package.swift
rg -n 'struct .*Store|actor .*Store|trashItem|FSEvent|LaunchAgent|releases/latest' apps/toolbox/Sources
sed -n '1,180p' .github/workflows/ci.yml
sed -n '1,220p' .github/workflows/release.yml
~~~

- [ ] **Step 2: Viết lại architecture**

Bao phủ target ownership, dependency direction, coordination, durable store, atomic/quarantine behavior, macOS integration, network boundary, safety và migration.

- [ ] **Step 3: Viết lại development/runtime operations**

Bao phủ toolchain, validation, XCTest boundary, scheduled-scan bootstrap/rollback, update check, data, recovery, redacted export và escalation.

- [ ] **Step 4: Viết lại release operations**

Tách historical exception của v2.0.0, future notarized default và immutable post-publication check. Gắn v2.0.0 với:

~~~text
source commit: c60367d84cdf06a93fe95c65e2ebe110ab3f70bb
release run: 32847772209
Pages run: 32847688077
SHA-256: ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba
~~~

- [ ] **Step 5: Verify nhóm**

~~~bash
python3 tests/check_docs.py docs/ARCHITECTURE.md docs/OPERATIONS.md docs/OPERATIONS-RELEASE.md
bash tests/unsigned_stable_release_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
~~~

### Task 4: Viết lại launch và evidence record

**Files:**
- Modify: docs/launch/product-hunt.md
- Modify: docs/launch/toolbox-2.0.0-beta.1.md
- Modify: docs/launch/toolbox-2.0.0.md
- Rename: docs/release-evidence/toolbox-2.0-beta.md to docs/release-evidence/toolbox-2.0.0.md
- Modify: docs/design-evidence/toolbox-site-fidelity.md
- Modify: site/assets/demo-script.md
- Modify: every reference to the renamed evidence file

**Interfaces:**
- Consumes: live Product Hunt, GitHub release/run data, public checksum, and visual fixtures.
- Produces: time-bounded trilingual records without stale candidate gates.

- [ ] **Step 1: Refresh external state**

Verify Product Hunt trong authenticated browser. Capture visible status, URL, date, tagline, description và maker comment. Chạy:

~~~bash
gh release view v2.0.0 --repo thangldw/toolbox --json tagName,isDraft,isPrerelease,publishedAt,url,assets
gh run view 32847772209 --repo thangldw/toolbox --json headSha,status,conclusion,url
gh run view 32847688077 --repo thangldw/toolbox --json headSha,status,conclusion,url
curl -fsSL https://thangldw.github.io/toolbox/ | rg -n 'Toolbox|not notarized|Open Anyway'
~~~

Không infer vote, user hoặc download.

- [ ] **Step 2: Rename và viết lại stable evidence**

Dùng git mv. Thay candidate placeholder bằng published evidence. Tách universal slice khỏi physical Intel execution và ad-hoc signature structure khỏi Apple trust.

- [ ] **Step 3: Viết lại release/launch record**

Đánh dấu beta là historical, stable là current cho v2.0.0 và Product Hunt là observed record. Giữ safe Gatekeeper và issue-report privacy guidance.

- [ ] **Step 4: Viết lại fidelity/demo evidence**

Giữ dimension, fixture disclosure, recording constraint và no-private-path rule. Xóa blocked-launch claim bị live state mâu thuẫn.

- [ ] **Step 5: Verify nhóm**

~~~bash
python3 tests/check_docs.py docs/launch/product-hunt.md docs/launch/toolbox-2.0.0-beta.1.md docs/launch/toolbox-2.0.0.md docs/release-evidence/toolbox-2.0.0.md docs/design-evidence/toolbox-site-fidelity.md site/assets/demo-script.md
bash tests/launch_assets.sh
bash tests/unsigned_stable_release_test.sh
if rg -n 'toolbox-2\.0-beta\.md|Public launch remains blocked|no 2\.0 DMG is published' . --glob '!docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'; then exit 1; fi
git diff --check
~~~

### Task 5: Chuyển original spec và plan thành as-built record

**Files:**
- Modify: docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md
- Modify: redesign spec only when renamed evidence links require it

**Interfaces:**
- Consumes: Git history, final source, exact release evidence, and approved product decisions.
- Produces: Status: completed records without unchecked tasks or future launch gates.

- [ ] **Step 1: Build evidence map**

~~~bash
git log --oneline --decorate --reverse 6a177e2..v2.0.0
git show --stat --oneline 6a177e2 f060306 e780df5 2c1eb1d 91c7147 50f5118 f88c934 da8c4cf f16edf6 e3f1a29 cefced3 37de5fc c60367d
~~~

- [ ] **Step 2: Viết lại product design theo as built**

Giữ goal, non-goal, target user, boundary, Reclaim Space, Install Trace, safety/privacy, migration, error, localization/accessibility và verification. Thêm final evidence; xóa promise đã supersede.

- [ ] **Step 3: Viết lại từng old plan**

Dùng: status/release identity; objective; implemented file map; contract/failure mode; execution record; verification evidence; deferred/unproven boundary. Thay checkbox task bằng dated prose và table.

- [ ] **Step 4: Verify nhóm**

~~~bash
python3 tests/check_docs.py docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md
if rg -n '^- \[ \]' docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md; then exit 1; fi
git diff --check
~~~

### Task 6: Vẽ và validate ba diagram

**Files:**
- Create: docs/diagrams/toolbox-architecture.html
- Create: docs/diagrams/install-trace-sequence.html
- Create: docs/diagrams/review-recovery-state.html
- Modify: README.md
- Modify: docs/ARCHITECTURE.md
- Modify: docs/OPERATIONS.md

**Interfaces:**
- Consumes: thangldw profile, selected Diagram Design references, and canonical docs.
- Produces: three static 1280 by 720 HTML diagrams with accessible SVG, trilingual interpretation, and canonical links.

- [ ] **Step 1: Resolve profile/template**

Validate .diagram-design, đọc /Users/thang/.diagram-design/profiles/thangldw.md và dùng /Users/thang/.agents/skills/diagram-design/assets/template.html làm structure. Không reuse màu example.

- [ ] **Step 2: Vẽ architecture**

Dùng Secure paved road cộng Architecture, tối đa ba zone, tám component, mười path, hai blocked path và một privileged gate. Thể hiện GUI ingress, app shell, Core/Storage/Changes, local store, macOS service, user-initiated GitHub Releases, blocked automatic upload/unreviewed mutation và audit record. Dùng orthogonal route và một focal element.

- [ ] **Step 3: Vẽ Install Trace sequence**

Dùng năm lifeline: User, GUI, coordinator, snapshot/FSEvents, installer. Giữ tối đa mười hai message và một opt cancel/interruption fragment. Dùng dashed filled return và một accent success response.

- [ ] **Step 4: Vẽ review/recovery state machine**

Dùng tối đa bảy state. Thể hiện candidate, review/confirmation, immediate revalidation, Trash mutation, recovery eligibility, conflict-safe restore và blocked outcome. Merge review/confirmation nếu cần. Label từng transition và accent một state.

- [ ] **Step 5: Thêm trilingual interpretation và link**

Dưới mỗi SVG, thêm giải thích EN/VI/JA đầy đủ về content, exclusion và safety boundary. Link từ README, architecture và operations.

- [ ] **Step 6: Chạy diagram và browser check**

~~~bash
diagram_skill_dir='/Users/thang/.agents/skills/diagram-design'
python3 "$diagram_skill_dir/scripts/self_check.py" docs/diagrams/toolbox-architecture.html docs/diagrams/install-trace-sequence.html docs/diagrams/review-recovery-state.html
python3 "$diagram_skill_dir/scripts/verify-geometry.py" docs/diagrams/toolbox-architecture.html docs/diagrams/install-trace-sequence.html docs/diagrams/review-recovery-state.html
python3 tests/check_diagrams.py docs/diagrams/*.html
python3 tests/check_docs.py README.md docs/ARCHITECTURE.md docs/OPERATIONS.md
git diff --check
~~~

Mở toàn bộ diagram ở desktop và narrow width. Reject clipping, connector overlap, hidden legend, page overflow, missing static meaning hoặc thiếu CJK fallback.

Ruling của controller: `/Users/thang/.agents/skills/diagram-design/scripts/verify-geometry.py` không tồn tại trong installed package. Command của approved plan vẫn được giữ ở trên, nhưng execution dùng `self_check.py`, `tests/check_diagrams.py`, browser inspection ở desktop và chính xác 390 px, cùng source/DOM geometry check; không claim `verify-geometry.py` pass.

- [ ] **Step 7: Làm global contract green và commit Tasks 1–6**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
git diff --check
git add .diagram-design README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md docs site/assets/demo-script.md tests/check_docs.py tests/check_diagrams.py tests/documentation_contract.sh
git commit -m "docs: rebuild Toolbox engineering documentation"
~~~

Không add build output hoặc change không liên quan.

Ruling của controller: commit theo từng task thay original Tasks 1–6 commit boundary này để mỗi SDD review range vẫn exact.

### Task 7: Thêm CI, chạy full gate, push, verify exact head

**Files:**
- Modify: .github/workflows/ci.yml
- Modify: contract tests only if exact CI exposes a real portability defect

**Interfaces:**
- Consumes: green documentation and diagrams.
- Produces: exact-head CI evidence and verified public documentation/release links.

- [ ] **Step 1: Thêm docs job**

Thêm root-level ubuntu-latest job với checkout, Python version, bash tests/documentation_contract.sh và python3 tests/check_diagrams.py docs/diagrams/*.html. CI không được require installed Diagram Design skill.

- [ ] **Step 2: Chạy documentation/release gate**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
bash tests/launch_assets.sh
bash tests/unsigned_stable_release_test.sh
bash tests/render_cask_test.sh
bash tests/adoption_report_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
~~~

- [ ] **Step 3: Chạy supported local Swift gate**

Từ apps/toolbox:

~~~bash
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
~~~

Chạy swift test riêng. Nếu Command Line Tools báo no such module XCTest, ghi lại environmental failure đó và yêu cầu exact-head macos-15 CI evidence.

- [ ] **Step 4: Commit CI**

~~~bash
git add .github/workflows/ci.yml tests/documentation_contract.sh
git commit -m "ci: validate Toolbox documentation contracts"
git status --short -uall
~~~

Expected: status sạch.

Ruling của controller: implementer Task 7 chỉ sở hữu Steps 1–4. Steps 5–6 bên dưới vẫn do controller thực hiện sau final whole-branch review; final correction agent không được chạy các bước đó.

- [ ] **Step 5: Push mà không rewrite history**

~~~bash
git pull --ff-only origin main
git push origin main
final_sha="$(git rev-parse HEAD)"
test "$final_sha" = "$(git ls-remote origin refs/heads/main | awk '{print $1}')"
~~~

Stop khi divergence; không force-push.

- [ ] **Step 6: Verify exact-head CI và public contract**

~~~bash
gh run list --repo thangldw/toolbox --commit "$final_sha" --workflow CI --json databaseId,headSha,status,conclusion,url
gh release view v2.0.0 --repo thangldw/toolbox --json tagName,isDraft,isPrerelease,url,assets
curl -fsSL https://thangldw.github.io/toolbox/ | rg -q 'Toolbox'
~~~

Yêu cầu documentation và Toolbox job của matching CI success. Report final commit, CI URL, document/diagram list, checksum, local XCTest boundary và retained historical limitation.

### Acceptance criteria

- Chạy mọi command trong task tương ứng mà không thay đổi, chỉ ngoại lệ ruling `verify-geometry.py` unavailable đã được ghi lại.
- Mọi file Markdown pass tests/check_docs.py.
- Mọi diagram pass Diagram Design self-check và tests/check_diagrams.py; geometry evidence là phương án thay thế đã ghi, không phải claim `verify-geometry.py`.
- Stable evidence chứa commit c60367d84cdf06a93fe95c65e2ebe110ab3f70bb và SHA-256 ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba.
- Không mô tả local swift test là pass khi XCTest unavailable; exact-head macos-15 CI cung cấp evidence đó sau controller push.
- Khi controller hoàn tất, remote main bằng local SHA, CI success và git status sạch.

### Tự review plan

- Spec coverage: mọi nhóm Markdown, profile, ba diagram, portable check, CI, push và external verification đều có task owner.
- Placeholder scan: mỗi task nêu file, interface, command, expected outcome và commit boundary.
- Type consistency: tên checker và filename diagram giống nhau giữa task và language.
- Scope consistency: không thêm application behavior hoặc website redesign.

## 日本語

### 状態、context、global constraints

状態: Task 1 から Task 6、および Task 7 Steps 1–4 は `7132bb513e9f46ee56de4ab37376786f392e667c` まで local 実装済みです。Controller-owned push と exact-head verification は未実行です。Final whole-branch review は、controller integration action の前に documentation/test-only の修正 commit を一件だけ許可しました。

Goal: すべての Toolbox Markdown document を完全な English/Vietnamese/Japanese engineering reference に書き直し、古い release evidence を置き換え、branded accessible diagram を三つ追加します。

Architecture: Source、executable test、workflow result、published artifact が evidence hierarchy を構成します。各 document は一つの responsibility を持ち、旧 implementation plan は as-built record になり、dependency-free repository check が language、link、release claim、accessible static diagram を enforce します。

Tech Stack: Markdown, Bash, Python 3 standard library, standalone HTML with inline SVG/CSS, SwiftPM, GitHub Actions, GitHub CLI.

Spec: docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md

- 18 baseline Markdown file、redesign spec、この plan をすべて対象にします。
- すべての追跡済み Markdown file は English、Vietnamese、Japanese の完全な section をこの順序で持ちます。
- Command、identifier、path、URL、tag、SHA、bundle ID、checksum は翻訳しません。
- Current claim は source/test、exact workflow evidence、published artifact の順に従います。
- Historical record は historical のままで、current policy を定義しません。
- v2.0.0 は ad-hoc signed で Apple-notarized されていません。Gatekeeper rejection が expected で、Open Anyway が安全な first-launch path です。
- 直接 evidence がない Developer ID、notarization、stapling、Homebrew、unique user、physical Intel execution を claim しません。
- Diagram は thangldw profile、doc-wide size、engineer audience、static HTML、no animation を使います。
- Application behavior と website design は scope 外です。

実行 note: `/.worktrees/` は、この implementation worktree を隔離する目的だけで `.gitignore` に追加しました。この delta は記録済み workspace-scope decision で、Toolbox application behavior または website design を変更しません。

Controller ruling: 選択した SDD workflow に従うため、task-by-task commit が original single Tasks 1–6 commit boundary を置き換えました。`/Users/thang/.agents/skills/diagram-design/scripts/verify-geometry.py` は unavailable で claim せず、代わりに packaged self-check、repository diagram check、desktop/390 px visual inspection、source/DOM geometry check を使いました。Task 7 Steps 5–6 は final review 後も controller-owned のため、この final fix は merge/push しません。

### File map

| File または group | Responsibility |
| --- | --- |
| .diagram-design | 保存済み thangldw profile を pin します。 |
| tests/check_docs.py | Language-section order と local Markdown link を validate します。 |
| tests/documentation_contract.sh | Current terminology、stable evidence、as-built state、diagram link を validate します。 |
| tests/check_diagrams.py | CI で accessible static HTML diagram を validate します。 |
| Root Markdown | Entry point、contribution、privacy、security、release history。 |
| docs/ARCHITECTURE.md | Module、dependency direction、durable data、integration、trust。 |
| docs/OPERATIONS*.md | Development/runtime と release operation。 |
| Launch/evidence Markdown | Time-bounded beta、stable、Product Hunt、release、visual、demo evidence。 |
| Existing docs/superpowers files | 三言語 as-built engineering record。 |
| docs/diagrams/*.html | Architecture、sequence、state-machine diagram。 |
| .github/workflows/ci.yml | Push と pull request に対する portable documentation check。 |

### Task 1: Documentation contract を追加し profile を pin

**Files:**
- Create: .diagram-design
- Create: tests/check_docs.py
- Create: tests/documentation_contract.sh
- Create: tests/check_diagrams.py

**Interfaces:**
- Consumes: repository-relative Markdown and HTML paths.
- Produces: three dependency-free checks returning zero only when their contracts pass.

- [ ] **Step 1: Markdown checker を作成**

argparse、pathlib、re、sys、urllib.parse で tests/check_docs.py を実装します。次の heading を一つずつ、この順序で要求します。

~~~python
LANGUAGE_HEADINGS = ("## English", "## Tiếng Việt", "## 日本語")
EXTERNAL_SCHEMES = ("http://", "https://", "mailto:")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
~~~

Missing file、absolute local path、repository 外へ出る link、存在しない local link target を reject します。Failure ごとに path/message を一つ出力し、failure が一つでもあれば one を返します。

- [ ] **Step 2: Content contract を作成**

set -euo pipefail で tests/documentation_contract.sh を実装します。Script location から repo_dir を resolve し、git ls-files で tracked Markdown を collect し、check_docs.py を呼び出して次を assert します。

~~~text
README.md -> v2.0.0, not notarized, Open Anyway, docs/ARCHITECTURE.md
SECURITY.md -> ad-hoc-signed, unnotarized exception
docs/OPERATIONS-RELEASE.md -> c60367d84cdf06a93fe95c65e2ebe110ab3f70bb
docs/release-evidence/toolbox-2.0.0.md -> ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba
docs/ARCHITECTURE.md -> docs/diagrams/toolbox-architecture.html
docs/OPERATIONS.md -> install-trace-sequence.html and review-recovery-state.html
~~~

Original historical docs/superpowers record 四つに Status: completed があることを要求し、それらの unchecked box を reject します。

- [ ] **Step 3: Diagram checker を作成**

html.parser.HTMLParser と pathlib で tests/check_diagrams.py を実装します。role=img の SVG 一つ、解決可能な aria-labelledby、SVG first child の title、non-empty desc、unique prefixed ID、viewBox 0 0 1280 720 を要求し、external image/script source、writing-mode、JetBrains Mono、script element を禁止します。

- [ ] **Step 4: Expected red state を確認**

~~~bash
python3 tests/check_docs.py $(git ls-files '*.md')
bash tests/documentation_contract.sh
~~~

Expected: 一部 Markdown file に完全な language がなく、renamed evidence/diagram が存在しないため failure。

- [ ] **Step 5: Profile を pin**

次を正確に書きます。

~~~text
profile: thangldw
~~~

.diagram-design に書き、profile content は repository に copy しません。

- [ ] **Step 6: Checker behavior を validate**

Validated mktemp directory 内の good/bad fixture を使います。Good fixture は pass、bad fixture は fail を要求し、その directory だけを clean します。実行 command:

~~~bash
python3 -m py_compile tests/check_docs.py tests/check_diagrams.py
git diff --check
~~~

- [ ] **Step 7: Task 1 を未 commit のまま保持**

Tasks 2–5 が document を書き直す間、final contract は意図的に red のままです。Task 6 が repository 全体を green にした時だけ commit します。

Controller ruling: SDD task-by-task commit が、この original single-commit boundary を delivered scope の変更なしで supersede しました。

### Task 2: Entry point と root policy を書き直す

**Files:**
- Modify: README.md
- Modify: CONTRIBUTING.md
- Modify: PRIVACY.md
- Modify: SECURITY.md
- Modify: CHANGELOG.md

**Interfaces:**
- Consumes: current source behavior and stable release evidence.
- Produces: five complete trilingual documents with distinct ownership.

- [ ] **Step 1: Fact を audit**

~~~bash
rg -n 'api.github.com|trashItem|FSEvent|scheduled-scan|Application Support/Toolbox|Full Disk Access|Open Anyway' apps/toolbox .github tests
gh api repos/thangldw/toolbox/releases/latest --jq '[.tag_name,.target_commitish,.html_url] | @tsv'
gh run view 32851142681 --repo thangldw/toolbox --json headSha,status,conclusion,url
~~~

- [ ] **Step 2: README を書き直す**

全 language で product boundary、install v2.0.0、Gatekeeper、core workflow、safety/privacy、build/validation、diagram/documentation、v1 history、license を扱います。

- [ ] **Step 3: Root policy を書き直す**

Exact ownership を維持します。

~~~text
CONTRIBUTING -> workflow, review evidence, localization, accessibility
PRIVACY -> local data, reads, stores, permissions, exports, network, migration
SECURITY -> support, private reporting, safety, release trust, incidents
CHANGELOG -> release history, including missing Japanese v2.0.0 stable entry
~~~

- [ ] **Step 4: Group を verify**

~~~bash
python3 tests/check_docs.py README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md
bash tests/unsigned_stable_release_test.sh
git diff --check
~~~

git diff --word-diff=plain を review します。Task 6 まで group を未 commit のまま保持します。

### Task 3: Canonical architecture と operations を書き直す

**Files:**
- Modify: docs/ARCHITECTURE.md
- Modify: docs/OPERATIONS.md
- Modify: docs/OPERATIONS-RELEASE.md

**Interfaces:**
- Consumes: Package.swift, source, scripts, workflows, and exact stable evidence.
- Produces: canonical module/trust and development/runtime/release references.

- [ ] **Step 1: Ownership を audit**

~~~bash
find apps/toolbox/Sources -maxdepth 2 -type f -print | sort
sed -n '1,220p' apps/toolbox/Package.swift
rg -n 'struct .*Store|actor .*Store|trashItem|FSEvent|LaunchAgent|releases/latest' apps/toolbox/Sources
sed -n '1,180p' .github/workflows/ci.yml
sed -n '1,220p' .github/workflows/release.yml
~~~

- [ ] **Step 2: Architecture を書き直す**

Target ownership、dependency direction、coordination、durable store、atomic/quarantine behavior、macOS integration、network boundary、safety、migration を扱います。

- [ ] **Step 3: Development/runtime operations を書き直す**

Toolchain、validation、XCTest boundary、scheduled-scan bootstrap/rollback、update check、data、recovery、redacted export、escalation を扱います。

- [ ] **Step 4: Release operations を書き直す**

v2.0.0 historical exception、future notarized default、immutable post-publication check を分離します。v2.0.0 を次に結び付けます。

~~~text
source commit: c60367d84cdf06a93fe95c65e2ebe110ab3f70bb
release run: 32847772209
Pages run: 32847688077
SHA-256: ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba
~~~

- [ ] **Step 5: Group を verify**

~~~bash
python3 tests/check_docs.py docs/ARCHITECTURE.md docs/OPERATIONS.md docs/OPERATIONS-RELEASE.md
bash tests/unsigned_stable_release_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
~~~

### Task 4: Launch と evidence record を書き直す

**Files:**
- Modify: docs/launch/product-hunt.md
- Modify: docs/launch/toolbox-2.0.0-beta.1.md
- Modify: docs/launch/toolbox-2.0.0.md
- Rename: docs/release-evidence/toolbox-2.0-beta.md to docs/release-evidence/toolbox-2.0.0.md
- Modify: docs/design-evidence/toolbox-site-fidelity.md
- Modify: site/assets/demo-script.md
- Modify: every reference to the renamed evidence file

**Interfaces:**
- Consumes: live Product Hunt, GitHub release/run data, public checksum, and visual fixtures.
- Produces: time-bounded trilingual records without stale candidate gates.

- [ ] **Step 1: External state を refresh**

Authenticated browser で Product Hunt を verify します。Visible status、URL、date、tagline、description、maker comment を capture します。実行 command:

~~~bash
gh release view v2.0.0 --repo thangldw/toolbox --json tagName,isDraft,isPrerelease,publishedAt,url,assets
gh run view 32847772209 --repo thangldw/toolbox --json headSha,status,conclusion,url
gh run view 32847688077 --repo thangldw/toolbox --json headSha,status,conclusion,url
curl -fsSL https://thangldw.github.io/toolbox/ | rg -n 'Toolbox|not notarized|Open Anyway'
~~~

Vote、user、download を infer しません。

- [ ] **Step 2: Stable evidence を rename/rewrite**

git mv を使います。Candidate placeholder を published evidence に置き換えます。Universal slice と physical Intel execution、ad-hoc signature structure と Apple trust を分離します。

- [ ] **Step 3: Release/launch record を書き直す**

Beta は historical、stable は v2.0.0 の current、Product Hunt は observed record と明示します。Safe Gatekeeper guidance と issue-report privacy guidance を維持します。

- [ ] **Step 4: Fidelity/demo evidence を書き直す**

Dimension、fixture disclosure、recording constraint、no-private-path rule を維持します。Live state と矛盾する blocked-launch claim を削除します。

- [ ] **Step 5: Group を verify**

~~~bash
python3 tests/check_docs.py docs/launch/product-hunt.md docs/launch/toolbox-2.0.0-beta.1.md docs/launch/toolbox-2.0.0.md docs/release-evidence/toolbox-2.0.0.md docs/design-evidence/toolbox-site-fidelity.md site/assets/demo-script.md
bash tests/launch_assets.sh
bash tests/unsigned_stable_release_test.sh
if rg -n 'toolbox-2\.0-beta\.md|Public launch remains blocked|no 2\.0 DMG is published' . --glob '!docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md'; then exit 1; fi
git diff --check
~~~

### Task 5: Original spec と plan を as-built record に変換

**Files:**
- Modify: docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md
- Modify: docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md
- Modify: redesign spec only when renamed evidence links require it

**Interfaces:**
- Consumes: Git history, final source, exact release evidence, and approved product decisions.
- Produces: Status: completed records without unchecked tasks or future launch gates.

- [ ] **Step 1: Evidence map を作成**

~~~bash
git log --oneline --decorate --reverse 6a177e2..v2.0.0
git show --stat --oneline 6a177e2 f060306 e780df5 2c1eb1d 91c7147 50f5118 f88c934 da8c4cf f16edf6 e3f1a29 cefced3 37de5fc c60367d
~~~

- [ ] **Step 2: Product design を as built として書き直す**

Goal、non-goal、target user、boundary、Reclaim Space、Install Trace、safety/privacy、migration、error、localization/accessibility、verification を保持します。Final evidence を追加し、superseded promise を削除します。

- [ ] **Step 3: 各 old plan を書き直す**

Status/release identity、objective、implemented file map、contract/failure mode、execution record、verification evidence、deferred/unproven boundary を使います。Checkbox task は dated prose と table に置き換えます。

- [ ] **Step 4: Group を verify**

~~~bash
python3 tests/check_docs.py docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md docs/superpowers/specs/2026-08-25-toolbox-documentation-redesign.md docs/superpowers/plans/2026-08-26-toolbox-documentation-redesign-plan.md
if rg -n '^- \[ \]' docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md docs/superpowers/plans/2026-08-25-toolbox-foundation-plan.md docs/superpowers/plans/2026-08-25-toolbox-evidence-workflows-plan.md docs/superpowers/plans/2026-08-25-toolbox-release-launch-plan.md; then exit 1; fi
git diff --check
~~~

### Task 6: 三つの diagram を作成・validate

**Files:**
- Create: docs/diagrams/toolbox-architecture.html
- Create: docs/diagrams/install-trace-sequence.html
- Create: docs/diagrams/review-recovery-state.html
- Modify: README.md
- Modify: docs/ARCHITECTURE.md
- Modify: docs/OPERATIONS.md

**Interfaces:**
- Consumes: thangldw profile, selected Diagram Design references, and canonical docs.
- Produces: three static 1280 by 720 HTML diagrams with accessible SVG, trilingual interpretation, and canonical links.

- [ ] **Step 1: Profile/template を resolve**

.diagram-design を validate し、/Users/thang/.diagram-design/profiles/thangldw.md を読み、/Users/thang/.agents/skills/diagram-design/assets/template.html を structure として使います。Example color は reuse しません。

- [ ] **Step 2: Architecture を描く**

Secure paved road と Architecture を使い、最大三 zone、八 component、十 path、二 blocked path、一 privileged gate にします。GUI ingress、app shell、Core/Storage/Changes、local store、macOS service、user-initiated GitHub Releases、blocked automatic upload/unreviewed mutation、audit record を示します。Orthogonal route と一 focal element を使います。

- [ ] **Step 3: Install Trace sequence を描く**

User、GUI、coordinator、snapshot/FSEvents、installer の五 lifeline を使います。Message は最大十二、opt cancel/interruption fragment は一つです。Dashed filled return と一 accent success response を使います。

- [ ] **Step 4: Review/recovery state machine を描く**

最大七 state で candidate、review/confirmation、immediate revalidation、Trash mutation、recovery eligibility、conflict-safe restore、blocked outcome を示します。必要なら review/confirmation を merge します。各 transition に label を付け、一 state を accent にします。

- [ ] **Step 5: Trilingual interpretation と link を追加**

各 SVG の下に content、exclusion、safety boundary の完全な EN/VI/JA explanation を追加します。README、architecture、operations から link します。

- [ ] **Step 6: Diagram/browser check を実行**

~~~bash
diagram_skill_dir='/Users/thang/.agents/skills/diagram-design'
python3 "$diagram_skill_dir/scripts/self_check.py" docs/diagrams/toolbox-architecture.html docs/diagrams/install-trace-sequence.html docs/diagrams/review-recovery-state.html
python3 "$diagram_skill_dir/scripts/verify-geometry.py" docs/diagrams/toolbox-architecture.html docs/diagrams/install-trace-sequence.html docs/diagrams/review-recovery-state.html
python3 tests/check_diagrams.py docs/diagrams/*.html
python3 tests/check_docs.py README.md docs/ARCHITECTURE.md docs/OPERATIONS.md
git diff --check
~~~

すべての diagram を desktop と narrow width で開きます。Clipping、overlapping connector、hidden legend、page overflow、missing static meaning、absent CJK fallback を reject します。

Controller ruling: `/Users/thang/.agents/skills/diagram-design/scripts/verify-geometry.py` は installed package に存在しませんでした。Approved-plan command は上に保持しますが、execution では `self_check.py`、`tests/check_diagrams.py`、desktop と exact 390 px の browser inspection、source/DOM geometry check を使いました。`verify-geometry.py` pass は claim しません。

- [ ] **Step 7: Global contract を green にし Tasks 1–6 を commit**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
git diff --check
git add .diagram-design README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md docs site/assets/demo-script.md tests/check_docs.py tests/check_diagrams.py tests/documentation_contract.sh
git commit -m "docs: rebuild Toolbox engineering documentation"
~~~

Build output または unrelated change を add しません。

Controller ruling: Task-by-task commit が original Tasks 1–6 commit boundary を置き換え、各 SDD review range を exact に保ちました。

### Task 7: CI を追加し full gate、push、exact head verification を実行

**Files:**
- Modify: .github/workflows/ci.yml
- Modify: contract tests only if exact CI exposes a real portability defect

**Interfaces:**
- Consumes: green documentation and diagrams.
- Produces: exact-head CI evidence and verified public documentation/release links.

- [ ] **Step 1: Docs job を追加**

Checkout、Python version、bash tests/documentation_contract.sh、python3 tests/check_diagrams.py docs/diagrams/*.html を持つ root-level ubuntu-latest job を追加します。CI は installed Diagram Design skill に依存しません。

- [ ] **Step 2: Documentation/release gate を実行**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
bash tests/launch_assets.sh
bash tests/unsigned_stable_release_test.sh
bash tests/render_cask_test.sh
bash tests/adoption_report_test.sh
actionlint .github/workflows/ci.yml .github/workflows/release.yml
git diff --check
~~~

- [ ] **Step 3: Supported local Swift gate を実行**

apps/toolbox から実行:

~~~bash
swift format lint --recursive --parallel Sources Tests Package.swift
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
plutil -lint Resources/Info.plist Resources/en.lproj/*.strings Resources/vi.lproj/*.strings
codesign --verify --deep --strict dist/Toolbox.app
~~~

swift test は別に実行します。Command Line Tools が no such module XCTest を返した場合、その environmental failure を記録し、exact-head macos-15 CI evidence を要求します。

- [ ] **Step 4: CI を commit**

~~~bash
git add .github/workflows/ci.yml tests/documentation_contract.sh
git commit -m "ci: validate Toolbox documentation contracts"
git status --short -uall
~~~

Expected: clean status。

Controller ruling: Task 7 implementer は Steps 1–4 だけを所有します。以下の Steps 5–6 は final whole-branch review 後も controller-owned です。Final correction agent は実行しません。

- [ ] **Step 5: History を rewrite せず push**

~~~bash
git pull --ff-only origin main
git push origin main
final_sha="$(git rev-parse HEAD)"
test "$final_sha" = "$(git ls-remote origin refs/heads/main | awk '{print $1}')"
~~~

Divergence では stop し、force-push しません。

- [ ] **Step 6: Exact-head CI と public contract を verify**

~~~bash
gh run list --repo thangldw/toolbox --commit "$final_sha" --workflow CI --json databaseId,headSha,status,conclusion,url
gh release view v2.0.0 --repo thangldw/toolbox --json tagName,isDraft,isPrerelease,url,assets
curl -fsSL https://thangldw.github.io/toolbox/ | rg -q 'Toolbox'
~~~

Matching CI の documentation/Toolbox job success を要求します。Final commit、CI URL、document/diagram list、checksum、local XCTest boundary、retained historical limitation を report します。

### Acceptance criteria

- 対応 task の全 command を変更せず実行します。ただし記録済み unavailable `verify-geometry.py` ruling だけは例外です。
- すべての Markdown file が tests/check_docs.py を pass します。
- すべての diagram が Diagram Design self-check と tests/check_diagrams.py を pass します。Geometry evidence は記録済み substitute であり、`verify-geometry.py` claim ではありません。
- Stable evidence に commit c60367d84cdf06a93fe95c65e2ebe110ab3f70bb と SHA-256 ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba を含めます。
- XCTest が unavailable の local swift test を pass と表現しません。Controller push 後の exact-head macos-15 CI が evidence を提供します。
- Controller 完了時に remote main と local SHA が一致し、CI success、git status clean を要求します。

### Plan self-review

- Spec coverage: すべての Markdown group、profile、三 diagram、portable check、CI、push、external verification に task owner があります。
- Placeholder scan: 各 task は file、interface、command、expected outcome、commit boundary を示します。
- Type consistency: Checker name と diagram filename は task/language 間で同一です。
- Scope consistency: Application behavior または website redesign を追加しません。
