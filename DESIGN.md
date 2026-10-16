---
version: production-candidate
omitted:
  - section: colors
    reason: Canonical palette is owned by native MacinityTheme.swift and adapted by scripts/sync_brand_tokens.py.
  - section: typography
    reason: Portfolio site-shell.css owns shared type; Japanese and Chinese route stacks are explicit in macinity-page.css.
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

Native MacinityTheme.swift owns the brand palette. scripts/sync_brand_tokens.py generates site/macinity-brand.css using the existing light/dark selector contract; no second hand-maintained brand palette. site-shell.css owns shared typography and controls; product-shell.js/product-support.js remain reviewed shared mirrors recorded in shared-assets.json. macinity-page.css owns the hero, nine capability cells, help/privacy composition, global scrollbar and responsive layout. The app icon is copied from the current native1024px asset.

### Content and behavior

Hero states what the app does; capability cells name actual implemented workflows. Release/first-launch guidance explicitly discloses ad-hoc signing and no notarization. While preparing, CTA links to release status rather than a nonexistent new download. preview.js is the shared four-locale copy/metadata owner; existing locale/theme preferences remain compatible. Help and privacy are sibling routes. Source identifiers/data namespace remain Macinity for compatibility, not user-facing branding.

### Verification

Verify real browser wide/narrow, all locales, theme and reload, first-launch disclosure, keyboard focus, support dialog and sibling guide/privacy routes. Run locale parity, link/content contracts, brand generation, shared mirror hashes, strict premium audit and docs checks. Local/native or historical benchmarks are not website production evidence. Publication state must follow actual GitHub release/Pages outcomes.

## Tiếng Việt

### Audience và mục tiêu

Mac users/developers toàn cầu, EN/VI/JA/ZH. Locale Nhật không tạo regulatedflow Nhật riêng. Marketing/help choMacinity3.0, nativeapp sởhữuringidentityđãduyệt. Khôngmock/syntheticmeasurement giảlàm liveevidence. CriticalJAprivacy/acquisition chưaindependentreview.

### Visual và component ownership

MacinityTheme.swift sởhữubrandpalette; scripts/sync_brand_tokens.py sinhsite/macinity-brand.css/lightdarkselector,khônghandmaintainedpalette thứhai. site-shell.css typography/control; product-shell/supportJSmirror trongshared-assets.json. macinity-page.css composition/scrollbar/responsive. Iconcopycurrentnative1024px.

### Nội dung và hành vi

Heromôtảapp,cellsworkflowthật. Release/firstlaunchdisclosead-hoc/chưa notarized;preparingCTAstatuskhôngdownloadkhôngtồn tại. preview.js4locale/metadata,giữprefscompat. Guide/privacy sibling. Macinitynamespace đểtươngthíchkhôngpublicbrand.

### Kiểm chứng

Browserwide/narrow/4locale/theme/reload/disclosure/keyboard/support/siblings. Locale/link/content/brandgenerator/mirrorhash/premium/docschecks. Historical/nativebenchkhôngwebsiteproductionproof. PublicationstatusphảitheoGHrelease/Pagesthật.

## 日本語

### Audienceと目的

GlobalMacusers/developers、EN/VI/JA/ZH。日本語localeはJapan-specificregulatedflowを導入しません。Macinity3.0marketing/help、nativeappの承認ringidentity。Mock/syntheticmeasurementをliveevidenceとして表示しません。CriticalJAprivacy/acquisitionはindependentreview未完。

### Visualとcomponent ownership

MacinityTheme.swiftがbrandpalette、scripts/sync_brand_tokens.pyがsite/macinity-brand.css/lightdarkselectorを生成、二重handmaintainedpaletteなし。Site-shell.cssはtype/control、product-shell/supportJSmirrorはshared-assets.json。Macinity-page.cssはcomposition/scrollbar/responsive、iconはcurrentnative1024pxコピー。

### Contentと動作

Heroはapp目的、cellは実workflow。Release/firstlaunchはad-hoc/unnotarized明示、preparingCTAはstatusで未公開downloadなし。Preview.jsは4locale/metadata、既存prefs互換。Guide/privacy sibling、Macinitynamespaceはcompatでpublicbrandではありません。

### 検証

Realbrowserwide/narrow/4locale/theme/reload/disclosure/keyboard/support/siblings、locale/link/content/brandgenerator/mirrorhash/premium/docs。Historical/nativebenchはwebsiteproofなし。Publicationstatusは実GHrelease/Pages結果に従います。
