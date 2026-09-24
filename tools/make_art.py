#!/usr/bin/env python3
"""Generate cozy top-down sprites for Scrapyard TD.

Flat cel colors, bold ink outlines, transparent backgrounds.
Creatures are cute eldritch horrors. Towers are scrapyard gadgets.
Everything is drawn to sit inside a single grid cell (boss slightly larger).
"""

from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ENEMY = os.path.join(ROOT, "assets", "sprites", "enemies")
TOWER = os.path.join(ROOT, "assets", "sprites", "towers")
MAP = os.path.join(ROOT, "assets", "sprites", "map")
PROJ = os.path.join(ROOT, "assets", "sprites", "projectiles")
UI = os.path.join(ROOT, "assets", "sprites", "ui")
CONCEPT = os.path.join(ROOT, "assets", "concept")

INK = (42, 32, 72, 255)
WHITE = (255, 252, 246, 255)
CREAM = (255, 236, 214, 255)
BLUSH = (255, 150, 176, 210)


class Canvas:
    def __init__(self, size: int, scale: int = 4):
        self.size = size
        self.s = scale
        self.im = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def _p(self, x: float, y: float) -> tuple[float, float]:
        return (x * self.s, y * self.s)

    def save(self, path: str) -> None:
        out = self.im.resize((self.size, self.size), Image.Resampling.LANCZOS)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        out.save(path)

    def circle(self, x, y, r, fill, outline=True, width=5):
        s = self.s
        X, Y, R = x * s, y * s, r * s
        w = width * s
        if outline:
            self.d.ellipse([X - R - w, Y - R - w, X + R + w, Y + R + w], fill=INK)
        self.d.ellipse([X - R, Y - R, X + R, Y + R], fill=fill)

    def ellipse(self, box, fill, outline=True, width=5):
        s = self.s
        x0, y0, x1, y1 = [v * s for v in box]
        w = width * s
        if outline:
            self.d.ellipse([x0 - w, y0 - w, x1 + w, y1 + w], fill=INK)
        self.d.ellipse([x0, y0, x1, y1], fill=fill)

    def round_rect(self, box, r, fill, outline=True, width=5):
        s = self.s
        x0, y0, x1, y1 = [v * s for v in box]
        rr = r * s
        w = width * s
        if outline:
            self.d.rounded_rectangle([x0 - w, y0 - w, x1 + w, y1 + w], radius=rr + w * 0.6, fill=INK)
        self.d.rounded_rectangle([x0, y0, x1, y1], radius=rr, fill=fill)

    def line(self, a, b, fill, width):
        s = self.s
        self.d.line([self._p(*a), self._p(*b)], fill=fill, width=int(width * s))

    def polygon(self, pts, fill, outline=True, width=5):
        s = self.s
        scaled = [(x * s, y * s) for x, y in pts]
        if outline:
            self.d.line(scaled + [scaled[0]], fill=INK, width=int(width * s * 2))
            # fat joints
            for x, y in scaled:
                rad = width * s
                self.d.ellipse([x - rad, y - rad, x + rad, y + rad], fill=INK)
        self.d.polygon(scaled, fill=fill)

    def capsule(self, x1, y1, x2, y2, radius, fill, outline=True, width=4):
        self.line((x1, y1), (x2, y2), INK if outline else fill, radius * 2 + (width * 2 if outline else 0))
        self.line((x1, y1), (x2, y2), fill, radius * 2)
        self.circle(x1, y1, radius, fill, outline, width)
        self.circle(x2, y2, radius, fill, outline, width)

    def shine(self, x, y, rx, ry, alpha=110):
        self.ellipse((x - rx, y - ry, x + rx, y + ry * 0.2), (255, 255, 255, alpha), outline=False)

    def eye(self, x, y, r, iris, pupil=None, look=(0.15, 0.1)):
        self.circle(x, y, r, WHITE, True, max(3, int(r * 0.28)))
        self.circle(x + look[0] * r, y + look[1] * r, r * 0.62, iris, False)
        self.circle(x + look[0] * r * 1.4, y + look[1] * r, r * 0.34, pupil or INK, False)
        self.circle(x - r * 0.28, y - r * 0.32, r * 0.18, WHITE, False)

    def smile(self, x, y, w, h=6):
        s = self.s
        self.d.arc(
            [ (x - w) * s, (y - h) * s, (x + w) * s, (y + h * 1.6) * s ],
            20,
            160,
            fill=INK,
            width=max(2, int(2.4 * s)),
        )

    def blush(self, x, y, rx=7, ry=4):
        self.ellipse((x - rx, y - ry, x + rx, y + ry), BLUSH, outline=False)


