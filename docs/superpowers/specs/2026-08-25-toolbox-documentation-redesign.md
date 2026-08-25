# Toolbox Documentation Redesign

Status: approved for planning on 2026-08-25.

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Purpose

Rewrite every tracked Markdown document related to Toolbox 2.0 as an engineering-first documentation system. The result must help a technical reader verify product behavior, safety boundaries, build and release evidence, while still giving end users a direct installation and first-launch path.

The baseline contains 18 tracked Markdown files. This design record is an additional workflow artifact and follows the same trilingual contract.

### Documentation architecture

`README.md` is the compact technical entry point. It explains the product boundary, directs users to the stable download and safe Gatekeeper flow, shows the repository layout, and routes readers to deeper references.

The root policy documents have non-overlapping ownership:

- `CONTRIBUTING.md` defines engineering workflow, review evidence, localization, accessibility, and change discipline.
- `PRIVACY.md` defines local processing, stored data, permissions, network behavior, exports, and legacy migration.
- `SECURITY.md` defines supported versions, vulnerability reporting, safety invariants, release trust, and incident response.
- `CHANGELOG.md` preserves release history without becoming an operations manual.

The canonical engineering references are:

- `docs/ARCHITECTURE.md` for dependency direction, module boundaries, local data, macOS integrations, and trust boundaries.
- `docs/OPERATIONS.md` for development, validation, runtime maintenance, scheduled scans, update checks, and recovery operations.
- `docs/OPERATIONS-RELEASE.md` for immutable artifact production, the `v2.0.0` signing exception, future notarized releases, and post-publication verification.

Launch and evidence records remain separate from canonical policy. Beta and stable release notes remain historical records. Product Hunt copy, site fidelity evidence, the demo script, and release evidence state exactly when they were observed and do not silently become permanent product contracts.

The four existing files under `docs/superpowers/` are rewritten as as-built engineering records. They retain goals, contracts, file ownership, failure modes, implementation decisions, and verification evidence, but remove future-tense instructions, incomplete checklists, and superseded launch claims.

### Language contract

All 18 baseline Markdown files and this design record contain complete English, Vietnamese, and Japanese sections in that order. English is the canonical wording for commands, identifiers, file paths, API endpoints, and immutable release evidence. Vietnamese and Japanese must preserve the same requirements and limitations rather than provide shorter summaries.

Source identifiers, shell commands, filenames, URLs, bundle identifiers, tag names, commit SHAs, and checksum values are never translated. Product terminology may remain in English when translation would obscure an exact UI label or technical contract.

### Evidence contract

Documentation claims are resolved against the following authority order:

1. Source code and executable tests.
2. GitHub workflow definitions and exact-run results.
3. Published release metadata and re-downloaded artifacts.
4. Documentation and launch copy.

Current claims must match the first available higher-authority source. Historical records keep their original time boundary and are labeled historical. Volatile values such as download counts are either removed or paired with an observation timestamp. Unknown evidence is described as unknown; it is never upgraded to a pass through inference.

The stable release evidence record replaces the stale beta-candidate framing. It records the stable tag, source commit, artifact checksum, architecture slices, ad-hoc signature, expected Gatekeeper rejection, exact CI/release/Pages runs, and the absence of Apple notarization. It must not claim Developer ID signing, stapling, Homebrew availability, unique-user counts, or physical Intel launch evidence without direct proof.

### Diagrams

The repository selects the saved `thangldw` Diagram Design profile through a root `.diagram-design` marker. Diagrams are static, self-contained HTML documents under `docs/diagrams/`, with inline SVG/CSS, accessible SVG titles and descriptions, and trilingual explanatory text.

Three diagrams are required:

1. `toolbox-architecture.html` uses the **Secure paved road** semantic pattern and **Architecture** type at `doc-wide` size for an engineer audience. It shows the GUI, Core, Storage, Changes, local stores, macOS services, and the single user-initiated GitHub Releases network path. It omits per-file implementation detail.
2. `install-trace-sequence.html` uses the **Sequence** type at `doc-wide` size with at most five lifelines. It shows the before snapshot, bounded FSEvents observation, normal macOS installer flow, after comparison, evidence persistence, and review handoff. Scheduled scans and exports are excluded.
3. `review-recovery-state.html` uses the **State machine** type at `doc-wide` size with at most seven states. It shows candidate review, confirmation, immediate revalidation, Trash-backed mutation, recovery eligibility, conflict-safe restore, and blocked outcomes. Non-mutating scans and legacy migration are excluded.

