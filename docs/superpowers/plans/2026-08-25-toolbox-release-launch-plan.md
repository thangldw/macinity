# Toolbox 2.0 Release and Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a reproducible universal release pipeline, direct-download website, Homebrew installation path, launch assets, and public adoption evidence for Toolbox 2.0.

**Architecture:** Build one universal app and DMG from `apps/toolbox`, sign and notarize only in the protected release path, deploy a static `site/` through GitHub Pages, and derive adoption counts from public GitHub release-asset metadata. Product Hunt publication occurs only after the exact public binary and landing page pass smoke checks.

**Tech Stack:** SwiftPM, codesign, `xcrun notarytool`, `stapler`, `hdiutil`, GitHub Actions/Releases/Pages, static HTML/CSS/JavaScript, Homebrew Cask, shell verification scripts.

**Spec:** `docs/superpowers/specs/2026-08-24-toolbox-super-app-design.md`

## Global Constraints

- Complete the foundation and evidence-workflow plans first.
- Release one `Toolbox-2.0.0.dmg` and matching `.sha256` for macOS 13+.
- The binary must contain arm64 and x86_64 slices, use bundle identifier `com.thang.toolbox`, and pass codesign, notarization stapling, and Gatekeeper assessment.
- Developer ID certificates and notarization credentials remain user-owned protected secrets; never commit them.
- The app has no telemetry. Website analytics, if enabled, are cookieless aggregate analytics disclosed in site privacy copy.
- Product Hunt gets one Toolbox post only after live binary and site verification.
- Each task ends with focused verification and a small commit.

---

## File map

```text
apps/toolbox/scripts/
├── build_universal.sh                    # Deterministic two-architecture build
├── build_dmg.sh                          # Signed app to DMG and checksum
├── notarize.sh                           # Protected credential boundary
└── verify_release.sh                     # Binary/bundle/DMG/Gatekeeper checks
.github/workflows/
├── ci.yml                                # Source validation
├── release.yml                           # Protected signed release
└── pages.yml                             # Static site deployment
scripts/render_cask.sh                    # Generates exact-version cask after release
site/
├── index.html
├── styles.css
├── privacy.html
└── assets/                               # Icon, screenshots, demo poster
scripts/adoption_report.sh                # Public GitHub asset counter
docs/release-evidence/toolbox-2.0.0.md
docs/launch/product-hunt.md
```

### Task 1: Build and verify a universal application locally

**Files:**
- Create: `apps/toolbox/scripts/build_universal.sh`
- Create: `apps/toolbox/scripts/verify_release.sh`
- Modify: `apps/toolbox/scripts/build_app.sh`
- Create: `apps/toolbox/Tests/Distribution/release_contract.sh`

**Interfaces:**
- Produces: `apps/toolbox/dist/Toolbox.app`
- Produces: executable with `arm64 x86_64` architectures

- [ ] **Step 1: Add a failing release contract**

```bash
#!/usr/bin/env bash
set -euo pipefail
app="${1:?Toolbox.app path required}"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" = "com.thang.toolbox"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "2.0.0"
lipo -archs "$app/Contents/MacOS/Toolbox" | grep -q 'arm64'
lipo -archs "$app/Contents/MacOS/Toolbox" | grep -q 'x86_64'
test -f "$app/Contents/Resources/en.lproj/Localizable.strings"
codesign --verify --deep --strict "$app"
```

- [ ] **Step 2: Run the contract against the current single-architecture build**

Run: `cd apps/toolbox && ./scripts/build_app.sh && bash Tests/Distribution/release_contract.sh dist/Toolbox.app`

Expected: FAIL on the missing architecture.

- [ ] **Step 3: Implement deterministic universal assembly**

`build_universal.sh` runs release builds for arm64 and x86_64, combines only the Toolbox executable with `lipo -create`, assembles resources once, and uses `SOURCE_DATE_EPOCH` only when supplied through a task-specific `TOOLBOX_SOURCE_DATE_EPOCH` variable. It must reject missing slices before signing.

- [ ] **Step 4: Verify the local ad-hoc universal build**

