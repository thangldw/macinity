# Toolbox 2.0 Release and Launch As-Built Record

Date: 2026-08-25
Status: completed
Release: `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Objective, release identity, and evidence order

This record replaces the executed release/launch plan. The objective was to build the universal app, provide explicit signing/notarization tooling, automate release and Pages publication, prepare launch assets, and record what was actually published. The final channel decision was an ad-hoc-signed, unnotarized stable exception rather than the originally planned notarized release.

Evidence remains separated by authority: source and executable tests establish behavior; workflow definitions plus exact-run results establish what automation ran; release metadata and downloaded asset identity establish publication; the authenticated Product Hunt page establishes only its observed state. The authoritative ledger is [docs/release-evidence/toolbox-2.0.0.md](../../release-evidence/toolbox-2.0.0.md).

### Published stable identity

| Field | Recorded evidence |
| --- | --- |
| Tag/source | `v2.0.0` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| GitHub release | Published `2026-08-25T12:33:04Z`; non-draft; non-prerelease |
| Release workflow | `32847772209`; completed `success` at the source commit |
| Pages workflow | `32847688077`; completed `success` at the source commit; public site returned HTTP 200 at observation time |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` bytes |
| Checksum | `Toolbox-2.0.0.dmg.sha256`; SHA-256 `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Trust | Ad-hoc signature; no Developer ID Application signature, Apple notarization, or stapling |
| Hardware | `arm64` and `x86_64` slices; no physical Intel execution evidence |
| Product Hunt | Scheduled, not launched, at `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` |

### Implemented file map

| Area | As-built files and responsibility |
| --- | --- |
| Universal app | `apps/toolbox/scripts/build_universal.sh`, `build_app.sh`, `verify_release.sh`, and `Tests/Distribution/release_contract.sh` build both slices, merge them, assemble the bundle, and verify structural contracts. |
| DMG and future trust path | `build_dmg.sh`, `notarize.sh`, and `docs/OPERATIONS-RELEASE.md` create the DMG/checksum and retain credential-bound Developer ID/notarization tooling for a future policy-compliant release. |
| Stable workflow | `.github/workflows/release.yml` validates the exact `v2.0.0` tag, runs format/XCTest/smoke/localization/universal/public contracts, builds with `verify_release.sh --allow-adhoc`, and publishes immutable DMG/checksum assets. |
| Cask tooling | `scripts/render_cask.sh` and `tests/render_cask_test.sh` render an exact-version cask from a URL/checksum; no Homebrew cask was published for `v2.0.0`. |
| Site | `site/index.html`, `site/styles.css`, `site/privacy.html`, product assets, `.github/workflows/pages.yml`, and `tests/site_contract.sh` implement and publish the static site. |
| Evidence/adoption | `scripts/adoption_report.sh`, `tests/adoption_report_test.sh`, and the stable evidence ledger distinguish DMG download events from unique users; no adoption count is claimed here. |
| Product Hunt | `docs/launch/product-hunt.md`, `site/assets/product-hunt-*.png`, `site/assets/demo-script.md`, and `tests/launch_assets.sh` contain the validated package and time-bounded scheduled-state record. |

### Release contracts and failure modes

`build_universal.sh` produces a bundle with `arm64` and `x86_64` slices. Slice presence is packaging evidence, not physical-machine execution. `build_dmg.sh` creates a read-only compressed DMG containing `Toolbox.app`, `/Applications`, and `Open Toolbox - First Launch.html`, then writes the checksum. `verify_release.sh --allow-adhoc` verifies bundle identity/version/resources, structural signature, slices, checksum, mount layout, and the first-launch guide while explicitly not asserting stapling or Gatekeeper acceptance.

The retained `notarize.sh` requires `TOOLBOX_CODESIGN_IDENTITY` and `TOOLBOX_NOTARY_PROFILE`, signs with hardened runtime/timestamp, submits and staples app/DMG, regenerates the checksum, and calls strict verification. Missing credentials stop before signing/submission and secrets are not printed. That tooling was not used for `v2.0.0`; its existence is not evidence of Developer ID or notarization.

For the published stable exception, direct Gatekeeper rejection is expected. The safe user path is **System Settings → Privacy & Security → Open Anyway** for this build only. Disabling Gatekeeper or removing quarantine attributes is outside the contract. Homebrew is unavailable.

The release workflow is deliberately fixed to tag/version `v2.0.0`. A later release must update the versioned contract and use the notarized path unless a separately reviewed exception changes policy. Published asset bytes are immutable; a mismatch requires a new patch release, not silent replacement under the tag.

### Execution record

| Commit | Recorded outcome |
| --- | --- |
| `91c7147` | Added universal build, release contract, and structural verification. |
| `50f5118` | Added DMG, Developer ID/notarization tooling, strict verification, and release operations. |
| `f88c934` | Added release automation, deterministic cask rendering, and tests. |
| `da8c4cf` | Added the static product/privacy site, Pages workflow, fixtures/screenshots, and site contract. |
| `f16edf6` | Added release evidence and a fixture-driven DMG download-event reporter. |
| `e3f1a29` | Added Product Hunt copy, thumbnail/gallery assets, demo script, and launch contracts. |
| `d4051da`, `b216d27` | Made Pages checks portable and corrected asynchronous update-check test timing. |
| `cefced3` | Prepared the unsigned `v2.0.0-beta.1` historical release path. |
| `37de5fc` | Promoted the stable `v2.0.0` ad-hoc/unnotarized exception, embedded first-launch guidance, and aligned site/release contracts. |
| `c60367d` | Made the launch contract portable; this is the tagged stable source. |

### Verification evidence

Release run `32847772209` completed `success` at the exact tagged source and validated format, XCTest, Core/Storage/Changes/App smoke, localization, universal slices, bundle contract, site contract, and launch assets before publishing the DMG and checksum. Pages run `32847688077` completed `success` at the same source commit. The public site returned HTTP 200 at the recorded observation.

Repository-local evidence dated `2026-08-25` separately records passing universal bundle and ad-hoc DMG structural checks. Those local results do not prove publication or Apple trust. The published artifact identity is the tag, full source SHA, asset name, byte size, and SHA-256 together; no download count is part of identity.

### Launch and adoption outcome

The GitHub stable release and Pages site were published. Product Hunt assets and copy were prepared, and the authenticated page was observed as scheduled for August 26, 2026 at 12:01 AM PDT with voting disabled until live. This record does not infer any later launch, vote, follower, user, or download state. The page's observed “public beta” wording was stale relative to the higher-authority stable GitHub release and remains historical copy only.

### Deferred and unproven boundaries

No Developer ID, notarization, stapling, Homebrew publication, physical Intel launch, clean-account production launch, public demo hosting, beta cohort, severity-1/2 defect tally, download/adoption count, unique-user count, Product Hunt launch, vote, or follower result is claimed. A successful workflow and universal slices do not fill those evidence gaps.

## Tiếng Việt

### Objective, release identity và evidence order

Record này thay release/launch plan đã execute. Objective là build universal app, cung cấp signing/notarization tooling explicit, automate release/Pages, chuẩn bị launch asset và ghi đúng thứ đã publish. Final channel decision là stable exception ký ad-hoc/chưa notarize, không phải release notarized dự kiến ban đầu.

Evidence tách theo authority: source/executable test chứng minh behavior; workflow definition/exact-run result chứng minh automation; release metadata/asset identity chứng minh publication; Product Hunt page đã authenticate chỉ chứng minh observed state. Ledger authoritative là [docs/release-evidence/toolbox-2.0.0.md](../../release-evidence/toolbox-2.0.0.md).

### Published stable identity

| Field | Evidence ghi nhận |
| --- | --- |
| Tag/source | `v2.0.0` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| GitHub release | Publish `2026-08-25T12:33:04Z`; non-draft; non-prerelease |
| Release workflow | `32847772209`; completed `success` tại source commit |
| Pages workflow | `32847688077`; completed `success` tại source commit; public site trả HTTP 200 lúc observation |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` byte |
| Checksum | `Toolbox-2.0.0.dmg.sha256`; SHA-256 `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Trust | Ad-hoc signature; không Developer ID Application, Apple notarization hay stapling |
| Hardware | Slice `arm64`/`x86_64`; không physical Intel execution evidence |
| Product Hunt | Scheduled, chưa launch tại `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` |

### Implemented file map

| Area | File/responsibility as built |
| --- | --- |
| Universal app | `build_universal.sh`, `build_app.sh`, `verify_release.sh`, `release_contract.sh` build/merge hai slice, assemble bundle và verify structural contract. |
| DMG/future trust | `build_dmg.sh`, `notarize.sh`, `docs/OPERATIONS-RELEASE.md` tạo DMG/checksum và giữ credential-bound Developer ID/notarization tooling cho future release. |
| Stable workflow | `.github/workflows/release.yml` validate exact `v2.0.0`, chạy format/XCTest/smoke/localization/universal/public contract, build với `--allow-adhoc` và publish DMG/checksum immutable. |
| Cask tooling | `scripts/render_cask.sh`, `tests/render_cask_test.sh` render cask từ exact URL/checksum; `v2.0.0` không publish Homebrew cask. |
| Site | `site/**`, `.github/workflows/pages.yml`, `tests/site_contract.sh` implement/publish static site. |
| Evidence/adoption | `scripts/adoption_report.sh`, test và stable ledger phân biệt DMG download event với unique user; record không claim adoption count. |
| Product Hunt | `docs/launch/product-hunt.md`, `site/assets/product-hunt-*.png`, demo script và launch test tạo validated package/observed scheduled-state record. |

### Release contract và failure mode

`build_universal.sh` tạo bundle có slice `arm64`/`x86_64`; slice không phải proof chạy máy vật lý. `build_dmg.sh` tạo read-only compressed DMG chứa `Toolbox.app`, `/Applications`, `Open Toolbox - First Launch.html` và checksum. `verify_release.sh --allow-adhoc` verify identity/version/resource, structural signature, slice, checksum, mount layout, first-launch guide, đồng thời không assert stapling/Gatekeeper acceptance.

`notarize.sh` giữ lại yêu cầu `TOOLBOX_CODESIGN_IDENTITY`, `TOOLBOX_NOTARY_PROFILE`, ký hardened runtime/timestamp, submit/staple app/DMG, tạo lại checksum và strict verify. Thiếu credential dừng trước signing/submission; secret không được print. Tooling đó không dùng cho `v2.0.0`, nên không là evidence Developer ID/notarization.

Với stable exception đã publish, Gatekeeper direct rejection là expected. Safe path là **System Settings → Privacy & Security → Open Anyway** chỉ cho build này. Tắt Gatekeeper/xóa quarantine ngoài contract. Homebrew không available.

Workflow cố định cho tag/version `v2.0.0`. Release sau phải update versioned contract và dùng notarized path trừ khi có exception review riêng. Published asset immutable; mismatch cần patch release mới, không silent replace.

### Execution record

| Commit | Kết quả ghi nhận |
| --- | --- |
| `91c7147` | Thêm universal build, release contract, structural verification. |
| `50f5118` | Thêm DMG, Developer ID/notarization tooling, strict verification, release operations. |
| `f88c934` | Thêm release automation, deterministic cask renderer/test. |
| `da8c4cf` | Thêm static product/privacy site, Pages, fixture/screenshot, site contract. |
| `f16edf6` | Thêm release evidence và fixture-driven DMG download-event reporter. |
| `e3f1a29` | Thêm Product Hunt copy, thumbnail/gallery, demo script, launch contract. |
| `d4051da`, `b216d27` | Làm Pages check portable và sửa timing test update check async. |
| `cefced3` | Chuẩn bị historical unsigned `v2.0.0-beta.1`. |
| `37de5fc` | Promote stable exception `v2.0.0`, thêm first-launch guide và align site/release contract. |
| `c60367d` | Làm launch contract portable; đây là tagged stable source. |

### Verification evidence

Release run `32847772209` completed `success` tại exact tagged source, validate format, XCTest, Core/Storage/Changes/App smoke, localization, universal slice, bundle/site/launch contract trước khi publish DMG/checksum. Pages run `32847688077` completed `success` tại cùng source. Public site trả HTTP 200 lúc observation.

Repository-local evidence ngày `2026-08-25` ghi PASS riêng cho universal bundle/ad-hoc DMG structural check; không prove publication hay Apple trust. Published identity là tag, full SHA, asset name, byte size và SHA-256; download count không thuộc identity.

### Launch/adoption outcome

GitHub stable release và Pages site đã publish. Product Hunt asset/copy đã prepare; authenticated page được quan sát là scheduled cho August 26, 2026 12:01 AM PDT, voting disabled đến lúc live. Không infer launch/vote/follower/user/download sau đó. “Public beta” trên page là stale copy so với stable GitHub record có authority cao hơn.

### Boundary deferred/chưa prove

Không claim Developer ID, notarization, stapling, Homebrew, physical Intel launch, clean-account production launch, public demo hosting, beta cohort, severity-1/2 defect tally, download/adoption, unique user, Product Hunt launch, vote hay follower. Workflow success/universal slice không lấp evidence gap đó.

## 日本語

### Objective、release identity、evidence order

この record は実行済み release/launch plan を置き換えます。Objective は universal app build、明示的 signing/notarization tooling、release/Pages automation、launch asset preparation、published state の正確な記録でした。Final channel decision は当初予定の notarized release ではなく ad-hoc signed/unnotarized stable exception でした。

Evidence authority を分離します。Source/executable test は behavior、workflow definition/exact-run result は automation、release metadata/asset identity は publication、authenticated Product Hunt page は observed state のみを証明します。Authoritative ledger は [docs/release-evidence/toolbox-2.0.0.md](../../release-evidence/toolbox-2.0.0.md) です。

### Published stable identity

| Field | 記録 evidence |
| --- | --- |
| Tag/source | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` の `v2.0.0` |
| GitHub release | `2026-08-25T12:33:04Z` publish; non-draft; non-prerelease |
| Release workflow | `32847772209`; source commit で completed `success` |
| Pages workflow | `32847688077`; source commit で completed `success`; 観測時 public site HTTP 200 |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` byte |
| Checksum | `Toolbox-2.0.0.dmg.sha256`; SHA-256 `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Trust | Ad-hoc signature; Developer ID Application、Apple notarization、stapling なし |
| Hardware | `arm64`/`x86_64` slice; physical Intel execution evidence なし |
| Product Hunt | `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` 時点で scheduled、未 launch |

### Implemented file map

| Area | As-built file/responsibility |
| --- | --- |
| Universal app | `build_universal.sh`、`build_app.sh`、`verify_release.sh`、`release_contract.sh` が両 slice の build/merge、bundle assembly、structural contract を実装します。 |
| DMG/future trust | `build_dmg.sh`、`notarize.sh`、`docs/OPERATIONS-RELEASE.md` が DMG/checksum と future release 用 credential-bound Developer ID/notarization tooling を実装します。 |
| Stable workflow | `.github/workflows/release.yml` は exact `v2.0.0` を validate し、format/XCTest/smoke/localization/universal/public contract、`--allow-adhoc` build、immutable DMG/checksum publish を行います。 |
| Cask tooling | `scripts/render_cask.sh`、`tests/render_cask_test.sh` は exact URL/checksum から cask を render しますが、`v2.0.0` Homebrew cask は未 publish です。 |
| Site | `site/**`、`.github/workflows/pages.yml`、`tests/site_contract.sh` が static site を implement/publish します。 |
| Evidence/adoption | `scripts/adoption_report.sh`、test、stable ledger が DMG download event と unique user を分離し、adoption count は claim しません。 |
| Product Hunt | `docs/launch/product-hunt.md`、`site/assets/product-hunt-*.png`、demo script、launch test が validated package/observed scheduled-state record を構成します。 |

### Release contract と failure mode

`build_universal.sh` は `arm64`/`x86_64` slice の bundle を作ります。Slice は physical execution proof ではありません。`build_dmg.sh` は `Toolbox.app`、`/Applications`、`Open Toolbox - First Launch.html` を含む read-only compressed DMG/checksum を作ります。`verify_release.sh --allow-adhoc` は identity/version/resource、structural signature、slice、checksum、mount layout、first-launch guide を verify しますが stapling/Gatekeeper acceptance は assert しません。

`notarize.sh` は `TOOLBOX_CODESIGN_IDENTITY`、`TOOLBOX_NOTARY_PROFILE` を要求し、hardened runtime/timestamp signing、app/DMG submit/staple、checksum regeneration、strict verify を行います。Credential 不足は signing/submission 前に停止し secret は print しません。この tooling は `v2.0.0` で未使用であり Developer ID/notarization evidence ではありません。

Published stable exception では Gatekeeper direct rejection が expected です。この build の safe path は **System Settings → Privacy & Security → Open Anyway** です。Gatekeeper disable/quarantine removal は contract 外です。Homebrew は unavailable です。

Workflow は tag/version `v2.0.0` 固定です。後続 release は versioned contract を更新し、別途 review 済み exception がなければ notarized path を使います。Published asset は immutable で、mismatch は同じ tag の silent replace ではなく新しい patch release が必要です。

### Execution record

| Commit | 記録結果 |
| --- | --- |
| `91c7147` | Universal build、release contract、structural verification を追加。 |
| `50f5118` | DMG、Developer ID/notarization tooling、strict verification、release operations を追加。 |
| `f88c934` | Release automation、deterministic cask renderer/test を追加。 |
| `da8c4cf` | Static product/privacy site、Pages、fixture/screenshot、site contract を追加。 |
| `f16edf6` | Release evidence、fixture-driven DMG download-event reporter を追加。 |
| `e3f1a29` | Product Hunt copy、thumbnail/gallery、demo script、launch contract を追加。 |
| `d4051da`, `b216d27` | Pages check portable 化、async update-check test timing 修正。 |
| `cefced3` | Historical unsigned `v2.0.0-beta.1` を準備。 |
| `37de5fc` | Stable `v2.0.0` exception を promote し first-launch guide と site/release contract を整合。 |
| `c60367d` | Launch contract portable 化。Tagged stable source。 |

### Verification evidence

Release run `32847772209` は exact tagged source で completed `success` となり、format、XCTest、Core/Storage/Changes/App smoke、localization、universal slice、bundle/site/launch contract 後に DMG/checksum を publish しました。Pages run `32847688077` も同じ source で completed `success` でした。観測時 public site は HTTP 200 でした。

`2026-08-25` repository-local evidence は universal bundle/ad-hoc DMG structural check の PASS を別に記録しますが、publication/Apple trust は prove しません。Published identity は tag、full SHA、asset name、byte size、SHA-256 の組で、download count は identity ではありません。

### Launch/adoption outcome

GitHub stable release と Pages site は publish 済みです。Product Hunt asset/copy は準備され、authenticated page は August 26, 2026 12:01 AM PDT に scheduled、live 前は voting disabled と観測されました。その後の launch、vote、follower、user、download は infer しません。Page の “public beta” はより高 authority の stable GitHub record に対する stale historical copy です。

### Deferred/unproven boundary

Developer ID、notarization、stapling、Homebrew、physical Intel launch、clean-account production launch、public demo hosting、beta cohort、severity-1/2 defect tally、download/adoption、unique user、Product Hunt launch、vote、follower は claim しません。Workflow success/universal slice はこれらの evidence gap を埋めません。
