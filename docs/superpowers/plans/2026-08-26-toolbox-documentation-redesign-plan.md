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

- [ ] **Step 7: Make the global contract green and commit Tasks 1 through 6**

~~~bash
bash tests/documentation_contract.sh
python3 tests/check_diagrams.py docs/diagrams/*.html
git diff --check
git add .diagram-design README.md CONTRIBUTING.md PRIVACY.md SECURITY.md CHANGELOG.md docs site/assets/demo-script.md tests/check_docs.py tests/check_diagrams.py tests/documentation_contract.sh
git commit -m "docs: rebuild Toolbox engineering documentation"
~~~

Do not add build output or unrelated changes.

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

## Tiếng Việt

### Bảy task tương đương

1. **Contract/profile:** tạo marker và ba checker; xác nhận red state; pin profile; giữ chưa commit.
2. **Root docs:** viết lại README, CONTRIBUTING, PRIVACY, SECURITY, CHANGELOG đầy đủ EN/VI/JA; bổ sung Japanese v2.0.0; chạy focused gates.
3. **Canonical docs:** audit source/workflow; viết lại ARCHITECTURE, OPERATIONS, OPERATIONS-RELEASE; gắn exact commit/run/checksum.
4. **Launch/evidence:** verify Product Hunt live; verify GitHub release/run/Pages; rename stable evidence; viết lại beta/stable/Product Hunt/fidelity/demo records.
5. **As-built records:** map commit; viết lại original spec và ba old plan với Status: completed, không unchecked task hoặc future launch gate.
6. **Diagrams:** tạo architecture, Install Trace sequence, review/recovery state machine bằng thangldw/doc-wide/static; thêm diễn giải EN/VI/JA; chạy self-check, geometry, repository checker và browser QA; commit Tasks 1–6 khi green.
7. **CI/push:** thêm Ubuntu docs job; chạy full docs/launch/release/Swift gates; commit CI; pull --ff-only; push không force; chờ exact-head CI; verify release và Pages.

### Acceptance criteria

- Chạy nguyên vẹn mọi command trong task English tương ứng.
- Mọi Markdown pass tests/check_docs.py.
- Mọi diagram pass Diagram Design self-check, geometry và tests/check_diagrams.py.
- Stable evidence chứa commit c60367d84cdf06a93fe95c65e2ebe110ab3f70bb và SHA-256 ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba.
- Không gọi local swift test là pass nếu thiếu XCTest; exact-head macos-15 CI cung cấp evidence.
- Remote main bằng local SHA, CI success và git status sạch.

## 日本語

### 同等の七 task

1. **Contract/profile:** Marker と三 checker を作成し、red state を確認し、profile を pin して未 commit のまま保持します。
2. **Root docs:** README、CONTRIBUTING、PRIVACY、SECURITY、CHANGELOG を完全な EN/VI/JA で書き直し、Japanese v2.0.0 を追加して focused gate を実行します。
3. **Canonical docs:** Source/workflow を audit し、ARCHITECTURE、OPERATIONS、OPERATIONS-RELEASE を書き直し、exact commit/run/checksum を結びます。
4. **Launch/evidence:** Product Hunt live state と GitHub release/run/Pages を確認し、stable evidence を rename し、beta/stable/Product Hunt/fidelity/demo record を更新します。
5. **As-built record:** Commit map を作り、original spec と旧三 plan を Status: completed、unchecked task なし、future launch gate なしの record に変換します。
6. **Diagram:** thangldw/doc-wide/static で architecture、Install Trace sequence、review/recovery state machine を作り、EN/VI/JA 解説、self-check、geometry、repository checker、browser QA を実行し、green の時だけ Tasks 1–6 を commit します。
7. **CI/push:** Ubuntu docs job を追加し、full docs/launch/release/Swift gate、CI commit、--ff-only pull、non-force push、exact-head CI、release、Pages verification を行います。

### Acceptance criteria

- 対応する English task の command をそのまま実行します。
- 全 Markdown が tests/check_docs.py を通過します。
- 全 diagram が Diagram Design self-check、geometry、tests/check_diagrams.py を通過します。
- Stable evidence に commit c60367d84cdf06a93fe95c65e2ebe110ab3f70bb と SHA-256 ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba を含めます。
- XCTest 不足の local swift test を pass と表現せず、exact-head macos-15 CI で証明します。
- Remote main と local SHA が一致し、CI success、git status clean を要求します。

---

## Plan self-review

- Spec coverage: all Markdown groups, profile, three diagrams, portable checks, CI, push, and external verification have task ownership.
- Placeholder scan: every task names files, interfaces, commands, expected outcomes, and commit boundaries.
- Type consistency: checker names and diagram filenames are identical across tasks and languages.
- Scope consistency: no application behavior or website redesign is introduced.

