# Macinity 3.1 release readiness

## English

### Release decision

The user selected an ad-hoc-signed, unnotarized Macinity 3.1.0 production release. No Developer ID or Apple notarization claim is made. `release.json` describes publication status; [validation.json](validation.json) records local checks. GitHub CI and published assets are verified separately.

### Verification

The final branding and package source passed 129 XCTest, strict Swift formatting, all five smoke contracts, four-locale localization lint, universal build, ad-hoc signature validation, DMG checksum/mount/first-launch checks, and public documentation, website and community contracts. Local artifact hashes are recorded in validation.json.

Historical evidence: the frozen sensor engine completed 28,800.869744 seconds, with 2,759 sensor observations and zero sensor failures. Sleep/wake transitions occurred during that run; it does not prove eight continuously awake hours or current GUI performance. Recording-duration state was reproduced and fixed; the selected 30-minute duration persisted through native scrolling and Start/Stop.

### Known limits

Current native foreground resource profiling remains unverified. Earlier active candidates recorded 2.900668%, 2.345208% and 2.434613% one-core CPU at 300 seconds, exceeding the 2% engineering target. Workloads differed; no causal improvement or later current-GUI 15-minute pass is claimed. Full VoiceOver, critical Japanese copy review, physical Intel/macOS 13/active Ethernet and native notification delivery remain unverified. Rosetta installation was declined.

### Scope and compatibility

The product name, icon, website and artifacts are Macinity. Module/executable names, the existing bundle identifier and the existing support-data directory remain compatibility identifiers. Hard CPU caps, automatic suspension, a NetworkExtension firewall, fan writes, privileged repair and exclusive APFS snapshot-byte calculation are outside this release. Raw machine QA evidence remains local and is excluded from public artifacts.

## Tiếng Việt

### Release decision

Người dùng chọn phát hành Macinity 3.1.0 ký ad-hoc, chưa notarized. Không công bố rằng app có Developer ID hoặc đã được Apple notarize. `release.json` mô tả trạng thái phát hành; [validation.json](validation.json) ghi kết quả kiểm tra cục bộ. CI và artifact đã công bố được kiểm tra riêng.

### Verification

Mã nguồn với nhận diện và bộ cài mới đã đạt 129 XCTest, định dạng Swift nghiêm ngặt, năm smoke contracts, kiểm tra bốn ngôn ngữ, universal build, chữ ký ad-hoc, checksum/mount/hướng dẫn mở DMG, cùng các kiểm tra tài liệu, website và community files. Hash của bộ cài cục bộ được ghi trong validation.json.

Bằng chứng lịch sử: sensor engine cố định đã chạy 28.800,869744 giây, ghi 2.759 lần quan sát cảm biến và không có lỗi cảm biến. Máy có chuyển trạng thái sleep/wake; kết quả này không chứng minh tám giờ liên tục thức hoặc hiệu năng GUI hiện tại. Lỗi lưu thời lượng ghi đã được tái hiện và sửa; lựa chọn 30 phút được giữ qua thao tác cuộn và Start/Stop native.

### Known limits

Hiệu năng foreground của bản hiện tại chưa được xác minh. Các candidate trước đo CPU một core ở mốc 300 giây lần lượt là 2,900668%, 2,345208% và 2,434613%, vượt mục tiêu kỹ thuật 2%. Workload khác nhau nên chưa kết luận cải thiện nhân quả hoặc đạt gate GUI 15 phút ở bản mới. Full VoiceOver, review câu chữ quan trọng tiếng Nhật, Intel/macOS 13/Ethernet vật lý và thông báo native chưa được xác minh. Người dùng đã từ chối cài Rosetta.

### Scope and compatibility

Tên, icon, website và bộ cài dùng Macinity. Tên module/executable, bundle identifier hiện có và thư mục dữ liệu hiện có được giữ để tương thích. Release không có hard CPU caps, tự động suspend, firewall NetworkExtension, ghi điều khiển quạt, sửa hệ thống với đặc quyền hoặc tính dung lượng riêng của APFS snapshots. Dữ liệu kiểm chứng máy thật được giữ cục bộ, không đưa vào artifact công khai.

## 日本語

### Release decision

ユーザーは、ad-hoc署名でAppleのnotarizationを受けていないMacinity 3.1.0の公開を選択しました。Developer ID署名やnotarization完了とは表示しません。公開状態は`release.json`、ローカル検証結果は[validation.json](validation.json)に記録します。GitHub CIと公開済みartifactは別途確認します。

### Verification

最終的な名称・アイコン・パッケージのソースは、129件のXCTest、Swiftフォーマット、五つのsmoke contracts、四言語、universal build、ad-hoc署名、DMGのchecksum・mount・初回起動ガイド、公開ドキュメント・website・community filesの検証に成功しました。ローカルartifactのhashはvalidation.jsonに記録しています。

過去の固定sensor engineは28,800.869744秒動作し、2,759回のsensor観測でsensor失敗はありませんでした。途中にsleep/wake遷移があり、連続して起きた状態での八時間や現在のGUI性能を証明する結果ではありません。録画時間の保持不具合は再現して修正し、30分の選択がnativeのscrollとStart/Stop後も維持されることを確認しました。

### Known limits

現在のforeground性能は未検証です。以前のcandidateの300秒時点CPUは、一つのcoreを基準に2.900668%、2.345208%、2.434613%で、技術目標の2%を超えました。Workloadが異なるため、因果的な改善や現在のGUIでの15分合格とは判断しません。完全なVoiceOver検証、重要な日本語表現の専門review、実機Intel/macOS 13/Ethernet、native通知の到達は未確認です。Rosettaの導入はユーザーが辞退しました。

### Scope and compatibility

製品名・icon・website・artifactはMacinityです。Module/executable名、既存bundle identifier、既存データ保存先は互換性のため保持します。Hard CPU caps、自動suspend、NetworkExtension firewall、fan制御、特権repair、APFS snapshot専有bytesの計算は含みません。実機QAのraw evidenceはローカルに保持し、公開artifactには含めません。
