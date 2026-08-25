# Toolbox Site Fidelity Ledger

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Evidence boundary

This ledger compares accepted static concepts with captured browser renders. It is visual-fidelity evidence, not release-signing, Product Hunt activity, production-user, or private-device evidence.

- Accepted first-viewport concept: `docs/design-concepts/toolbox-site-hero-concept.png` at `1536×1024`.
- Accepted downstream concept: `docs/design-concepts/toolbox-site-sections-concept.png` at `872×1800`.
- Desktop browser render: `docs/design-evidence/toolbox-site-desktop.png` at `1280×800`.
- Mobile browser render: `docs/design-evidence/toolbox-site-mobile.png` at `390×844`.
- Product Hunt gallery fixtures: four PNG files at `1270×760`; thumbnail at `512×512`.
- Verification surface: Codex in-app browser against a local static HTTP server.
- Published-site evidence: Pages run `32847688077` completed `success` at `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`; https://thangldw.github.io/toolbox/ returned HTTP 200 at the `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` observation.

### Comparison

| Point | Accepted concept | Captured render | Result |
| --- | --- | --- | --- |
| Copy and hierarchy | Two-sentence promise, restrained support copy, two CTAs | Same heading, support copy, CTA labels, and order | Match |
| Layout | Asymmetric text/product split and quiet header | Same split at `1280` px; one-column continuation at `390` px | Match |
| Typography | Large Swiss-style white headline and compact UI text | System sans with matching weight, tracking, scale, and control typography | Match |
| Palette | Graphite, white, muted gray, electric lime | `#090a0a`, `#f5f6f3`, `#a6aaa5`, `#d7ff36` | Match |
| Media treatment | One dark macOS frame with thin border and no overlay | Stable `1270×760` frame, thin border, no tint or overlay | Match |
| Container rhythm | Open sections, horizontal workflow, minimal cards | Open bands and lists; no repeated card grid | Match |
| Responsive behavior | Airy desktop with clear continuation | No horizontal overflow at `1280` or `390` px; mobile CTA and footer verified | Match |

### Fixture and recording disclosure

The captures visibly disclose “Representative local fixture data” because Screen Recording access was unavailable in the build environment. The disclosure remains intentional after the stable release: fixture imagery demonstrates layout and workflows but does not imply customer data, production usage, physical Intel execution, or Apple trust approval.

Future captures must use disposable fixtures, omit private paths and notifications, keep confirmation steps visible, and preserve the explicit ad-hoc-signed/not-notarized boundary. A production screenshot is not required to make the published stable release valid, and this ledger makes no claim about Product Hunt state after the observation time.

## Tiếng Việt

### Ranh giới evidence

Ledger này so sánh static concept đã accept với browser render đã capture. Đây là visual-fidelity evidence, không phải evidence về release signing, hoạt động Product Hunt, production user hay thiết bị riêng tư.

- First-viewport concept: `docs/design-concepts/toolbox-site-hero-concept.png`, `1536×1024`.
- Downstream concept: `docs/design-concepts/toolbox-site-sections-concept.png`, `872×1800`.
- Desktop browser render: `docs/design-evidence/toolbox-site-desktop.png`, `1280×800`.
- Mobile browser render: `docs/design-evidence/toolbox-site-mobile.png`, `390×844`.
- Product Hunt gallery fixture: bốn PNG `1270×760`; thumbnail `512×512`.
- Verification surface: Codex in-app browser với local static HTTP server.
- Published-site evidence: Pages run `32847688077` completed `success` tại `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb`; https://thangldw.github.io/toolbox/ trả HTTP 200 khi quan sát lúc `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT`.

### So sánh

