# Orven release operations

## English

### Current release contract

Orven3.0.0/v3.0.0 is the current stable target. The user explicitly authorized ad-hoc signing and not-notarized disclosure. release.json and Info.plist must agree; ZIP/DMG names, first-launch guide, website and release notes must identify the same product/version. Historical Toolbox tags remain immutable on GitHub.

### Validation and packaging

Complete source tests/smokes/format/locales/docs/site, universal bundle and ad-hoc structural checks. Mount the DMG read-only to verify Orven.app, Applications link and first-launch guide; verify checksum after final DMG bytes. Record known unverified native/hardware/resource limits without substituting old candidates. No signing identity or credentials are required for the authorized ad-hoc channel.

### Publication and update

Publish from an exact reviewed source commit/tag and immutable assets/checksum. The release workflow only supports v3.0.0 and runs checks before publication; Pages publishes the maintained site from main. Check GitHub latest release and Pages rendered content after completion. If an upload outcome is uncertain, inspect existing release assets before retrying. [Release notes](launch/orven-3.0.0.md), [readiness](production/RELEASE-READINESS.md).

## Tiếng Việt

### Current release contract

CurrentstabletargetOrven3.0.0/v3.0.0,đượcphépad-hoc/chưa notarized. release.json/Info.plist/artifact/guide/web/notesphảiđồngbộ. OldToolboxtagsimmutableGitHub.

### Validation and packaging

Hoàntất sourcechecks/smoke/format/locale/docs/site/universal/ad-hoc. MountDMGreadonly verifyOrven.app/Applicationslink/guide;checksumtheobyteDMGfinal. Recordunknownnative/hardware/resource,khôngdùngoldcandidate thay. Ad-hockhông cầnidentity/credentials.

### Publication and update

Publishexactreviewedcommit/tag+immutableasset/checksum. Workflowchỉv3.0.0/checktrướcpublish,Pagesmain. VerifylatestGitHub/site rendered sauhoàntất. Uploadunknownphảiinspecttrướcretry. [Notes](launch/orven-3.0.0.md)/[readiness](production/RELEASE-READINESS.md).

## 日本語

### Current release contract

CurrentstabletargetOrven3.0.0/v3.0.0、ad-hoc/unnotarized承認。release.json/Info.plist/artifact/guide/web/notes一致、旧ToolboxtagはGitHubimmutable。

### Validation and packaging

Sourcechecks/smoke/format/locale/docs/site/universal/ad-hoc完了。ReadonlyDMGでOrven.app/Applicationslink/guide、finalbytechecksum確認。Unknownnative/hardware/resource明示、oldcandidate代用なし。Ad-hocにidentity/credentials不要。

### Publication and update

Exactreviewedcommit/tagとimmutableasset/checksum公開。Workflowはv3.0.0のみ/check後publish、Pagesmain。完了後latestGitHub/renderedsite確認。Upload不明時asset確認後retry。[Notes](launch/orven-3.0.0.md)/[readiness](production/RELEASE-READINESS.md)。
