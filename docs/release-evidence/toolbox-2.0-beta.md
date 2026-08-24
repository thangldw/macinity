# Toolbox 2.0 Beta and Release Evidence

Status is evidence-based. `PASS` requires output from the exact release candidate; unknowns remain `NOT YET VERIFIED`.

## Candidate identity

| Field | Evidence |
| --- | --- |
| Commit SHA | NOT YET VERIFIED — fill with signed release-candidate SHA |
| Version | 2.0.0 |
| Bundle identifier | `com.thang.toolbox` |
| Minimum macOS | 13.0 |
| Candidate DMG | `Toolbox-2.0.0.dmg` |
| Candidate SHA-256 | NOT YET VERIFIED — generated after final DMG stapling |
| Public Toolbox 2 DMG baseline | 0 download events on 2026-08-25; no 2.0 DMG is published yet |

## Local source gates — 2026-08-25

Environment: Apple Silicon macOS, Swift 6 toolchain from Command Line Tools. Full Xcode/XCTest is unavailable locally and remains a CI gate.

| Gate | Command | Status |
| --- | --- | --- |
| Format | `swift format lint --recursive --parallel Sources Tests Package.swift` | PASS |
| Core smoke | `./scripts/test_core.sh` | PASS |
| Storage and recovery smoke | `./scripts/test_storage.sh` | PASS — includes five byte-for-byte restore drills and a no-overwrite conflict |
| Change Timeline smoke | `./scripts/test_changes.sh` | PASS |
| App/update contract | `./scripts/test_app.sh` | PASS |
| Localization | `./scripts/lint_localizations.swift` | PASS — 76 literal EN/VI keys |
| Universal bundle | `./scripts/build_universal.sh` | PASS — `arm64 x86_64` |
| Local DMG | `./scripts/build_dmg.sh && ./scripts/verify_release.sh --allow-adhoc` | PASS — checksum, mount, resources, signature structure |
| XCTest | `swift test` | NOT YET VERIFIED locally — Command Line Tools reports `no such module XCTest`; GitHub Actions with full Xcode required |

## Migration evidence

| Fixture | Expected | Status |
| --- | --- | --- |
| Diskora cleanup history | Decode, merge, verify, marker last, original untouched | PASS in core/storage smoke |
| Changeora completed session | Stable ID and evidence import | PASS in core/changes smoke |
| Changeora active/baseline state | Interrupted-state recovery | PASS in core/changes smoke |
| Second migration run | No duplicate import | PASS in core smoke |
| Corrupt legacy input | No partial marker or destructive write | PASS in core smoke |

## Recovery drills

Five independent Trash fixtures restore byte-for-byte into previously absent destinations. Each drill verifies one restored item, identical payload, and removal of the Trash fixture. A sixth conflict fixture verifies that an existing destination is unchanged and the restore count remains zero.

Status: PASS locally through `./scripts/test_storage.sh`. Repeat all five drills against the signed beta on a clean account before public launch.

## Performance and hardware

| Evidence | Status |
| --- | --- |
| Representative scan elapsed time and peak memory versus v1 | NOT YET VERIFIED — benchmark exact fixtures on both versions |
| Apple Silicon signed launch | NOT YET VERIFIED |
| Intel signed launch | NOT YET VERIFIED — universal slice exists; physical/virtual Intel launch evidence still required |
| macOS 13 clean-account DMG install | NOT YET VERIFIED |
| Full Disk Access reduced/full sentinel behavior | PASS locally; signed clean-account confirmation still required |

## Distribution trust gates

| Gate | Status |
| --- | --- |
| Developer ID signature | NOT YET VERIFIED — protected certificate required |
| App notarization and staple | NOT YET VERIFIED — Apple notary credentials required |
| DMG notarization and staple | NOT YET VERIFIED — Apple notary credentials required |
| Gatekeeper `spctl` assessment | NOT YET VERIFIED |
| Public asset re-download checksum | NOT YET VERIFIED |
| GitHub Pages direct DMG HTTP 200 | NOT YET VERIFIED |
| Homebrew install of identical SHA-256 | NOT YET VERIFIED |

## Beta cohort and defects

| Gate | Status |
| --- | --- |
| 20 developers completed signed beta | NOT YET VERIFIED — 0/20 recorded |
| Severity-1 defects | NOT YET VERIFIED — establish beta issue triage |
| Severity-2 defects | NOT YET VERIFIED — establish beta issue triage |
| Product Hunt gallery uses exact signed release candidate | NOT YET VERIFIED — current site previews are marked representative fixture data |

Public launch remains blocked until every `NOT YET VERIFIED` launch gate is replaced by dated evidence tied to the exact commit and artifact checksum.
