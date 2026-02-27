#!/usr/bin/env python3
"""Generate a 1024x1024 app icon for the Finance app."""

from PIL import Image, ImageDraw, ImageFont
import math, os

SIZE = 1024

img = Image.new("RGBA", (SIZE, SIZE))
draw = ImageDraw.Draw(img)

# --- Gradient background matching AppTheme.balanceGradient ---
# Top-left: (0.10, 0.62, 0.45)  →  Bottom-right: (0.08, 0.30, 0.48)
c1 = (26, 158, 115)   # emerald green
c2 = (15, 107, 133)   # teal
c3 = (20, 77, 122)    # deep blue

for y in range(SIZE):
    t = y / SIZE
    if t < 0.5:
        tt = t * 2
        r = int(c1[0] + (c2[0] - c1[0]) * tt)
        g = int(c1[1] + (c2[1] - c1[1]) * tt)
        b = int(c1[2] + (c2[2] - c1[2]) * tt)
    else:
        tt = (t - 0.5) * 2
        r = int(c2[0] + (c3[0] - c2[0]) * tt)
        g = int(c2[1] + (c3[1] - c2[1]) * tt)
        b = int(c2[2] + (c3[2] - c2[2]) * tt)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# --- Subtle decorative circles (like the balance card) ---
overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
od = ImageDraw.Draw(overlay)

# Large circle top-right
cx, cy, cr = 780, 180, 280
od.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(255, 255, 255, 18))

# Smaller circle bottom-left
cx2, cy2, cr2 = 200, 800, 200
od.ellipse([cx2 - cr2, cy2 - cr2, cx2 + cr2, cy2 + cr2], fill=(255, 255, 255, 13))

# Tiny circle top-left
cx3, cy3, cr3 = 150, 250, 100
od.ellipse([cx3 - cr3, cy3 - cr3, cx3 + cr3, cy3 + cr3], fill=(255, 255, 255, 10))

img = Image.alpha_composite(img, overlay)
draw = ImageDraw.Draw(img)

# --- Draw a stylized wallet/chart icon ---
# We'll draw a simple but elegant design:
# A circular badge with a dollar sign, surrounded by a thin ring
# Plus a small upward-trending line chart element

center_x, center_y = SIZE // 2, SIZE // 2 - 20

# Outer glow ring
ring_r = 300
for i in range(40, 0, -1):
    alpha = int(3 * i)
    ring_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(ring_overlay)
    ring_draw.ellipse(
        [center_x - ring_r - i, center_y - ring_r - i,
         center_x + ring_r + i, center_y + ring_r + i],
        outline=(255, 255, 255, alpha), width=2
    )
    img = Image.alpha_composite(img, ring_overlay)

draw = ImageDraw.Draw(img)

# Inner filled circle (slightly darker)
inner_r = 280
inner_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
inner_draw = ImageDraw.Draw(inner_overlay)
inner_draw.ellipse(
    [center_x - inner_r, center_y - inner_r,
     center_x + inner_r, center_y + inner_r],
    fill=(0, 0, 0, 40)
)
img = Image.alpha_composite(img, inner_overlay)
draw = ImageDraw.Draw(img)

# Thin white ring
draw.ellipse(
    [center_x - inner_r, center_y - inner_r,
     center_x + inner_r, center_y + inner_r],
    outline=(255, 255, 255, 80), width=4
)

# --- Dollar sign ---
# Try to use a system font; fall back to default
font_size = 360
try:
    font = ImageFont.truetype("/System/Library/Fonts/SFCompactRounded-Bold.otf", font_size)
except:
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()

dollar = "$"
# Get text bounding box
bbox = draw.textbbox((0, 0), dollar, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
tx = center_x - tw // 2 - bbox[0]
ty = center_y - th // 2 - bbox[1]

# Drop shadow
shadow_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
shadow_draw = ImageDraw.Draw(shadow_overlay)
shadow_draw.text((tx + 4, ty + 6), dollar, font=font, fill=(0, 0, 0, 60))
img = Image.alpha_composite(img, shadow_overlay)

# Main text
draw = ImageDraw.Draw(img)
draw.text((tx, ty), dollar, font=font, fill=(255, 255, 255, 240))

# --- Small upward trend line at bottom ---
trend_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
trend_draw = ImageDraw.Draw(trend_overlay)

points = [
    (320, 780),
    (420, 740),
    (500, 760),
    (580, 700),
    (700, 650),
]
# Glow effect
for w in range(12, 0, -2):
    alpha = int(20 * (12 - w) / 12)
    trend_draw.line(points, fill=(120, 230, 160, alpha), width=w, joint="curve")

# Main line
trend_draw.line(points, fill=(150, 255, 180, 200), width=5, joint="curve")

# Small dot at the end (tip of trend)
ex, ey = points[-1]
trend_draw.ellipse([ex - 10, ey - 10, ex + 10, ey + 10], fill=(180, 255, 200, 220))

img = Image.alpha_composite(img, trend_overlay)

# --- Save ---
output_dir = "FinanceApp/Resources/Assets.xcassets/AppIcon.appiconset"
output_path = os.path.join(output_dir, "AppIcon.png")
# Convert to RGB (no alpha — iOS icons must be opaque)
final = Image.new("RGB", (SIZE, SIZE))
final.paste(img, mask=img.split()[3])
final.save(output_path, "PNG")
print(f"✅ Icon saved to {output_path} ({final.size[0]}x{final.size[1]})")
