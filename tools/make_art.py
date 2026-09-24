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

    def horn(self, x, y, length, width, angle_deg, fill):
        ang = math.radians(angle_deg)
        px, py = math.cos(ang), math.sin(ang)
        nx, ny = -py, px
        tip = (x + px * length, y + py * length)
        left = (x + nx * width, y + ny * width)
        right = (x - nx * width, y - ny * width)
        self.polygon([left, tip, right], fill, True, 3)

    def blush(self, x, y, rx=7, ry=4):
        self.ellipse((x - rx, y - ry, x + rx, y + ry), BLUSH, outline=False)


def fast_skitter(path: str) -> None:
    """Pink fuzzy spider. Tiny, lots of legs, face toward the camera."""
    c = Canvas(128)
    fur = (255, 154, 196, 255)
    fluff = (255, 186, 214, 255)
    leg = (244, 128, 176, 255)
    legs = [
        (58, 62, 20, 32, 4.0),
        (50, 74, 14, 62, 4.2),
        (50, 88, 16, 110, 4.0),
        (60, 96, 32, 118, 3.8),
        (70, 62, 108, 32, 4.0),
        (78, 74, 114, 62, 4.2),
        (78, 88, 112, 110, 4.0),
        (68, 96, 96, 118, 3.8),
    ]
    for x1, y1, x2, y2, radius in legs:
        c.capsule(x1, y1, x2, y2, radius, leg, True, 3)
    for ang in range(0, 360, 36):
        rad = math.radians(ang)
        c.circle(64 + math.cos(rad) * 28, 72 + math.sin(rad) * 24, 9, fluff, True, 3)
    c.circle(64, 72, 28, fur, True, 5)
    c.shine(50, 56, 12, 8)
    c.eye(52, 66, 9, (110, 48, 96, 255))
    c.eye(76, 66, 9, (110, 48, 96, 255))
    c.blush(40, 80, 5, 3)
    c.blush(88, 80, 5, 3)
    c.smile(64, 84, 7, 3.2)
    c.save(path)


def chunky_tank(path: str) -> None:
    """Purple turtle. Segmented shell, sleepy face, stubby feet."""
    c = Canvas(128)
    shell = (142, 96, 204, 255)
    scute = (112, 74, 176, 255)
    plate = (176, 146, 224, 255)
    head = (206, 184, 236, 255)
    foot = (132, 96, 190, 255)
    for box in ((22, 70, 46, 92), (82, 70, 106, 92), (28, 100, 50, 120), (78, 100, 100, 120)):
        c.ellipse(box, foot, True, 3)
    c.ellipse((26, 28, 102, 100), shell, True, 5)
    c.ellipse((44, 40, 84, 70), scute, True, 3)
    c.ellipse((32, 52, 58, 84), plate, True, 3)
    c.ellipse((70, 52, 96, 84), plate, True, 3)
    c.ellipse((46, 68, 82, 96), scute, True, 3)
    c.ellipse((38, 84, 90, 122), head, True, 4)
    c.shine(48, 40, 12, 7, 90)
    c.eye(52, 98, 5.2, (88, 52, 130, 255), look=(0, 0.4))
    c.eye(76, 98, 5.2, (88, 52, 130, 255), look=(0, 0.4))
    c.line((44, 94), (60, 96), INK, 2.6)
    c.line((68, 96), (84, 94), INK, 2.6)
    c.blush(36, 108, 5, 3)
    c.blush(92, 108, 5, 3)
    c.smile(64, 110, 6, 3)
    c.save(path)


def shielded(path: str) -> None:
    """Shy mint creature. The glass bubble is drawn in-game so it can pop."""
    c = Canvas(128)
    body = (120, 214, 184, 255)
    belly = (196, 242, 224, 255)
    foot = (86, 176, 150, 255)
    c.ellipse((38, 96, 58, 118), foot, True, 3)
    c.ellipse((70, 96, 90, 118), foot, True, 3)
    c.circle(64, 66, 32, body, True, 5)
    c.ellipse((44, 72, 84, 100), belly, True, 3)
    c.shine(48, 48, 12, 8)
    c.smile(50, 60, 7, 3.2)
    c.smile(78, 60, 7, 3.2)
    c.blush(40, 76, 5, 3)
    c.blush(88, 76, 5, 3)
    c.smile(64, 84, 6, 3)
    c.save(path)


def _blob_face(c: Canvas, x, y, r, fill, pupil) -> None:
    c.circle(x, y, r, fill, True, 3 if r < 16 else 5)
    if r >= 11:
        c.eye(x - r * 0.28, y - r * 0.08, r * 0.32, pupil)
        c.eye(x + r * 0.28, y - r * 0.08, r * 0.32, pupil)
        c.smile(x, y + r * 0.28, r * 0.22, r * 0.1)
    else:
        c.circle(x - r * 0.22, y - r * 0.05, max(1.4, r * 0.16), INK, False)
        c.circle(x + r * 0.22, y - r * 0.05, max(1.4, r * 0.16), INK, False)