def eye_squid(path: str) -> None:
    c = Canvas(128)
    body = (214, 186, 255, 255)
    tent = (176, 140, 230, 255)
    # Tentacles first so the body covers the roots.
    anchors = [
        (40, 78, 22, 104),
        (52, 84, 40, 116),
        (64, 86, 64, 118),
        (76, 84, 88, 116),
        (88, 78, 106, 104),
        (34, 64, 16, 78),
        (94, 64, 112, 78),
    ]
    for x1, y1, x2, y2 in anchors:
        c.capsule(x1, y1, x2, y2, 7, tent, True, 3)
    c.circle(64, 58, 30, body, True, 5)
    c.shine(52, 44, 12, 8)
    c.eye(64, 56, 16, (150, 110, 230, 255))
    c.blush(42, 68)
    c.blush(86, 68)
    c.smile(64, 74, 8, 4)
    c.save(path)


def star_toad(path: str) -> None:
    c = Canvas(128)
    body = (255, 186, 102, 255)
    belly = (255, 224, 170, 255)
    plate = (230, 140, 64, 255)
    star = (255, 214, 120, 255)
    for i in range(6):
        ang = -math.pi / 2 + i * math.tau / 6
        x = 64 + math.cos(ang) * 34
        y = 66 + math.sin(ang) * 30
        c.circle(x, y, 12, star, True, 4)
    c.circle(64, 66, 32, body, True, 5)
    c.ellipse((40, 70, 88, 98), belly, True, 4)
    # Sleepy armored plates.
    c.round_rect((46, 40, 82, 54), 6, plate, True, 3)
    c.circle(56, 47, 2.2, CREAM, False)
    c.circle(72, 47, 2.2, CREAM, False)
    c.eye(50, 64, 7, (120, 78, 48, 255), look=(0, 0.2))
    c.eye(78, 64, 7, (120, 78, 48, 255), look=(0, 0.2))
    # Sleepy lids.
    c.line((42, 60), (58, 62), INK, 2.4)
    c.line((70, 62), (86, 60), INK, 2.4)
    c.blush(36, 74, 6, 3.5)
    c.blush(92, 74, 6, 3.5)
    c.smile(64, 82, 8, 4)
    c.save(path)


def halo_wisp(path: str) -> None:
    """Ghost face only — the shield bubble is drawn in-game so it can pop."""
    c = Canvas(128)
    body = (255, 214, 232, 255)
    # Soft ghost: head circle + scalloped hem.
    c.circle(64, 58, 28, body, True, 5)
    c.circle(46, 82, 12, body, True, 4)
    c.circle(64, 88, 13, body, True, 4)
    c.circle(82, 82, 12, body, True, 4)
    c.round_rect((40, 64, 88, 86), 10, body, True, 4)
    c.shine(52, 46, 10, 7)
    c.eye(52, 58, 8, (255, 140, 186, 255))
    c.eye(76, 58, 8, (255, 140, 186, 255))
    c.blush(40, 70, 5, 3)
    c.blush(88, 70, 5, 3)
    c.smile(64, 74, 7, 4)
    c.save(path)