SVG labels remain concise technical English. Each HTML page provides semantically equivalent English, Vietnamese, and Japanese interpretation below the figure. Motion is not used.

### Scope by file group

The rewrite covers:

- Root: `README.md`, `CONTRIBUTING.md`, `PRIVACY.md`, `SECURITY.md`, `CHANGELOG.md`.
- Canonical references: `docs/ARCHITECTURE.md`, `docs/OPERATIONS.md`, `docs/OPERATIONS-RELEASE.md`.
- Launch and evidence: `docs/launch/product-hunt.md`, `docs/launch/toolbox-2.0.0-beta.1.md`, `docs/launch/toolbox-2.0.0.md`, `docs/release-evidence/toolbox-2.0-beta.md`, `docs/design-evidence/toolbox-site-fidelity.md`, `site/assets/demo-script.md`.
- Engineering records: the existing Toolbox 2.0 spec and three plans under `docs/superpowers/`.

The beta evidence file is renamed to a stable `toolbox-2.0.0.md` record and all references are updated. No historical release note or changelog entry is deleted. Application source and website design are outside scope; site copy or tests may change only where required to preserve documentation and release contracts.

### Verification

The implementation must add or update deterministic checks for:

- valid relative Markdown links and renamed evidence paths;
- complete English, Vietnamese, and Japanese top-level sections in every tracked Markdown file;
- absence of stale current claims such as an unpublished `v2.0.0`, a blocked public launch, or a promised notarized stable release;
- preservation of the explicit ad-hoc-signed, unnotarized `v2.0.0` boundary and safe **Open Anyway** guidance;
- exact references required by release and launch workflows;
- Diagram Design self-check and geometry validation for every new HTML diagram;
- existing launch, release, localization, smoke, build, bundle, and signature gates.

Before completion, the exact pushed commit must have successful GitHub CI. The public Pages site and latest GitHub release are rechecked when documentation changes affect their contracts.

## Tiếng Việt

### Mục tiêu

Viết lại mọi tài liệu Markdown được track liên quan đến Toolbox 2.0 thành một hệ thống tài liệu ưu tiên kỹ thuật. Kết quả phải giúp người đọc kỹ thuật xác minh hành vi sản phẩm, ranh giới an toàn, bằng chứng build/release, đồng thời vẫn cung cấp đường dẫn cài đặt và first-launch trực tiếp cho người dùng.

Baseline có 18 file Markdown được track. Design record này là artifact điều phối bổ sung và tuân theo cùng contract ba ngôn ngữ.

### Kiến trúc tài liệu

`README.md` là điểm vào kỹ thuật ngắn gọn. File này giải thích ranh giới sản phẩm, dẫn đến bản stable và luồng Gatekeeper an toàn, mô tả layout repository và chuyển người đọc đến reference sâu hơn.

Các policy document ở root có ownership không chồng lặp:

- `CONTRIBUTING.md` định nghĩa workflow kỹ thuật, evidence khi review, localization, accessibility và kỷ luật thay đổi.
- `PRIVACY.md` định nghĩa xử lý local, dữ liệu lưu, permission, network behavior, export và legacy migration.
- `SECURITY.md` định nghĩa version được support, báo cáo lỗ hổng, safety invariant, release trust và incident response.
- `CHANGELOG.md` giữ lịch sử release nhưng không trở thành operations manual.

Các engineering reference canonical là:

- `docs/ARCHITECTURE.md` cho dependency direction, module boundary, dữ liệu local, tích hợp macOS và trust boundary.
- `docs/OPERATIONS.md` cho development, validation, runtime maintenance, scheduled scan, update check và recovery operation.
- `docs/OPERATIONS-RELEASE.md` cho tạo artifact immutable, ngoại lệ signing của `v2.0.0`, release notarized trong tương lai và verification sau publish.

