# Macinity utility expansion

## English

### Scope and delivery

The utility increment retains six workspaces and exposes 21 native routes. Keep Awake is inside Battery & Thermal; saved Wi-Fi, sharing and port inspection are inside Wi-Fi & LAN. Package operations extend Developer Tools. Release status is recorded in release.json.

| Utility | Implemented behavior | Boundary |
| --- | --- | --- |
| Startup & Background | LaunchAgent/Daemon plist inventory, owner/executable/path and containing-app Finder link when verifiable, current user registration/PID/last exit, explicit macOS background-item report, Settings handoff, previewed runtime start/stop for owned user LaunchAgents | System daemon state remains unknown. Runtime changes do not edit launch plists or permanently disable startup. Fresh plist fingerprint and registration checks precede changes. |
| Keep Awake | 15/30/60-minute idle-system-sleep assertions, process-identity-bound sessions, countdown, Stop, battery context | Screen locking, display sleep and manual sleep are unchanged. Process sessions have a 24-hour ceiling. Quit releases assertions. |
| External Drives | External disk/partition inventory, format/capacity/mount, normal macOS eject after preview, bounded open-file inspection | Eject revalidates volume UUID and mount. No force eject or process termination. Restricted processes can be absent. |
| Ports | Exact local-port filtering of existing TCP/UDP snapshots, listener state, interface binding, process link, explicit command-line inspection | PID/start identity is checked before and after reading commands. Wildcard binding does not establish Internet exposure. Arguments remain local and may contain secrets. |
| Files | Existing content-duplicate workflow, SHA-256/expected-hash comparison, folder content comparison, batch rename preview, exclusive moves and retained recovery journal/undo | No destination overwrite. Symlinks excluded; folder packages excluded. 2,000 selected files, 20,000 tree entries, 16 GiB per hash and two minutes per read operation. Failed/partial operations are not reported as complete. |
| Packages | Explicit version reads for discovered tools, Homebrew formula/cask inventory and update/uninstall, Python environment/package inventory with virtual-environment-only pip writes, npm global inventory/update/uninstall | Commands are previewed and confirmed; no shell initialization or sudo. Fresh package inventory precedes mutation. Updates can execute package code and affect dependencies; no automatic rollback. npm lifecycle scripts are skipped. |
| Devices | USB/Thunderbolt/display/audio/Bluetooth system snapshots, supplied accessory battery fields, bounded refresh-comparison history | Snapshot history is not exact physical connection history. Paired Bluetooth devices may be disconnected. No invented missing readings. |
| Workspaces | Local named presets of selected apps/folders and observable window geometry; previewed open/restore and recoverable preset removal | Accessibility access required for geometry. Missing/ambiguous windows skipped. No browser tab, terminal session, document or VPN restoration. |
| Wi-Fi access | macOS-exposed saved profiles, Passwords/Settings handoff, locally generated QR from manual credentials, nearby security labels and weak-signal/overlap guidance | No password retrieval, cracking or capture. QR is memory-only and cleared on page exit. Channel overlap is a heuristic, not measured interference. Existing gateway/DNS/latency checks remain explicit. |

### Verification and remaining scope

Regression tests exercise command validation, PID absence, parsing, QR escaping, package boundaries, hashes, rename/undo/conflict behavior, relative-path normalization and display geometry. Native verification, universal packaging and limitations are recorded separately in `docs/monitoring/evidence/utilities/verification.json`; implementation and tests alone do not establish hardware/permission/mutation coverage. Production machine packages, launch agents, disks and window layouts are not mutated during read-only verification.

Final local validation: 120 XCTest tests, universal build, ad-hoc bundle contract, strict formatting and localization checks passed. Native fixture rename/undo, Keep Awake release, loopback ownership and package command preview were verified across the utility candidates. The final Bluetooth identity-only parser refinement passed regression and native recheck on the final binary after unlocking and relaunching. Identity-only devices remain visible without numeric grouping rows; macOS-supplied accessory battery fields are shown without assuming disconnected-device readings are fresh. Physical eject, real package/service changes, Accessibility window restoration, four-locale visual review and new utility performance/minimum-window coverage remain unverified.

Future stages remain selected-file SQL/columnar previews, clipboard/snippets, API requests, App Intents, local AI/OCR, and integrations with existing container/VM runtimes. These are not delivered by this utility increment. The bounded process runner and existing duplicate/history/navigation owners are reused.

## Tiếng Việt

### Phạm vi và chức năng

Đợt tiện ích giữ sáu nhóm với 21 trang native. Keep Awake nằm trong Battery & Thermal; Wi-Fi đã lưu, chia sẻ và cổng nằm trong Wi-Fi & LAN. Quản lý package mở rộng Developer Tools. Trạng thái phát hành được ghi trong release.json.

