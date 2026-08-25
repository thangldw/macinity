# Toolbox Release Operations

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Release policy boundary

Public artifacts are immutable outputs of an exact source tag. Source and executable tests take precedence over documentation; workflow definitions and exact-run results prove what automation executed; release metadata and re-downloaded bytes prove what was published. A local build is never publication, notarization, or end-user launch evidence.

`v2.0.0` is a completed historical exception: it is a stable product-channel release that is ad-hoc signed and not Apple-notarized. It does not establish permission for another unsigned release. Every later public release defaults to Developer ID Application signing, Apple notarization, stapling, and Gatekeeper acceptance unless a new, explicit, reviewed exception changes policy.

### Immutable `v2.0.0` record

The public release was observed and its exact run metadata rechecked on 2026-08-26 UTC:

| Field | Immutable evidence |
| --- | --- |
| Tag | `v2.0.0` |
| Published | `2026-08-25T12:33:04Z`; non-draft, non-prerelease, latest GitHub release |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Release run | `32847772209`; `Release`; completed `success` at the source commit |
| Pages run | `32847688077`; `Pages`; completed `success` at the source commit |
| Published assets | `Toolbox-2.0.0.dmg`, `Toolbox-2.0.0.dmg.sha256` |
| DMG SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Architecture contract | `arm64` and `x86_64` slices verified by the release job; no physical Intel launch claim |
| Apple trust | Ad-hoc signature, no Apple notarization or stapling, expected initial Gatekeeper rejection |

Run `32847772209` validated the tagged source, format, XCTest, smoke/localization contracts, universal slices, bundle contract, and public release contracts. Its publish job ran `build_universal.sh`, `build_dmg.sh`, and `verify_release.sh --allow-adhoc`, then created the GitHub release from the DMG and checksum. The DMG contains `Toolbox.app`, an `/Applications` link, and `Open Toolbox - First Launch.html` with the safe **Open Anyway** flow. The exception does not permit disabling Gatekeeper, stripping quarantine attributes, claiming Apple approval, or distributing this build through Homebrew.

Stable describes the product channel, not Apple trust. For this exact release, `codesign --verify` and the universal-slice check are positive structural evidence, while `spctl` rejection is the expected trust result. Do not reinterpret that rejection as Gatekeeper acceptance.

### Local structural checks

From `apps/toolbox`, the historical ad-hoc path is:

```bash
./scripts/build_universal.sh
./scripts/build_dmg.sh
./scripts/verify_release.sh --allow-adhoc
```

This checks bundle identifier `com.thang.toolbox`, version `2.0.0`, `arm64` and `x86_64` slices, English/Vietnamese resources, structural code signature, checksum consistency, read-only DMG mount, `/Applications` link, and the embedded first-launch guide. `--allow-adhoc` explicitly skips stapler and Gatekeeper-acceptance checks. It is suitable only for reproducing structural evidence or the recorded `v2.0.0` exception; it is not the default release gate.

Inspect the resulting evidence explicitly:

```bash
lipo -archs dist/Toolbox.app/Contents/MacOS/Toolbox
codesign --verify --deep --strict --verbose=2 dist/Toolbox.app
codesign -dv --verbose=4 dist/Toolbox.app
spctl --assess --type execute --verbose=4 dist/Toolbox.app
(cd dist && shasum -a 256 -c Toolbox-2.0.0.dmg.sha256)
```

For an ad-hoc reproduction, `spctl` must reject. Record the exit status and output as expected rejection, not as a passing Gatekeeper gate.

### Future notarized default

The current `.github/workflows/release.yml`, application version, artifact names, and release scripts are deliberately fixed to `v2.0.0`; the workflow publishes with `--allow-adhoc` and does not call `notarize.sh`. Before a later release, update and review the version/tag/file contract and change the protected release job to use the notarized path. Do not trigger the existing workflow for a new version and assume it provides notarization.

After format, XCTest, smoke, localization, release build, universal bundle, and public contract gates succeed on the exact candidate commit, prepare these values only in a protected release environment:

