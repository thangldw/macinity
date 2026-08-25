# Toolbox Security Policy

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Supported versions

Security fixes target the latest Toolbox 2.x release. Historical Diskora and Changeora releases through `v1.4.0` remain available for archive and migration but are not active support branches. Reports against older versions should state whether the issue reproduces on the latest 2.x release.

### Private vulnerability reporting

Use [GitHub private vulnerability reporting](https://github.com/thangldw/toolbox/security/advisories/new) before public disclosure. Include the affected version or commit, macOS version and architecture, minimal reproduction steps, expected and observed results, security impact, and a proposed mitigation if available. Redact personal paths, account data, tokens, credentials, and unrelated file contents. Never attach private keys, certificates, notarization credentials, or a full private dataset.

Ordinary reproducible bugs without a security impact belong in [GitHub Issues](https://github.com/thangldw/toolbox/issues). Do not open a public issue for an uncoordinated vulnerability disclosure.

### Safety invariants

- Mutation targets are canonicalized and validated against exact allowed roots immediately before use; path, symlink, permission, or state uncertainty fails closed.
- Project cleanup matches explicit project markers and known rebuildable artifacts inside the user-selected root. Globs, unresolved variables, name-only deletion, and inferred targets are not accepted authority.
- External process execution uses exact executable and argument allowlists. Toolbox has no privileged helper and does not bypass Gatekeeper.
- Every mutation requires foreground review. Eligible files move to macOS Trash, recovery records original and Trash paths, and restore refuses to overwrite an existing destination.
- Scheduled work scans and notifies only. It never deletes automatically.
- Evidence remains local; exports redact the current home prefix but still require user review before sharing.
- The only built-in network request is the user-initiated public GitHub Releases GET described in [Privacy](PRIVACY.md), with no scan or device payload.

### Release trust

Published releases provide a SHA-256 checksum. Verify `v2.0.0` with:

```bash
shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
```

The checksum detects download corruption or mismatch with the published checksum; because it is distributed beside the DMG, it is not an independent Apple trust assertion.

`v2.0.0` is an explicit ad-hoc-signed, unnotarized exception. Stable describes its product channel, not Developer ID signing, Apple notarization, stapling, or Gatekeeper acceptance. Initial Gatekeeper rejection is expected. Follow the DMG's **Open Anyway** instructions; never disable Gatekeeper or remove quarantine attributes. Homebrew remains unavailable for this release.

The default policy for later releases is Developer ID signing, notarization, stapling, strict verification, and post-publication re-download checks. Local build, ad-hoc `codesign` verification, architecture inspection, and CI success are necessary evidence for their respective claims but do not substitute for Apple notarization evidence. Published assets are immutable; corrections require a new patch release.

### Incident response

For a confirmed incident, preserve evidence without exposing user data, determine affected versions and artifacts, make unsafe assets unavailable, publish a coordinated advisory, rotate compromised credentials, and issue a new patch release with fresh build, checksum, signing, notarization, and exact-run evidence as applicable. Do not silently replace an existing release asset. Document any residual unknowns and recovery steps.

## Tiếng Việt

### Version được support

Security fix tập trung vào release Toolbox 2.x mới nhất. Release Diskora/Changeora lịch sử đến `v1.4.0` vẫn tồn tại cho archive và migration nhưng không phải active support branch. Report cho version cũ cần nêu issue có tái hiện trên release 2.x mới nhất hay không.

### Báo cáo lỗ hổng riêng tư

Dùng [GitHub private vulnerability reporting](https://github.com/thangldw/toolbox/security/advisories/new) trước khi public disclosure. Gửi version hoặc commit bị ảnh hưởng, macOS version/architecture, bước tái hiện tối thiểu, kết quả expected/observed, security impact và mitigation đề xuất nếu có. Redact path cá nhân, account data, token, credential và nội dung file không liên quan. Không bao giờ đính kèm private key, certificate, notarization credential hoặc toàn bộ private dataset.

Bug tái hiện được nhưng không có security impact nên gửi qua [GitHub Issues](https://github.com/thangldw/toolbox/issues). Không mở public issue để disclosure lỗ hổng chưa phối hợp.

### Safety invariant

- Mutation target được canonicalize và validate với allowed root chính xác ngay trước khi dùng; uncertainty về path, symlink, permission hoặc state phải fail closed.
- Project cleanup khớp explicit project marker và artifact có thể build lại đã biết trong root người dùng chọn. Glob, biến chưa resolve, name-only deletion và target suy luận không phải authority hợp lệ.
- External process execution dùng executable/argument allowlist chính xác. Toolbox không có privileged helper và không bypass Gatekeeper.
- Mọi mutation cần foreground review. File đủ điều kiện được đưa vào macOS Trash, recovery ghi vị trí gốc/Trash và restore từ chối ghi đè destination đang tồn tại.
- Scheduled work chỉ scan/notify, tuyệt đối không tự động xóa.
- Evidence ở local; export redaction home prefix hiện tại nhưng vẫn cần người dùng review trước khi chia sẻ.
- Built-in network request duy nhất là public GitHub Releases GET do người dùng khởi tạo như mô tả trong [Privacy](PRIVACY.md), không có scan hoặc device payload.

### Release trust

Release đã publish cung cấp checksum SHA-256. Xác minh `v2.0.0` bằng:

```bash
shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
```

Checksum phát hiện download bị lỗi hoặc không khớp checksum đã publish; vì checksum được phân phối cạnh DMG, nó không phải independent Apple trust assertion.

`v2.0.0` là ngoại lệ explicit được ký ad-hoc và chưa notarize. Stable mô tả product channel, không phải Developer ID signing, Apple notarization, stapling hoặc Gatekeeper acceptance. Gatekeeper từ chối ban đầu là expected. Làm theo hướng dẫn **Open Anyway** trong DMG; không bao giờ tắt Gatekeeper hoặc xóa quarantine attribute. Homebrew vẫn không có cho release này.

Policy mặc định cho release sau là Developer ID signing, notarization, stapling, strict verification và re-download check sau publish. Local build, ad-hoc `codesign` verification, architecture inspection và CI success là evidence cần thiết cho claim tương ứng nhưng không thay Apple notarization evidence. Asset đã publish là immutable; correction cần patch release mới.

### Incident response

Với incident đã xác nhận, giữ evidence mà không lộ user data, xác định version/artifact bị ảnh hưởng, gỡ khả dụng asset không an toàn, publish advisory đã phối hợp, rotate credential bị compromise và phát hành patch mới với fresh build, checksum, signing, notarization, exact-run evidence phù hợp. Không âm thầm thay release asset hiện tại. Ghi lại residual unknown và recovery step.

## 日本語

### Supported version

Security fix は最新 Toolbox 2.x release を対象にします。`v1.4.0` までの historical Diskora/Changeora release は archive と migration 用に残しますが、active support branch ではありません。古い version の report は、最新 2.x release でも再現するかを記載してください。

### Private vulnerability reporting

Public disclosure 前に [GitHub private vulnerability reporting](https://github.com/thangldw/toolbox/security/advisories/new) を使用します。Affected version/commit、macOS version/architecture、最小の reproduction step、expected/observed result、security impact、可能であれば proposed mitigation を含めます。Personal path、account data、token、credential、無関係な file content は redaction してください。Private key、certificate、notarization credential、private dataset 全体を添付しないでください。

Security impact のない通常の reproducible bug は [GitHub Issues](https://github.com/thangldw/toolbox/issues) に報告します。未調整の vulnerability disclosure を public issue に投稿しません。

### Safety invariant

- Mutation target は使用直前に canonicalize し、exact allowed root に対して validate します。Path、symlink、permission、state が不確実な場合は fail closed します。
- Project cleanup は user-selected root 内の explicit project marker と既知の再生成可能 artifact に一致させます。Glob、未解決変数、name-only deletion、推測 target は有効な authority ではありません。
- External process execution は exact executable/argument allowlist を使います。Toolbox には privileged helper がなく、Gatekeeper を bypass しません。
- すべての mutation は foreground review が必要です。対象 file は macOS Trash に移動し、recovery は original/Trash path を記録し、既存 destination を上書きせず restore を拒否します。
- Scheduled work は scan/notification のみで、自動削除しません。
- Evidence は local に保持します。Export は現在の home prefix を redaction しますが、共有前に user review が必要です。
- Built-in network request は [Privacy](PRIVACY.md) に記載した user-initiated public GitHub Releases GET だけで、scan/device payload を含みません。

### Release trust

公開 release は SHA-256 checksum を提供します。`v2.0.0` は次で検証します。

```bash
shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
```

Checksum は download corruption または公開 checksum との mismatch を検出します。DMG と同じ場所で配布されるため、独立した Apple trust assertion ではありません。

`v2.0.0` は明示的な ad-hoc 署名・未 notarize の例外です。Stable は product channel を示し、Developer ID signing、Apple notarization、stapling、Gatekeeper acceptance を意味しません。最初の Gatekeeper rejection は expected result です。DMG の **Open Anyway** 手順に従い、Gatekeeper を無効化したり quarantine attribute を削除したりしないでください。この release に Homebrew はありません。

以後の release の default policy は Developer ID signing、notarization、stapling、strict verification、公開後 re-download check です。Local build、ad-hoc `codesign` verification、architecture inspection、CI success は各 claim に必要な evidence ですが、Apple notarization evidence の代わりにはなりません。公開 asset は immutable とし、修正には新しい patch release を使います。

### Incident response

Incident を確認したら、user data を露出せず evidence を保持し、affected version/artifact を特定し、unsafe asset を unavailable にし、coordinated advisory を公開し、compromised credential を rotate し、必要に応じて fresh build、checksum、signing、notarization、exact-run evidence を持つ新しい patch release を発行します。既存 release asset を黙って置換しません。Residual unknown と recovery step を記録します。
