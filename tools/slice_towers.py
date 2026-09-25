#!/usr/bin/env python3
"""Cut in-game tower sprites out of the art-director sheet.

Source of truth: assets/concept/02_towers_sheet.png
Outputs transparent PNGs for the five guns. Does not redraw them.
"""

from __future__ import annotations

import os
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SHEET = os.path.join(ROOT, "assets", "concept", "02_towers_sheet.png")
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "towers")

# Vertical bands on the 1280-wide sheet. Nameplates sit below y=528.
BANDS = (
    ("pea", 0, 270),
    ("spark", 270, 522),
    ("glue", 522, 750),
    ("boom", 750, 1012),
    ("magnet", 1012, 1280),
)


def _components(mask: np.ndarray) -> list[tuple[np.ndarray, np.ndarray]]:
    h, w = mask.shape
    seen = np.zeros((h, w), np.uint8)
    found = []
    ys, xs = np.where(mask)
    for y, x in zip(ys.tolist(), xs.tolist()):
        if seen[y, x]:
            continue
        q = deque([(y, x)])
        seen[y, x] = 1
        cy = []
        cx = []
        while q:
            yy, xx = q.pop()
            cy.append(yy)
            cx.append(xx)
            for ny, nx in ((yy - 1, xx), (yy + 1, xx), (yy, xx - 1), (yy, xx + 1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = 1
                    q.append((ny, nx))
        if len(cy) > 1500:
            found.append((np.asarray(cy), np.asarray(cx)))
    return found


def _largest(mask: np.ndarray) -> np.ndarray:
    comps = _components(mask)
    if not comps:
        raise RuntimeError("no tower pixels in band")
    cy, cx = max(comps, key=lambda c: len(c[0]))
    out = np.zeros(mask.shape, np.uint8)
    out[cy, cx] = 255
    return out


def slice_sheet(sheet_path: str = SHEET) -> None:
    src = Image.open(sheet_path).convert("RGB")
    rgb = np.asarray(src).astype(np.float32)
    height, width, _ = rgb.shape
    left = rgb[:, 2:16].mean(axis=1)
    right = rgb[:, width - 16 : width - 2].mean(axis=1)
    background = ((left + right) * 0.5)[:, None, :]
    diff = np.linalg.norm(rgb - background, axis=2)
    hard = diff > 46
    hard[:36] = False
    hard[528:] = False

    os.makedirs(OUT_DIR, exist_ok=True)
    for name, x0, x1 in BANDS:
        band = np.zeros_like(hard)
        band[:, x0:x1] = hard[:, x0:x1]
        body = _largest(band)
        grown = Image.fromarray(body, "L").filter(ImageFilter.MaxFilter(5))
        region = np.asarray(grown) > 0
        alpha = np.clip((diff - 20.0) / 26.0, 0.0, 1.0)
        alpha = np.where(region, alpha, 0.0)
        alpha[:30] = 0
        alpha[534:] = 0
        ys, xs = np.where(alpha > 0.12)
        pad = 10
        top = max(0, int(ys.min()) - pad)
        bottom = min(height, int(ys.max()) + pad + 1)
        left_x = max(0, int(xs.min()) - pad)
        right_x = min(width, int(xs.max()) + pad + 1)
        crop_rgb = rgb[top:bottom, left_x:right_x].astype(np.uint8)
        crop_a = (alpha[top:bottom, left_x:right_x] * 255).astype(np.uint8)
        # Square canvas so the bottom-bar icon keeps the whole character in frame.
        side = max(crop_rgb.shape[0], crop_rgb.shape[1])
        canvas = np.zeros((side, side, 4), np.uint8)
        oy = (side - crop_rgb.shape[0]) // 2
        ox = (side - crop_rgb.shape[1]) // 2
        canvas[oy : oy + crop_rgb.shape[0], ox : ox + crop_rgb.shape[1], :3] = crop_rgb
        canvas[oy : oy + crop_rgb.shape[0], ox : ox + crop_rgb.shape[1], 3] = crop_a
        path = os.path.join(OUT_DIR, f"{name}.png")
        Image.fromarray(canvas, "RGBA").save(path)
        print("wrote", path, canvas.shape[1], canvas.shape[0])


if __name__ == "__main__":
    slice_sheet()