- `TOOLBOX_CODESIGN_IDENTITY`: the exact Developer ID Application identity available in the release keychain.
- `TOOLBOX_NOTARY_PROFILE`: a `notarytool` keychain profile backed by protected App Store Connect credentials.

Never commit or print certificate data, private keys, passwords, App Store Connect keys, issuer identifiers, or profile secrets. Build the universal app, then invoke the protected path:

```bash
cd apps/toolbox
./scripts/build_universal.sh
TOOLBOX_CODESIGN_IDENTITY="Developer ID Application: …" \
TOOLBOX_NOTARY_PROFILE="toolbox-release" \
./scripts/notarize.sh
```

After the versioned filenames have been updated, `notarize.sh` signs the app with hardened runtime and a trusted timestamp, verifies the signature, submits an app archive, staples and validates the app, builds the DMG, submits and staples the DMG, regenerates the checksum after final stapling, and calls strict `verify_release.sh`. Missing protected variables stop before signing or submission. A command exit of zero is necessary evidence; retain the `notarytool` submission result, stapler validation, `codesign` output, and `spctl` output with the release record.

### Pre-publication gate

Before creating a public release:

1. Resolve the candidate tag to one commit and record the full SHA. Verify all required CI jobs succeeded at that SHA; if site/install contracts changed, verify the Pages run at the same SHA.
2. Build once from that exact checkout. Do not modify the bundle between final signing/notarization and checksum generation.
3. Verify bundle ID, version, universal slices, resources, signature, notarization ticket, stapling, strict Gatekeeper acceptance, DMG layout, embedded first-launch guide, and checksum. For later releases, any use of `--allow-adhoc` is a failed gate.
4. Mount the final DMG read-only, drag Toolbox to Applications on a clean macOS 13+ account, and perform the first-launch and core smoke path. Record hardware/OS actually exercised; architecture slices alone are not physical-machine launch evidence.
5. Publish only the final DMG and its checksum file from the tag. Release notes must identify trust state accurately and must not claim Homebrew, usage counts, or hardware coverage without direct evidence.

### Publication and post-publication verification

Publish through a protected GitHub Actions environment with least-privilege `contents: write`; validation jobs retain `contents: read`. The tag, source commit, workflow run, release notes, and two asset bytes form one release record. Do not rebuild inside an unrelated checkout or upload an artifact from an unrecorded local run.

Immediately after publication:

1. Query the GitHub release and exact workflow run. Confirm tag, target commit, draft/prerelease state, asset names, sizes, and workflow conclusion.
2. Re-download both assets into a clean directory and run `shasum -a 256 -c <checksum-file>`. Compare the computed digest with the recorded digest; do not trust the local pre-upload copy alone.
3. Mount the downloaded DMG read-only. Re-run the bundle contract, confirm the `/Applications` link and first-launch guide, install by drag-and-drop, and repeat the clean-account launch smoke.
4. For notarized releases, re-run `codesign --verify --deep --strict --verbose=2`, `xcrun stapler validate` on the app and DMG, and `spctl --assess --type execute --verbose=4` on the installed app. For the historical `v2.0.0` exception only, record expected rejection and verify the documented **Open Anyway** path without weakening Gatekeeper.
5. Record exact tag/SHA, release and Pages run IDs, checksum, signature authority, architecture slices, notarization/stapling results, Gatekeeper result, tested OS/hardware, and observation time. Omit volatile download counts unless the timestamp and meaning are explicit; they are not unique-user evidence.

Published binary assets are immutable. If any re-download, checksum, signature, notarization, or launch check fails, stop promotion, preserve the mismatched bytes and logs, make the affected release unavailable without replacing its assets, explain impact, and issue a new patch version from a reviewed source commit. If signing credentials may be compromised, revoke/rotate them before rebuilding. Never silently replace a DMG or checksum under an existing tag.

## Tiếng Việt

### Ranh giới release policy

Public artifact là output immutable của một exact source tag. Source và executable test có authority cao hơn documentation; workflow definition và exact-run result chứng minh automation đã chạy gì; release metadata cùng byte được re-download chứng minh nội dung đã publish. Local build không bao giờ là evidence cho publication, notarization hoặc end-user launch.