| Điểm | Concept đã accept | Render đã capture | Kết quả |
| --- | --- | --- | --- |
| Copy/hierarchy | Promise hai câu, support copy gọn, hai CTA | Cùng heading, support copy, CTA label và thứ tự | Match |
| Layout | Text/product split bất đối xứng, header yên | Cùng split ở `1280` px; chuyển một cột ở `390` px | Match |
| Typography | Headline trắng lớn kiểu Swiss, UI text gọn | System sans cùng weight, tracking, scale và control typography | Match |
| Palette | Graphite, trắng, xám muted, lime điện | `#090a0a`, `#f5f6f3`, `#a6aaa5`, `#d7ff36` | Match |
| Media | Một macOS frame tối, border mảnh, không overlay | Frame `1270×760` ổn định, border mảnh, không tint/overlay | Match |
| Rhythm | Section mở, workflow ngang, card tối thiểu | Open band/list; không repeated card grid | Match |
| Responsive | Desktop thoáng và continuation rõ | Không horizontal overflow ở `1280`/`390` px; mobile CTA/footer đã verify | Match |

### Disclosure về fixture và recording

Capture hiển thị rõ “Representative local fixture data” vì build environment không có Screen Recording access. Disclosure này vẫn được giữ sau stable release: fixture image minh họa layout/workflow nhưng không hàm ý customer data, production usage, physical Intel execution hay Apple trust approval.

Capture sau này phải dùng disposable fixture, loại private path và notification, giữ confirmation step trong khung hình, đồng thời duy trì ranh giới ad-hoc-signed/chưa notarize. Stable release đã publish không phụ thuộc production screenshot, và ledger này không claim Product Hunt state sau thời điểm quan sát.

## 日本語

### Evidence boundary

この ledger は accepted static concept と captured browser render を比較します。Visual-fidelity evidence であり、release signing、Product Hunt activity、production user、private device の evidence ではありません。

- First-viewport concept: `docs/design-concepts/toolbox-site-hero-concept.png`, `1536×1024`。
- Downstream concept: `docs/design-concepts/toolbox-site-sections-concept.png`, `872×1800`。
- Desktop browser render: `docs/design-evidence/toolbox-site-desktop.png`, `1280×800`。
- Mobile browser render: `docs/design-evidence/toolbox-site-mobile.png`, `390×844`。
- Product Hunt gallery fixture: 4 個の `1270×760` PNG、`512×512` thumbnail。
- Verification surface: local static HTTP server に対する Codex in-app browser。
- Published-site evidence: Pages run `32847688077` は `c60367d84cdf06a93fe95c65e2ebe110ab3f70bb` で completed `success`。https://thangldw.github.io/toolbox/ は `2026-08-26 02:07 JST` / `2026-08-25 10:07 PDT` の観測時に HTTP 200。

### 比較

| Point | Accepted concept | Captured render | Result |
| --- | --- | --- | --- |
| Copy/hierarchy | Two-sentence promise、抑制した support copy、二つの CTA | 同じ heading、support copy、CTA label/order | Match |
| Layout | 非対称 text/product split と静かな header | `1280` px で同じ split、`390` px で one-column continuation | Match |
| Typography | 大きい Swiss-style white headline と compact UI text | 同等の weight、tracking、scale、control typography の system sans | Match |
| Palette | Graphite、white、muted gray、electric lime | `#090a0a`, `#f5f6f3`, `#a6aaa5`, `#d7ff36` | Match |
| Media | Thin border、overlay なしの dark macOS frame | Stable `1270×760` frame、thin border、tint/overlay なし | Match |
| Rhythm | Open section、horizontal workflow、minimal card | Open band/list、repeated card grid なし | Match |
| Responsive | Airy desktop と明確な continuation | `1280`/`390` px で horizontal overflow なし。Mobile CTA/footer verify 済み | Match |

### Fixture と recording の disclosure

Build environment で Screen Recording access が利用できなかったため、capture は “Representative local fixture data” を明示します。この disclosure は stable release 後も意図的に保持します。Fixture image は layout/workflow を示しますが、customer data、production usage、physical Intel execution、Apple trust approval を示しません。

Future capture は disposable fixture を使い、private path と notification を除外し、confirmation step を隠さず、ad-hoc-signed/not-notarized 境界を維持します。Published stable release の成立に production screenshot は不要で、この ledger は観測時刻より後の Product Hunt state を claim しません。
