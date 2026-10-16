# Macinity — Cobalt Link

## English

The first approved Macinity concept is implemented with a clean geometric master in `source/mark.json`. `assets/` contains cobalt, Graphite and white SVG marks, transparent PNGs, a shaded app icon and monochrome menu templates. The native app uses a flat mark in the sidebar/About and an 18 pt template with a 2x representation in the menu bar. The existing internal Macinity type names are implementation details, not public branding.

Palette: Graphite `#151A23`, Cobalt `#4169F5`, Silver `#CCD4E0`, Porcelain `#F5F7FB`. Use system typography. The wordmark is live text; proprietary font files are not redistributed. Preserve the diagonal cut, proportions and clear space. Use flat monochrome for small icons, and the graphite tile only for the app icon. Action buttons use a darker blue for contrast.

Run `node source/build.mjs` in this directory to regenerate assets and an ICNS family using Node, Swift/CoreGraphics and iconutil. No third-party packages are required. Copy approved icon and logo outputs into the app Resources before building. The black PNG/template is pure black; the dark SVG is Graphite. Generated concept PNGs are historical references, not the shipping master.

Tagline: “Your Mac. Everything connected.” Credit: “Developed by [thangldw](https://thangldw.github.io/) & Codex”. See [integration status](INTEGRATION.md) for current verification and remaining limits.

## Tiếng Việt

Phương án Macinity đầu tiên đã được dựng lại bằng hình học sạch tại `source/mark.json`. `assets/` gồm logo SVG cobalt, Graphite và trắng, PNG trong suốt, app icon có sắc độ và template menu bar đơn sắc. App dùng logo phẳng ở sidebar/About và template 18 pt có bản 2x trên menu bar. Tên kiểu Macinity trong mã chỉ là chi tiết triển khai.

Bảng màu: Graphite `#151A23`, Cobalt `#4169F5`, Silver `#CCD4E0`, Porcelain `#F5F7FB`. Dùng font hệ thống; wordmark là chữ trực tiếp, không phân phối font độc quyền. Giữ nguyên đường cắt chéo, tỷ lệ và khoảng trống. Dùng đơn sắc ở kích thước nhỏ; nền graphite chỉ dành cho app icon. Nút thao tác dùng xanh đậm hơn để đảm bảo tương phản.

Chạy `node source/build.mjs` trong thư mục này để tạo asset và bộ ICNS bằng Node, Swift/CoreGraphics và iconutil, không cần package bên thứ ba. Chép icon/logo đã duyệt vào Resources của app trước khi build. PNG đen/template dùng đen tuyệt đối; SVG tối dùng Graphite. PNG concept cũ chỉ là tài liệu tham khảo.

Thông điệp: “Mac của bạn. Mọi thứ kết nối.” Ghi công: “Được phát triển bởi [thangldw](https://thangldw.github.io/) và Codex”. Xem [trạng thái tích hợp](INTEGRATION.md) để biết kết quả kiểm chứng và giới hạn.

## 日本語

承認された最初のMacinity案を、`source/mark.json` の幾何学マスターから再構成しました。`assets/` にはコバルト、Graphite、白のSVG、透過PNG、階調付きアプリアイコン、単色メニューテンプレートがあります。アプリのサイドバーと紹介画面にはフラットロゴ、メニューバーには2x画像を含む18 ptテンプレートを使用します。内部のMacinity型名は実装上の名称です。

配色はGraphite `#151A23`、Cobalt `#4169F5`、Silver `#CCD4E0`、Porcelain `#F5F7FB`。システムフォントを使用し、ワードマークはテキストとして表示します。独自フォントの配布はありません。斜めの切れ目、比率、余白を保ち、小さいアイコンには単色を使用します。Graphiteのタイルはアプリアイコン用です。操作ボタンはコントラストのため濃い青を使います。

このディレクトリで `node source/build.mjs` を実行すると、Node、Swift/CoreGraphics、iconutilでアセットとICNSを再生成できます。外部パッケージは不要です。承認済みの出力をアプリのResourcesへコピーしてからビルドします。黒のPNG/templateは純黒、暗色SVGはGraphiteです。以前のコンセプトPNGは参考資料です。

タグラインは「あなたのMac。すべてがつながる。」、開発者表記は「[thangldw](https://thangldw.github.io/) & Codex」です。検証結果と制限は[統合状況](INTEGRATION.md)を参照してください。