`v2.0.0` là historical exception đã hoàn tất: đây là stable product-channel release ký ad-hoc và chưa Apple-notarize. Nó không tạo quyền cho unsigned release khác. Mọi public release sau mặc định phải có Developer ID Application signing, Apple notarization, stapling và Gatekeeper acceptance, trừ khi một exception mới, explicit và đã review thay đổi policy.

### Record immutable của `v2.0.0`

Public release đã được quan sát và exact run metadata được recheck vào 2026-08-26 UTC:

| Field | Immutable evidence |
| --- | --- |
| Tag | `v2.0.0` |
| Published | `2026-08-25T12:33:04Z`; non-draft, non-prerelease, latest GitHub release |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Release run | `32847772209`; `Release`; completed `success` tại source commit |
| Pages run | `32847688077`; `Pages`; completed `success` tại source commit |
| Published assets | `Toolbox-2.0.0.dmg`, `Toolbox-2.0.0.dmg.sha256` |
| DMG SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Architecture contract | Slice `arm64` và `x86_64` được release job verify; không có claim physical Intel launch |
| Apple trust | Ad-hoc signature, không Apple notarization hoặc stapling, initial Gatekeeper rejection là expected |

Run `32847772209` validate tagged source, format, XCTest, smoke/localization contract, universal slice, bundle contract và public release contract. Publish job chạy `build_universal.sh`, `build_dmg.sh` và `verify_release.sh --allow-adhoc`, rồi tạo GitHub release từ DMG và checksum. DMG chứa `Toolbox.app`, link `/Applications` và `Open Toolbox - First Launch.html` với luồng **Open Anyway** an toàn. Exception không cho phép tắt Gatekeeper, xóa quarantine attribute, claim Apple approval hoặc phân phối build này qua Homebrew.

Stable mô tả product channel, không phải Apple trust. Với exact release này, `codesign --verify` và universal-slice check là structural evidence dương, còn `spctl` rejection là trust result dự kiến. Không diễn giải rejection đó thành Gatekeeper acceptance.

### Structural check local

Từ `apps/toolbox`, historical ad-hoc path là:

```bash
./scripts/build_universal.sh
./scripts/build_dmg.sh
./scripts/verify_release.sh --allow-adhoc
```

Luồng này check bundle identifier `com.thang.toolbox`, version `2.0.0`, slice `arm64`/`x86_64`, resource English/Vietnamese, structural code signature, checksum consistency, read-only DMG mount, link `/Applications` và embedded first-launch guide. `--allow-adhoc` explicit bỏ qua stapler và Gatekeeper-acceptance check. Nó chỉ phù hợp để reproduce structural evidence hoặc exception `v2.0.0` đã ghi; không phải default release gate.

Kiểm tra evidence kết quả một cách explicit:

```bash
lipo -archs dist/Toolbox.app/Contents/MacOS/Toolbox
codesign --verify --deep --strict --verbose=2 dist/Toolbox.app
codesign -dv --verbose=4 dist/Toolbox.app
spctl --assess --type execute --verbose=4 dist/Toolbox.app
(cd dist && shasum -a 256 -c Toolbox-2.0.0.dmg.sha256)
```

Với ad-hoc reproduction, `spctl` phải reject. Ghi exit status và output như expected rejection, không phải Gatekeeper gate pass.

### Default notarized cho release tương lai

`.github/workflows/release.yml`, application version, artifact name và release script hiện tại được cố định có chủ đích cho `v2.0.0`; workflow publish bằng `--allow-adhoc` và không gọi `notarize.sh`. Trước release sau, update và review contract version/tag/file rồi đổi protected release job sang notarized path. Không trigger workflow hiện tại cho version mới và giả định nó cung cấp notarization.

Sau khi format, XCTest, smoke, localization, release build, universal bundle và public contract gate thành công trên exact candidate commit, chỉ chuẩn bị các value sau trong protected release environment:

- `TOOLBOX_CODESIGN_IDENTITY`: exact Developer ID Application identity có trong release keychain.
- `TOOLBOX_NOTARY_PROFILE`: `notarytool` keychain profile dựa trên protected App Store Connect credential.

Không bao giờ commit hoặc in certificate data, private key, password, App Store Connect key, issuer identifier hoặc profile secret. Build universal app rồi gọi protected path:

```bash
cd apps/toolbox
./scripts/build_universal.sh
TOOLBOX_CODESIGN_IDENTITY="Developer ID Application: …" \
TOOLBOX_NOTARY_PROFILE="toolbox-release" \
./scripts/notarize.sh
```

Sau khi filename theo version đã được update, `notarize.sh` ký app với hardened runtime và trusted timestamp, verify signature, submit app archive, staple/validate app, build DMG, submit/staple DMG, tạo lại checksum sau final stapling, rồi gọi strict `verify_release.sh`. Thiếu protected variable sẽ dừng trước signing hoặc submission. Command exit zero là evidence cần thiết; giữ `notarytool` submission result, stapler validation, `codesign` output và `spctl` output cùng release record.

### Gate trước publication

Trước khi tạo public release:

1. Resolve candidate tag thành một commit và ghi full SHA. Verify mọi CI job bắt buộc thành công tại SHA đó; nếu site/install contract đổi, verify Pages run tại cùng SHA.
2. Build một lần từ exact checkout đó. Không sửa bundle giữa final signing/notarization và checksum generation.
3. Verify bundle ID, version, universal slice, resource, signature, notarization ticket, stapling, strict Gatekeeper acceptance, DMG layout, embedded first-launch guide và checksum. Với release sau, mọi lần dùng `--allow-adhoc` là failed gate.
4. Mount final DMG read-only, kéo Toolbox vào Applications trên clean account macOS 13+ và chạy first-launch/core smoke path. Ghi hardware/OS thực tế đã test; architecture slice riêng không phải physical-machine launch evidence.
5. Chỉ publish final DMG và checksum file từ tag. Release note phải mô tả đúng trust state và không claim Homebrew, usage count hoặc hardware coverage nếu thiếu direct evidence.

### Publication và verification sau publish

Publish qua protected GitHub Actions environment với least-privilege `contents: write`; validation job giữ `contents: read`. Tag, source commit, workflow run, release note và byte của hai asset tạo thành một release record. Không rebuild trong checkout không liên quan hoặc upload artifact từ local run không được ghi nhận.

Ngay sau publication:

1. Query GitHub release và exact workflow run. Xác nhận tag, target commit, draft/prerelease state, asset name, size và workflow conclusion.
2. Re-download cả hai asset vào clean directory rồi chạy `shasum -a 256 -c <checksum-file>`. So sánh digest tính được với digest đã ghi; không chỉ tin local pre-upload copy.
3. Mount downloaded DMG read-only. Chạy lại bundle contract, xác nhận link `/Applications` và first-launch guide, install bằng drag-and-drop rồi lặp clean-account launch smoke.
4. Với notarized release, chạy lại `codesign --verify --deep --strict --verbose=2`, `xcrun stapler validate` trên app và DMG, cùng `spctl --assess --type execute --verbose=4` trên installed app. Chỉ với historical exception `v2.0.0`, ghi expected rejection và verify path **Open Anyway** đã document mà không làm yếu Gatekeeper.
5. Ghi exact tag/SHA, release/Pages run ID, checksum, signature authority, architecture slice, notarization/stapling result, Gatekeeper result, OS/hardware đã test và observation time. Bỏ volatile download count trừ khi timestamp và ý nghĩa explicit; nó không phải unique-user evidence.

Published binary asset là immutable. Nếu re-download, checksum, signature, notarization hoặc launch check fail, dừng promotion, giữ mismatched byte/log, làm affected release không còn available mà không replace asset, giải thích impact và phát hành patch version mới từ reviewed source commit. Nếu signing credential có thể bị compromise, revoke/rotate trước khi rebuild. Không bao giờ âm thầm replace DMG hoặc checksum dưới tag hiện có.