Launch/evidence record tách khỏi policy canonical. Release note beta và stable vẫn là hồ sơ lịch sử. Product Hunt copy, site fidelity evidence, demo script và release evidence phải ghi rõ thời điểm quan sát, không âm thầm trở thành product contract vĩnh viễn.

Bốn file hiện tại dưới `docs/superpowers/` được viết lại thành as-built engineering record. Chúng giữ goal, contract, file ownership, failure mode, implementation decision và verification evidence, nhưng loại bỏ chỉ dẫn ở thì tương lai, checklist chưa hoàn tất và launch claim đã lỗi thời.

### Contract ngôn ngữ

Toàn bộ 18 file Markdown baseline và design record này có đầy đủ phần English, Vietnamese và Japanese theo thứ tự đó. English là wording canonical cho command, identifier, file path, API endpoint và immutable release evidence. Vietnamese và Japanese phải giữ cùng requirement và limitation, không phải bản tóm tắt ngắn hơn.

Source identifier, shell command, filename, URL, bundle identifier, tag, commit SHA và checksum không được dịch. Product terminology có thể giữ English nếu dịch làm mờ UI label hoặc technical contract chính xác.

### Contract evidence

Claim trong tài liệu được giải quyết theo thứ tự authority:

1. Source code và executable test.
2. GitHub workflow definition và kết quả exact run.
3. Published release metadata và artifact được tải lại.
4. Documentation và launch copy.

Claim hiện tại phải khớp nguồn authority cao hơn đầu tiên có sẵn. Historical record giữ time boundary gốc và được gắn nhãn lịch sử. Giá trị biến động như download count phải bị loại bỏ hoặc có timestamp quan sát. Evidence chưa biết phải ghi là chưa biết; không được suy luận thành pass.

Stable release evidence thay framing beta candidate đã lỗi thời. Record này ghi stable tag, source commit, artifact checksum, architecture slice, ad-hoc signature, Gatekeeper rejection dự kiến, exact CI/release/Pages run và trạng thái chưa Apple-notarize. Không được claim Developer ID signing, stapling, Homebrew, unique-user count hoặc physical Intel launch nếu không có proof trực tiếp.

### Sơ đồ

Repository chọn Diagram Design profile `thangldw` bằng marker `.diagram-design` ở root. Sơ đồ là HTML static, self-contained dưới `docs/diagrams/`, dùng inline SVG/CSS, có SVG title/description accessible và phần giải thích ba ngôn ngữ.

Ba sơ đồ bắt buộc:

1. `toolbox-architecture.html` dùng semantic pattern **Secure paved road** và type **Architecture**, size `doc-wide`, audience engineer. Sơ đồ thể hiện GUI, Core, Storage, Changes, local store, macOS service và network path GitHub Releases duy nhất do người dùng kích hoạt. Chi tiết theo từng file bị loại bỏ.
2. `install-trace-sequence.html` dùng type **Sequence**, size `doc-wide`, tối đa năm lifeline. Sơ đồ thể hiện before snapshot, quan sát FSEvents có giới hạn, installer flow bình thường của macOS, after comparison, lưu evidence và review handoff. Scheduled scan và export bị loại bỏ.
3. `review-recovery-state.html` dùng type **State machine**, size `doc-wide`, tối đa bảy state. Sơ đồ thể hiện candidate review, confirmation, revalidation ngay trước hành động, mutation qua Trash, recovery eligibility, restore không xung đột và blocked outcome. Scan không mutation và legacy migration bị loại bỏ.

Nhãn SVG dùng technical English ngắn gọn. Mỗi HTML có diễn giải tương đương bằng English, Vietnamese và Japanese bên dưới figure. Không dùng motion.

### Phạm vi theo nhóm file

Rewrite bao phủ:

