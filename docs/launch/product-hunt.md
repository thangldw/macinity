# Toolbox Product Hunt Launch Draft

Name: Toolbox

Tagline: See what changed. Reclaim developer storage safely.

Description: A local-first macOS utility that traces installer changes, explains developer storage, and moves reviewed cleanup targets to Trash with recovery evidence.

Topics: Developer Tools, Mac, Open Source

Pricing: Free

Website: https://thangldw.github.io/toolbox/

GitHub: https://github.com/thangldw/toolbox

First comment: I built Toolbox after repeatedly finding gigabytes of project output and app leftovers without a trustworthy answer to two questions: what created this path, and can I undo the cleanup? Toolbox puts change evidence and storage review in one local-first macOS GUI. Install Trace records metadata before and after a normal macOS installer flow; Projects recognizes rebuildable output only inside folders you choose; reviewed cleanup moves to Trash and keeps recovery paths. There is no account, telemetry, privileged helper, automatic deletion, or malware verdict. Toolbox 2.0 combines and migrates the useful history from my earlier Diskora and Changeora apps. I would value concrete feedback on the workflow: which evidence is missing, and which confirmation or recovery step still feels unclear?

## Gallery order and captions

1. `product-hunt-home.png` — One place to understand storage, change evidence, and recovery.
2. `product-hunt-trace.png` — Compare before/after metadata and review each affected path.
3. `product-hunt-projects.png` — Find known rebuildable artifacts only inside selected project roots.
4. `product-hunt-recovery.png` — Restore Trash-backed actions only after destination and source checks pass.

Thumbnail: `product-hunt-thumbnail.png`.

## Maker checklist

- Maker: Thang (`thangldw`)
- Product status: free, open source, macOS 13+
- Primary action: Download for macOS
- Secondary action: View source
- Support destination: GitHub Issues
- Privacy destination: `https://thangldw.github.io/toolbox/privacy.html`
- Launch-day response focus: reproduce workflow friction, collect macOS/hardware context, link evidence or an issue, avoid defensive replies

## Publication gate

Status: BLOCKED — source package ready, public launch not authorized by evidence yet.

Before uploading these fields to Product Hunt:

- Replace all four representative fixture previews with exact signed release-candidate captures at the same dimensions.
- Verify the public DMG, checksum, Pages link, Homebrew install, notarization staple, Gatekeeper assessment, Apple Silicon launch, and Intel launch.
- Record 20 completed signed-beta users and close every severity-1/2 defect.
- Rehearse and record the 30–60 second demo from `site/assets/demo-script.md` using the exact public build.
- Confirm Product Hunt maker profile, launch date, website, topics, pricing, thumbnail, gallery, demo, and first comment in one final review.

Do not create the public post or upload the representative previews before this gate passes.
