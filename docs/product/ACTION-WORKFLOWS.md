# Action Center, Smart Diagnostics and Work Profiles

## English

This local increment adds a Smart Diagnostics route and upgrades the existing Home and Workspace Presets routes without changing their persisted identities. The sidebar contains 22 routes. Release status is recorded in release.json.

- **Action Center:** up to eight locally saved favorites; observation-based attention hints; existing alert events and activity-ledger entries; the active Macinity Keep Awake countdown and Stop; current/recent Work Profile runs. This is not a universal job queue: existing storage and package operations retain their own owners and confirmation flows.
- **Smart Diagnostics:** explicit analysis for slow Mac, heat, battery drain, network and storage symptoms. It reuses existing samples and reads passive network configuration only when requested. Each finding retains source and time. Missing, paused, future, nonfinite or older-than-15-second measurements remain unknown. Thresholds are disclosed triage heuristics: CPU 80%, battery 20%, available storage 10%, Wi-Fi -75 dBm; memory/thermal states use macOS classifications. A single observation cannot establish persistence or causality. A repeat analysis compares only newer fresh numeric measurements for the same symptom. Process links preserve PID/start identity. Reports remain in memory for this app session.
- **Work Profiles:** existing apps, folders and captured window positions plus optional system default audio output/input and 15/30/60-minute Keep Awake. Choices remain visible without dropdowns. Existing presets lacking options retain previous behavior. A concrete preview precedes every run; each step is checked again at execution and receives a result. Stop takes effect between steps. Completed steps remain applied after failure/cancellation; no automatic rollback is promised. Audio changes verify stable device UID and read back the default. Apps with independent routing may ignore system defaults. No audio is recorded. Layout restoration still requires Accessibility and unambiguous windows. A selected Keep Awake duration replaces the current Macinity assertion and does not alter Lock Screen.

Profiles and audio device identifiers remain in the existing local `workspace-presets-v1.json`; favorites use local preferences. At most 20 profiles, 20 session results and eight favorites are retained by their respective models. Removing a preset retains the existing recovery copy. No passwords, network identities or audio recordings are added to diagnostic reports.

Validation and candidate-specific limitations are recorded in `docs/monitoring/evidence/action-workflows/verification.json`. Automated tests do not establish physical-device, permission-dependent layout restoration or live performance coverage. The app remains ad-hoc signed and not notarized.

## Tiếng Việt

Đợt bổ sung cục bộ này thêm màn hình Chẩn đoán thông minh, nâng cấp Home và Workspace Presets nhưng giữ định danh điều hướng cũ. Sidebar có 22 mục. Trạng thái phát hành được ghi trong release.json.

- **Trung tâm thao tác:** tối đa tám mục yêu thích lưu cục bộ; gợi ý từ mẫu đo; cảnh báo và lịch sử thao tác hiện có; đếm ngược/dừng Giữ máy thức; hồ sơ đang chạy và kết quả gần đây. Đây không phải hàng đợi chung cho mọi tác vụ; phần dung lượng và package giữ luồng xác nhận riêng.
- **Chẩn đoán thông minh:** phân tích theo nút bấm cho máy chậm, nóng, hao pin, mạng chậm và thiếu dung lượng. Dùng mẫu hiện có; chỉ đọc cấu hình mạng thụ động khi yêu cầu. Kết quả giữ nguồn và thời điểm. Mẫu thiếu, tạm dừng, ở tương lai, không hữu hạn hoặc quá 15 giây được ghi là chưa rõ. Ngưỡng gợi ý: CPU 80%, pin 20%, dung lượng khả dụng 10%, Wi-Fi -75 dBm; áp lực bộ nhớ/nhiệt theo macOS. Một mẫu không chứng minh lỗi kéo dài hay nguyên nhân. Lần phân tích tiếp theo chỉ so sánh mẫu số mới, còn hạn, cùng triệu chứng. Liên kết tiến trình giữ PID/thời điểm khởi chạy. Báo cáo chỉ giữ trong phiên app.
- **Hồ sơ làm việc:** ứng dụng, thư mục và bố cục đã lưu, thêm đầu ra/micrô mặc định tùy chọn và giữ máy thức 15/30/60 phút. Chọn trực tiếp, không dropdown. Preset cũ vẫn tương thích. Mỗi lần chạy có bản xem trước, kiểm tra lại và kết quả từng bước. Dừng sau bước hiện tại. Bước đã thành công vẫn có hiệu lực nếu bước sau lỗi hoặc bị dừng; không tự hoàn tác. Âm thanh kiểm tra UID và đọc lại thiết bị mặc định; app có định tuyến riêng có thể không dùng thiết lập đó. Không ghi âm. Bố cục vẫn cần Accessibility và cửa sổ xác định rõ. Giữ máy thức thay phiên hiện tại của Macinity, không đổi Lock Screen.

Hồ sơ và định danh thiết bị âm thanh lưu trong file cục bộ hiện có `workspace-presets-v1.json`; mục yêu thích lưu trong tùy chọn. Giới hạn 20 hồ sơ, 20 kết quả trong phiên và tám mục yêu thích. Xóa preset giữ bản sao khôi phục. Báo cáo không lưu mật khẩu, định danh mạng hay bản ghi âm.

