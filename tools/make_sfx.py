#!/usr/bin/env python3
"""Tiny cozy one-shot sounds. No external samples."""

from __future__ import annotations

import math
import os
import random
import struct
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "audio")
SR = 22050


def env(i: int, n: int, attack: float = 0.008, release: float = 0.06) -> float:
    t = i / SR
    dur = n / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (dur - t) / release) if release > 0 else 1.0
    return max(0.0, min(a, r))


def write(name: str, samples: list[float]) -> None:
    path = os.path.join(OUT, name + ".wav")
    os.makedirs(OUT, exist_ok=True)
    with wave.open(path, "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        frames = bytearray()
        for sample in samples:
            clipped = max(-1.0, min(1.0, sample))
            frames += struct.pack("<h", int(clipped * 32767))
        handle.writeframes(frames)
    print("wrote", path)


def tone(dur: float, freq_at, vol: float = 0.35, wave_kind: str = "sine", release: float = 0.08) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        freq = freq_at(t, dur)
        phase = 2 * math.pi * freq * t
        if wave_kind == "square":
            raw = 1.0 if math.sin(phase) >= 0 else -1.0
            raw = raw * 0.65 + math.sin(phase) * 0.35
        elif wave_kind == "tri":
            raw = 2 * abs(2 * ((t * freq) % 1) - 1) - 1
        else:
            raw = math.sin(phase)
        out.append(raw * vol * env(i, n, 0.006, release))
    return out


def mix(*tracks: list[float]) -> list[float]:
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    peak = max(1e-6, max(abs(s) for s in out))
    if peak > 0.95:
        scale = 0.95 / peak
        out = [s * scale for s in out]
    return out


def noise(dur: float, vol: float, release: float = 0.1) -> list[float]:
    rng = random.Random(7)
    n = int(SR * dur)
    out = []
    low = 0.0
    for i in range(n):
        low = low * 0.82 + rng.uniform(-1, 1) * 0.18
        out.append(low * vol * env(i, n, 0.002, release))
    return out


def slide(a: float, b: float):
    return lambda t, dur: a + (b - a) * (t / max(0.0001, dur))


def main() -> None:
    write("ui", tone(0.07, lambda t, d: 660, 0.22, "sine", 0.04))
    write("place", mix(
        tone(0.12, slide(420, 680), 0.28, "sine", 0.06),
        tone(0.12, slide(640, 980), 0.12, "sine", 0.05),
    ))
    write("upgrade", mix(
        tone(0.16, slide(520, 880), 0.26, "tri", 0.08),
        tone(0.18, slide(780, 1240), 0.12, "sine", 0.08),
    ))
    write("sell", tone(0.14, slide(540, 280), 0.24, "sine", 0.08))
    write("error", tone(0.12, lambda t, d: 180, 0.22, "square", 0.06))
    write("pea", tone(0.07, slide(880, 420), 0.2, "sine", 0.04))
    write("spark", mix(
        tone(0.09, slide(1400, 600), 0.16, "square", 0.04),
        noise(0.06, 0.08, 0.04),
    ))
    write("glue", tone(0.1, slide(300, 180), 0.22, "sine", 0.07))
    write("boom", mix(
        noise(0.22, 0.35, 0.16),
        tone(0.2, slide(160, 60), 0.3, "sine", 0.12),
    ))
    write("hit", tone(0.05, slide(1200, 700), 0.12, "sine", 0.03))
    write("pop", mix(
        tone(0.1, slide(600, 240), 0.22, "sine", 0.06),
        tone(0.08, lambda t, d: 900, 0.08, "tri", 0.04),
    ))
    write("shield", tone(0.12, slide(980, 1400), 0.16, "sine", 0.08))
    write("leak", mix(
        tone(0.22, slide(440, 180), 0.26, "sine", 0.12),
        tone(0.22, slide(330, 120), 0.12, "sine", 0.12),
    ))
    write("wave", mix(
        tone(0.18, lambda t, d: 523, 0.2, "tri", 0.08),
        tone(0.22, lambda t, d: 659, 0.14, "sine", 0.1),
    ))
    write("scrap", mix(
        tone(0.08, lambda t, d: 880, 0.18, "sine", 0.04),
        tone(0.12, lambda t, d: 1320, 0.12, "sine", 0.06),
    ))
    write("win", mix(
        tone(0.4, lambda t, d: 523 if t < 0.1 else (659 if t < 0.2 else (784 if t < 0.3 else 1046)), 0.22, "tri", 0.12),
    ))
    write("lose", tone(0.45, lambda t, d: 392 - 180 * (t / d), 0.22, "sine", 0.18))


if __name__ == "__main__":
    main()
