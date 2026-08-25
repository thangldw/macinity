# Toolbox 2.0.0 Stable Release Evidence

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Record boundary and source audit

This record freezes the externally observed stable state at `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`. It replaces the pre-publication beta-candidate ledger. A published release can be stable while still lacking Apple trust approval.

| Source | Observed fact | What it does not prove |
| --- | --- | --- |
| GitHub release metadata | `v2.0.0` is published, non-draft, non-prerelease, with the named assets | End-user launch, adoption, or Apple approval |
| Exact GitHub Actions runs | Release run `32847772209` and Pages run `32847688077` completed `success` at the source commit | Physical Intel execution or notarization |
| Published asset metadata and checksum | DMG name, size, URL, and SHA-256 below | Unique users or download success on another machine |
| Public Pages response | https://thangldw.github.io/toolbox/ returned HTTP 200 | Visual fidelity on every browser or successful DMG launch |
| Repository-local checks dated `2026-08-25` | Source behavior, migration, recovery, bundle slices, and ad-hoc signature structure | Publication, Developer ID signing, notarization, or Gatekeeper acceptance |
| Authenticated Product Hunt observation | `This product is scheduled for August 26th, 2026 12:01 AM PDT.` and `Upvoting is disabled until the launch is live.` | Later launch status, votes, followers, users, or downloads |

### Stable identity and published artifact

