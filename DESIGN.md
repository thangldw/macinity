---
version: production-candidate
omitted:
  - section: colors
    reason: The public site uses the portfolio palette from site-shell.css, as on KakeFlow. The native app owns its own palette.
  - section: typography
    reason: Portfolio site-shell.css owns typography, including the script-capable font stack.
  - section: spacing
    reason: Shared portfolio controls retain their tokens; route composition owns responsive spacing.
  - section: rounded
    reason: Native Macinity icon and shared controls remain canonical.
  - section: components
    reason: Theme and support remain canonical shared portfolio mirrors.
---
# Macinity website design

## English

### Audience and intent

Global macOS users and developers, with EN/VI/JA/ZH localization. Japanese locale does not introduce Japan-specific regulated business flows. This is a marketing/help site for Macinity3.0; native app owns the approved ring identity. No mock dashboard or synthetic measurement is shown as live evidence. Critical Japanese privacy/acquisition copy has not received independent native review.

### Visual and component ownership

The public landing, guide and privacy pages follow the KakeFlow product-page design. Load macinity-page.css first and the portfolio site-shell.css last. The shell supplies the white and dark canvases, accent, typography, controls, scrollbar and portfolio header. The route stylesheet composes the two-column hero, signal diagram, capability grid and reading sections. The app icon identifies Macinity within the diagram. MacinityTheme.swift remains the native palette owner. The generated macinity-brand.css is a legacy asset and is not loaded by these pages.

### Content and behavior

Hero states what the app does; capability cells name actual implemented workflows. Release/first-launch guidance explicitly discloses ad-hoc signing and no notarization. While preparing, CTA links to release status rather than a nonexistent new download. preview.js is the shared four-locale copy/metadata owner; existing locale/theme preferences remain compatible. Help and privacy are sibling routes. Source identifiers/data namespace remain Macinity for compatibility, not user-facing branding.

### Verification

Verify real browser wide/narrow, all locales, theme and reload, first-launch disclosure, keyboard focus, support dialog and sibling guide/privacy routes. Run locale parity, link/content contracts, brand generation, shared mirror hashes, strict premium audit and docs checks. Local/native or historical benchmarks are not website production evidence. Publication state must follow actual GitHub release/Pages outcomes.

## Tiếng Việt

### Audience và mục tiêu

Mac users/developers toàn cầu, EN/VI/JA/ZH. Locale Nhật không tạo regulatedflow Nhật riêng. Marketing/help choMacinity3.0, nativeapp sởhữuringidentityđãduyệt. Khôngmock/syntheticmeasurement giảlàm liveevidence. CriticalJAprivacy/acquisition chưaindependentreview.

### Visual và component ownership

Trang giới thiệu, hướng dẫn và quyền riêng tư dùng thiết kế KakeFlow. CSS chung của portfolio được nạp sau cùng và quản lý nền, màu nhấn, kiểu chữ, nút và thanh đầu trang. CSS của Macinity quản lý bố cục và sơ đồ. Biểu tượng ứng dụng xuất hiện trong sơ đồ. Bảng màu của ứng dụng macOS thuộc MacinityTheme.swift.

### Nội dung và hành vi

Heromôtảapp,cellsworkflowthật. Release/firstlaunchdisclosead-hoc/chưa notarized;preparingCTAstatuskhôngdownloadkhôngtồn tại. preview.js4locale/metadata,giữprefscompat. Guide/privacy sibling. Macinitynamespace đểtươngthíchkhôngpublicbrand.

### Kiểm chứng

Browserwide/narrow/4locale/theme/reload/disclosure/keyboard/support/siblings. Locale/link/content/brandgenerator/mirrorhash/premium/docschecks. Historical/nativebenchkhôngwebsiteproductionproof. PublicationstatusphảitheoGHrelease/Pagesthật.

## 日本語

### Audienceと目的

GlobalMacusers/developers、EN/VI/JA/ZH。日本語localeはJapan-specificregulatedflowを導入しません。Macinity3.0marketing/help、nativeappの承認ringidentity。Mock/syntheticmeasurementをliveevidenceとして表示しません。CriticalJAprivacy/acquisitionはindependentreview未完。

### Visualとcomponent ownership

紹介、ガイド、プライバシーの各ページは KakeFlow と共通のデザインを使用します。ポートフォリオの site-shell.css を最後に読み込み、背景色、アクセントカラー、書体、ボタン、ヘッダーを統一します。Macinity 専用の CSS はレイアウトと構成図を担当し、構成図にはアプリのアイコンを表示します。macOS アプリの配色は MacinityTheme.swift で管理します。

### Contentと動作

Heroはapp目的、cellは実workflow。Release/firstlaunchはad-hoc/unnotarized明示、preparingCTAはstatusで未公開downloadなし。Preview.jsは4locale/metadata、既存prefs互換。Guide/privacy sibling、Macinitynamespaceはcompatでpublicbrandではありません。

### 検証

Realbrowserwide/narrow/4locale/theme/reload/disclosure/keyboard/support/siblings、locale/link/content/brandgenerator/mirrorhash/premium/docs。Historical/nativebenchはwebsiteproofなし。Publicationstatusは実GHrelease/Pages結果に従います。
