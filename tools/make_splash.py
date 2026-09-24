#!/usr/bin/env python3
"""Main-menu splash pair.

Bright candy yard of the cartoon guns firing on the boss, plus a dimmer
twin of the same picture so the menu can crossfade as the UI appears.
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BRIGHT = os.path.join(ROOT, "assets", "concept", "05_main_menu_splash.png")
DIM = os.path.join(ROOT, "assets", "concept", "05_main_menu_splash_dim.png")
W, H = 1280, 720


def _gradient() -> Image.Image:
    im = Image.new("RGBA", (W, H))
    px = im.load()
    top = (255, 246, 236)
    mid = (230, 210, 255)
    low = (176, 224, 255)
    ground = (168, 230, 176)
    for y in range(H):
        t = y / (H - 1)
        if t < 0.42:
            u = t / 0.42
            col = tuple(int(top[i] + (mid[i] - top[i]) * u) for i in range(3))
        elif t < 0.62:
            u = (t - 0.42) / 0.20
            col = tuple(int(mid[i] + (low[i] - mid[i]) * u) for i in range(3))
        else:
            u = (t - 0.62) / 0.38
            col = tuple(int(low[i] + (ground[i] - low[i]) * u) for i in range(3))
        for x in range(W):
            px[x, y] = (*col, 255)
    return im


def _paste(base: Image.Image, path: str, cx: int, cy: int, size: int) -> None:
    sprite = Image.open(path).convert("RGBA")
    sprite = sprite.resize((size, size), Image.Resampling.LANCZOS)
    # Soft drop shadow so the cutouts sit on the yard.
    shadow = Image.new("RGBA", sprite.size, (0, 0, 0, 0))
    alpha = sprite.getchannel("A")
    shade = Image.new("L", sprite.size, 90)
    shadow.putalpha(alpha.point(lambda a: int(a * 0.28)))
    shadow = Image.merge("RGBA", (shade, shade, Image.new("L", sprite.size, 110), shadow.getchannel("A")))
    shadow = shadow.filter(ImageFilter.GaussianBlur(6))
    base.alpha_composite(shadow, (cx - size // 2 + 8, cy - size // 2 + 14))
    base.alpha_composite(sprite, (cx - size // 2, cy - size // 2))


def _shot(draw: ImageDraw.ImageDraw, a, b, color, width=10) -> None:
    draw.line([a, b], fill=(90, 60, 110, 255), width=width + 6)
    draw.line([a, b], fill=color, width=width)


def main() -> None:
    print("Menu splash is the art-director pair in assets/ui/. Not overwriting it.")
    return
    im = _gradient()
    draw = ImageDraw.Draw(im)
    # Clouds.
    for box, fill in (
        ((40, 40, 280, 140), (255, 255, 255, 170)),
        ((180, 80, 420, 170), (255, 248, 255, 140)),
        ((860, 30, 1180, 150), (255, 255, 255, 160)),
        ((1040, 90, 1260, 190), (255, 236, 250, 140)),
    ):
        draw.ellipse(box, fill=fill)
    # Sparkles.
    for x, y, r in (
        (160, 200, 4),
        (520, 90, 5),
        (700, 160, 3),
        (240, 280, 3),
        (1180, 240, 4),
        (90, 320, 3),
    ):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(255, 250, 220, 230))
    # Yard path.
    draw.rounded_rectangle((80, 470, 1200, 680), radius=48, fill=(255, 236, 196, 255), outline=(255, 214, 150, 255), width=6)
    draw.rounded_rectangle((120, 500, 760, 650), radius=36, fill=(186, 236, 196, 255))

    sprites = os.path.join(ROOT, "assets", "sprites")
    # Shots first, so the characters sit on top of the candy trails.
    _shot(draw, (360, 430), (860, 360), (186, 230, 96, 255), 14)
    _shot(draw, (470, 390), (900, 340), (255, 236, 120, 255), 12)
    _shot(draw, (400, 520), (880, 420), (255, 170, 200, 255), 12)
    _shot(draw, (560, 470), (920, 400), (255, 170, 90, 255), 16)
    pea = os.path.join(sprites, "projectiles", "pea.png")
    glue = os.path.join(sprites, "projectiles", "glue.png")
    boom = os.path.join(sprites, "projectiles", "boom.png")
    for path, pos, size in (
        (pea, (620, 390), 42),
        (pea, (740, 370), 36),
        (glue, (700, 460), 40),
        (boom, (780, 420), 48),
    ):
        _paste(im, path, *pos, size)
    # Little impact stars near the boss, cute not grim.
    for x, y, r in ((900, 340, 14), (960, 300, 10), (860, 390, 8)):
        pts = []
        for i in range(8):
            ang = math.radians(-90 + i * 45)
            rad = r if i % 2 == 0 else r * 0.4
            pts.append((x + math.cos(ang) * rad, y + math.sin(ang) * rad))
        draw.polygon(pts, fill=(255, 248, 210, 255), outline=(90, 60, 110, 255))

    _paste(im, os.path.join(sprites, "map", "core.png"), 150, 560, 130)
    _paste(im, os.path.join(sprites, "towers", "magnet.png"), 250, 430, 120)
    _paste(im, os.path.join(sprites, "towers", "spark.png"), 390, 400, 150)
    _paste(im, os.path.join(sprites, "towers", "pea.png"), 330, 530, 170)
    _paste(im, os.path.join(sprites, "towers", "glue.png"), 470, 560, 140)
    _paste(im, os.path.join(sprites, "towers", "boom.png"), 560, 450, 160)
    _paste(im, os.path.join(sprites, "enemies", "swarmling.png"), 1040, 560, 90)
    _paste(im, os.path.join(sprites, "enemies", "big_cute_boss.png"), 1040, 390, 420)

    os.makedirs(os.path.dirname(BRIGHT), exist_ok=True)
    bright = im.convert("RGB")
    bright.save(BRIGHT, "PNG")
    # Same composition, dusk grade. The menu crossfades onto this.
    dusk = Image.new("RGB", bright.size, (92, 64, 122))
    mixed = Image.blend(bright, dusk, 0.34)
    dim = ImageEnhance.Brightness(mixed).enhance(0.86)
    dim.save(DIM, "PNG")
    print("wrote", BRIGHT)
    print("wrote", DIM)


if __name__ == "__main__":
    main()