| Field | Evidence |
| --- | --- |
| Tag | `v2.0.0` |
| Release state | Published `2026-08-25T12:33:04Z`; not draft; not prerelease |
| Release URL | https://github.com/thangldw/toolbox/releases/tag/v2.0.0 |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Version | `2.0.0` |
| Bundle identifier | `com.thang.toolbox` |
| Minimum macOS | `13.0` |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` bytes |
| DMG URL | https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg |
| Checksum asset | `Toolbox-2.0.0.dmg.sha256` |
| DMG SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |

The public artifact identity is the tag, source commit, asset name, byte size, and checksum together. No download count is used as identity or adoption evidence.

### Exact workflow and Pages evidence

| Gate | Exact evidence | Result |
| --- | --- | --- |
| Release | https://github.com/thangldw/toolbox/actions/runs/32847772209 | completed `success` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Pages | https://github.com/thangldw/toolbox/actions/runs/32847688077 | completed `success` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Public site | https://thangldw.github.io/toolbox/ | HTTP 200 at observation time |

Workflow success is tied to the exact source commit. It is not generalized to unrelated commits or rebuilt artifacts.

### Architecture, signature, and Apple trust

| Evidence | Recorded result |
| --- | --- |
| Bundle slices | `arm64` and `x86_64` are present in the universal bundle |
| Physical Intel execution | No direct evidence is recorded; no claim is made |
| Signature structure | Ad-hoc signature; structural verification is not an Apple trust chain |
| Developer ID Application | Absent for this release |
| Apple notarization | Absent for the app and DMG |
| Stapling | Absent for the app and DMG |
| Gatekeeper direct first launch | Rejection is expected; this is not a passing `spctl` result |
| Safe exception | **System Settings → Privacy & Security → Open Anyway** for this build only |
| Prohibited workaround | Do not disable Gatekeeper or remove quarantine attributes |
| Homebrew | Unavailable for this release |

Stable is a product-channel label. Ad-hoc signature structure, universal slices, Apple trust, and physical-machine execution are separate claims and remain separate in this record.

### Source and recovery evidence — `2026-08-25`

These are repository-local results retained from the implementation evidence. They do not replace the published-artifact record above.

| Gate | Command | Result |
| --- | --- | --- |
| Format | `swift format lint --recursive --parallel Sources Tests Package.swift` | PASS |
| Core smoke | `./scripts/test_core.sh` | PASS |
| Storage and recovery smoke | `./scripts/test_storage.sh` | PASS; five byte-for-byte restores plus one no-overwrite conflict |
| Change Timeline smoke | `./scripts/test_changes.sh` | PASS |
| App/update contract | `./scripts/test_app.sh` | PASS |
| Localization | `./scripts/lint_localizations.swift` | PASS for the recorded English/Vietnamese contract |
| Universal bundle | `./scripts/build_universal.sh` | PASS; `arm64 x86_64` slices |
| Local DMG structure | `./scripts/build_dmg.sh && ./scripts/verify_release.sh --allow-adhoc` | PASS for checksum, mount, resources, and ad-hoc signature structure |
| Local XCTest under Command Line Tools | `swift test` | Not executed successfully there; `XCTest` was unavailable in that environment |

Migration smoke covered Diskora cleanup history, completed and interrupted Changeora sessions, idempotent second migration, and corrupt legacy input without partial markers or destructive writes. Recovery smoke restored five independent Trash fixtures byte-for-byte and preserved an existing destination in the conflict case.

### Explicit non-claims and related records

This evidence does not claim a performance comparison, a physical Intel launch, a clean-account production launch, Developer ID signing, notarization, stapling, Homebrew distribution, a beta cohort, defect counts, votes, followers, unique users, or downloads. Absence of those claims does not change the recorded fact that `v2.0.0` is already published as the stable product-channel release.

See the [stable release record](../launch/toolbox-2.0.0.md) and [Product Hunt observation](../launch/product-hunt.md).

## Tiếng Việt

### Ranh giới record và source audit

Record này đóng băng stable state quan sát từ bên ngoài lúc `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`. Nó thay ledger beta candidate trước publication. Một release có thể stable theo product channel nhưng vẫn không có Apple trust approval.

| Source | Fact đã quan sát | Không chứng minh |
| --- | --- | --- |
| GitHub release metadata | `v2.0.0` đã publish, không phải draft/prerelease, có asset được ghi dưới đây | End-user launch, adoption hoặc Apple approval |
| Exact GitHub Actions run | Release run `32847772209` và Pages run `32847688077` completed `success` tại source commit | Physical Intel execution hoặc notarization |
| Published asset metadata/checksum | Tên DMG, size, URL và SHA-256 | Unique user hoặc download thành công trên máy khác |
| Public Pages response | https://thangldw.github.io/toolbox/ trả HTTP 200 | Visual fidelity trên mọi browser hoặc DMG launch thành công |
| Repository-local check ngày `2026-08-25` | Source behavior, migration, recovery, bundle slice và cấu trúc ad-hoc signature | Publication, Developer ID, notarization hoặc Gatekeeper acceptance |
| Quan sát Product Hunt đã authenticate | Trang đã lên lịch và chưa live tại thời điểm quan sát | Trạng thái sau đó, vote, follower, user hoặc download |

### Stable identity và published artifact

| Field | Evidence |
| --- | --- |
| Tag | `v2.0.0` |
| Release state | Publish `2026-08-25T12:33:04Z`; không phải draft; không phải prerelease |
| Release URL | https://github.com/thangldw/toolbox/releases/tag/v2.0.0 |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Version | `2.0.0` |
| Bundle identifier | `com.thang.toolbox` |
| Minimum macOS | `13.0` |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` byte |
| DMG URL | https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg |
| Checksum asset | `Toolbox-2.0.0.dmg.sha256` |
| DMG SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |

Public artifact identity là tổ hợp tag, source commit, asset name, byte size và checksum. Không dùng download count làm identity hay adoption evidence.

### Exact workflow và Pages evidence

| Gate | Exact evidence | Result |
| --- | --- | --- |
| Release | https://github.com/thangldw/toolbox/actions/runs/32847772209 | completed `success` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Pages | https://github.com/thangldw/toolbox/actions/runs/32847688077 | completed `success` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Public site | https://thangldw.github.io/toolbox/ | HTTP 200 tại thời điểm quan sát |

Workflow success chỉ gắn với exact source commit, không áp dụng cho commit khác hay artifact rebuild.

### Architecture, signature và Apple trust

