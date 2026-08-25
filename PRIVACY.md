# Toolbox Privacy

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Local processing

Toolbox has no account, telemetry, advertising SDK, analytics endpoint, or built-in cloud synchronization. Scans, snapshots, hashes, photo analysis, evidence, activity, migration, and recovery data are processed on the Mac. Toolbox does not upload file contents and does not declare software malicious.

### Data read

The exact read scope depends on the workflow, roots selected by the user, and macOS permissions. Toolbox may read filesystem paths and metadata, allocated sizes, partial and full file hashes, image features and metadata, project markers, application bundle metadata, code-signing identifiers, package receipts, Launch Services and background-item registration, shell/PATH configuration, configuration profiles, browser-extension metadata, and FSEvents observed during an active trace. Package and registration records are used as evidence, not as deletion authorization.

Install Trace accepts `.dmg`, `.pkg`, and `.app` paths for identification and evidence capture. It does not mount or execute the dropped installer; the user performs installation, update, or uninstall through the normal macOS flow.

### Data stored

Local application state is stored under `~/Library/Application Support/Toolbox`. It can include cleanup and recovery history in `history.json`, Change Timeline sessions and snapshots in `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, and `trusted-baseline.json`, evidence in `evidence-v1.json`, activity in `activity-v1.json`, storage checkpoints, migration state in `migration-v1.json`, and locally generated reports. `active-trace-metadata.json` may contain the selected installer source URL/path, display name, installer kind, and observation timestamp until finish or cancel clears active state; only an unexpected interruption may retain it for reduced-coverage recovery. Recovery entries can contain original and Trash paths. Preferences such as language and scheduled-scan status use macOS preferences, and an enabled schedule creates `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`.

### Permissions and mutations

Full Disk Access is optional. Without it, protected paths may be unreadable and Toolbox reports reduced coverage. Notification permission is requested only when enabling scheduled scan notifications. Toolbox has no privileged helper and does not ask for broad permission to bypass macOS controls.

Mutations happen only after foreground review and immediate target revalidation. Eligible file operations use macOS Trash and record recovery paths. Scheduled runs only scan and notify; they never delete. Project scan roots and export destinations are selected by the user.

### Exports

Change Timeline exports are generated locally as Markdown or JSON. Paths under the current home directory are redacted by replacing that prefix with `~`; names, attribution, reasons, timestamps, and paths outside the home directory can remain. The user chooses the destination and controls any later sharing. Review every report before transmitting it.

### Network behavior

Toolbox makes no automatic update request. Only after the user chooses **Check for Updates**, and only when no scan is active, it sends a GET request to `https://api.github.com/repos/thangldw/toolbox/releases/latest`. The request uses GitHub's JSON `Accept` header and a `User-Agent` containing the Toolbox version. Toolbox adds no scan results, paths, evidence, file metadata, or device fields to the request. There are no other built-in application network paths.

### Legacy migration

On first launch, Toolbox may inspect supported JSON under `~/Library/Application Support/Diskora`, `~/Library/Application Support/MacCleaner`, and `~/Library/Application Support/Changeora`. Import is opt-in: Toolbox decodes the source, merges supported records, writes them to its own directory, reads them back for verification, and records completion. Original legacy files are not modified or deleted, including after a migration failure.

Replacing a legacy Diskora schedule is a separate, confirmed Settings action. Toolbox first installs and bootstraps its scan-only LaunchAgent; it removes the legacy plist only after that succeeds.

## Tiếng Việt

### Xử lý local

Toolbox không có account, telemetry, advertising SDK, analytics endpoint hoặc cloud synchronization tích hợp. Scan, snapshot, hash, phân tích ảnh, evidence, activity, migration và recovery data được xử lý trên máy Mac. Toolbox không upload nội dung file và không kết luận software là malware.

### Dữ liệu được đọc

Read scope chính xác phụ thuộc workflow, root người dùng chọn và permission của macOS. Toolbox có thể đọc filesystem path/metadata, allocated size, partial/full file hash, image feature/metadata, project marker, application bundle metadata, code-signing identifier, package receipt, đăng ký Launch Services/background item, cấu hình shell/PATH, configuration profile, browser-extension metadata và FSEvents quan sát trong active trace. Package/registration record chỉ được dùng làm evidence, không phải authorization để xóa.

Install Trace nhận path `.dmg`, `.pkg`, `.app` để nhận diện và capture evidence. Toolbox không mount hoặc execute installer được thả vào; người dùng thực hiện install, update hoặc uninstall qua luồng macOS bình thường.

### Dữ liệu được lưu

Application state local được lưu dưới `~/Library/Application Support/Toolbox`. Dữ liệu có thể gồm cleanup/recovery history trong `history.json`; session/snapshot Change Timeline trong `sessions.json`, `active-snapshot.json`, `active-trace-metadata.json`, `trusted-baseline.json`; evidence trong `evidence-v1.json`; activity trong `activity-v1.json`; storage checkpoint; migration state trong `migration-v1.json`; và report tạo local. `active-trace-metadata.json` có thể chứa source URL/path của installer đã chọn, display name, installer kind và observation timestamp cho đến khi finish hoặc cancel xóa active state; chỉ unexpected interruption mới có thể giữ file này để recovery với reduced coverage. Recovery entry có thể chứa vị trí gốc và Trash. Preference như language và scheduled-scan status dùng macOS preferences; khi bật lịch, app tạo `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist`.

### Permission và mutation

Full Disk Access là tùy chọn. Khi không có quyền này, protected path có thể không đọc được và Toolbox báo reduced coverage. Notification permission chỉ được yêu cầu khi bật thông báo scheduled scan. Toolbox không có privileged helper và không yêu cầu quyền rộng để bypass cơ chế macOS.

