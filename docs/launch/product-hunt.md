# Toolbox Product Hunt Launch Record

Status: SCHEDULED — August 26, 2026 at 12:01 AM PDT.

Launch URL: https://www.producthunt.com/products/toolbox-14?launch=toolbox-14

Name: Toolbox

Tagline: Understand Mac changes before you clean them up

Description: Toolbox is a free, open-source macOS app I built after getting tired of cleanup tools that show large folders without explaining what created them or whether removal is reversible. It traces installer changes, finds rebuildable project output only inside folders you choose, and records Trash-backed cleanup actions so you can recover them. Everything runs locally. No account, telemetry, privileged helper, or automatic deletion. Not Apple-notarized; first launch requires Open Anyway.

Topics: Developer Tools, Mac, Open Source

Pricing: Free

Website: https://thangldw.github.io/toolbox/

GitHub: https://github.com/thangldw/toolbox

First comment: Hi Product Hunt, I built Toolbox because I kept running into the same problem on my Mac: I could see that a folder was large, but I couldn't tell what created it, whether it was safe to remove, or how I would undo the cleanup if I got it wrong. So I made the tool I wanted to use myself. Toolbox has three main workflows: Install Trace compares filesystem metadata before and after a normal installer; Projects finds known rebuildable output only inside project folders you choose; Recovery keeps evidence for Trash-backed cleanup actions and checks paths before restoring. It runs locally and doesn't require an account. There is no telemetry, privileged helper, automatic deletion, or malware verdict. One honest limitation: Toolbox 2.0 is ad-hoc signed and not notarized by Apple, so macOS requires the Open Anyway step in Privacy & Security. I included a SHA-256 checksum, and the source is public. Please don't disable Gatekeeper or remove quarantine attributes. I'm looking for practical feedback from Mac developers: what evidence would you need before cleaning a path, which confirmation or recovery step feels unclear, and which project artifact should Toolbox recognize next? Reproducible issues can be reported at https://github.com/thangldw/toolbox/issues without private paths or files. Thanks for trying it.

## Gallery order

1. `product-hunt-home.png` — One place to understand storage, change evidence, and recovery.
2. `product-hunt-trace.png` — Compare before/after metadata and review each affected path.
3. `product-hunt-projects.png` — Find known rebuildable artifacts only inside selected project roots.
4. `product-hunt-recovery.png` — Restore Trash-backed actions only after destination and source checks pass.

Thumbnail: `product-hunt-thumbnail.png`.

## Maker and support

- Maker: Thang (`thangldw`)
- Product status: free, open source, macOS 13+
- Primary action: Download for macOS
- Secondary action: View source
- Support: https://github.com/thangldw/toolbox/issues
- Privacy: https://thangldw.github.io/toolbox/privacy.html

## Evidence limits accepted for this launch

- The release is stable at the product-channel level but remains ad-hoc signed and not Apple-notarized.
- Gatekeeper rejection is expected; users receive `Open Anyway` guidance on the website, in the DMG, and in onboarding.
- Homebrew remains unavailable.
- Gallery images use representative local fixture data and do not claim production-user evidence.
