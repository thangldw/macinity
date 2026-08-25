# Toolbox Product Hunt Launch Record

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Observed state

This is a time-bounded record of the authenticated Product Hunt page, not a claim about later launch activity.

- Observation time: `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`.
- Canonical URL: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14
- Authenticated page status: `This product is scheduled for August 26th, 2026 12:01 AM PDT.` Interactive voting was disabled until the launch became live.
- Result at observation time: scheduled, not launched.
- Visible tagline: `Understand Mac changes before you clean them up`.

Status: SCHEDULED — August 26, 2026 at 12:01 AM PDT.

Launch URL: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14

### Visible copy and stable-release reconciliation

Name: Toolbox

Tagline: Understand Mac changes before you clean them up

Description: The visible description said Toolbox is free and open source; traces installer changes; finds known rebuildable output only in user-chosen folders; records Trash-backed cleanup; and runs locally without an account, telemetry, a privileged helper, or automatic deletion. It still called the current build a public beta, which conflicts with the stable GitHub release identity recorded below. Not Apple-notarized; first launch requires Open Anyway.

Topics: Developer Tools, Mac, Open Source

Pricing: Free

Website: https://thangldw.github.io/toolbox/

GitHub: https://github.com/thangldw/toolbox

First comment: The visible maker comment still called the release a first public beta. Its workflow and trust content remained accurate: Install Trace compares filesystem metadata around the normal installer flow; Projects finds known rebuildable output only inside selected roots; Recovery retains evidence for Trash-backed cleanup; processing is local; the build is ad-hoc signed and not notarized; the safe exception is Open Anyway; checksum and source are available. It asks what evidence developers need before cleaning a path, which confirmation or recovery step is unclear, and which project artifact Toolbox should recognize next; feedback must omit private paths and files. The stable-aligned repository copy is: Toolbox 2.0 is a stable product release, but it is ad-hoc signed and not notarized by Apple. Do not disable Gatekeeper or remove quarantine attributes. Report reproducible issues at https://github.com/thangldw/toolbox/issues without private paths or files.

The words “public beta” and “first public beta” are retained here only as observed stale Product Hunt copy. They do not define the current release channel. The higher-authority GitHub record shows `v2.0.0`, published `2026-08-25T12:33:04Z`, non-draft, non-prerelease, from `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

### Gallery and recording evidence

1. `product-hunt-home.png` — One place to understand storage, change evidence, and recovery.
2. `product-hunt-trace.png` — Compare before/after metadata and review each affected path.
3. `product-hunt-projects.png` — Find known rebuildable artifacts only inside selected project roots.
4. `product-hunt-recovery.png` — Restore Trash-backed actions only after destination and source checks pass.

The gallery images are `1270×760`; `product-hunt-thumbnail.png` is `512×512`. They use representative local fixture data, contain no private paths, and are visual demonstrations rather than production-user evidence.

### Product and evidence boundary

- Maker: Thang (`thangldw`).
- Product status: free, open source, macOS 13+.
- Primary action: Download for macOS.
- Secondary action: View source.
- Support: https://github.com/thangldw/toolbox/issues
- Privacy: https://thangldw.github.io/toolbox/privacy.html
- `v2.0.0` is stable at the product-channel level, ad-hoc signed, and not Apple-notarized.
- Direct first launch is expected to be rejected by Gatekeeper. Use **System Settings → Privacy & Security → Open Anyway** for this build only.
- Never disable Gatekeeper or remove quarantine attributes.
- No vote, follower, user, download, or adoption count is recorded or inferred.

## Tiếng Việt

### Trạng thái đã quan sát

Đây là record có mốc thời gian của trang Product Hunt đã đăng nhập, không phải claim về hoạt động launch sau thời điểm đó.

- Thời điểm quan sát: `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`.
- URL canonical: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14
- Trạng thái trên trang: `This product is scheduled for August 26th, 2026 12:01 AM PDT.` Chức năng bình chọn bị vô hiệu hóa cho đến khi launch bắt đầu.
- Kết quả tại thời điểm quan sát: đã lên lịch, chưa launch.
- Tagline hiển thị: `Understand Mac changes before you clean them up`.

Status: SCHEDULED — August 26, 2026 at 12:01 AM PDT.

Launch URL: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14

### Đối chiếu copy hiển thị với stable release

Name: Toolbox

Tagline: Understand Mac changes before you clean them up

Description: Description hiển thị nói Toolbox miễn phí và mã nguồn mở; trace thay đổi của installer; chỉ tìm known rebuildable output trong folder người dùng chọn; ghi nhận cleanup qua Trash; và chạy local không account, telemetry, privileged helper hoặc automatic deletion. Description vẫn gọi build hiện tại là public beta, mâu thuẫn với stable GitHub release identity ghi bên dưới. Chưa Apple-notarized; lần mở đầu yêu cầu Open Anyway.

Topics: Developer Tools, Mac, Open Source

Pricing: Free

Website: https://thangldw.github.io/toolbox/

GitHub: https://github.com/thangldw/toolbox

First comment: Maker comment hiển thị vẫn gọi release là first public beta. Nội dung workflow và trust vẫn chính xác: Install Trace so sánh filesystem metadata quanh luồng installer bình thường; Projects chỉ tìm known rebuildable output trong selected root; Recovery giữ evidence cho cleanup qua Trash; xử lý ở local; build ký ad-hoc và chưa notarize; exception an toàn là Open Anyway; checksum và source có sẵn. Comment hỏi developer cần evidence nào trước khi clean một path, confirmation hoặc recovery step nào chưa rõ và Toolbox nên nhận diện project artifact nào tiếp theo; feedback phải bỏ private path và file. Stable-aligned repository copy là: Toolbox 2.0 is a stable product release, but it is ad-hoc signed and not notarized by Apple. Do not disable Gatekeeper or remove quarantine attributes. Report reproducible issues at https://github.com/thangldw/toolbox/issues without private paths or files.

Các từ “public beta” và “first public beta” chỉ được giữ ở đây như stale Product Hunt copy đã quan sát. Chúng không định nghĩa current release channel. GitHub record có authority cao hơn cho thấy `v2.0.0`, publish lúc `2026-08-25T12:33:04Z`, non-draft, non-prerelease, từ `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