def egg_sac(path: str) -> None:
    c = Canvas(128)
    shell = (255, 176, 210, 255)
    spot = (240, 130, 180, 255)
    c.ellipse((34, 24, 94, 108), shell, True, 5)
    c.shine(52, 40, 14, 10)
    for sx, sy, sr in ((48, 48, 5), (78, 44, 4), (70, 70, 6), (46, 78, 4)):
        c.circle(sx, sy, sr, spot, False)
    # Crack with peeking eyes.
    c.line((58, 50), (70, 64), INK, 3)
    c.line((70, 64), (60, 80), INK, 3)
    c.eye(54, 62, 5, (186, 140, 255, 255))
    c.eye(74, 70, 4.2, (186, 140, 255, 255))
    c.eye(62, 84, 3.6, (150, 220, 255, 255))
    c.save(path)


def fractal_baby(path: str) -> None:
    c = Canvas(128)
    body = (190, 236, 255, 255)
    c.capsule(40, 78, 28, 96, 8, (255, 190, 220, 255), True, 3)
    c.capsule(88, 78, 102, 96, 8, (210, 190, 255, 255), True, 3)
    c.circle(64, 62, 26, body, True, 5)
    c.shine(52, 50, 9, 6)
    c.eye(64, 60, 12, (120, 170, 255, 255))
    c.blush(44, 72, 5, 3)
    c.blush(84, 72, 5, 3)
    c.smile(64, 78, 6, 3)
    c.save(path)


def grand_nibbler(path: str) -> None:
    c = Canvas(192)
    body = (198, 176, 255, 255)
    spot_cols = [
        (255, 214, 120, 255),
        (150, 230, 255, 255),
        (255, 170, 210, 255),
        (190, 255, 210, 255),
    ]
    # Little feet / nubs.
    for ang in (200, 230, 250, 280, 310, 340):
        rad = math.radians(ang)
        x = 96 + math.cos(rad) * 62
        y = 104 + math.sin(rad) * 52
        c.circle(x, y, 12, (176, 150, 230, 255), True, 4)
    c.circle(96, 96, 62, body, True, 6)
    for i, col in enumerate(spot_cols):
        ang = math.radians(30 + i * 78)
        c.circle(96 + math.cos(ang) * 36, 90 + math.sin(ang) * 28, 7, col, False)
    c.shine(72, 70, 18, 12, 90)
    # Friendly cluster of eyes. Two big, three small.
    c.eye(74, 92, 16, (150, 120, 230, 255))
    c.eye(118, 92, 16, (150, 120, 230, 255))
    c.eye(96, 70, 8, (255, 196, 140, 255))
    c.eye(58, 74, 6, (140, 220, 255, 255))
    c.eye(136, 76, 6, (255, 170, 210, 255))
    c.blush(48, 112, 8, 5)
    c.blush(144, 112, 8, 5)
    c.smile(96, 122, 16, 7)
    # Tiny bolt bowtie so the scrapyard dressed it.
    c.polygon([(78, 128), (96, 138), (78, 150)], (232, 84, 96, 255), True, 3)
    c.polygon([(114, 128), (96, 138), (114, 150)], (232, 84, 96, 255), True, 3)
    c.circle(96, 138, 5, (255, 214, 120, 255), True, 2)
    c.save(path)


def _base(c: Canvas, accent: tuple) -> None:
    metal = (214, 220, 230, 255)
    dark = (120, 132, 156, 255)
    c.round_rect((22, 78, 106, 116), 16, metal, True, 5)
    c.circle(34, 90, 3, dark, False)
    c.circle(94, 90, 3, dark, False)
    c.circle(34, 106, 3, dark, False)
    c.circle(94, 106, 3, dark, False)
    c.round_rect((40, 88, 88, 108), 8, accent, True, 3)


def pea_blaster(path: str) -> None:
    c = Canvas(128)
    _base(c, (126, 200, 96, 255))
    c.round_rect((48, 22, 80, 70), 14, (78, 170, 72, 255), True, 4)
    c.circle(64, 48, 16, (150, 220, 110, 255), True, 4)
    c.circle(64, 48, 7, (40, 90, 48, 255), False)
    c.circle(64, 16, 9, (176, 230, 96, 255), True, 3)
    c.shine(56, 40, 5, 3, 140)
    c.save(path)


