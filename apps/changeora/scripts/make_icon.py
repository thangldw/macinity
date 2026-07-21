#!/usr/bin/env python3
"""Create a cropped, alpha-safe macOS icon master from generated artwork."""
from pathlib import Path

from PIL import Image, ImageDraw

project = Path(__file__).resolve().parent.parent
source = project / "Resources" / "AppIcon.png"
output = project / "Resources" / "AppIcon-1024.png"

image = Image.open(source).convert("RGBA")
side = min(image.size)
left = (image.width - side) // 2
top = (image.height - side) // 2
image = image.crop((left, top, left + side, top + side))

# Generated artwork includes presentation padding. Crop it so the app icon fills
# the standard macOS icon canvas while preserving a small optical margin.
margin = round(side * 0.095)
image = image.crop((margin, margin, side - margin, side - margin))
image = image.resize((1024, 1024), Image.Resampling.LANCZOS)

scale = 4
mask = Image.new("L", (1024 * scale, 1024 * scale), 0)
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle(
    (8 * scale, 8 * scale, 1016 * scale, 1016 * scale),
    radius=215 * scale,
    fill=255,
)
mask = mask.resize((1024, 1024), Image.Resampling.LANCZOS)
image.putalpha(mask)
image.save(output, optimize=True)
print(output)