Run: `cd apps/toolbox && ./scripts/build_universal.sh && bash Tests/Distribution/release_contract.sh dist/Toolbox.app`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/toolbox/scripts apps/toolbox/Tests/Distribution
git commit -m "build: produce universal Toolbox application"
```

### Task 2: Add signed DMG and notarization tooling

**Files:**
- Create: `apps/toolbox/scripts/build_dmg.sh`
- Create: `apps/toolbox/scripts/notarize.sh`
- Modify: `apps/toolbox/scripts/verify_release.sh`
- Create: `docs/OPERATIONS-RELEASE.md`

**Interfaces:**
- Consumes: `TOOLBOX_CODESIGN_IDENTITY`, `TOOLBOX_NOTARY_PROFILE`
- Produces: `dist/Toolbox-2.0.0.dmg`, `.dmg.sha256`, stapled app and DMG

- [ ] **Step 1: Add a failing unsigned-DMG verification path**

```bash
codesign --verify --deep --strict --verbose=2 dist/Toolbox.app
xcrun stapler validate dist/Toolbox.app
xcrun stapler validate dist/Toolbox-2.0.0.dmg
spctl --assess --type execute --verbose=4 dist/Toolbox.app
shasum -a 256 -c dist/Toolbox-2.0.0.dmg.sha256
```

- [ ] **Step 2: Verify current local artifacts cannot satisfy notarization**

Expected: ad-hoc app passes structural codesign but stapler/notarization checks FAIL.

- [ ] **Step 3: Implement explicit credential-bound scripts**

```bash
: "${TOOLBOX_CODESIGN_IDENTITY:?Set Developer ID Application identity}"
: "${TOOLBOX_NOTARY_PROFILE:?Set notarytool keychain profile}"
codesign --force --deep --options runtime --timestamp --sign "$TOOLBOX_CODESIGN_IDENTITY" dist/Toolbox.app
ditto -c -k --keepParent dist/Toolbox.app dist/Toolbox-2.0.0-app.zip
xcrun notarytool submit dist/Toolbox-2.0.0-app.zip --keychain-profile "$TOOLBOX_NOTARY_PROFILE" --wait
xcrun stapler staple dist/Toolbox.app
./scripts/build_dmg.sh
xcrun notarytool submit dist/Toolbox-2.0.0.dmg --keychain-profile "$TOOLBOX_NOTARY_PROFILE" --wait
xcrun stapler staple dist/Toolbox-2.0.0.dmg
shasum -a 256 dist/Toolbox-2.0.0.dmg > dist/Toolbox-2.0.0.dmg.sha256
rm dist/Toolbox-2.0.0-app.zip
```

`build_dmg.sh` creates a read-only compressed DMG with `/Applications` symlink. The local ad-hoc path writes a checksum immediately; the notarization path rewrites the checksum after stapling the final DMG. Scripts print no credential values.

- [ ] **Step 4: Test non-secret failure modes locally**

Run: `cd apps/toolbox && env -u TOOLBOX_CODESIGN_IDENTITY -u TOOLBOX_NOTARY_PROFILE ./scripts/notarize.sh`

Expected: FAIL immediately with the missing variable name and no partial upload.

- [ ] **Step 5: Commit**

```bash
git add apps/toolbox/scripts docs/OPERATIONS-RELEASE.md
git commit -m "build: add Toolbox signing and notarization pipeline"
```

### Task 3: Add protected release automation and reproducible Homebrew cask generation

**Files:**
- Create: `.github/workflows/release.yml`
- Create: `scripts/render_cask.sh`
- Create: `tests/render_cask_test.sh`
- Modify: `README.md`
- Modify: `docs/OPERATIONS.md`

**Interfaces:**
- Produces: GitHub Release assets from a `v2.0.0` tag
- Produces: exact-version `Casks/toolbox.rb` after the public DMG checksum exists

- [ ] **Step 1: Add workflow/cask contract checks**

```bash
rg -q 'workflow_dispatch|push:' .github/workflows/release.yml
rg -q 'Toolbox-2.0.0.dmg' .github/workflows/release.yml
rg -q 'xcrun notarytool' apps/toolbox/scripts/notarize.sh
bash tests/render_cask_test.sh
```

- [ ] **Step 2: Run checks and verify release files are absent**

Expected: FAIL because workflow and cask do not exist.

- [ ] **Step 3: Implement a protected tag release job**

The workflow checks out the exact tag, imports the Developer ID certificate from protected secrets, configures a temporary notary keychain profile, runs the full test/build/notarize/verify scripts, uploads only the DMG and checksum, and removes the temporary keychain in an `always()` step. It uses least-privilege `contents: write` only in the release job.

- [ ] **Step 4: Add deterministic cask rendering against an exact release asset**

```bash
version="${1:?version required}"
sha256="${2:?sha256 required}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$sha256" =~ ^[0-9a-f]{64}$ ]]
mkdir -p Casks
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
} > Casks/toolbox.rb
```

`tests/render_cask_test.sh` renders version `2.0.0` with a fixed 64-character fixture checksum, asserts exact version/URL/checksum output, and rejects malformed input. After the public DMG is downloadable, run the renderer with the checksum from the verified asset and commit the generated cask.

- [ ] **Step 5: Run local YAML, cask, and release-script validation**

Run: `bash tests/render_cask_test.sh && actionlint .github/workflows/release.yml && cd apps/toolbox && ./scripts/build_universal.sh && ./scripts/build_dmg.sh && ./scripts/verify_release.sh --allow-adhoc`

Expected: PASS for local structural checks; protected notarization remains a release-environment gate.

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/release.yml scripts/render_cask.sh tests/render_cask_test.sh README.md docs/OPERATIONS.md
git commit -m "release: automate Toolbox distribution"
```