## 日本語

### Release policy boundary

Public artifact は exact source tag の immutable output です。Source/executable test は documentation より優先され、workflow definition/exact-run result は automation の実行内容を証明し、release metadata/re-downloaded bytes は公開内容を証明します。Local build は publication、notarization、end-user launch evidence ではありません。

`v2.0.0` は完了済み historical exception です。Stable product-channel release ですが ad-hoc 署名で Apple-notarize されていません。別の unsigned release を許可する前例にはなりません。以後の public release は、新しい明示的かつ review 済み exception で policy を変更しない限り、Developer ID Application signing、Apple notarization、stapling、Gatekeeper acceptance が default です。

### Immutable `v2.0.0` record

Public release を観測し、exact run metadata を 2026-08-26 UTC に再確認しました。

| Field | Immutable evidence |
| --- | --- |
| Tag | `v2.0.0` |
| Published | `2026-08-25T12:33:04Z`; non-draft, non-prerelease, latest GitHub release |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Release run | `32847772209`; `Release`; source commit で completed `success` |
| Pages run | `32847688077`; `Pages`; source commit で completed `success` |
| Published assets | `Toolbox-2.0.0.dmg`, `Toolbox-2.0.0.dmg.sha256` |
| DMG SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Architecture contract | Release job が `arm64` と `x86_64` slice を verify。Physical Intel launch claim はなし |
| Apple trust | Ad-hoc signature、Apple notarization/stapling なし、initial Gatekeeper rejection が expected |

Run `32847772209` は tagged source、format、XCTest、smoke/localization contract、universal slice、bundle contract、public release contract を validate しました。Publish job は `build_universal.sh`、`build_dmg.sh`、`verify_release.sh --allow-adhoc` を実行し、DMG/checksum から GitHub release を作成しました。DMG には `Toolbox.app`、`/Applications` link、安全な **Open Anyway** flow を含む `Open Toolbox - First Launch.html` があります。この exception は Gatekeeper disable、quarantine attribute 削除、Apple approval claim、Homebrew 配布を許可しません。

Stable は product channel を表し Apple trust ではありません。この exact release では `codesign --verify` と universal-slice check は positive structural evidence ですが、`spctl` rejection が expected trust result です。その rejection を Gatekeeper acceptance と解釈しません。

### Local structural check

`apps/toolbox` から historical ad-hoc path を実行します。

```bash
./scripts/build_universal.sh
./scripts/build_dmg.sh
./scripts/verify_release.sh --allow-adhoc
```

Bundle identifier `com.thang.toolbox`、version `2.0.0`、`arm64`/`x86_64` slice、English/Vietnamese resource、structural code signature、checksum consistency、read-only DMG mount、`/Applications` link、embedded first-launch guide を確認します。`--allow-adhoc` は stapler/Gatekeeper-acceptance check を明示的に skip します。Structural evidence または記録済み `v2.0.0` exception の再現専用で、default release gate ではありません。

結果 evidence を明示的に確認します。

```bash
lipo -archs dist/Toolbox.app/Contents/MacOS/Toolbox
codesign --verify --deep --strict --verbose=2 dist/Toolbox.app
codesign -dv --verbose=4 dist/Toolbox.app
spctl --assess --type execute --verbose=4 dist/Toolbox.app
(cd dist && shasum -a 256 -c Toolbox-2.0.0.dmg.sha256)
```

Ad-hoc reproduction では `spctl` が reject する必要があります。Exit status/output を expected rejection として記録し、Gatekeeper gate pass としません。

### Future notarized default

現在の `.github/workflows/release.yml`、application version、artifact name、release script は意図的に `v2.0.0` 固定です。Workflow は `--allow-adhoc` で publish し、`notarize.sh` を呼びません。後続 release 前に version/tag/file contract を update/review し、protected release job を notarized path に変更します。現在の workflow を新 version で trigger して notarization が得られると仮定しません。