- Root: `README.md`, `CONTRIBUTING.md`, `PRIVACY.md`, `SECURITY.md`, `CHANGELOG.md`.
- Canonical reference: `docs/ARCHITECTURE.md`, `docs/OPERATIONS.md`, `docs/OPERATIONS-RELEASE.md`.
- Launch/evidence: `docs/launch/product-hunt.md`, `docs/launch/toolbox-2.0.0-beta.1.md`, `docs/launch/toolbox-2.0.0.md`, `docs/release-evidence/toolbox-2.0-beta.md`, `docs/design-evidence/toolbox-site-fidelity.md`, `site/assets/demo-script.md`.
- Engineering record: Toolbox 2.0 spec và ba plan hiện có dưới `docs/superpowers/`.

File beta evidence được đổi tên thành stable record `toolbox-2.0.0.md` và mọi reference được cập nhật. Không xóa historical release note hoặc changelog entry. Source app và thiết kế website nằm ngoài scope; site copy hoặc test chỉ thay đổi khi cần giữ documentation/release contract.

### Xác minh

Implementation phải thêm hoặc cập nhật deterministic check cho:

- relative Markdown link hợp lệ và evidence path sau rename;
- đầy đủ top-level section English, Vietnamese và Japanese trong mọi Markdown được track;
- không còn current claim lỗi thời như `v2.0.0` chưa publish, public launch bị block hoặc stable notarized được hứa nhưng chưa có;
- giữ ranh giới `v2.0.0` ký ad-hoc, chưa notarize và hướng dẫn **Open Anyway** an toàn;
- giữ exact reference mà release/launch workflow cần;
- Diagram Design self-check và geometry validation cho mọi HTML diagram mới;
- các gate launch, release, localization, smoke, build, bundle và signature hiện có.

Trước khi hoàn tất, exact commit đã push phải có GitHub CI thành công. Public Pages và latest GitHub release được kiểm tra lại khi thay đổi tài liệu ảnh hưởng contract của chúng.

## 日本語

### 目的

Toolbox 2.0 に関係する追跡済み Markdown 文書を、engineering-first の documentation system として全面的に書き直します。技術読者が product behavior、安全境界、build/release evidence を検証できることを優先しつつ、end user に stable install と first-launch の直接的な手順も提供します。

Baseline には 18 個の追跡済み Markdown file があります。この design record は追加の workflow artifact で、同じ三言語 contract に従います。

### Documentation architecture

`README.md` は短い technical entry point です。Product boundary、stable download、安全な Gatekeeper flow、repository layout を説明し、詳細 reference へ案内します。

Root policy document の責務は重複させません。

- `CONTRIBUTING.md` は engineering workflow、review evidence、localization、accessibility、change discipline を定義します。
- `PRIVACY.md` は local processing、保存 data、permission、network behavior、export、legacy migration を定義します。
- `SECURITY.md` は supported version、vulnerability reporting、安全 invariant、release trust、incident response を定義します。
- `CHANGELOG.md` は release history を保持し、operations manual にはしません。

Canonical engineering reference は次の三つです。

- `docs/ARCHITECTURE.md`: dependency direction、module boundary、local data、macOS integration、trust boundary。
- `docs/OPERATIONS.md`: development、validation、runtime maintenance、scheduled scan、update check、recovery operation。
- `docs/OPERATIONS-RELEASE.md`: immutable artifact production、`v2.0.0` signing exception、将来の notarized release、公開後 verification。

Launch/evidence record は canonical policy と分離します。Beta/stable release note は historical record として残します。Product Hunt copy、site fidelity evidence、demo script、release evidence は観測時点を明示し、永続的な product contract に変えません。

`docs/superpowers/` の既存四 file は as-built engineering record に書き直します。Goal、contract、file ownership、failure mode、implementation decision、verification evidence を保持し、future-tense instruction、未完了 checklist、古い launch claim を除去します。

### 言語 contract

Baseline の 18 Markdown file とこの design record は、English、Vietnamese、Japanese の完全な section をこの順序で持ちます。Command、identifier、file path、API endpoint、immutable release evidence は English wording を canonical とします。Vietnamese と Japanese は短縮 summary ではなく、同じ requirement と limitation を保持します。

