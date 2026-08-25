# Changelog

All notable changes to Toolbox are documented here. Releases follow [Semantic Versioning](https://semver.org/). Historical tags through `v1.4.0` contain the standalone Diskora and Changeora applications; 2.0 and later ship one Toolbox application.

## English

### Toolbox 2.0.0 Beta 1 — 2026-08-25

- Published tag `v2.0.0-beta.1` as an explicitly unnotarized public beta with manual Gatekeeper approval instructions.
- Replaced the standalone applications with one six-destination Toolbox GUI.
- Added user-selected project artifact cleanup for seven developer ecosystems.
- Added drag-and-drop Install Trace with persisted before/after evidence and interrupted-session recovery.
- Added versioned evidence/activity stores, conflict-safe Recovery, and copy-then-verify legacy migration.
- Revalidated every mutation against canonical roots and exact allowlisted developer commands.
- Added onboarding, Settings, scan-only schedule migration, isolated update checks, and English/Vietnamese parity gates.
- Consolidated CI, packaging, documentation, and release ownership under `apps/toolbox`.

### Toolbox 1.4.0 — 2026-08-02

This release contains Diskora 1.3.0 and Changeora 1.4.0.

- Added an in-app English/Vietnamese language selector to both applications.
- Made English the default while preserving Vietnamese as a first-class interface language.
- Persisted language preferences locally and refreshed the full interface when changed.
- Localized navigation, actions, safety explanations, scan states, errors, and About panels.
- Added packaged macOS localization resources and release checks for both languages.

### Toolbox 1.3.0 — 2026-08-02

This release contains Diskora 1.2.0 and Changeora 1.3.0.

#### Diskora 1.2.0

- Added Undo Center with original and Trash locations, conflict-safe restore, and recovery status.
- Added explainable cleanup confidence: Safe, Review, or Dangerous.
- Improved application artifact discovery using Bundle ID, package receipts, launch services, login/background items, and containers.
- Rebuilt duplicate scanning as size grouping → partial SHA-256 → full SHA-256, with bounded I/O and phase progress.
- Rebuilt similar-photo detection around pairwise clustering, resolution, sharpness, file size, and capture metadata.
- Added allowlisted cleanup through official tools such as `simctl`, Docker, Homebrew, npm, and pip.
- Added scheduled scan-and-notify. Scheduled work never deletes files automatically.

#### Changeora 1.3.0

- Combined FSEvents with before/after snapshots to retain deep filesystem changes.
- Added coverage for login items, background tasks, package receipts, extensions, configuration profiles, browser extensions, and shell/PATH changes.
- Added application attribution using Bundle ID, Team ID, code-signing metadata, names, and time proximity.
- Added explainable risk scoring for every detected change.
- Added clean-baseline comparison and comparison between any two sessions.
- Added redacted JSON and Markdown support-report exports.
- Added uninstall observation to help identify remaining artifacts.

#### Repository

- Updated both applications to build 3.
- Expanded unit and smoke coverage for restore, phased hashing, FSEvents, and baseline persistence.
- Rebuilt all documentation in English, Vietnamese, and Japanese.

### Toolbox 1.1.0 — 2026-08-02

- Made Diskora cleanup recoverable through Trash.
- Tightened application-leftover matching.
- Expanded Changeora snapshot coverage.
- Restored unit-test and continuous-integration infrastructure.

### Toolbox 1.0.0 — 2026-07-26

- Consolidated Diskora and Changeora in one repository.
- Established local-first processing, explicit previews, and recoverable operations.

## Tiếng Việt

### Toolbox 2.0.0 Beta 1 — 2026-08-25

- Publish tag `v2.0.0-beta.1` dưới dạng public beta chưa notarize, kèm hướng dẫn người dùng tự phê duyệt qua Gatekeeper.
- Thay hai ứng dụng độc lập bằng một GUI Toolbox với sáu destination.
- Thêm dọn artifact project theo root người dùng chọn cho bảy hệ sinh thái developer.
- Thêm Install Trace kéo-thả với bằng chứng trước/sau và khôi phục phiên bị gián đoạn.
- Thêm evidence/activity store có version, Recovery không ghi đè và migration copy-then-verify.
- Revalidate mọi mutation theo canonical root và developer command allowlist chính xác.
- Thêm onboarding, Settings, migrate lịch chỉ-quét, update check tách biệt và gate English/Tiếng Việt.
- Hợp nhất CI, packaging, tài liệu và release vào `apps/toolbox`.

### Toolbox 1.4.0 — 2026-08-02

Bản phát hành này gồm Diskora 1.3.0 và Changeora 1.4.0.

- Thêm bộ chọn English/Tiếng Việt ngay trong cả hai ứng dụng.
- Dùng English làm mặc định và giữ Tiếng Việt là ngôn ngữ giao diện đầy đủ.
- Lưu lựa chọn ngôn ngữ cục bộ và cập nhật toàn bộ giao diện khi thay đổi.
- Bản địa hóa navigation, thao tác, giải thích an toàn, trạng thái quét, lỗi và About panel.
- Đóng gói tài nguyên localization macOS và bổ sung kiểm tra release cho cả hai ngôn ngữ.

### Toolbox 1.3.0 — 2026-08-02

Bản phát hành này gồm Diskora 1.2.0 và Changeora 1.3.0.

#### Diskora 1.2.0

- Thêm Undo Center lưu vị trí gốc và vị trí trong Trash, khôi phục an toàn khi trùng tên và hiển thị trạng thái phục hồi.
- Thêm mức tin cậy có giải thích: An toàn, Cần xem lại hoặc Nguy hiểm.
- Nâng cấp nhận diện dữ liệu ứng dụng bằng Bundle ID, package receipt, launch service, login/background item và container.
- Xây lại duplicate scanner theo chuỗi kích thước → SHA-256 một phần → SHA-256 đầy đủ, giới hạn I/O và hiển thị tiến độ theo giai đoạn.
- Xây lại Similar Photos bằng phân cụm từng cặp, độ phân giải, độ nét, kích thước và metadata ngày chụp.
- Thêm cleanup qua danh sách lệnh chính thức được cho phép như `simctl`, Docker, Homebrew, npm và pip.
- Thêm lịch quét và thông báo; tác vụ theo lịch không bao giờ tự xóa.

#### Changeora 1.3.0

- Kết hợp FSEvents với snapshot trước/sau để giữ lại thay đổi sâu trong filesystem.
- Theo dõi thêm login item, background task, package receipt, extension, configuration profile, browser extension và thay đổi shell/PATH.
- Quy nguồn thay đổi về ứng dụng bằng Bundle ID, Team ID, chữ ký, tên và thời điểm.
- Thêm risk score có lý do cho từng thay đổi.
- Thêm baseline máy sạch và so sánh hai phiên bất kỳ.
- Export JSON và báo cáo hỗ trợ Markdown đã ẩn đường dẫn cá nhân.
- Theo dõi uninstall để phát hiện artifact còn sót.

#### Repository

- Nâng cả hai ứng dụng lên build 3.
- Mở rộng unit test và smoke test cho khôi phục, hashing theo giai đoạn, FSEvents và baseline.
- Viết lại toàn bộ tài liệu bằng tiếng Anh, tiếng Việt và tiếng Nhật.

### Toolbox 1.1.0 — 2026-08-02

- Chuyển cleanup của Diskora qua Trash để có thể khôi phục.
- Siết nhận diện dữ liệu ứng dụng còn sót.
- Mở rộng phạm vi snapshot của Changeora.
- Khôi phục unit test và continuous integration.

### Toolbox 1.0.0 — 2026-07-26

- Hợp nhất Diskora và Changeora trong một repository.
- Thiết lập nguyên tắc local-first, xem trước rõ ràng và ưu tiên thao tác có thể phục hồi.

## 日本語

### Toolbox 2.0.0 Beta 1 — 2026-08-25

- `v2.0.0-beta.1` を未 notarize の public beta として公開し、Gatekeeper の手動許可手順を追加しました。
- Standalone app を一つの 6 destination Toolbox GUI に統合しました。
- User 選択 root 内で 7 ecosystem の project artifact cleanup を追加しました。
- Drag-and-drop Install Trace、前後 evidence、interrupted session recovery を追加しました。
- Versioned evidence/activity store、上書きしない Recovery、copy-then-verify migration を追加しました。
- 全 mutation に canonical root validation と exact command allowlist を適用しました。
- Onboarding、Settings、scan-only schedule migration、isolated update check、英語/ベトナム語 gate を追加しました。
- CI、packaging、documentation、release を `apps/toolbox` に統合しました。

### Toolbox 1.4.0 — 2026-08-02

このリリースには Diskora 1.3.0 と Changeora 1.4.0 が含まれます。

- 両アプリに English / Tiếng Việt のアプリ内言語 selector を追加しました。
- English を既定にし、ベトナム語も完全な UI 言語として維持します。
- 言語設定をローカル保存し、変更時に UI 全体を更新します。
- Navigation、操作、安全性の説明、scan status、error、About panel を localization 対象にしました。
- macOS localization resource を app bundle に含め、両言語の release check を追加しました。

### Toolbox 1.3.0 — 2026-08-02

このリリースには Diskora 1.2.0 と Changeora 1.3.0 が含まれます。

#### Diskora 1.2.0

- 元の場所と Trash 内の場所を記録し、競合を避けて復元できる Undo Center を追加しました。
- 「安全・要確認・危険」の根拠付き信頼度を追加しました。
- Bundle ID、package receipt、launch service、login/background item、container を使うアプリ artifact 検出に改善しました。
- 重複スキャンをサイズ → partial SHA-256 → full SHA-256 の段階処理に変更し、I/O 制限と詳細 progress を追加しました。
- 類似写真を pairwise clustering、解像度、鮮明度、サイズ、撮影 metadata で比較する方式に変更しました。
- `simctl`、Docker、Homebrew、npm、pip など、許可リスト内の公式コマンドによる cleanup を追加しました。
- 自動削除を行わない定期 scan-and-notify を追加しました。

#### Changeora 1.3.0

- FSEvents と前後 snapshot を組み合わせ、深い階層の変更も保持できるようにしました。
- Login item、background task、package receipt、extension、configuration profile、browser extension、shell/PATH を監視対象に追加しました。
- Bundle ID、Team ID、署名情報、名前、時刻から変更元アプリを推定します。
- 検出した変更ごとに説明可能な risk score を追加しました。
- クリーン baseline と任意の 2 session 比較を追加しました。
- 個人パスを秘匿した JSON と Markdown support report の export を追加しました。
- Uninstall を監視し、残存 artifact を検出できるようにしました。

#### Repository

- 両アプリを build 3 に更新しました。
- Restore、段階的 hash、FSEvents、baseline 保存の unit/smoke test を拡充しました。
- 全ドキュメントを英語、ベトナム語、日本語で再構成しました。

### Toolbox 1.1.0 — 2026-08-02

- Diskora cleanup を Trash 経由で復元可能にしました。
- アプリ残存データの判定を厳密化しました。
- Changeora snapshot の監視範囲を拡張しました。
- Unit test と continuous integration を復元しました。

### Toolbox 1.0.0 — 2026-07-26

- Diskora と Changeora を 1 つの repository に統合しました。
- Local-first、明示的 preview、復元可能な操作を基本方針にしました。