| Tiện ích | Hành vi triển khai | Giới hạn |
| --- | --- | --- |
| Startup & Background | Plist LaunchAgent/Daemon, chủ sở hữu/file thực thi/đường dẫn và liên kết app chứa file khi xác minh được, đăng ký/PID/mã thoát của người dùng, báo cáo background items, mở Settings, xem trước chạy/dừng user LaunchAgent sở hữu | Chưa xác minh daemon hệ thống. Chỉ đổi đăng ký runtime, không sửa plist hay tắt khởi động vĩnh viễn. Kiểm tra lại fingerprint/trạng thái trước thao tác. |
| Keep Awake | Giữ máy thức 15/30/60 phút hoặc theo identity tiến trình, đếm ngược, Stop, thông tin pin | Không đổi khóa máy/tắt màn hình/ngủ thủ công. Phiên theo tiến trình tối đa 24 giờ. Thoát app giải phóng yêu cầu. |
| Ổ ngoài | Danh sách ổ/phân vùng, định dạng/dung lượng/mount, tháo ổ qua macOS sau preview, kiểm tra file đang mở | Xác minh lại UUID/mount. Không cưỡng chế tháo hay dừng tiến trình. Có thể thiếu tiến trình bị giới hạn. |
| Cổng | Lọc chính xác cổng cục bộ từ TCP/UDP snapshot, trạng thái nghe/bind, liên kết tiến trình, đọc lệnh theo nút bấm | Kiểm tra PID/start trước và sau. Bind mọi interface không chứng minh truy cập Internet. Tham số có thể nhạy cảm, chỉ hiển thị tại máy. |
| File | Dùng lại tìm trùng nội dung, SHA-256/đối chiếu hash, so sánh thư mục, preview đổi tên, không ghi đè, nhật ký/hoàn tác | Bỏ symlink và nội dung package trong so sánh thư mục. Tối đa 2.000 file chọn, 20.000 mục thư mục, 16 GiB/file hash, hai phút mỗi phép đọc. Không coi kết quả lỗi/thiếu là hoàn tất. |
| Package | Đọc phiên bản theo nút bấm, Homebrew formula/cask và cập nhật/gỡ, Python/package và chỉ ghi pip trong venv, npm global và cập nhật/gỡ | Preview/xác nhận lệnh, không nạp shell hay sudo. Kiểm tra package lại trước thay đổi. Có thể chạy mã package/đổi dependencies; không tự rollback. npm bỏ lifecycle scripts. |
| Thiết bị | Snapshot USB/Thunderbolt/màn hình/âm thanh/Bluetooth, pin phụ kiện nếu có, lịch sử so sánh các lần refresh có giới hạn | Không phải thời điểm cắm/rút chính xác. Bluetooth có thể chứa thiết bị đã ghép nhưng không kết nối. Không suy đoán dữ liệu thiếu. |
| Workspace | Lưu app/thư mục đã chọn và bố cục đọc được; xem trước mở/khôi phục, bỏ preset có bản sao phục hồi | Cần Accessibility cho bố cục. Bỏ cửa sổ thiếu/không khớp duy nhất. Không phục hồi tab, terminal, tài liệu, VPN. |
| Wi-Fi | Profile hệ thống cho đọc, mở Passwords/Settings, QR từ thông tin nhập tay xử lý tại máy, nhãn bảo mật và gợi ý tín hiệu/chồng kênh | Không đọc/bẻ/bắt mật khẩu. QR chỉ trong bộ nhớ, xóa khi rời trang. Chồng kênh là gợi ý, không đo nhiễu. Giữ phép thử gateway/DNS/latency theo nút bấm. |

### Kiểm chứng và phần còn lại

Test bao phủ kiểm tra lệnh, PID không tồn tại, parser, escape QR, ranh giới package, hash, đổi tên/hoàn tác/xung đột, đường dẫn tương đối và hình học màn hình. Bằng chứng native, universal và giới hạn nằm tại `docs/monitoring/evidence/utilities/verification.json`; code và test không thay thế kiểm chứng phần cứng/quyền/thao tác thật. Không đổi package, LaunchAgent, ổ đĩa hoặc bố cục cửa sổ thật trong kiểm chứng chỉ đọc.

Kiểm tra local cuối: 120 XCTest, build universal, contract bundle ad-hoc, format và bản dịch đã qua. Đã kiểm tra native đổi tên/hoàn tác fixture, giải phóng Keep Awake, listener localhost và preview lệnh package qua các candidate. Parser Bluetooth cuối đã qua regression và đối chiếu native trên đúng binary cuối sau mở khóa và nạp lại. Thiết bị ít thông tin vẫn hiện, không còn hàng nhóm số; pin phụ kiện do macOS cung cấp được hiển thị nhưng không mặc định coi dữ liệu của thiết bị đã ngắt kết nối là mới. Tháo ổ vật lý, thay đổi package/dịch vụ thật, khôi phục cửa sổ qua Accessibility, rà soát hình ảnh bốn ngôn ngữ và hiệu năng/cửa sổ nhỏ của tiện ích mới còn chưa xác minh.

