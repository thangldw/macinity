# Toolbox 2.0.0 Beta 1 — Historical Release Record

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Historical boundary

`v2.0.0-beta.1`, dated `2026-08-25` in the repository release history, was the public beta that combined Diskora and Changeora into one local-first macOS GUI. This file is retained as a historical record. It does not describe the current download channel and is superseded by stable `v2.0.0`.

The beta supported installer-change tracing, review of developer storage inside user-selected roots, and recovery records for Trash-backed cleanup. Processing was local, with no account, telemetry, privileged helper, or automatic deletion.

### Historical trust state

The beta was ad-hoc signed and not notarized by Apple. Gatekeeper did not approve direct first launch automatically. Stable `v2.0.0` is also an explicit ad-hoc-signed, unnotarized release; the beta record must not be read as a promise that stable became Developer ID-signed or notarized.

For the historical beta only, the safe manual flow was:

1. Verify the downloaded DMG against the checksum published with that tag.
2. Open the DMG and drag Toolbox to Applications.
3. Try to open Toolbox once.
4. Open **System Settings → Privacy & Security → Open Anyway**, then authenticate.

Never disable Gatekeeper or remove quarantine attributes. This record does not claim a currently available beta asset, a current beta checksum, Apple trust approval, Homebrew availability, adoption, or physical Intel execution.

### Current path and issue privacy

Use the stable [Toolbox 2.0.0 release record](toolbox-2.0.0.md) for current installation and exact artifact evidence. Report reproducible issues at https://github.com/thangldw/toolbox/issues with macOS version, Mac architecture, workflow, and observed result. Do not attach private paths or files.

## Tiếng Việt

### Ranh giới lịch sử

`v2.0.0-beta.1`, được ghi ngày `2026-08-25` trong release history của repository, là public beta hợp nhất Diskora và Changeora thành một GUI macOS local-first. File này chỉ là historical record. Nó không mô tả download channel hiện tại và đã được stable `v2.0.0` thay thế.

Beta hỗ trợ trace thay đổi installer, review developer storage trong root người dùng chọn và giữ recovery record cho cleanup qua Trash. Xử lý diễn ra local, không account, telemetry, privileged helper hay automatic deletion.

### Trust state lịch sử

Beta được ký ad-hoc và chưa được Apple notarize. Gatekeeper không tự động chấp thuận lần mở trực tiếp đầu tiên. Stable `v2.0.0` cũng là ngoại lệ ad-hoc-signed, unnotarized rõ ràng; historical beta record không phải lời hứa rằng stable đã được Developer ID-sign hoặc notarize.

Luồng manual an toàn của historical beta là:

1. Verify DMG đã download theo checksum publish cùng tag đó.
2. Mở DMG và kéo Toolbox vào Applications.
3. Thử mở Toolbox một lần.
4. Mở **System Settings → Privacy & Security → Open Anyway**, rồi authenticate.

Không tắt Gatekeeper hoặc xóa quarantine attribute. Record này không claim beta asset/checksum hiện còn available, Apple trust approval, Homebrew, adoption hay physical Intel execution.

### Đường hiện tại và privacy khi báo lỗi

Dùng [record Toolbox 2.0.0](toolbox-2.0.0.md) cho cài đặt hiện tại và artifact evidence chính xác. Báo issue tái hiện được tại https://github.com/thangldw/toolbox/issues kèm macOS version, Mac architecture, workflow và kết quả quan sát. Không đính kèm private path hoặc file.

## 日本語

### Historical boundary

Repository release history で `2026-08-25` と記録された `v2.0.0-beta.1` は、Diskora と Changeora を一つの local-first macOS GUI に統合した public beta でした。この file は historical record として保持します。Current download channel を説明するものではなく、stable `v2.0.0` に置き換えられています。

Beta は installer change tracing、user-selected root 内の developer storage review、Trash-backed cleanup の recovery record を提供しました。処理は local で、account、telemetry、privileged helper、automatic deletion はありませんでした。

### Historical trust state

Beta は ad-hoc signed で、Apple-notarize されていませんでした。Gatekeeper は direct first launch を自動承認しませんでした。Stable `v2.0.0` も明示的な ad-hoc-signed、unnotarized release です。この beta record は stable が Developer ID-signed または notarized になったという約束ではありません。

Historical beta だけに対する安全な manual flow:

1. Download した DMG を、その tag とともに publish された checksum で verify します。
2. DMG を開き、Toolbox を Applications に drag します。
3. Toolbox を一度 open します。
4. **System Settings → Privacy & Security → Open Anyway** を開き、authenticate します。

Gatekeeper を無効化せず、quarantine attribute を削除しません。この record は current beta asset/checksum、Apple trust approval、Homebrew、adoption、physical Intel execution を claim しません。

### Current path と issue privacy

Current installation と exact artifact evidence には [Toolbox 2.0.0 release record](toolbox-2.0.0.md) を使います。再現可能な issue は macOS version、Mac architecture、workflow、observed result とともに https://github.com/thangldw/toolbox/issues へ報告します。Private path または file は添付しません。
