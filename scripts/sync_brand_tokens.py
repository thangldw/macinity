#!/usr/bin/env python3
"""Adapt the canonical native Orven palette for the public website."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
source = (root / 'apps/toolbox/Sources/ToolboxCore/OrvenTheme.swift').read_text()
colors = {name: (light, dark) for name, light, dark in re.findall(
    r'public static let (\w+): Color = adaptive\(light: 0x([0-9A-F]{6}), dark: 0x([0-9A-F]{6})\)', source
)}
roles = {'color-canvas': 'canvas', 'color-background': 'canvas', 'color-surface': 'surface',
         'color-accent': 'accent', 'color-text-strong': 'ink', 'color-text-body': 'secondary',
         'color-border': 'border'}
lines = ['/* Generated from OrvenTheme.swift by scripts/sync_brand_tokens.py. */']
for index, selector in [(0, ':root[data-theme="light"]'), (1, ':root[data-theme="dark"]')]:
    lines.append(selector + '{')
    lines.extend(f'  --{role}: #{colors[owner][index]};' for role, owner in roles.items())
    lines.append('  --color-on-accent: ' + ('#FFFFFF;' if index == 0 else '#' + colors['canvas'][1] + ';'))
    lines.append('}')
lines.append('body.orven-page{background:var(--color-canvas);color:var(--color-text-strong)}')
(root / 'site/orven-brand.css').write_text('\n'.join(lines) + '\n')