def spark_arc(path: str) -> None:
    c = Canvas(128)
    _base(c, (255, 196, 90, 255))
    c.circle(64, 52, 24, (214, 140, 70, 255), True, 4)
    c.circle(64, 52, 12, (120, 220, 255, 255), True, 3)
    c.circle(64, 52, 5, WHITE, False)
    # Lightning rod.
    c.polygon([(64, 8), (74, 28), (66, 28), (76, 46), (54, 26), (62, 26), (52, 12)], (255, 226, 90, 255), True, 3)
    c.save(path)


def glue_goo(path: str) -> None:
    c = Canvas(128)
    _base(c, (255, 150, 196, 255))
    c.round_rect((42, 28, 86, 78), 16, (255, 156, 200, 255), True, 4)
    c.ellipse((50, 34, 78, 52), (255, 210, 230, 255), False)
    c.circle(64, 22, 8, (255, 120, 180, 255), True, 3)
    c.circle(78, 66, 7, (255, 120, 186, 255), True, 3)
    c.circle(86, 78, 5, (255, 150, 200, 255), True, 2)
    c.save(path)


def boom_barrel(path: str) -> None:
    c = Canvas(128)
    _base(c, (255, 150, 70, 255))
    c.circle(64, 50, 26, (255, 138, 64, 255), True, 5)
    c.round_rect((40, 42, 88, 58), 4, (255, 214, 80, 255), True, 3)
    c.round_rect((40, 42, 88, 50), 3, (42, 32, 72, 255), False)
    c.line((64, 24), (64, 12), INK, 3)
    c.circle(64, 10, 4, (255, 230, 120, 255), True, 2)
    c.circle(52, 46, 3, (255, 220, 200, 180), False)
    c.save(path)


def scrap_magnet(path: str) -> None:
    c = Canvas(128)
    _base(c, (240, 160, 170, 255))
    # Horseshoe from above: a thick U.
    c.capsule(46, 36, 46, 70, 12, (220, 70, 86, 255), True, 4)
    c.capsule(82, 36, 82, 70, 12, (236, 236, 242, 255), True, 4)
    c.capsule(46, 36, 82, 36, 12, (220, 70, 86, 255), True, 4)
    # Orbiting bolts.
    c.round_rect((18, 40, 30, 52), 3, (255, 214, 120, 255), True, 2)
    c.round_rect((98, 28, 112, 40), 3, (180, 220, 255, 255), True, 2)
    c.circle(100, 68, 5, (255, 214, 120, 255), True, 2)
    c.save(path)


def station_core(path: str) -> None:
    c = Canvas(128)
    c.round_rect((16, 16, 112, 112), 22, (186, 198, 214, 255), True, 5)
    c.circle(64, 64, 34, (255, 214, 110, 255), True, 4)
    c.circle(64, 64, 22, (140, 255, 196, 255), True, 3)
    c.shine(52, 50, 8, 5, 130)
    c.eye(52, 62, 6, (80, 60, 40, 255), look=(0, 0))
    c.eye(76, 62, 6, (80, 60, 40, 255), look=(0, 0))
    c.smile(64, 76, 7, 3)
    # Antenna.
    c.line((64, 18), (64, 8), INK, 3)
    c.circle(64, 7, 4, (255, 120, 160, 255), True, 2)
    c.save(path)


def rift(path: str) -> None:
    c = Canvas(128)
    c.circle(64, 64, 36, (186, 140, 255, 255), True, 5)
    c.circle(64, 64, 22, (120, 80, 210, 255), True, 4)
    c.circle(64, 64, 10, (255, 210, 245, 255), True, 3)
    c.shine(52, 48, 6, 4, 120)
    # Swirl hint.
    s = c.s
    c.d.arc([40 * s, 40 * s, 88 * s, 88 * s], 200, 430, fill=WHITE, width=int(3 * s))
    c.save(path)


