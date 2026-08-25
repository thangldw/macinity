# Toolbox 2.0.0

This stable GitHub release combines Diskora and Changeora into one local-first macOS GUI for tracing installer changes, reviewing developer storage, and recovering Trash-backed cleanup actions.

## Important: not Apple-notarized

This build is ad-hoc signed and has not been notarized by Apple. Stable describes the Toolbox release channel, not Apple trust approval. Gatekeeper will require one manual approval.

## Install

1. Download `Toolbox-2.0.0.dmg` and `Toolbox-2.0.0.dmg.sha256` into the same folder.
2. Verify the download with `shasum -a 256 -c Toolbox-2.0.0.dmg.sha256`.
3. Open the DMG and read `Open Toolbox - First Launch.html`.
4. Drag Toolbox to Applications and try to open it once.
5. Open **System Settings → Privacy & Security → Open Anyway**, then authenticate.

Do not disable Gatekeeper or remove quarantine attributes. This manual approval applies only to this Toolbox build on your Mac.

## Scope

- macOS 13 or later; Apple Silicon and Intel.
- Local-only data processing with no account or telemetry.
- Reviewed cleanup moves eligible files to Trash and records recovery paths.
- Homebrew installation is unavailable while the release is not Developer ID-signed and notarized.

Report reproducible issues at <https://github.com/thangldw/toolbox/issues> with your macOS version, Mac architecture, workflow, and observed result. Do not attach personal paths or private files.