### Task 4: Build the static product site

**Files:**
- Create: `site/index.html`
- Create: `site/styles.css`
- Create: `site/privacy.html`
- Create: `site/assets/**`
- Create: `.github/workflows/pages.yml`
- Create: `tests/site_contract.sh`

**Interfaces:**
- Produces: direct DMG URL, Homebrew command, trust boundaries, screenshots, demo link

- [ ] **Step 1: Add failing site-content and accessibility contracts**

```bash
#!/usr/bin/env bash
set -euo pipefail
rg -q 'See what changed\. Reclaim space safely\.' site/index.html
rg -q 'Toolbox-2.0.0.dmg' site/index.html
rg -q 'No telemetry' site/index.html
rg -q 'Trash' site/index.html
rg -q '<main' site/index.html
rg -q 'aria-label|aria-labelledby' site/index.html
test -f site/privacy.html
test "$(find site/assets -type f | wc -l | tr -d ' ')" -ge 5
```

- [ ] **Step 2: Run the contract and verify the site is absent**

Run: `bash tests/site_contract.sh`

Expected: FAIL.

- [ ] **Step 3: Implement the responsive static landing page**

The first viewport contains the promise, one sentence of differentiation, direct Download and Homebrew actions, macOS requirement, and a product preview. Follow with a three-step Trace → Review → Recover story, four product previews, local-first/safety proof, installation instructions, and source/security/support links. No framework or runtime dependency is required. Representative generated previews are allowed during source preparation only when marked as fixture data; replace them with exact release-candidate captures before public launch.

- [ ] **Step 4: Add privacy copy and Pages deployment**

The privacy page distinguishes no in-app telemetry from optional cookieless aggregate site analytics. The Pages workflow deploys only `site/`, runs the site contract first, and uses the standard Pages OIDC permissions.

- [ ] **Step 5: Verify links, responsive layout, and static contracts**

Run: `bash tests/site_contract.sh && npx --yes html-validate 'site/*.html'`

Expected: PASS. Manually inspect at 1280x800 and 390x844 before commit.

- [ ] **Step 6: Commit**

```bash
git add site .github/workflows/pages.yml tests/site_contract.sh
git commit -m "feat: add Toolbox product site"
```

### Task 5: Create reproducible release evidence and adoption reporting

**Files:**
- Create: `scripts/adoption_report.sh`
- Create: `docs/release-evidence/toolbox-2.0.0.md`
- Create: `tests/adoption_report_test.sh`

**Interfaces:**
- Produces: monthly and cumulative DMG download counts from GitHub release JSON
- Produces: beta/release gate record with exact commands and observed results

- [ ] **Step 1: Add a fixture-driven failing counter test**

```bash
fixture='[{"published_at":"2026-09-01T00:00:00Z","assets":[{"name":"Toolbox-2.0.0.dmg","download_count":7},{"name":"Toolbox-2.0.0.dmg.sha256","download_count":2}]}]'
actual=$(printf '%s' "$fixture" | scripts/adoption_report.sh --stdin --asset-regex '^Toolbox-.*\.dmg$')
printf '%s\n' "$actual" | tail -1 | grep -Eq '^TOTAL[[:space:]]+7$'
```

- [ ] **Step 2: Run the test and verify the reporter is missing**

Run: `bash tests/adoption_report_test.sh`

Expected: FAIL.

- [ ] **Step 3: Implement the public counter**

