# Orven Security

## English

### Supported scope and reporting

Report vulnerabilities privately through [GitHub private reporting](https://github.com/thangldw/toolbox/security/advisories/new). Include affected version, reproduction and impact; omit credentials and private filesystem/network reports. Orven3.0 is the current development/release line. Older Toolbox binaries remain historical downloads.

### Release trust

Orven3.0.0 is an explicitly authorized ad-hoc-signed, unnotarized release. Verify the SHA-256 from the same published release before installing. Structural codesign verification does not establish Developer ID trust or notarization. macOS may require Open Anyway after the blocked first launch; do not disable Gatekeeper or strip quarantine. No Homebrew distribution is claimed.

### Data and actions

No privileged helper, automatic cleanup, credential collection or malware verdict. Explicit network probes are bounded direct-argument helpers, without shell evaluation; user-entered hosts reject URLs/options/credentials. Pending operations cancel only owned processes. Process actions revalidate PID/start identity. Priority lowering is manual, not a hard CPU cap or automatic suspension.

Eligible file mutations require foreground review, canonical-path/identity revalidation and recovery evidence. Trash is used where supported. Restore refuses to overwrite existing paths; package receipts/registrations/leftovers are evidence, not authorization. Corrupt health stores are preserved and block writes. Permission denial and missing readings remain explicit; missing sensor values are not zero.

### Known coverage

Mapped hardware sensors are community mappings and model dependent. No firewall, full packet history, fan control, calibrated per-core temperature, exclusive snapshot-byte calculation or privileged system repair is provided. Current foreground resource profiling, physical Intel/macOS13/Ethernet, full VoiceOver, Japanese critical-copy review and OS notification delivery are incomplete. See [release readiness](docs/production/RELEASE-READINESS.md) and [Privacy](PRIVACY.md).

## Tiếng Việt

### Scope hỗ trợ và báo cáo

Báo vulnerability riêng qua [GitHub private reporting](https://github.com/thangldw/toolbox/security/advisories/new). Gửiversion/reproduction/impact, khôngcredentials/reportfilesystem/networkriêng. Orven3.0 là dòng hiện tại; binaryToolbox cũ là downloadhistorical.

### Trustrelease

Orven3.0.0 kýad-hoc/chưa notarized theo lựa chọn được phép. VerifySHA-256 của cùngrelease trước cài. Codesignstructural không proofDeveloperID/notarization. macOS có thể cầnOpenAnyway saufirstlaunchblocked; không tắtGatekeeper/xóaquarantine. Không claimHomebrew.

### Dữ liệu và actions

Khôngprivilegedhelper/autocleanup/credentialcollection/malwareverdict. Probe bounded/directargs khôngshell; hostrejectURL/options/credentials. Cancel chỉownedprocess. ProcessactionrevalidatePID/start. Lowerprioritymanual khônghardCPUcap/autosuspend.

Eligiblemutation cầnforegroundreview/canonicalpath/identityrevalidation/recoveryevidence; dùngTrash nếu hỗ trợ. Restore khôngoverwritepathoccupied. Receipt/registration/leftover chỉevidence. Healthstorehỏng giữnguyên/chặnwrite. Permissiondenial/missingrõràng, sensor thiếu không thành0.

### Coverage còn thiếu

Sensorcommunity/modeldependent; khôngfirewall/fullpackethistory/fancontrol/calibratedper-coretemp/exclusivesnapshotbytes/privilegedrepair. Foregroundresource/Intel/macOS13/Ethernetvật lý/fullVoiceOver/JAcriticalcopy/OSnotification cònchưa xác minh. [Release readiness](docs/production/RELEASE-READINESS.md)/[Privacy](PRIVACY.md).

## 日本語

### Support範囲と報告

Vulnerabilityは[GitHub private reporting](https://github.com/thangldw/toolbox/security/advisories/new)へ非公開報告。Version/reproduction/impactを含めcredentials/privatefilesystem/networkreportは除外。Orven3.0が現在line、旧Toolboxbinaryはhistoricaldownload。

### Release trust

Orven3.0.0は承認されたad-hoc署名/unnotarized。同publishedreleaseのSHA-256を確認。StructuralcodesignはDeveloperID/notarization証明ではありません。Firstlaunchblocked後OpenAnywayが必要な場合、Gatekeeper無効化/quarantine除去なし。Homebrewの主張なし。

### Dataとaction

Privilegedhelper/autocleanup/credentialcollection/malwareverdictなし。Probeはbounded/directargs、shell評価なし。HostはURL/options/credentialsをreject。Cancelはownedprocessのみ、processactionはPID/startrevalidate。ManualpriorityloweringはhardCPUcap/autosuspendではありません。

Eligiblemutationはforegroundreview/canonicalpath/identityrevalidation/recoveryevidence、対応時Trash使用。Restoreはoccupiedpathをoverwriteしません。Receipt/registration/leftoverはevidenceのみ。破損healthstore保持・write停止。Permissiondenial/missing明示、sensor欠測は0にしません。

### 未確認coverage

Sensorはcommunity/modeldependent。Firewall/fullpackethistory/fancontrol/calibratedper-coretemp/exclusivesnapshotbytes/privilegedrepairなし。Foregroundresource/physicalIntel/macOS13/Ethernet/fullVoiceOver/JAcriticalcopy/OSnotificationは未確認。[Release readiness](docs/production/RELEASE-READINESS.md)/[Privacy](PRIVACY.md)参照。
