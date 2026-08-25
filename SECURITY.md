# Toolbox Security Policy

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

Security fixes target the latest Toolbox 2.x release. Historical Diskora and Changeora releases through `v1.4.0` are retained for archive/migration purposes and are not active support branches.

Report suspected vulnerabilities privately to the repository owner before public disclosure. Include the affected version/commit, macOS version and architecture, reproduction steps, impact, logs with personal paths and credentials removed, and any proposed mitigation. Do not include private keys, notarization credentials, full home paths, or unrelated file contents.

Security boundaries:

- exact canonical-path validation immediately before every mutation
- fail-closed project rules and exact executable/argument allowlists
- explicit review; no automatic cleanup, overwrite-on-restore, privileged helper, or Gatekeeper bypass
- local evidence and redacted exports
- one user-initiated public GitHub update endpoint with no scan/device payload
- published SHA-256 checksums; signed/notarized artifacts by default

`v2.0.0` is an explicit ad-hoc-signed, unnotarized exception. Its stable label describes the product channel, not Apple trust approval. Gatekeeper rejection is expected, and users receive safe **Open Anyway** instructions; Toolbox never instructs users to disable Gatekeeper or remove quarantine attributes. Later releases return to the signed/notarized default.

Verify a release checksum with:

```bash
shasum -a 256 -c Toolbox-2.0.0.dmg.sha256
```

Do not silently replace a release asset. For an incident, make the affected release unavailable, publish an advisory, rotate compromised credentials, and ship a new patch release with reproducible evidence.

## Tiếng Việt

Bản vá bảo mật tập trung vào release Toolbox 2.x mới nhất. Diskora/Changeora đến `v1.4.0` chỉ được giữ cho archive/migration, không phải nhánh support active.

Báo cáo lỗ hổng riêng cho chủ repository trước khi công khai. Gửi version/commit, macOS/architecture, bước tái hiện, ảnh hưởng và log đã bỏ path cá nhân/credential. Không gửi private key, notarization credential hoặc nội dung file không liên quan.

Ranh giới chính: validate canonical path ngay trước mutation; project rule fail-closed; executable/argument allowlist chính xác; review foreground; không auto cleanup/overwrite restore/privileged helper/Gatekeeper bypass; evidence local; update endpoint công khai duy nhất theo thao tác người dùng; checksum SHA-256 đã publish. `v2.0.0` là ngoại lệ ký ad-hoc, chưa notarize, có Gatekeeper rejection dự kiến và hướng dẫn **Open Anyway** an toàn; release sau quay lại mặc định ký/notarize.

Không thay asset im lặng. Khi có incident, gỡ khả dụng bản ảnh hưởng, công bố advisory, rotate credential và phát hành patch mới.

## 日本語

Security fix は最新 Toolbox 2.x release を対象にします。`v1.4.0` までの Diskora / Changeora は archive/migration 用で、active support branch ではありません。

公開前に repository owner へ private report を送り、version/commit、macOS/architecture、再現手順、impact、個人 path/credential を除いた log を含めます。Private key、notarization credential、無関係な file content を送らないでください。

境界は mutation 直前の canonical path validation、fail-closed project rule、exact executable/argument allowlist、foreground review、restore overwrite/automatic cleanup/privileged helper/Gatekeeper bypass の禁止、local evidence、user-initiated の単一 public update endpoint、公開 SHA-256 です。`v2.0.0` は ad-hoc 署名・未 notarize の明示的な例外で、Gatekeeper rejection を expected result として記録し、安全な **Open Anyway** 手順を提供します。以後は signed/notarized の既定方針に戻ります。Asset を黙って差し替えず、incident 時は affected release を無効化して advisory と patch release を公開します。