def projectile(path: str, fill, kind: str) -> None:
    c = Canvas(48)
    if kind == "pea":
        c.circle(24, 24, 12, fill, True, 3)
        c.shine(18, 16, 4, 3, 150)
    elif kind == "glue":
        c.ellipse((10, 8, 38, 40), fill, True, 3)
        c.circle(24, 14, 6, (255, 230, 240, 255), False)
    else:
        c.circle(24, 26, 12, fill, True, 3)
        c.round_rect((8, 18, 40, 26), 2, (42, 32, 72, 255), False)
        c.circle(24, 8, 3, (255, 230, 120, 255), True, 2)
    c.save(path)


def icon(path: str) -> None:
    c = Canvas(128)
    c.round_rect((4, 4, 124, 124), 28, (36, 28, 74, 255), False)
    c.circle(64, 66, 36, (198, 176, 255, 255), True, 5)
    c.eye(64, 64, 16, (150, 110, 230, 255))
    c.smile(64, 86, 10, 4)
    c.circle(28, 78, 8, (176, 140, 230, 255), True, 3)
    c.circle(100, 78, 8, (176, 140, 230, 255), True, 3)
    c.save(path)


def scrap_icon(path: str) -> None:
    c = Canvas(64)
    c.round_rect((8, 18, 56, 50), 8, (255, 206, 90, 255), True, 4)
    c.circle(32, 34, 8, (255, 244, 210, 255), True, 3)
    c.line((32, 10), (32, 18), INK, 4)
    c.save(path)


def contact_sheet(paths: list[str], dest: str) -> None:
    thumbs = []
    for p in paths:
        im = Image.open(p).convert("RGBA")
        thumbs.append(im)
    cell = 160
    cols = 6
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGBA", (cols * cell, rows * cell), (244, 236, 220, 255))
    for i, im in enumerate(thumbs):
        scale = min((cell - 24) / im.width, (cell - 24) / im.height)
        resized = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.Resampling.LANCZOS)
        x = (i % cols) * cell + (cell - resized.width) // 2
        y = (i // cols) * cell + (cell - resized.height) // 2
        sheet.alpha_composite(resized, (x, y))
    sheet.save(dest)


def main() -> None:
    files = []
    specs = [
        (eye_squid, os.path.join(ENEMY, "eye_squid.png")),
        (star_toad, os.path.join(ENEMY, "star_toad.png")),
        (halo_wisp, os.path.join(ENEMY, "halo_wisp.png")),
        (egg_sac, os.path.join(ENEMY, "egg_sac.png")),
        (fractal_baby, os.path.join(ENEMY, "fractal_baby.png")),
        (grand_nibbler, os.path.join(ENEMY, "grand_nibbler.png")),
        (pea_blaster, os.path.join(TOWER, "pea.png")),
        (spark_arc, os.path.join(TOWER, "spark.png")),
        (glue_goo, os.path.join(TOWER, "glue.png")),
        (boom_barrel, os.path.join(TOWER, "boom.png")),
        (scrap_magnet, os.path.join(TOWER, "magnet.png")),
        (station_core, os.path.join(MAP, "core.png")),
        (rift, os.path.join(MAP, "rift.png")),
        (icon, os.path.join(UI, "icon.png")),
        (scrap_icon, os.path.join(UI, "scrap.png")),
    ]
    for fn, path in specs:
        fn(path)
        files.append(path)
        print("wrote", path)
    projectile(os.path.join(PROJ, "pea.png"), (170, 230, 96, 255), "pea")
    projectile(os.path.join(PROJ, "glue.png"), (255, 140, 190, 255), "glue")
    projectile(os.path.join(PROJ, "boom.png"), (255, 140, 64, 255), "boom")
    files += [
        os.path.join(PROJ, "pea.png"),
        os.path.join(PROJ, "glue.png"),
        os.path.join(PROJ, "boom.png"),
    ]
    contact_sheet(files, os.path.join(CONCEPT, "05-ingame-sprites.png"))
    # Editor / project icon lives next to the ui copy too.
    Image.open(os.path.join(UI, "icon.png")).save(os.path.join(ROOT, "icon.png"))
    print("contact sheet ready")


if __name__ == "__main__":
    main()