### Gallery và recording evidence

1. `product-hunt-home.png` — Một nơi để hiểu storage, change evidence và recovery.
2. `product-hunt-trace.png` — So sánh metadata trước/sau và review từng path bị ảnh hưởng.
3. `product-hunt-projects.png` — Chỉ tìm known rebuildable artifact trong project root đã chọn.
4. `product-hunt-recovery.png` — Chỉ restore action qua Trash sau khi source và destination check thành công.

Gallery image có kích thước `1270×760`; `product-hunt-thumbnail.png` là `512×512`. Các ảnh dùng representative local fixture data, không chứa private path và không phải production-user evidence.

### Ranh giới sản phẩm và evidence

- Maker: Thang (`thangldw`).
- Product status: miễn phí, mã nguồn mở, macOS 13+.
- Primary action: Download for macOS.
- Secondary action: View source.
- Support: https://github.com/thangldw/toolbox/issues
- Privacy: https://thangldw.github.io/toolbox/privacy.html
- `v2.0.0` stable ở product-channel level, ký ad-hoc và chưa Apple-notarized.
- Gatekeeper dự kiến từ chối lần mở trực tiếp đầu tiên. Chỉ dùng **System Settings → Privacy & Security → Open Anyway** cho build này.
- Không tắt Gatekeeper hoặc xóa quarantine attribute.
- Không ghi hoặc suy luận số lượt bình chọn, follower, user, download hay adoption.

## 日本語

### 観測した状態

これは authenticated Product Hunt page の時点付き record であり、その後の launch activity を示す claim ではありません。

- 観測時刻: `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`。
- Canonical URL: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14
- Page status: `This product is scheduled for August 26th, 2026 12:01 AM PDT.` Launch 開始までは投票操作が無効でした。
- 観測時点の結果: scheduled であり、未 launch。
- 表示 tagline: `Understand Mac changes before you clean them up`。

Status: SCHEDULED — August 26, 2026 at 12:01 AM PDT.

Launch URL: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14

### 表示 copy と stable release の照合

Name: Toolbox

Tagline: Understand Mac changes before you clean them up

Description: 表示 description は、Toolbox が free/open source であり、installer change を trace し、user-selected folder 内だけで known rebuildable output を検出し、Trash-backed cleanup を記録し、account、telemetry、privileged helper、automatic deletion なしで local 実行することを説明していました。Current build を public beta と呼ぶ部分は、下記 stable GitHub release identity と矛盾します。Apple-notarized ではなく、first launch には Open Anyway が必要です。

Topics: Developer Tools, Mac, Open Source

Pricing: Free

Website: https://thangldw.github.io/toolbox/

GitHub: https://github.com/thangldw/toolbox

First comment: 表示 maker comment は release を first public beta と呼んでいました。Workflow/trust content は正確なままです。Install Trace は通常 installer flow の前後で filesystem metadata を比較し、Projects は selected root 内の known rebuildable output だけを検出し、Recovery は Trash-backed cleanup の evidence を保持します。Processing は local で、build は ad-hoc signed/not notarized、安全な exception は Open Anyway、checksum/source は公開済みです。Cleanup 前に developer が必要とする evidence、不明瞭な confirmation/recovery step、次に認識すべき project artifact を質問し、feedback から private path/file を除くよう求めています。Stable-aligned repository copy は次です: Toolbox 2.0 is a stable product release, but it is ad-hoc signed and not notarized by Apple. Do not disable Gatekeeper or remove quarantine attributes. Report reproducible issues at https://github.com/thangldw/toolbox/issues without private paths or files.

“public beta” と “first public beta” は、観測した stale Product Hunt copy としてのみ保持します。Current release channel を定義しません。より高 authority の GitHub record は、`v2.0.0` が `2026-08-25T12:33:04Z` に publish され、non-draft、non-prerelease、source は `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` であることを示します。

### Gallery と recording evidence

1. `product-hunt-home.png` — Storage、change evidence、recovery を一か所で確認します。
2. `product-hunt-trace.png` — Before/after metadata を比較し、affected path を review します。
3. `product-hunt-projects.png` — Selected project root 内の known rebuildable artifact だけを検出します。
4. `product-hunt-recovery.png` — Source/destination check 成功後にのみ Trash-backed action を restore します。

Gallery image は `1270×760`、`product-hunt-thumbnail.png` は `512×512` です。Representative local fixture data を使い、private path を含まず、production-user evidence ではありません。

### Product と evidence の境界

- Maker: Thang (`thangldw`)。
- Product status: free、open source、macOS 13+。
- Primary action: Download for macOS.
- Secondary action: View source.
- Support: https://github.com/thangldw/toolbox/issues
- Privacy: https://thangldw.github.io/toolbox/privacy.html
- `v2.0.0` は product-channel level では stable ですが、ad-hoc signed で Apple-notarized ではありません。
- Direct first launch は Gatekeeper に拒否される想定です。この build に限り **System Settings → Privacy & Security → Open Anyway** を使います。
- Gatekeeper を無効化せず、quarantine attribute を削除しません。
- Vote、follower、user、download、adoption count は記録も推測もしません。