Kết quả và giới hạn theo từng bản nằm tại `docs/monitoring/evidence/action-workflows/verification.json`. Kiểm thử tự động không thay thế thử phần cứng, quyền bố cục hay hiệu năng trực tiếp. App ký ad-hoc, chưa notarized.

## 日本語

このローカル更新ではスマート診断を追加し、既存のHomeとWorkspace Presetsを保存済みルートIDを変えずに拡張します。サイドバーは22項目です。公開状況はrelease.jsonに記録します。

- **アクションセンター:** 最大8件のローカルお気に入り、観測による注意事項、既存通知と操作履歴、Macinityのスリープ防止残り時間・停止、実行中と最近のプロファイル結果を表示します。全機能共通のジョブキューではありません。容量・package操作は既存の確認処理を維持します。
- **スマート診断:** 動作が遅い、熱い、電池消費、ネットワーク、容量不足を明示操作で分析します。既存サンプルを再利用し、要求時のみネットワーク設定を読み取ります。各結果に取得元と時刻を保持します。欠測・停止中・未来・非有限・15秒より古い値は不明です。目安はCPU 80%、電池20%、空き容量10%、Wi-Fi -75 dBmで、メモリ・温度はmacOSの分類を使用します。単一観測は継続的問題や原因の証明ではありません。同じ症状の再分析では新しく有効な数値のみ比較します。プロセスへのリンクはPIDと開始時刻を保持します。レポートはセッション内のみ保存します。
- **作業プロファイル:** アプリ・フォルダ・保存済み配置に、任意の既定音声出力・マイクと15/30/60分のスリープ防止を追加します。選択肢は直接表示し、ドロップダウンを使いません。旧presetも互換です。実行前に内容を確認し、各手順で再検証して結果を記録します。停止は現在の手順後です。失敗・停止時も完了した変更は残り、自動復元はありません。音声はUIDを検証して既定値を再取得します。独自音声設定のアプリには反映されない場合があります。録音しません。配置にはAccessibilityと一意に識別できるウインドウが必要です。スリープ防止は既存のMacinityセッションを置き換え、画面ロックを変更しません。

プロファイルと音声UIDは既存のローカル`workspace-presets-v1.json`に、お気に入りは設定に保存します。上限は20プロファイル・20セッション結果・8お気に入りです。preset削除時は復元用copyを残します。診断にパスワード・ネットワーク識別情報・録音を保存しません。

候補別の検証結果と制限は`docs/monitoring/evidence/action-workflows/verification.json`に記録します。自動テストは実機・権限が必要な配置復元・実際の性能検証を代替しません。ad-hoc署名で、notarizationは未実施です。

## Verification — 2026-10-16

**English:** Final local checks passed: 129 XCTest cases (nine new workflow/regression tests), universal build, ad-hoc release contract, strict formatting, localization coverage and documentation contract. All 22 routes fit 960×640 in automated layout checks; a populated long summary wraps in a 600-point content width. Native checks across recorded candidates covered CPU/network analysis, comparison, favorites, a temporary Keep Awake profile with Stop, locale changes without reopening the page, and the final activity-row clipping fix. Real audio switching, Accessibility window restoration, cancellation during a real multi-app run, manual minimum-window inspection, a new 15-minute foreground resource profile, full VoiceOver and physical Intel/macOS 13 remain unverified. No such checks are inferred from old candidates or from a paused app.

**Tiếng Việt:** Gate cục bộ đã qua: 129 XCTest (chín test mới cho workflow/lỗi hồi quy), universal build, contract ad-hoc, format nghiêm ngặt, bản dịch và tài liệu. Kiểm tra bố cục tự động đạt 960×640 cho 22 route; hàng tóm tắt có dữ liệu dài xuống dòng trong vùng rộng 600 điểm. Các bản native được ghi riêng đã kiểm tra phân tích CPU/mạng, so sánh, mục yêu thích, hồ sơ Giữ máy thức tạm thời và Stop, đổi ngôn ngữ ngay tại màn hình, cùng sửa tràn hàng lịch sử trên bản cuối. Chưa xác minh đổi âm thanh thật, khôi phục cửa sổ bằng Accessibility, dừng giữa lượt chạy nhiều app thật, cửa sổ nhỏ bằng tay, đo foreground 15 phút mới, VoiceOver đầy đủ và Intel/macOS 13 thật. Không suy ra các kết quả này từ bản cũ hay app đang tạm dừng.

**日本語:** ローカル検証は129件のXCTest（新規9件）、universal build、ad-hoc配布contract、厳密format、翻訳・文書チェックに成功しました。22ルートの960×640自動layout検証と、長い内容を含む概要行の幅600ポイントでの折り返しを確認しました。candidate別native検証ではCPU・ネットワーク分析、比較、お気に入り、一時スリープ防止profileと停止、画面を開き直さない言語変更、最終版の履歴行はみ出し修正を確認しました。実際の音声切替、Accessibilityによる配置復元、実アプリの複数手順中断、手動最小画面、新しい15分foreground性能測定、完全なVoiceOver、Intel/macOS 13実機は未検証です。旧版や停止中の状態をこれらの証拠として扱いません。