SQL/file cột, clipboard/snippet, API client, App Intents, AI/OCR cục bộ và container/VM vẫn thuộc các giai đoạn sau. Dùng lại runner có giới hạn và các owner duplicate/history/navigation hiện có.

## 日本語

### 範囲と実装

六つの領域と21のnative画面を維持します。Keep AwakeはBattery & Thermal、保存済みWi-Fi・共有・ポートはWi-Fi & LAN、package操作はDeveloper Toolsに配置します。公開状況はrelease.jsonに記録します。

| ツール | 実装した動作 | 制限 |
| --- | --- | --- |
| 起動・バックグラウンド | LaunchAgent/Daemon plist、所有者・実行ファイル・パス・確認可能な所属appへのリンク、ユーザー登録・PID・終了状態、background項目レポート、設定への移動、所有するuser LaunchAgentの起動・停止確認 | system daemon状態は不明。plistや恒久的起動設定は変更せず、実行時登録のみ。直前にfingerprintと状態を再確認。 |
| Keep Awake | 15/30/60分、プロセスidentityに連動する防止要求、残り時間、Stop、電池情報 | ロック・画面スリープ・手動スリープは変更しません。プロセス連動は最大24時間。終了時に解除。 |
| 外部ドライブ | ディスク・パーティション、形式・容量・mount、確認後の通常取り出し、開いているファイルの確認 | UUIDとmountを再確認。強制取り出し・プロセス終了なし。制限されたプロセスは欠落可能。 |
| ポート | TCP/UDP snapshotから正確なローカルポート検索、待受・bind、プロセス画面、明示的コマンド取得 | PID/startを前後で確認。全interfaceへのbindはInternet公開の証明ではありません。引数はローカル表示のみ。 |
| ファイル | 既存重複検索、SHA-256照合、フォルダ比較、一括名前変更preview、上書きしない移動、復元ログとundo | symlinkと比較時のpackage内部は除外。選択2,000ファイル、tree20,000項目、hash16 GiB/ファイル、読み取り2分。失敗・不完全を完了扱いしません。 |
| パッケージ | 明示的version取得、Homebrew formula/caskと更新・削除、Python環境とvenv限定pip変更、npm global一覧と変更 | コマンド確認、shell初期化・sudoなし。変更前に再取得。package code実行・依存変更を伴い、自動rollbackなし。npm lifecycle scriptは省略。 |
| デバイス | USB・Thunderbolt・画面・音声・Bluetooth snapshot、提供される電池情報、更新間の変更履歴 | 正確な接続時刻ではありません。未接続のpair済みBluetooth機器を含む場合があります。欠測を推測しません。 |
| Workspace | 選択アプリ・フォルダ・取得可能な配置を保存し、確認後に開いて復元。preset削除時は復元用copy | 配置にはAccessibilityが必要。不明確なwindowは省略。tab・terminal・文書・VPNは復元しません。 |
| Wi-Fi | 公開profile、Passwords/設定、手入力からlocal QR、securityと電波・channel重複の説明 | パスワード取得・解析・傍受なし。QRはメモリのみで離脱時に消去。重複は推定で干渉測定ではありません。gateway/DNS/latency試験は明示操作。 |

### 検証と未実装範囲

テストはコマンド検証、存在しないPID、parser、QR escape、package境界、hash、名前変更・undo・競合、相対パス、画面geometryを対象とします。native・universalと制限は `docs/monitoring/evidence/utilities/verification.json` に記録します。コードとテストだけでhardware・権限・実変更を検証したとは扱いません。読み取り検証中に実機のpackage、LaunchAgent、disk、window配置は変更しません。

最終local検証では120件のXCTest、universal build、ad-hoc bundle contract、format、翻訳チェックが成功しました。複数candidateでfixtureの名前変更・undo、Keep Awake解除、localhost listener、packageコマンドpreviewをnative確認しました。最後のBluetooth parser修正はregression testと、ロック解除・再起動後の最終binaryでのnative確認に成功しました。情報の少ない機器も保持され、数値だけのグループ行は表示されません。macOSが提供する電池情報を表示しますが、未接続機器の値が最新とは見なしません。実ドライブ取り出し、実package・service変更、Accessibility配置復元、四言語の目視、新utilityの最小画面・性能検証は未確認です。

SQL/columnar file、clipboard/snippet、API client、App Intents、local AI/OCR、container/VM連携は後続段階です。既存のbounded runnerとduplicate/history/navigationを再利用します。

## Follow-on increment / Đợt tiếp theo / 次の更新

Action Center, Smart Diagnostics and Work Profiles extend this utility baseline; the current catalog has 22 routes. See [Action workflows](ACTION-WORKFLOWS.md) for equivalent English, Vietnamese and Japanese scope and evidence boundaries. Earlier results above remain historical utility-candidate evidence.
