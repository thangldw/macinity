---
version: alpha
omitted:
  - section: colors
    reason: Canonical palette is owned by the portfolio css/tokens.css and is not duplicated here.
  - section: typography
    reason: Type and multilingual font recipes inherit the canonical site-shell.css entry.
  - section: spacing
    reason: Existing portfolio spacing tokens remain the runtime source of truth.
  - section: rounded
    reason: Shared control and logo shapes inherit the portfolio recipes.
  - section: components
    reason: Shared buttons, logo, theme and support controls remain owned by the portfolio.
---
# Toolbox landing design

## English

### Overview
The user selected revised mockup 2 and authorized production release. Scope is the marketing landing only; the native Swift application and existing privacy page remain unchanged. README.md, docs/ARCHITECTURE.md, PRIVACY.md and SECURITY.md provide product evidence. Global macOS users and developers receive EN/VN/JP/CN website copy. Japanese locale does not introduce Japan-specific regulated flows. New Japanese acquisition/install copy has not received independent native review.

### Colors
The portfolio css/tokens.css owns the palette. The final official stylesheet is https://thangldw.github.io/css/site-shell.css. Route CSS consumes semantic variables only; canvas is the approved #F6F5F1. Fresh theme defaults to light and explicit saved preferences are restored by the shared owner.

### Typography
Use canonical Inter and Japanese/Chinese font stacks. Hero, headings, lead, body and paths use the existing semantic type recipes. Vietnamese headings inherit the diacritic fix. Japanese and Chinese prose wraps naturally; technical paths and release filenames stay literal.

### Layout
Preserve the hero/trust split, equal Storage/Projects/Applications columns, review/Trash/recovery workflow, secondary Change Timeline/Install Trace row and install block. Canonical thang. replaces the mock's accidental Space. wordmark. Synthetic sizes and paths are labeled; first-launch guidance is a disclosure. Narrow layouts stack columns and use a 2x2 workflow, with document scrolling.

### Elevation and shapes
Flat surfaces and hairline borders follow the portfolio. Shared logo and button shapes are unchanged. Native meter elements show synthetic folder sizes; they are not measurements or benchmarks. Supplied Tabler Icons v3.35.0 assets and MIT license live under site/assets/icons.

### Components
The final canonical CSS owns shared states; toolbox-page.css owns composition only. product-shell.js and product-support.js are exact reviewed deployment mirrors, recorded with source commit and SHA-256 in shared-assets.json. Shared theme accessibility and support behavior remain canonical. preview.js owns complete locale messages, metadata, illustrative number formatting and toolbox.site.locale. Copy announces success or a manual fallback; native details/summary owns first-launch disclosure.

### Product boundaries
Only recognized rebuildable project artifacts within a selected root are represented. App-linked evidence is not deletion permission. Foreground review precedes eligible mutations to Trash; restore requires an unoccupied original path. Preserve v2.0.0, macOS 13+, ARM64/x86_64 slices and the ad-hoc/not-notarized disclosure. Do not claim physical Intel validation, automatic cleanup, installer execution or Homebrew installation.

### Verification
Run JavaScript syntax, site and documentation contracts, shared mirror hashes, and DESIGN.md lint. Verify browser desktop/mobile, locale reload, theme, Copy, disclosure, keyboard focus and Support dialog. The premium scanner's actionless-button rule recognizes only inline handlers; corroborate externally bound controls with browser evidence. No fake inline handlers or scanner workarounds. Native Swift is unchanged; no native build is claimed for this landing.

## Tiếng Việt

### Tổng quan
Người dùng chọn mockup mới số 2 và cho phép release production. Phạm vi chỉ là landing giới thiệu; ứng dụng Swift và trang quyền riêng tư hiện có không đổi. README.md, docs/ARCHITECTURE.md, PRIVACY.md và SECURITY.md là nguồn thông tin sản phẩm. Website hỗ trợ EN/VN/JP/CN cho người dùng macOS và lập trình viên toàn cầu. Ngôn ngữ Nhật không bổ sung luồng pháp lý riêng của Nhật. Nội dung Nhật mới về giới thiệu và cài đặt chưa được người bản ngữ độc lập review.

### Màu sắc
css/tokens.css của portfolio sở hữu bảng màu. Stylesheet chính thức cuối cùng là https://thangldw.github.io/css/site-shell.css. CSS riêng chỉ dùng biến semantic; nền là #F6F5F1 đã chốt. Mặc định lần đầu là sáng; nguồn chung khôi phục lựa chọn đã lưu.

### Kiểu chữ
Dùng Inter và font stack Nhật/Trung chuẩn chung. Hero, tiêu đề, lead, nội dung và đường dẫn dùng thang chữ semantic hiện có. Tiêu đề Việt kế thừa sửa lỗi dấu. Văn bản Nhật và Trung xuống dòng tự nhiên; đường dẫn kỹ thuật và tên file release giữ nguyên.

### Bố cục
Giữ hero và phần tin cậy, ba cột Dung lượng/Dự án/Ứng dụng, quy trình duyệt/Trash/khôi phục, hàng Lịch sử thay đổi/Theo dõi cài đặt và phần cài đặt. Logo thang. thay chữ Space. do mockup tạo nhầm. Dung lượng và đường dẫn mẫu có nhãn; hướng dẫn mở lần đầu là disclosure. Màn hình hẹp xếp các cột dọc, dùng quy trình 2x2 và cuộn toàn trang.

