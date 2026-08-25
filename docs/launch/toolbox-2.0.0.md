# Toolbox 2.0.0 — Stable Release Record

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Published identity

This is the current latest stable GitHub release record observed at `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`.

| Field | Published evidence |
| --- | --- |
| GitHub release | `v2.0.0`; published `2026-08-25T12:33:04Z`; non-draft; non-prerelease |
| Release URL | https://github.com/thangldw/toolbox/releases/tag/v2.0.0 |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` bytes |
| DMG URL | https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg |
| SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Release workflow | `32847772209`; completed `success` at the source commit |
| Pages workflow | `32847688077`; completed `success` at the source commit; public site returned HTTP 200 |

Stable describes the Toolbox product channel. It does not describe Apple trust approval.

### Install the published artifact

1. Download `Toolbox-2.0.0.dmg` and `Toolbox-2.0.0.dmg.sha256` from the `v2.0.0` GitHub release into the same folder.
2. Verify the checksum with `shasum -a 256 -c Toolbox-2.0.0.dmg.sha256`. The expected DMG digest is `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba`.
3. Open the DMG and read `Open Toolbox - First Launch.html`.
4. Drag Toolbox to Applications and try to open it once.
5. After the expected Gatekeeper rejection, open **System Settings → Privacy & Security → Open Anyway**, then authenticate.

Do not disable Gatekeeper or remove quarantine attributes. The manual approval is scoped to this Toolbox build on that Mac.

### Trust and hardware boundary

- `v2.0.0` is ad-hoc signed and not notarized by Apple.
- No Developer ID signature, notarization ticket, or staple is claimed.
- Direct first launch is expected to be rejected by Gatekeeper; **Open Anyway** is the documented safe exception.
- The artifact contains `arm64` and `x86_64` slices. Universal slices are packaging evidence, not evidence of physical Intel execution.
- Homebrew installation is unavailable for this release.
- No user, download, or adoption count is claimed.

### Product scope and issue privacy

Toolbox combines Diskora and Changeora into one local-first macOS 13+ GUI for tracing installer changes, reviewing known rebuildable output inside user-selected roots, and recovering eligible Trash-backed cleanup actions. It uses no account or telemetry and does not delete automatically.

Report reproducible issues at https://github.com/thangldw/toolbox/issues with macOS version, Mac architecture, workflow, and observed result. Do not attach private paths or files.

## Tiếng Việt

### Identity đã publish

Đây là record của GitHub release stable hiện tại, quan sát lúc `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`.

| Field | Published evidence |
| --- | --- |
| GitHub release | `v2.0.0`; publish `2026-08-25T12:33:04Z`; không phải draft; không phải prerelease |
| Release URL | https://github.com/thangldw/toolbox/releases/tag/v2.0.0 |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` byte |
| DMG URL | https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg |
| SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Release workflow | `32847772209`; completed `success` tại source commit |
| Pages workflow | `32847688077`; completed `success` tại source commit; public site trả HTTP 200 |

Stable mô tả product channel của Toolbox, không mô tả Apple trust approval.

### Cài published artifact

1. Download `Toolbox-2.0.0.dmg` và `Toolbox-2.0.0.dmg.sha256` từ GitHub release `v2.0.0` vào cùng folder.
2. Verify checksum bằng `shasum -a 256 -c Toolbox-2.0.0.dmg.sha256`. Digest DMG dự kiến là `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba`.
3. Mở DMG và đọc `Open Toolbox - First Launch.html`.
4. Kéo Toolbox vào Applications và thử mở một lần.
5. Sau khi Gatekeeper từ chối như dự kiến, mở **System Settings → Privacy & Security → Open Anyway**, rồi authenticate.

Không tắt Gatekeeper hoặc xóa quarantine attribute. Manual approval chỉ áp dụng cho Toolbox build này trên máy đó.

### Ranh giới trust và hardware

- `v2.0.0` ký ad-hoc và chưa được Apple notarize.
- Không claim Developer ID signature, notarization ticket hay staple.
- Gatekeeper dự kiến từ chối lần mở trực tiếp đầu tiên; **Open Anyway** là exception an toàn được document.
- Artifact có slice `arm64` và `x86_64`. Universal slice là packaging evidence, không phải evidence chạy trên máy Intel vật lý.
- Homebrew không available cho release này.
- Không claim số user, download hay adoption.

### Phạm vi sản phẩm và privacy khi báo lỗi

Toolbox hợp nhất Diskora và Changeora thành một GUI macOS 13+ local-first để trace thay đổi installer, review known rebuildable output trong root người dùng chọn và recover cleanup action đủ điều kiện qua Trash. Ứng dụng không dùng account hay telemetry và không tự động delete.

Báo issue tái hiện được tại https://github.com/thangldw/toolbox/issues kèm macOS version, Mac architecture, workflow và kết quả quan sát. Không đính kèm private path hoặc file.

## 日本語

### Published identity

これは `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` に観測した current stable GitHub release record です。

| Field | Published evidence |
| --- | --- |
| GitHub release | `v2.0.0`; `2026-08-25T12:33:04Z` publish; non-draft; non-prerelease |
| Release URL | https://github.com/thangldw/toolbox/releases/tag/v2.0.0 |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` byte |
| DMG URL | https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg |
| SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |
| Release workflow | `32847772209`; source commit で completed `success` |
| Pages workflow | `32847688077`; source commit で completed `success`; public site は HTTP 200 |

Stable は Toolbox の product channel を示し、Apple trust approval を示しません。

### Published artifact の install

1. `v2.0.0` GitHub release から `Toolbox-2.0.0.dmg` と `Toolbox-2.0.0.dmg.sha256` を同じ folder に download します。
2. `shasum -a 256 -c Toolbox-2.0.0.dmg.sha256` で checksum を verify します。Expected DMG digest は `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` です。
3. DMG を開き、`Open Toolbox - First Launch.html` を読みます。
4. Toolbox を Applications に drag し、一度 open します。
5. Expected Gatekeeper rejection の後、**System Settings → Privacy & Security → Open Anyway** を開き、authenticate します。

Gatekeeper を無効化せず、quarantine attribute を削除しません。Manual approval はその Mac 上のこの Toolbox build だけに適用されます。

### Trust と hardware の境界

- `v2.0.0` は ad-hoc signed で Apple-notarize されていません。
- Developer ID signature、notarization ticket、staple は claim しません。
- Direct first launch は Gatekeeper に拒否される想定です。**Open Anyway** が document 済みの安全な exception です。
- Artifact は `arm64` と `x86_64` slice を含みます。Universal slice は packaging evidence であり、physical Intel execution evidence ではありません。
- この release に Homebrew install はありません。
- User、download、adoption count は claim しません。

### Product scope と issue privacy

Toolbox は Diskora と Changeora を一つの local-first macOS 13+ GUI に統合し、installer change の trace、user-selected root 内の known rebuildable output review、eligible Trash-backed cleanup action の recovery を提供します。Account と telemetry はなく、自動 delete しません。

再現可能な issue は macOS version、Mac architecture、workflow、observed result とともに https://github.com/thangldw/toolbox/issues へ報告します。Private path または file は添付しません。