| Evidence | Kết quả ghi nhận |
| --- | --- |
| Bundle slice | Universal bundle có `arm64` và `x86_64` |
| Physical Intel execution | Không có direct evidence; không claim |
| Signature structure | Ad-hoc signature; structural verification không phải Apple trust chain |
| Developer ID Application | Không có cho release này |
| Apple notarization | Không có cho app và DMG |
| Stapling | Không có cho app và DMG |
| Gatekeeper direct first launch | Dự kiến bị từ chối; không phải kết quả `spctl` pass |
| Safe exception | **System Settings → Privacy & Security → Open Anyway** chỉ cho build này |
| Workaround bị cấm | Không tắt Gatekeeper hoặc xóa quarantine attribute |
| Homebrew | Không available cho release này |

Stable là nhãn product channel. Cấu trúc ad-hoc signature, universal slice, Apple trust và physical-machine execution là các claim tách biệt.

### Source và recovery evidence — `2026-08-25`

Đây là repository-local result giữ lại từ implementation evidence, không thay thế published-artifact record.

| Gate | Command | Result |
| --- | --- | --- |
| Format | `swift format lint --recursive --parallel Sources Tests Package.swift` | PASS |
| Core smoke | `./scripts/test_core.sh` | PASS |
| Storage/recovery smoke | `./scripts/test_storage.sh` | PASS; năm restore byte-for-byte và một no-overwrite conflict |
| Change Timeline smoke | `./scripts/test_changes.sh` | PASS |
| App/update contract | `./scripts/test_app.sh` | PASS |
| Localization | `./scripts/lint_localizations.swift` | PASS cho English/Vietnamese contract đã ghi |
| Universal bundle | `./scripts/build_universal.sh` | PASS; slice `arm64 x86_64` |
| Local DMG structure | `./scripts/build_dmg.sh && ./scripts/verify_release.sh --allow-adhoc` | PASS cho checksum, mount, resource và cấu trúc ad-hoc signature |
| Local XCTest dưới Command Line Tools | `swift test` | Không chạy thành công tại đó vì environment không có `XCTest` |

Migration smoke bao phủ Diskora cleanup history, Changeora session đã complete/bị interrupt, migration lần hai idempotent và corrupt legacy input không tạo partial marker hay destructive write. Recovery smoke restore năm Trash fixture độc lập byte-for-byte và giữ nguyên destination đã tồn tại trong conflict case.

### Non-claim rõ ràng và record liên quan

Evidence này không claim performance comparison, physical Intel launch, clean-account production launch, Developer ID signing, notarization, stapling, Homebrew distribution, beta cohort, defect count, vote, follower, unique user hay download. Việc không claim các mục đó không thay đổi fact đã ghi rằng `v2.0.0` đã publish trên stable product channel.

Xem [stable release record](../launch/toolbox-2.0.0.md) và [Product Hunt observation](../launch/product-hunt.md).

## 日本語

### Record boundary と source audit

この record は外部観測した stable state を `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` 時点で固定します。Publication 前の beta-candidate ledger を置き換えます。Release は product channel で stable でも、Apple trust approval がない場合があります。

| Source | 観測した fact | 証明しないもの |
| --- | --- | --- |
| GitHub release metadata | `v2.0.0` は published、non-draft、non-prerelease で、下記 asset を持つ | End-user launch、adoption、Apple approval |
| Exact GitHub Actions run | Release run `32847772209` と Pages run `32847688077` は source commit で completed `success` | Physical Intel execution、notarization |
| Published asset metadata/checksum | DMG name、size、URL、SHA-256 | Unique user、別 machine での download success |
| Public Pages response | https://thangldw.github.io/toolbox/ は HTTP 200 | 全 browser の visual fidelity、DMG launch success |
| `2026-08-25` の repository-local check | Source behavior、migration、recovery、bundle slice、ad-hoc signature structure | Publication、Developer ID、notarization、Gatekeeper acceptance |
| Authenticated Product Hunt observation | 観測時に page は scheduled で未 live | その後の status、vote、follower、user、download |

### Stable identity と published artifact