Without `--stdin`, the script calls `gh api --paginate repos/thangldw/toolbox/releases`; it counts only `.dmg` assets, groups by release month, prints a total, and labels the result `download events, not unique users`.

- [ ] **Step 4: Record the beta evidence template with executable gates**

The evidence document records commit SHA, macOS/hardware, Swift/Xcode, format/test/smoke/build commands, migration fixture counts, five restore drills, scan fixture elapsed time/peak memory versus v1, codesign/notary/Gatekeeper outputs, Apple Silicon/Intel verification, 20-beta-user status, and unresolved severity-1/2 defects. Unknown or unavailable evidence is marked `not yet verified`, never passed.

- [ ] **Step 5: Run tests and generate the current public baseline**

Run: `bash tests/adoption_report_test.sh && scripts/adoption_report.sh`

Expected: fixture test PASS; live report counts only existing Toolbox DMGs matching the new naming contract.

- [ ] **Step 6: Commit**

```bash
git add scripts/adoption_report.sh tests/adoption_report_test.sh docs/release-evidence
git commit -m "docs: add Toolbox release evidence and adoption reporting"
```

### Task 6: Prepare the Product Hunt launch package

**Files:**
- Create: `docs/launch/product-hunt.md`
- Create: `site/assets/product-hunt-thumbnail.png`
- Create: `site/assets/product-hunt-home.png`
- Create: `site/assets/product-hunt-projects.png`
- Create: `site/assets/product-hunt-trace.png`
- Create: `site/assets/product-hunt-recovery.png`
- Create: `site/assets/demo-script.md`
- Create: `tests/launch_assets.sh`

**Interfaces:**
- Produces: one Toolbox launch draft and validated asset set

- [ ] **Step 1: Add failing launch-asset contracts**

```bash
sips -g pixelWidth -g pixelHeight site/assets/product-hunt-thumbnail.png | rg -q '240|512'
for image in home projects trace recovery; do
  sips -g pixelWidth -g pixelHeight "site/assets/product-hunt-$image.png" | rg -q '1270|2540'
done
rg -q '^Tagline:' docs/launch/product-hunt.md
rg -q '^Description:' docs/launch/product-hunt.md
rg -q '^First comment:' docs/launch/product-hunt.md
```

- [ ] **Step 2: Run the contract and verify assets are missing**

Run: `bash tests/launch_assets.sh`

Expected: FAIL.

- [ ] **Step 3: Create launch copy**

Use these locked messages:

```text
Name: Toolbox
Tagline: See what changed. Reclaim developer storage safely.
Description: A local-first macOS utility that traces installer changes, explains developer storage, and moves reviewed cleanup targets to Trash with recovery evidence.
Topics: Developer Tools, Mac, Open Source
Pricing: Free
```

The first comment covers the developer-storage problem, why change evidence and cleanup belong together, local-first/no-telemetry boundaries, migration from Diskora/Changeora, and a direct request for workflow feedback rather than votes.

- [ ] **Step 4: Capture assets from the verified release candidate**

Use real app screens with representative local fixture data. Thumbnail is square; gallery images are 1270x760 or 2540x1520; copy remains readable at Product Hunt preview size. The 30–60 second demo follows Start Trace → install fixture → finish trace → Review in Storage → Trash → Recovery.

- [ ] **Step 5: Run asset and copy validation**

Run: `bash tests/launch_assets.sh`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add docs/launch site/assets tests/launch_assets.sh
git commit -m "docs: prepare Toolbox Product Hunt launch"
```

## Public launch gate

Do not publish the GitHub release or Product Hunt post until all of these are true:

```text
[ ] Exact source commit passes CI.
[ ] DMG contains arm64 and x86_64.
[ ] Developer ID signature, notarization staple, and Gatekeeper assessment pass.
[ ] SHA-256 check passes after downloading the public asset.
[ ] GitHub Pages points directly to that asset and returns HTTP 200.
[ ] Homebrew installs the same asset and launches Toolbox.
[ ] Five restore drills pass without overwrite or data loss.
[ ] At least 20 developers completed the signed beta.
[ ] No unresolved severity-1 or severity-2 product defect remains.
[ ] Product Hunt gallery, demo, copy, maker, topics, and first comment are complete.
```

Publishing or credential configuration that requires the user's Apple Developer, GitHub repository-secret, YouTube, or Product Hunt account remains an explicit user-owned handoff. All source, scripts, assets, drafts, and non-secret verification continue automatically before that handoff.
