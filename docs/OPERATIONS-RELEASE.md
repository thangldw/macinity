# Toolbox Release Operations

## Release boundary

Only the protected GitHub release job may publish stable Toolbox releases. Local builds are ad-hoc signed and are useful for structural and DMG tests, but are not notarization evidence. The narrowly scoped public-beta exception is documented below.

Required protected values:

- `TOOLBOX_CODESIGN_IDENTITY`: exact Developer ID Application identity imported into the temporary release keychain.
- `TOOLBOX_NOTARY_PROFILE`: temporary `notarytool` keychain profile created by the release job.

The repository never stores or prints certificate, password, App Store Connect key, issuer, or private-key values.

## Local structural release check

From `apps/toolbox`:

```bash
./scripts/build_universal.sh
./scripts/build_dmg.sh
./scripts/verify_release.sh --allow-adhoc
```

This verifies the bundle identifier, version, `arm64` and `x86_64` slices, English and Vietnamese resources, structural code signature, DMG checksum, and expected file layout. The explicit flag skips stapler and Gatekeeper acceptance.

## Temporary unnotarized beta exception

Tag `v2.0.0-beta.1` may be published manually only as a GitHub pre-release after exact-head CI and Pages succeed. Its DMG must pass the local structural release check above, remain labeled ad-hoc signed and unnotarized on the release page, README, and product site, and include the manual **Open Anyway** instructions. Do not publish it through Homebrew, mark it latest/stable, disable Gatekeeper, remove quarantine attributes, or reuse its assets for stable `v2.0.0`.

Publish only the immutable DMG and SHA-256 file from the tagged commit. The stable `v2.0.0` release remains blocked until Developer ID signing, notarization, stapling, Gatekeeper acceptance, and the protected release job pass.

## Protected signing and notarization

After CI succeeds on the exact commit:

```bash
./scripts/build_universal.sh
TOOLBOX_CODESIGN_IDENTITY="Developer ID Application: …" \
TOOLBOX_NOTARY_PROFILE="toolbox-release" \
./scripts/notarize.sh
```

`notarize.sh` signs with hardened runtime and a trusted timestamp, submits and staples the app, builds the DMG, submits and staples the DMG, regenerates the checksum after stapling, then runs strict verification. Missing variables stop the script before signing or submission.

Publish only:

- `apps/toolbox/dist/Toolbox-2.0.0.dmg`
- `apps/toolbox/dist/Toolbox-2.0.0.dmg.sha256`

Re-download both assets after publication, verify the checksum, mount the DMG, drag Toolbox to Applications, launch it on a clean macOS 13+ account, and confirm Gatekeeper acceptance. Do not replace a published asset; issue a patch release.

## Tiếng Việt

Chỉ job release được bảo vệ mới được publish stable release. Riêng `v2.0.0-beta.1` được phép publish thủ công dưới dạng GitHub pre-release chưa notarize, phải ghi rõ giới hạn và hướng dẫn **Open Anyway**, không đưa lên Homebrew hoặc gắn latest/stable. Build local chỉ có chữ ký ad-hoc, dùng để kiểm tra cấu trúc/DMG chứ không phải bằng chứng notarization. Stable `v2.0.0` vẫn phải dừng nếu thiếu identity hoặc notary profile.

## 日本語

Stable release の公開は protected release job のみです。`v2.0.0-beta.1` だけは未 notarize の GitHub pre-release として手動公開でき、制限と **Open Anyway** 手順を明記し、Homebrew や latest/stable にはしません。Local build は ad-hoc 署名で notarization evidence ではありません。Stable `v2.0.0` は identity または notary profile がない場合、公開しません。
