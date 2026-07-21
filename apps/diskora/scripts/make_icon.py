#!/usr/bin/env python3
"""Create the macOS icon master with an alpha-safe rounded mask."""
from pathlib import Path
from PIL import Image, ImageDraw

project = Path(__file__).resolve().parent.parent
source = project / "Resources" / "AppIcon.png"
output = project / "Resources" / "AppIcon-1024.png"

image = Image.open(source).convert("RGBA").resize((1024, 1024), Image.Resampling.LANCZOS)
scale = 4
mask = Image.new("L", (1024 * scale, 1024 * scale), 0)
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle((8 * scale, 8 * scale, 1016 * scale, 1016 * scale), radius=205 * scale, fill=255)
mask = mask.resize((1024, 1024), Image.Resampling.LANCZOS)
image.putalpha(mask)
image.save(output, optimize=True)
print(output)