def swarm_splitter(path: str) -> None:
    """Orange blob with a happy face and a little swarm around it."""
    c = Canvas(128)
    blob = (245, 164, 42, 255)
    little = (255, 196, 78, 255)
    tiny = (255, 214, 120, 255)
    pupil = (120, 62, 28, 255)
    for x, y, r, col in (
        (20, 30, 11, little),
        (106, 28, 9, tiny),
        (14, 78, 8, tiny),
        (112, 84, 12, little),
        (96, 114, 8, tiny),
        (26, 110, 9, little),
    ):
        _blob_face(c, x, y, r, col, pupil)
    c.circle(64, 68, 28, blob, True, 5)
    c.shine(50, 50, 12, 8)
    c.eye(52, 62, 9, pupil)
    c.eye(78, 62, 9, pupil)
    c.blush(40, 76, 5, 3)
    c.blush(88, 76, 5, 3)
    c.ellipse((55, 76, 73, 90), (168, 72, 48, 255), True, 3)
    c.ellipse((58, 78, 70, 84), (255, 156, 140, 255), False)
    c.save(path)


def swarmling(path: str) -> None:
    c = Canvas(128)
    blob = (255, 186, 64, 255)
    c.circle(64, 66, 30, blob, True, 5)
    c.shine(50, 50, 11, 7)
    c.eye(52, 60, 8, (120, 62, 28, 255))
    c.eye(78, 60, 8, (120, 62, 28, 255))
    c.blush(40, 76, 5, 3)
    c.blush(88, 76, 5, 3)
    c.smile(64, 80, 7, 3.2)
    c.save(path)


def big_cute_boss(path: str) -> None:
    """Purple cosmic sphere. Horns, a pile of eyes, tiny danglers."""
    c = Canvas(192)
    body = (128, 82, 198, 255)
    horn = (198, 132, 220, 255)
    dang = (104, 64, 168, 255)
    for ang, length, width in (
        (-90, 42, 12),
        (-56, 28, 9),
        (-124, 28, 9),
        (-22, 18, 7),
        (-158, 18, 7),
    ):
        rad = math.radians(ang)
        bx = 96 + math.cos(rad) * 56
        by = 100 + math.sin(rad) * 52
        c.horn(bx, by, length, width, ang, horn)
    for dx, extra in ((-28, 0), (0, 6), (28, 0)):
        c.capsule(96 + dx, 146 + extra, 96 + dx, 166 + extra, 4.5, dang, True, 3)
        c.circle(96 + dx, 168 + extra, 5.5, horn, True, 3)
    c.circle(96, 100, 58, body, True, 6)
    for x, y, r in (
        (62, 70, 2.6),
        (132, 66, 2.2),
        (148, 96, 2.0),
        (48, 96, 1.8),
        (118, 128, 2.2),
    ):
        c.circle(x, y, r, (255, 248, 230, 255), False)
    c.shine(72, 70, 16, 10, 80)
    pupil = (64, 36, 110, 255)
    for x, y, r in (
        (70, 82, 10),
        (96, 74, 9),
        (122, 82, 10),
        (66, 108, 8),
        (96, 106, 12),
        (126, 108, 8),
    ):
        c.eye(x, y, r, pupil, look=(0.05, 0.12))
    c.blush(46, 122, 7, 4)
    c.blush(146, 122, 7, 4)
    c.smile(96, 126, 12, 5)
    c.save(path)


def _feet(c: Canvas) -> None:
    foot = (255, 214, 186, 255)
    c.ellipse((24, 98, 54, 122), foot, True, 4)
    c.ellipse((74, 98, 104, 122), foot, True, 4)


def _cute_face(c: Canvas, x, y, scale=1.0, pupil=(88, 48, 120, 255)) -> None:
    er = 8.0 * scale
    c.eye(x - 14 * scale, y, er, pupil)
    c.eye(x + 14 * scale, y, er, pupil)
    c.blush(x - 28 * scale, y + 12 * scale, 7 * scale, 4 * scale)
    c.blush(x + 28 * scale, y + 12 * scale, 7 * scale, 4 * scale)
    c.smile(x, y + 16 * scale, 9 * scale, 4 * scale)


def _star(c: Canvas, x, y, r, fill) -> None:
    pts = []
    for i in range(8):
        ang = math.radians(-90 + i * 45)
        rad = r if i % 2 == 0 else r * 0.42
        pts.append((x + math.cos(ang) * rad, y + math.sin(ang) * rad))
    c.polygon(pts, fill, True, 3)


def pea_blaster(path: str) -> None:
    """Chubby lime pea-popper. Round body, fat snout, a face. No metal plate."""
    c = Canvas(128)
    _feet(c)
    c.circle(64, 74, 38, (154, 224, 96, 255), True, 5)
    c.ellipse((40, 82, 88, 108), (206, 244, 150, 255), True, 3)
    c.round_rect((46, 8, 82, 50), 18, (92, 196, 78, 255), True, 5)
    c.circle(64, 16, 15, (198, 244, 130, 255), True, 4)
    c.circle(64, 16, 6, (72, 160, 78, 255), False)
    c.shine(48, 52, 12, 7, 140)
    _cute_face(c, 64, 78, 0.82, (48, 120, 56, 255))
    c.save(path)