### Bề mặt và hình dạng
Bề mặt phẳng và viền mảnh theo portfolio. Logo và hình dạng nút chung không đổi. Phần tử meter hiển thị dung lượng mẫu, không phải số đo hay benchmark. Icon Tabler v3.35.0 và giấy phép MIT nằm trong site/assets/icons.

### Thành phần
CSS chính thức ở cuối sở hữu trạng thái chung; toolbox-page.css chỉ phụ trách bố cục. product-shell.js và product-support.js là bản sao triển khai đã review, ghi commit nguồn và SHA-256 trong shared-assets.json. Nhãn accessibility của theme và hành vi Support giữ nguồn chung. preview.js sở hữu bản dịch đầy đủ, metadata, định dạng số mẫu và toolbox.site.locale. Copy báo thành công hoặc cách sao chép thủ công; details/summary điều khiển hướng dẫn mở lần đầu.

### Ranh giới sản phẩm
Chỉ minh họa dữ liệu dự án có thể tạo lại đã được nhận diện trong thư mục người dùng chọn. Bằng chứng liên quan đến ứng dụng không phải quyền xóa. Người dùng duyệt trước khi chuyển file đủ điều kiện vào Trash; khôi phục cần vị trí gốc còn trống. Giữ v2.0.0, macOS 13+, binary ARM64/x86_64 và thông tin ký ad-hoc/chưa notarize. Không tuyên bố đã thử trên máy Intel thật, tự dọn dẹp, chạy installer hay cài qua Homebrew.

### Kiểm tra
Chạy kiểm tra cú pháp JavaScript, contract trang và tài liệu, hash bản sao chung và lint DESIGN.md. Kiểm tra trình duyệt desktop/mobile, lưu ngôn ngữ khi reload, theme, Copy, disclosure, focus bàn phím và Support dialog. Scanner premium chỉ nhận handler inline; xác minh các nút gắn sự kiện bên ngoài bằng trình duyệt. Không thêm handler giả hoặc né scanner. Swift không đổi; không tuyên bố build native cho landing này.

## 日本語

### 概要
利用者が新しいモックアップの2番を選び、本番公開を承認しました。対象は紹介ページのみです。Swiftアプリと既存のプライバシーページは変更しません。製品情報の根拠はREADME.md、docs/ARCHITECTURE.md、PRIVACY.md、SECURITY.mdです。世界のmacOS利用者と開発者向けにEN/VN/JP/CNを提供します。日本語対応によって日本固有の規制対象の手続きは追加しません。新しい日本語の紹介・インストール文言は、独立した日本語母語話者の確認を受けていません。

### 配色
portfolioのcss/tokens.cssが配色を管理します。最後に適用する公式stylesheetはhttps://thangldw.github.io/css/site-shell.cssです。ページ固有のCSSはsemantic変数のみを使用し、背景は承認済みの#F6F5F1です。初回はライトテーマ、保存済みの明示的な選択は共通の実装が復元します。

### 書体
共通のInterと日本語・中国語font stackを使用します。Hero、見出し、導入文、本文、パスは既存のsemantic文字サイズに従います。ベトナム語見出しの発音記号修正も継承します。日本語と中国語は自然に改行し、技術的なパスと公開ファイル名はそのまま表示します。

### レイアウト
Heroと信頼情報、ストレージ・プロジェクト・アプリの等幅3列、確認・ゴミ箱・復元の手順、変更履歴・インストール追跡の補助行、インストール部分を維持します。モックに誤って含まれたSpace.は正規のthang.ロゴに置き換えます。容量とパスの例にはサンプルであることを表示します。初回起動の説明は開閉式です。狭い画面では列を縦に並べ、手順を2x2にし、ページ全体をスクロールできます。

### 面と形状
平坦な面と細い境界線はportfolioの規則に従います。共通ロゴとボタンの形状は変更しません。meter要素の容量は説明用であり、実測値やbenchmarkではありません。Tabler Icons v3.35.0の素材とMITライセンスをsite/assets/iconsに含めます。

### コンポーネント
最後に読み込む公式CSSが共通の状態を管理し、toolbox-page.cssは配置のみを担当します。product-shell.jsとproduct-support.jsは確認済みの配布用コピーで、shared-assets.jsonに元commitとSHA-256を記録します。テーマのアクセシブル名とSupportの動作は共通実装を維持します。preview.jsは翻訳、metadata、例の数値書式、toolbox.site.localeを管理します。Copyは成功または手動コピーの案内を通知し、details/summaryが初回起動説明を開閉します。

### 製品の境界
選択したルート内で認識された再生成可能な生成物だけを示します。アプリとの関連の根拠は削除の許可ではありません。対象ファイルをゴミ箱へ移動する前に確認が必要で、復元先は空いている必要があります。v2.0.0、macOS 13以上、ARM64/x86_64のbinary slice、アドホック署名と未公証の説明を維持します。実機Intel検証、自動整理、installer実行、Homebrew対応を主張しません。

### 検証
JavaScript構文、サイトと文書のcontract、共通コピーのhash、DESIGN.md lintを実行します。ブラウザーでdesktop/mobile、再読み込み後の言語、テーマ、Copy、開閉説明、キーボードfocus、Support dialogを確認します。premium scannerはinline handlerのみを認識するため、外部scriptで接続した操作はブラウザーの証拠で確認します。偽のhandlerやscanner回避を追加しません。Swiftは変更せず、この紹介ページのためのnative buildは主張しません。