Format、XCTest、smoke、localization、release build、universal bundle、public contract gate が exact candidate commit で成功した後、次の値を protected release environment だけで準備します。

- `TOOLBOX_CODESIGN_IDENTITY`: release keychain で利用可能な exact Developer ID Application identity。
- `TOOLBOX_NOTARY_PROFILE`: protected App Store Connect credential に基づく `notarytool` keychain profile。

Certificate data、private key、password、App Store Connect key、issuer identifier、profile secret を commit/print しません。Universal app を build して protected path を実行します。

```bash
cd apps/toolbox
./scripts/build_universal.sh
TOOLBOX_CODESIGN_IDENTITY="Developer ID Application: …" \
TOOLBOX_NOTARY_PROFILE="toolbox-release" \
./scripts/notarize.sh
```

Versioned filename の update 後、`notarize.sh` は hardened runtime/trusted timestamp で app を sign し、signature verify、app archive submit、app staple/validate、DMG build、DMG submit/staple、final stapling 後の checksum 再生成、strict `verify_release.sh` を実行します。Protected variable がなければ signing/submission 前に停止します。Command exit zero は必要 evidence です。`notarytool` submission result、stapler validation、`codesign` output、`spctl` output を release record と共に保持します。

### Pre-publication gate

Public release 作成前:

1. Candidate tag を一つの commit に resolve し full SHA を記録します。Required CI job がその SHA で成功したことを verify し、site/install contract が変わった場合は同じ SHA の Pages run を verify します。
2. Exact checkout から一度だけ build します。Final signing/notarization と checksum generation の間に bundle を変更しません。
3. Bundle ID、version、universal slice、resource、signature、notarization ticket、stapling、strict Gatekeeper acceptance、DMG layout、embedded first-launch guide、checksum を verify します。後続 release での `--allow-adhoc` 使用は failed gate です。
4. Final DMG を read-only mount し、clean macOS 13+ account で Toolbox を Applications へ drag して first-launch/core smoke path を実行します。実際に試した hardware/OS を記録し、architecture slice だけを physical-machine launch evidence としません。
5. Tag から final DMG/checksum file だけを publish します。Release note は trust state を正確に示し、direct evidence のない Homebrew、usage count、hardware coverage を claim しません。

### Publication と post-publication verification

Least-privilege `contents: write` の protected GitHub Actions environment から publish し、validation job は `contents: read` を維持します。Tag、source commit、workflow run、release note、二 asset の bytes が一つの release record です。無関係な checkout で rebuild したり、未記録 local run の artifact を upload しません。

Publication 直後:

1. GitHub release と exact workflow run を query し、tag、target commit、draft/prerelease state、asset name/size、workflow conclusion を確認します。
2. 両 asset を clean directory に re-download し、`shasum -a 256 -c <checksum-file>` を実行します。Computed digest を記録済み digest と比較し、local pre-upload copy だけを信頼しません。
3. Downloaded DMG を read-only mount し、bundle contract を再実行し、`/Applications` link/first-launch guide を確認し、drag-and-drop install と clean-account launch smoke を繰り返します。
4. Notarized release では installed app に `codesign --verify --deep --strict --verbose=2`、app/DMG に `xcrun stapler validate`、installed app に `spctl --assess --type execute --verbose=4` を再実行します。Historical `v2.0.0` exception だけは expected rejection を記録し、Gatekeeper を弱めず documented **Open Anyway** path を verify します。
5. Exact tag/SHA、release/Pages run ID、checksum、signature authority、architecture slice、notarization/stapling result、Gatekeeper result、tested OS/hardware、observation time を記録します。Volatile download count は timestamp/meaning が明示的でない限り省きます。Unique-user evidence ではありません。

Published binary asset は immutable です。Re-download、checksum、signature、notarization、launch check のいずれかが失敗したら promotion を止め、mismatched bytes/log を保持し、asset を replace せず affected release を unavailable にし、impact を説明し、reviewed source commit から新しい patch version を発行します。Signing credential compromise の可能性があれば rebuild 前に revoke/rotate します。既存 tag 下の DMG/checksum を黙って replace しません。