def spark_arc(path: str) -> None:
    """Butter-yellow spark buddy. Soft coil, rounded whiskers, not a rod."""
    c = Canvas(128)
    _feet(c)
    c.capsule(16, 36, 38, 58, 5, (255, 236, 120, 255), True, 3)
    c.capsule(112, 36, 90, 58, 5, (255, 236, 120, 255), True, 3)
    c.circle(64, 76, 36, (255, 210, 78, 255), True, 5)
    c.circle(64, 44, 16, (255, 244, 168, 255), True, 4)
    c.circle(64, 26, 9, (255, 252, 220, 255), True, 3)
    _star(c, 64, 12, 9, (255, 250, 210, 255))
    c.shine(48, 64, 10, 6, 150)
    _cute_face(c, 64, 80, 0.86, (186, 110, 28, 255))
    c.save(path)


def glue_goo(path: str) -> None:
    """Squishy pink gumdrop with a drip spout."""
    c = Canvas(128)
    _feet(c)
    c.circle(90, 96, 9, (255, 140, 186, 255), True, 3)
    c.circle(64, 72, 38, (255, 156, 198, 255), True, 5)
    c.ellipse((42, 78, 86, 106), (255, 214, 230, 255), True, 3)
    c.circle(64, 30, 13, (255, 112, 170, 255), True, 4)
    c.circle(64, 14, 8, (255, 196, 220, 255), True, 3)
    c.shine(46, 54, 12, 7, 130)
    _cute_face(c, 64, 76, 0.82, (168, 48, 110, 255))
    c.save(path)


def boom_barrel(path: str) -> None:
    """Round candy cannon. Cream stripe, curly fuse, smiling face."""
    c = Canvas(128)
    _feet(c)
    c.circle(64, 76, 36, (255, 154, 78, 255), True, 5)
    c.ellipse((32, 66, 96, 88), (255, 228, 150, 255), True, 4)
    s = c.s
    c.d.arc([44 * s, 6 * s, 86 * s, 48 * s], 210, 10, fill=INK, width=int(8 * s))
    c.d.arc([48 * s, 10 * s, 82 * s, 44 * s], 210, 10, fill=(255, 214, 110, 255), width=int(4 * s))
    _star(c, 80, 16, 7, (255, 244, 170, 255))
    c.shine(46, 60, 10, 6, 120)
    _cute_face(c, 64, 90, 0.72, (150, 64, 24, 255))
    c.save(path)


def scrap_magnet(path: str) -> None:
    """Chunky candy horseshoe with a face in the crook. No bolts."""
    c = Canvas(128)
    _feet(c)
    red = (255, 102, 128, 255)
    cream = (255, 246, 236, 255)
    c.capsule(40, 34, 40, 82, 15, red, True, 4)
    c.capsule(88, 34, 88, 82, 15, cream, True, 4)
    c.capsule(40, 34, 88, 34, 15, red, True, 4)
    _star(c, 20, 36, 8, (255, 214, 96, 255))
    _star(c, 108, 48, 7, (176, 226, 255, 255))
    c.circle(104, 90, 6, (255, 170, 196, 255), True, 3)
    c.shine(52, 28, 8, 4, 120)
    _cute_face(c, 64, 64, 0.62, (150, 40, 70, 255))
    c.save(path)


def station_core(path: str) -> None:
    c = Canvas(128)
    c.round_rect((16, 16, 112, 112), 22, (255, 236, 214, 255), True, 5)
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
        c.circle(24, 24, 13, fill, True, 3)
        c.ellipse((10, 16, 38, 28), (255, 230, 160, 255), False)
        c.circle(24, 8, 4, (255, 244, 180, 255), True, 2)
    c.save(path)


def icon(path: str) -> None:
    c = Canvas(128)
    c.round_rect((4, 4, 124, 124), 28, (255, 214, 232, 255), False)
    c.horn(64, 40, 22, 10, -90, (198, 132, 220, 255))
    c.circle(64, 74, 34, (128, 82, 198, 255), True, 5)
    c.eye(50, 68, 8, (64, 36, 110, 255))
    c.eye(78, 68, 8, (64, 36, 110, 255))
    c.eye(64, 84, 6, (64, 36, 110, 255))
    c.smile(64, 98, 8, 3)
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
        (fast_skitter, os.path.join(ENEMY, "fast_skitter.png")),
        (chunky_tank, os.path.join(ENEMY, "chunky_tank.png")),
        (shielded, os.path.join(ENEMY, "shielded.png")),
        (swarm_splitter, os.path.join(ENEMY, "swarm_splitter.png")),
        (swarmling, os.path.join(ENEMY, "swarmling.png")),
        (big_cute_boss, os.path.join(ENEMY, "big_cute_boss.png")),
        # Tower PNGs are cut from assets/concept/02_towers_sheet.png.
        # tools/slice_towers.py owns them; do not redraw over the art-director guns.
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
    projectile(os.path.join(PROJ, "glue.png"), (90, 220, 210, 255), "glue")
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