Source identifier、shell command、filename、URL、bundle identifier、tag、commit SHA、checksum は翻訳しません。正確な UI label や technical contract を曖昧にする場合、product term は English のまま使えます。

### Evidence contract

Documentation claim の authority 順序は次の通りです。

1. Source code と executable test。
2. GitHub workflow definition と exact-run result。
3. Published release metadata と再 download した artifact。
4. Documentation と launch copy。

Current claim は、利用できる最初の高 authority source と一致させます。Historical record は元の time boundary を維持して historical と明示します。Download count のような変動値は削除するか観測 timestamp を付けます。Unknown evidence は unknown と記録し、推測で pass にしません。

Stable release evidence は古い beta-candidate framing を置き換えます。Stable tag、source commit、artifact checksum、architecture slice、ad-hoc signature、expected Gatekeeper rejection、exact CI/release/Pages run、Apple notarization がないことを記録します。直接 proof がない Developer ID signing、stapling、Homebrew、unique-user count、physical Intel launch は claim しません。

### Diagram

Repository root の `.diagram-design` marker で保存済み `thangldw` profile を選択します。Diagram は `docs/diagrams/` の static self-contained HTML で、inline SVG/CSS、accessible SVG title/description、三言語の説明を持ちます。

必須 diagram は三つです。

1. `toolbox-architecture.html`: **Secure paved road** semantic pattern、**Architecture** type、`doc-wide`、engineer audience。GUI、Core、Storage、Changes、local store、macOS service、user-initiated の唯一の GitHub Releases network path を示します。File 単位の詳細は除外します。
2. `install-trace-sequence.html`: **Sequence** type、`doc-wide`、最大五 lifeline。Before snapshot、bounded FSEvents observation、通常の macOS installer flow、after comparison、evidence persistence、review handoff を示します。Scheduled scan と export は除外します。
3. `review-recovery-state.html`: **State machine** type、`doc-wide`、最大七 state。Candidate review、confirmation、action 直前の revalidation、Trash-backed mutation、recovery eligibility、conflict-safe restore、blocked outcome を示します。Non-mutating scan と legacy migration は除外します。

SVG label は短い technical English を使います。各 HTML は figure の下に同等の English、Vietnamese、Japanese 解説を置きます。Motion は使いません。

### File group ごとの scope

Rewrite 対象:

- Root: `README.md`, `CONTRIBUTING.md`, `PRIVACY.md`, `SECURITY.md`, `CHANGELOG.md`。
- Canonical reference: `docs/ARCHITECTURE.md`, `docs/OPERATIONS.md`, `docs/OPERATIONS-RELEASE.md`。
- Launch/evidence: `docs/launch/product-hunt.md`, `docs/launch/toolbox-2.0.0-beta.1.md`, `docs/launch/toolbox-2.0.0.md`, `docs/release-evidence/toolbox-2.0-beta.md`, `docs/design-evidence/toolbox-site-fidelity.md`, `site/assets/demo-script.md`。
- Engineering record: `docs/superpowers/` の既存 Toolbox 2.0 spec と三 plan。

Beta evidence file は stable record `toolbox-2.0.0.md` に rename し、全 reference を更新します。Historical release note と changelog entry は削除しません。Application source と website design は scope 外です。Site copy または test は documentation/release contract 維持に必要な場合だけ変更します。

### Verification

Implementation は次の deterministic check を追加または更新します。

- Relative Markdown link と rename 後の evidence path が有効であること。
- すべての追跡済み Markdown file に完全な English、Vietnamese、Japanese top-level section があること。
- `v2.0.0` 未公開、public launch blocked、notarized stable promised などの古い current claim が残らないこと。
- `v2.0.0` の ad-hoc signed、unnotarized 境界と安全な **Open Anyway** guidance を保持すること。
- Release/launch workflow が必要とする exact reference を保持すること。
- 新しい各 HTML diagram に Diagram Design self-check と geometry validation を実行すること。
- 既存の launch、release、localization、smoke、build、bundle、signature gate を維持すること。

完了前に、push 済み exact commit の GitHub CI が成功していなければなりません。Documentation change が contract に影響する場合、public Pages と latest GitHub release も再確認します。
