# Toolbox Release Operations

## Release boundary

Only the protected GitHub release job may publish Toolbox. Local builds are ad-hoc signed and are useful for structural and DMG tests, but are not notarization evidence.

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

Chỉ job release được bảo vệ mới được publish. Build local chỉ có chữ ký ad-hoc, dùng để kiểm tra cấu trúc/DMG chứ không phải bằng chứng notarization. Thiếu identity hoặc notary profile phải dừng trước khi ký hay upload. Sau publish, tải lại đúng DMG và checksum, kiểm tra checksum, mount/copy/launch trên tài khoản macOS 13+ sạch rồi mới mở launch công khai.

## 日本語

公開は protected release job のみです。Local build は ad-hoc 署名で、構造と DMG の検証用であり notarization evidence ではありません。Identity または notary profile がない場合は署名・upload 前に停止します。公開後は DMG と checksum を再取得し、clean macOS 13+ account で mount・copy・launch・Gatekeeper を確認します。
