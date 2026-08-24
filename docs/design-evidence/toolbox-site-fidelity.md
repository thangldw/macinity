# Toolbox Site Fidelity Ledger

## Evidence

- Accepted first-viewport concept: `docs/design-concepts/toolbox-site-hero-concept.png` at 1,536 × 1,024.
- Accepted downstream concept: `docs/design-concepts/toolbox-site-sections-concept.png` at 872 × 1,800.
- Browser render: `docs/design-evidence/toolbox-site-desktop.png` at 1,280 × 800.
- Mobile render: `docs/design-evidence/toolbox-site-mobile.png` at 390 × 844.
- Verification surface: Codex in-app browser against a local static HTTP server.

## Comparison

| Point | Concept | Browser render | Result |
| --- | --- | --- | --- |
| Copy and hierarchy | Two-sentence promise, restrained support copy, two CTAs | Same heading, support copy, CTA labels, and order | Match |
| Layout | Asymmetric text/product split and quiet header | Same split at 1,280 px; one-column continuation at 390 px | Match |
| Typography | Large Swiss-style white headline and compact UI text | System sans with matching weight, tracking, scale, and control typography | Match |
| Palette | True graphite, white, muted gray, electric lime | Tokenized `#090a0a`, `#f5f6f3`, `#a6aaa5`, `#d7ff36` | Match |
| Media treatment | One dark macOS frame with thin border and no overlay | Stable 1,270 × 760 frame, thin border, no tint or overlay | Match |
| Container rhythm | Open sections, horizontal workflow, minimal cards | Open bands and lists; no bento or repeated card grid | Match |
| Responsive behavior | Airy desktop with clear continuation | No horizontal overflow at 1,280 or 390 px; mobile CTA and footer verified | Match |

## Intentional deviation

The browser render adds a visible “Representative local fixture data” caption because Screen Recording access was unavailable in the build environment. The generated previews must be replaced by exact release-candidate captures before public launch. This disclosure is intentionally retained instead of presenting fixture imagery as production evidence.

Above-the-fold copy otherwise matches the accepted concept. No material visual mismatch remains in the verified desktop or mobile implementation.
