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

### Đối chiếu copy hiển thị với stable release

Trang hiển thị Toolbox là phần mềm miễn phí, mã nguồn mở; trace thay đổi của installer; chỉ tìm known rebuildable output trong folder người dùng chọn; ghi nhận cleanup qua Trash; và chạy local không account, telemetry, privileged helper hay automatic deletion. Description vẫn gọi build hiện tại là public beta; maker comment vẫn gọi đây là first public beta.

Hai cách gọi beta được giữ lại chỉ như stale copy đã quan sát. Chúng không xác định release channel hiện tại. GitHub record có authority cao hơn cho thấy `v2.0.0` được publish lúc `2026-08-25T12:33:04Z`, không phải draft hay prerelease, từ commit `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`.

Maker comment vẫn mô tả đúng ba workflow, giới hạn ad-hoc signed/chưa notarize, đường **Open Anyway** an toàn và checksum/source công khai. Comment hỏi developer cần evidence nào trước khi cleanup path, confirmation/recovery step nào chưa rõ và Toolbox nên nhận diện project artifact nào tiếp theo; không gửi private path hay file. Issue tái hiện được báo tại https://github.com/thangldw/toolbox/issues.

### Gallery và recording evidence

1. `product-hunt-home.png` — Một nơi để hiểu storage, change evidence và recovery.
2. `product-hunt-trace.png` — So sánh metadata trước/sau và review từng path bị ảnh hưởng.
3. `product-hunt-projects.png` — Chỉ tìm known rebuildable artifact trong project root đã chọn.
4. `product-hunt-recovery.png` — Chỉ restore action qua Trash sau khi source và destination check thành công.

Gallery image có kích thước `1270×760`; `product-hunt-thumbnail.png` là `512×512`. Các ảnh dùng representative local fixture data, không chứa private path và không phải production-user evidence.

### Ranh giới sản phẩm và evidence

- Maker: Thang (`thangldw`).
- Sản phẩm: miễn phí, mã nguồn mở, macOS 13+.
- Website: https://thangldw.github.io/toolbox/
- Source: https://github.com/thangldw/toolbox
- Support: https://github.com/thangldw/toolbox/issues
- Privacy: https://thangldw.github.io/toolbox/privacy.html
- `v2.0.0` stable theo product channel nhưng ký ad-hoc và chưa được Apple notarize.
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

### 表示 copy と stable release の照合

表示 description は、Toolbox が free/open source であり、installer change を trace し、user-selected folder 内だけで known rebuildable output を検出し、Trash-backed cleanup を記録し、account、telemetry、privileged helper、automatic deletion なしで local 実行することを説明していました。一方、current build を public beta と呼び、maker comment も first public beta と呼んでいました。

この二つの beta 表現は観測した stale copy としてのみ残します。Current release channel の定義ではありません。より高 authority の GitHub record では、`v2.0.0` は `2026-08-25T12:33:04Z` に publish され、draft でも prerelease でもなく、source commit は `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` です。

Maker comment の three workflow、ad-hoc signed/not notarized 制約、安全な **Open Anyway** path、checksum/source 公開は引き続き正確です。Cleanup 前に必要な evidence、分かりにくい confirmation/recovery step、次に認識すべき project artifact を質問し、private path/file を送らないよう求めています。再現可能な issue は https://github.com/thangldw/toolbox/issues に報告します。

### Gallery と recording evidence

1. `product-hunt-home.png` — Storage、change evidence、recovery を一か所で確認します。
2. `product-hunt-trace.png` — Before/after metadata を比較し、affected path を review します。
3. `product-hunt-projects.png` — Selected project root 内の known rebuildable artifact だけを検出します。
4. `product-hunt-recovery.png` — Source/destination check 成功後にのみ Trash-backed action を restore します。

Gallery image は `1270×760`、`product-hunt-thumbnail.png` は `512×512` です。Representative local fixture data を使い、private path を含まず、production-user evidence ではありません。

### Product と evidence の境界

- Maker: Thang (`thangldw`)。
- Product: free、open source、macOS 13+。
- Website: https://thangldw.github.io/toolbox/
- Source: https://github.com/thangldw/toolbox
- Support: https://github.com/thangldw/toolbox/issues
- Privacy: https://thangldw.github.io/toolbox/privacy.html
- `v2.0.0` は product-channel では stable ですが、ad-hoc signed で Apple-notarize されていません。
- Direct first launch は Gatekeeper に拒否される想定です。この build に限り **System Settings → Privacy & Security → Open Anyway** を使います。
- Gatekeeper を無効化せず、quarantine attribute を削除しません。
- Vote、follower、user、download、adoption count は記録も推測もしません。