| Field | Evidence |
| --- | --- |
| Tag | `v2.0.0` |
| Release state | `2026-08-25T12:33:04Z` publish; non-draft; non-prerelease |
| Release URL | https://github.com/thangldw/toolbox/releases/tag/v2.0.0 |
| Source commit | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` |
| Version | `2.0.0` |
| Bundle identifier | `com.thang.toolbox` |
| Minimum macOS | `13.0` |
| DMG | `Toolbox-2.0.0.dmg`; `6055290` byte |
| DMG URL | https://github.com/thangldw/toolbox/releases/download/v2.0.0/Toolbox-2.0.0.dmg |
| Checksum asset | `Toolbox-2.0.0.dmg.sha256` |
| DMG SHA-256 | `ce9bdf8cfb67089c004d66302ef33ebd2d0c603a43435e66d58e447be9943dba` |

Public artifact identity は tag、source commit、asset name、byte size、checksum の組です。Download count を identity または adoption evidence に使いません。

### Exact workflow と Pages evidence

| Gate | Exact evidence | Result |
| --- | --- | --- |
| Release | https://github.com/thangldw/toolbox/actions/runs/32847772209 | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` で completed `success` |
| Pages | https://github.com/thangldw/toolbox/actions/runs/32847688077 | `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` で completed `success` |
| Public site | https://thangldw.github.io/toolbox/ | 観測時 HTTP 200 |

Workflow success は exact source commit にだけ結び付け、別 commit や rebuilt artifact に一般化しません。

### Architecture、signature、Apple trust

| Evidence | 記録結果 |
| --- | --- |
| Bundle slice | Universal bundle は `arm64` と `x86_64` を含む |
| Physical Intel execution | Direct evidence なし。Claim しない |
| Signature structure | Ad-hoc signature。Structural verification は Apple trust chain ではない |
| Developer ID Application | この release にはなし |
| Apple notarization | App と DMG の両方になし |
| Stapling | App と DMG の両方になし |
| Gatekeeper direct first launch | Rejection が expected。`spctl` pass result ではない |
| Safe exception | この build に限り **System Settings → Privacy & Security → Open Anyway** |
| 禁止 workaround | Gatekeeper を無効化せず、quarantine attribute を削除しない |
| Homebrew | この release では unavailable |

Stable は product-channel label です。Ad-hoc signature structure、universal slice、Apple trust、physical-machine execution は別々の claim として扱います。

### Source と recovery evidence — `2026-08-25`

以下は implementation evidence から保持した repository-local result であり、published-artifact record を置き換えません。

| Gate | Command | Result |
| --- | --- | --- |
| Format | `swift format lint --recursive --parallel Sources Tests Package.swift` | PASS |
| Core smoke | `./scripts/test_core.sh` | PASS |
| Storage/recovery smoke | `./scripts/test_storage.sh` | PASS; 5 件の byte-for-byte restore と 1 件の no-overwrite conflict |
| Change Timeline smoke | `./scripts/test_changes.sh` | PASS |
| App/update contract | `./scripts/test_app.sh` | PASS |
| Localization | `./scripts/lint_localizations.swift` | 記録済み English/Vietnamese contract で PASS |
| Universal bundle | `./scripts/build_universal.sh` | PASS; `arm64 x86_64` slice |
| Local DMG structure | `./scripts/build_dmg.sh && ./scripts/verify_release.sh --allow-adhoc` | Checksum、mount、resource、ad-hoc signature structure で PASS |
| Command Line Tools の local XCTest | `swift test` | その environment に `XCTest` がなく成功実行できず |

Migration smoke は Diskora cleanup history、completed/interrupted Changeora session、idempotent second migration、partial marker/destructive write を残さない corrupt legacy input を対象にしました。Recovery smoke は 5 個の独立 Trash fixture を byte-for-byte restore し、conflict case の existing destination を保持しました。

### 明示的 non-claim と関連 record

この evidence は performance comparison、physical Intel launch、clean-account production launch、Developer ID signing、notarization、stapling、Homebrew distribution、beta cohort、defect count、vote、follower、unique user、download を claim しません。これらを claim しないことは、`v2.0.0` が stable product channel で既に publish 済みという fact を変えません。

[Stable release record](../launch/toolbox-2.0.0.md) と [Product Hunt observation](../launch/product-hunt.md) を参照してください。
