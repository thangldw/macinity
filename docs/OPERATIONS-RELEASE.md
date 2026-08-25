# Toolbox Release Operations

## Release boundary

Toolbox `v2.0.0` uses the narrowly scoped unsigned-stable policy below. Local and release-job builds are ad-hoc signed and are useful for structural and DMG tests, but are not notarization evidence. Future notarized releases use the protected signing path.

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

## Unsigned stable v2.0.0 policy

Tag `v2.0.0` may be published as the latest GitHub release after exact-head CI and Pages succeed. Stable describes the product release channel, not Apple trust approval. Its DMG must pass the structural release check above, remain labeled ad-hoc signed and unnotarized on the release page, README, product site, and Product Hunt, and include `Open Toolbox - First Launch.html` with the manual **Open Anyway** instructions.

Publish only the immutable DMG and SHA-256 file from the tagged commit. Do not publish through Homebrew, disable Gatekeeper, remove quarantine attributes, or claim Developer ID signing, notarization, stapling, or Gatekeeper acceptance. `spctl` rejection is expected and must be recorded for this release.

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

`v2.0.0` là stable theo kênh sản phẩm nhưng vẫn ký ad-hoc và chưa notarize. Release phải ghi rõ giới hạn, chứa `Open Toolbox - First Launch.html`, hướng dẫn **Open Anyway**, không đưa lên Homebrew và không tuyên bố Gatekeeper pass. Build chỉ là bằng chứng cấu trúc/DMG, không phải bằng chứng notarization.

## 日本語

`v2.0.0` は product channel 上の stable release ですが、ad-hoc 署名で未 notarize です。Release は制限、`Open Toolbox - First Launch.html`、**Open Anyway** 手順を明記し、Homebrew を提供せず Gatekeeper pass を主張しません。Build は構造/DMG evidence であり notarization evidence ではありません。
