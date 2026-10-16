# Macinity repository and website migration

## English

The canonical repository is https://github.com/thangldw/macinity and the website is https://thangldw.github.io/macinity/. The repository was renamed in place: repository ID, Git history, tags, issues and releases were retained. Local origin now points to the new URL. GitHub redirects the old repository, release downloads and update API. Do not create another repository named `toolbox`: that would replace GitHub's old-name redirects.

The account website repository owns the `/toolbox/` compatibility directory. Its index, guide and privacy pages redirect to `/macinity/`, retaining the path, query and fragment through JavaScript; a no-JavaScript fallback links to the corresponding page. Static asset and release-metadata URLs remain served there. The root 404 handler redirects other `/toolbox/` paths to the equivalent new route. A nonexistent destination remains nonexistent. Keep these compatibility files when updating the portfolio.

This is an address migration, not a user-data migration. Bundle ID `com.thang.toolbox`, executable, preference keys, permissions and `Application Support/Toolbox` are unchanged. No user files were moved or deleted. The published 3.1.0 DMG is unchanged; its existing update endpoint still works through GitHub's redirect. Source URLs are updated for future builds.

Verified: repository ID 1307313498 retained, all six releases and asset IDs/sizes/digests preserved, old repository HTTP 301, old update endpoint HTTP 200, old DMG download SHA-256 `57aa780a4a3b86af79661fcc78641621fd9f660424d148da0beb52b70eec73e7`. A real browser retained `guide.html?lang=vi#install` across the website redirect. 129 local tests and GitHub CI passed for the URL changes; both websites deployed successfully.

## Tiếng Việt

Repo chính là https://github.com/thangldw/macinity và website là https://thangldw.github.io/macinity/. Repo được đổi tên tại chỗ, giữ ID, lịch sử Git, tag, issue và release. Remote local trỏ tới URL mới. GitHub chuyển hướng repo, download và API cập nhật cũ. Không tạo repo khác tên `toolbox`, vì sẽ thay thế các chuyển hướng tên cũ của GitHub.

Repo website cá nhân sở hữu thư mục tương thích `/toolbox/`. Trang chủ, hướng dẫn và quyền riêng tư chuyển tới `/macinity/`, giữ path, query và fragment qua JavaScript; khi không có JavaScript có liên kết tới trang tương ứng. URL asset và metadata release cũ vẫn được phục vụ. Handler 404 của site chuyển các path `/toolbox/` khác sang route mới tương ứng; đích không tồn tại vẫn không tồn tại. Giữ các file tương thích này khi cập nhật portfolio.

Đây là chuyển địa chỉ, không chuyển dữ liệu người dùng. Bundle ID `com.thang.toolbox`, executable, khóa cấu hình, quyền và `Application Support/Toolbox` không đổi. Không di chuyển hoặc xóa file người dùng. DMG 3.1.0 đã phát hành giữ nguyên; API cập nhật cũ vẫn hoạt động qua redirect GitHub. URL trong source đã cập nhật cho các build sau.

Đã xác minh: giữ repo ID 1307313498, cả sáu release cùng ID/kích thước/digest asset, repo cũ trả HTTP 301, API cũ HTTP 200, download DMG cũ có SHA-256 `57aa780a4a3b86af79661fcc78641621fd9f660424d148da0beb52b70eec73e7`. Trình duyệt thật giữ `guide.html?lang=vi#install` sau chuyển hướng. 129 tests local và CI GitHub qua cho thay đổi URL; hai website đã triển khai thành công.

## 日本語

正規repositoryは https://github.com/thangldw/macinity、websiteは https://thangldw.github.io/macinity/ です。既存repositoryの名称変更により、ID、Git履歴、tag、issue、releaseを維持しました。local originは新URLです。旧repository、download、更新APIはGitHubが転送します。`toolbox`という別repositoryを作成すると旧名の転送が失われるため、再利用しないでください。

アカウントwebsiteのrepositoryで `/toolbox/` 互換ディレクトリを維持します。トップ、guide、privacyを `/macinity/` へ転送し、JavaScriptでpath、query、fragmentを保持します。JavaScript無効時も対応ページへのリンクがあります。旧assetとrelease metadataも提供します。root 404 handlerは他の `/toolbox/` pathを対応する新routeへ転送しますが、存在しないページは新規作成しません。portfolio更新時も互換ファイルを維持してください。

これはアドレス移行であり、利用者データの移行ではありません。bundle ID `com.thang.toolbox`、実行ファイル、設定キー、権限、`Application Support/Toolbox`を維持します。利用者ファイルの移動・削除は行いません。公開済み3.1.0 DMGも同一で、旧更新APIはGitHub転送で動作します。次回build向けsource URLを更新しました。

確認済み：repository ID 1307313498、六つのreleaseとasset ID・size・digestを維持。旧repositoryはHTTP 301、旧APIはHTTP 200、旧DMGのSHA-256は `57aa780a4a3b86af79661fcc78641621fd9f660424d148da0beb52b70eec73e7`。実ブラウザで `guide.html?lang=vi#install` の保持を確認しました。URL変更の129 local testsとGitHub CIに成功し、両websiteを公開しました。
