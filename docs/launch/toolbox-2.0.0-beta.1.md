# Toolbox 2.0.0 Beta 1

This GitHub pre-release combines Diskora and Changeora into one local-first macOS GUI for tracing installer changes, reviewing developer storage, and recovering Trash-backed cleanup actions.

## Important: unnotarized beta

This build is ad-hoc signed and has not been notarized by Apple. Gatekeeper will not approve it automatically. If you prefer not to make a manual exception, build from source or wait for the signed and notarized stable release.

## Install

1. Download `Toolbox-2.0.0.dmg` and `Toolbox-2.0.0.dmg.sha256` into the same folder.
2. Verify the download with `shasum -a 256 -c Toolbox-2.0.0.dmg.sha256`.
3. Open the DMG and drag Toolbox to Applications.
4. Try to open Toolbox once.
5. Open **System Settings → Privacy & Security → Open Anyway**, then authenticate.

Do not disable Gatekeeper or remove quarantine attributes. This manual approval applies only to this Toolbox build on your Mac.

## Scope

- macOS 13 or later; Apple Silicon and Intel.
- Local-only data processing with no account or telemetry.
- Reviewed cleanup moves eligible files to Trash and records recovery paths.
- Homebrew installation is intentionally unavailable for this unnotarized beta.

Report reproducible issues at <https://github.com/thangldw/toolbox/issues> with your macOS version, Mac architecture, workflow, and observed result. Do not attach personal paths or private files.
