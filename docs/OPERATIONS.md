# Orven operations

## English

### Build and verify

Use full Xcode with a per-command DEVELOPER_DIR, Swift6 and macOS13deployment. Run all XCTest and smoke contracts, strict formatting and locale lint, then build_universal.sh/build_dmg.sh/verify_release.sh --allow-adhoc. Artifacts are Orven.app and Orven-3.0.0.dmg. The explicit exception for Orven3.0.0 is ad-hoc/unnotarized; no Gatekeeper bypass command is permitted.

### Local data and cleanup

Keep bundle/data namespace stable. Do not reset corrupt stores automatically or silently seed history. Preserve skipped/missing/permission-reduced coverage. Scheduled scans do not delete; eligible cleanup and irreversible developer commands have distinct reviewed flows. [Installation trace](diagrams/install-trace-sequence.html) and [recovery](diagrams/review-recovery-state.html).

### Support and limitations

Report actual version, architecture, permission scope and fresh timestamps. Do not publish raw private diagnostic reports. See [user guide](USER-GUIDE.md), [readiness](production/RELEASE-READINESS.md), [privacy](../PRIVACY.md) and [release operations](OPERATIONS-RELEASE.md).

## Tiếng Việt

### Build and verify

FullXcode/DEVELOPER_DIRtheocommand/Swift6/macOS13. ChạyXCTest/smoke/strictformat/localelint,builduniversal/dmg/verifyallow-adhoc. ArtifactOrven.app/Orven-3.0.0.dmg;exception3.0ad-hoc/chưa notarized,khôngbypassGatekeepercommand.

### Local data and cleanup

Giữbundle/datanamespace. Khôngresetcorrupt/seedhistorytựđộng. Giữmissing/skipped/permissioncoverage. Scheduledkhôngdelete;eligiblecleanup vàirreversibledevelopercommandflowsreviewriêng. [Trace](diagrams/install-trace-sequence.html)/[recovery](diagrams/review-recovery-state.html).

### Support and limitations

Báoversion/architecture/quyền/timestampthật,khôngpublishreportprivate. [Guide](USER-GUIDE.md)/[readiness](production/RELEASE-READINESS.md)/[privacy](../PRIVACY.md)/[release](OPERATIONS-RELEASE.md).

## 日本語

### Build and verify

FullXcode/per-commandDEVELOPER_DIR/Swift6/macOS13。XCTest/smoke/format/locale後universal/dmg/verifyallow-adhoc。ArtifactOrven.app/Orven-3.0.0.dmg、3.0exceptionad-hoc/unnotarized、Gatekeeperbypasscommand禁止。

### Local data and cleanup

Bundle/data維持、corruptstore自動reset/historyseedなし。Missing/skipped/permissioncoverage保持。Scheduleddeleteなし、eligiblecleanup/irreversibledevelopercommandは別review。[Trace](diagrams/install-trace-sequence.html)/[recovery](diagrams/review-recovery-state.html)。

### Support and limitations

実version/architecture/permission/timestamp報告、private report公開なし。[Guide](USER-GUIDE.md)/[readiness](production/RELEASE-READINESS.md)/[privacy](../PRIVACY.md)/[release](OPERATIONS-RELEASE.md)。