Mutation chỉ xảy ra sau foreground review và revalidation target ngay trước thao tác. File operation đủ điều kiện dùng macOS Trash và ghi recovery path. Lịch chạy chỉ scan/notify, tuyệt đối không xóa. Project scan root và export destination do người dùng chọn.

### Export

Change Timeline export được tạo local dưới dạng Markdown hoặc JSON. Path trong home directory hiện tại được redaction bằng cách thay prefix đó bằng `~`; tên, attribution, reason, timestamp và path ngoài home có thể vẫn còn. Người dùng chọn destination và kiểm soát mọi chia sẻ sau đó. Phải review từng report trước khi truyền đi.

### Network behavior

Toolbox không tự gửi update request. Chỉ sau khi người dùng chọn **Check for Updates**, và chỉ khi không có scan active, app gửi GET tới `https://api.github.com/repos/thangldw/toolbox/releases/latest`. Request dùng JSON `Accept` header của GitHub và `User-Agent` chứa version Toolbox. Toolbox không thêm kết quả scan, path, evidence, file metadata hoặc device field vào request. Ứng dụng không có built-in network path nào khác.

### Legacy migration

Ở lần chạy đầu, Toolbox có thể inspect JSON được hỗ trợ dưới `~/Library/Application Support/Diskora`, `~/Library/Application Support/MacCleaner` và `~/Library/Application Support/Changeora`. Import là opt-in: Toolbox decode source, merge record được hỗ trợ, ghi vào directory riêng, đọc lại để verify và ghi completion. File legacy gốc không bị sửa hoặc xóa, kể cả khi migration fail.

Thay lịch Diskora cũ là action riêng trong Settings, có confirmation. Toolbox cài và bootstrap scan-only LaunchAgent trước; app chỉ xóa legacy plist sau khi bước đó thành công.

## 日本語

### Local processing

Toolbox には account、telemetry、advertising SDK、analytics endpoint、内蔵 cloud synchronization がありません。Scan、snapshot、hash、photo analysis、evidence、activity、migration、recovery data は Mac 上で処理されます。File content を upload せず、software を malware と判定しません。

### 読み取る data

正確な read scope は workflow、user が選択した root、macOS permission に依存します。Toolbox は filesystem path/metadata、allocated size、partial/full file hash、image feature/metadata、project marker、application bundle metadata、code-signing identifier、package receipt、Launch Services/background-item registration、shell/PATH configuration、configuration profile、browser-extension metadata、active trace 中に観測した FSEvents を読み取る場合があります。Package/registration record は evidence であり、削除 authorization ではありません。

Install Trace は識別と evidence capture のため `.dmg`、`.pkg`、`.app` path を受け取ります。Drop された installer を mount または execute しません。User が通常の macOS flow で install、update、uninstall を実行します。

### 保存する data

Local application state は `~/Library/Application Support/Toolbox` に保存されます。Cleanup/recovery history の `history.json`、Change Timeline session/snapshot の `sessions.json`、`active-snapshot.json`、`active-trace-metadata.json`、`trusted-baseline.json`、evidence の `evidence-v1.json`、activity の `activity-v1.json`、storage checkpoint、migration state の `migration-v1.json`、local 生成 report を含む場合があります。`active-trace-metadata.json` は、finish または cancel が active state を消去するまで、選択した installer の source URL/path、display name、installer kind、observation timestamp を含む場合があります。Reduced-coverage recovery のために保持されるのは unexpected interruption の場合だけです。Recovery entry は original/Trash path を含む場合があります。Language と scheduled-scan status などの preference は macOS preferences を使い、schedule を有効にすると `~/Library/LaunchAgents/com.thang.toolbox.scheduled-scan.plist` を作成します。

### Permission と mutation

Full Disk Access は任意です。許可しない場合、protected path を読めず reduced coverage と表示することがあります。Notification permission は scheduled scan notification を有効にする場合だけ要求します。Toolbox には privileged helper がなく、macOS control を bypass する広範な permission を要求しません。

Mutation は foreground review と action 直前の target revalidation 後だけ実行します。対象 file operation は macOS Trash を使い recovery path を記録します。Scheduled run は scan/notification のみで削除しません。Project scan root と export destination は user が選択します。

### Export

Change Timeline export は local で Markdown または JSON として生成します。現在の home directory 配下の path は prefix を `~` に置換して redaction します。Name、attribution、reason、timestamp、home 外の path は残る場合があります。Destination とその後の共有は user が管理します。送信前に各 report を review してください。

### Network behavior

Toolbox は自動 update request を行いません。User が **Check for Updates** を選択し、scan が active でない場合だけ、`https://api.github.com/repos/thangldw/toolbox/releases/latest` に GET を送信します。Request は GitHub JSON `Accept` header と Toolbox version を含む `User-Agent` を使います。Scan result、path、evidence、file metadata、device field を request に追加しません。その他の built-in application network path はありません。

### Legacy migration

初回起動時、Toolbox は `~/Library/Application Support/Diskora`、`~/Library/Application Support/MacCleaner`、`~/Library/Application Support/Changeora` の supported JSON を inspect できます。Import は opt-in です。Source を decode し、supported record を merge して Toolbox directory に書き、再度読み取って verify し、completion を記録します。Migration failure の場合も含め、元の legacy file を変更・削除しません。

Legacy Diskora schedule の置換は Settings の別 action で、confirmation が必要です。Toolbox は先に scan-only LaunchAgent を install/bootstrap し、成功した場合だけ legacy plist を削除します。
