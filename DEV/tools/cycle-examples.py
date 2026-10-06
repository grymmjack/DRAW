#!/usr/bin/env python3
"""Generate the palette color cycling example art (PNG + GIMP palette + ranges).

    python3 DEV/tools/cycle-examples.py OUTDIR

Writes OUTDIR/<name>.png, <name>.gpl and <name>.cycle (DRAW --cycle args,
one per line). DEV/tools/make-cycle-examples.sh turns them into .draw
documents with DRAW's batch mode and exports every cycling format.

Every pixel is an exact palette color, laid out so that rotating a palette
range moves something: index grows along the direction of motion, and each
range's colors form a seamless loop (light -> dark -> light).
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from importlib import util as _u  # noqa: E402

_spec = _u.spec_from_file_location('cf', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cycle-fixture.py'))
cf = _u.module_from_spec(_spec)
_spec.loader.exec_module(cf)

W, H = 320, 200


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def ramp(stops, n):
    """n colors through the stop list (evenly spaced)."""
    out = []
    for i in range(n):
        t = i / max(1, n - 1) * (len(stops) - 1)
        k = min(int(t), len(stops) - 2)
        out.append(lerp(stops[k], stops[k + 1], t - k))
    return out


def loop_ramp(stops, n):
    """n colors that go through the stops and back (seamless when rotated)."""
    half = n // 2 + 1
    up = ramp(stops, half)
    return (up + up[-2:0:-1])[:n]


class Pal:
    def __init__(self):
        self.c = []

    def add(self, cols):
        lo = len(self.c)
        self.c.extend(cols)
        return lo, len(self.c) - 1

    def finish(self):
        # unique colors (a chip IS its pixels): nudge exact duplicates
        seen = set()
        for i, c in enumerate(self.c):
            r, g, b = c
            while (r, g, b) in seen:
                b = b + 1 if b < 255 else b - 1
            self.c[i] = (r, g, b)
            seen.add((r, g, b))
        return self.c


def save(outdir, name, pal, idx, cycles):
    cols = pal.finish()
    px = [[cols[idx[y][x]] + (255,) for x in range(W)] for y in range(H)]
    cf.write_png(os.path.join(outdir, name + '.png'), W, H, px)
    cf.write_gpl(os.path.join(outdir, name + '.gpl'), name, cols)
    with open(os.path.join(outdir, name + '.cycle'), 'w') as f:
        for c in cycles:
            f.write(c + '\n')


def grid():
    return [[0] * W for _ in range(H)]


# ---------------------------------------------------------------- waterfall
def waterfall(outdir):
    rnd = random.Random(1)
    p = Pal()
    p.add([(8, 8, 16)])
    sky_lo, _ = p.add(ramp([(40, 60, 140), (120, 170, 230), (220, 230, 250)], 12))
    rock_lo, _ = p.add(ramp([(40, 30, 28), (110, 90, 70), (160, 140, 110)], 8))
    grass_lo, _ = p.add(ramp([(20, 60, 20), (60, 140, 40), (130, 200, 70)], 6))
    w_lo, w_hi = p.add(loop_ramp([(20, 60, 160), (60, 130, 220), (170, 220, 255), (240, 250, 255)], 16))
    f_lo, f_hi = p.add(loop_ramp([(120, 180, 230), (220, 240, 255), (255, 255, 255)], 8))
    g = grid()
    fall_l, fall_r = 128, 192
    for y in range(H):
        for x in range(W):
            g[y][x] = sky_lo + min(11, y * 12 // 90)
    # cliffs
    for x in range(W):
        top = 60 + int(14 * math.sin(x / 23.0) + 8 * math.sin(x / 7.0))
        if fall_l - 6 <= x <= fall_r + 6:
            top = 70
        for y in range(max(0, top), H):
            g[y][x] = rock_lo + (rnd.randrange(3) + (y - top) // 30) % 8
        for y in range(max(0, top - 3), min(H, top + 2)):
            g[y][x] = grass_lo + rnd.randrange(6)
    # falling water: index grows downward, per-column phase for streaks
    phase = [rnd.randrange(16) for _ in range(W)]
    for x in range(fall_l, fall_r):
        for y in range(70, 170):
            g[y][x] = w_lo + (y // 2 + phase[x] // 4) % 16
    # pool with foam ripples (index grows outward from the impact)
    for y in range(160, H):
        for x in range(60, 260):
            d = math.hypot((x - 160) / 2.2, (y - 166) * 1.2)
            if d < 50:
                g[y][x] = f_lo + int(d / 3) % 8
    save(outdir, 'waterfall', p, g, ['%d-%d:16' % (w_lo, w_hi), '%d-%d:8' % (f_lo, f_hi)])


# ---------------------------------------------------------------- fire
def fire(outdir):
    rnd = random.Random(2)
    p = Pal()
    p.add([(6, 2, 2)])
    wall_lo, _ = p.add(ramp([(24, 16, 14), (60, 40, 34)], 6))
    log_lo, _ = p.add(ramp([(40, 20, 8), (110, 60, 24)], 6))
    fl_lo, fl_hi = p.add(loop_ramp([(90, 0, 0), (200, 40, 0), (255, 140, 0), (255, 230, 80), (255, 255, 220)], 24))
    em_lo, em_hi = p.add(loop_ramp([(60, 10, 0), (255, 90, 0), (255, 200, 60)], 8))
    g = grid()
    for y in range(H):
        for x in range(W):
            g[y][x] = wall_lo + ((x // 16 + y // 8) % 2) * 2 + (1 if (y % 8 == 0 or x % 16 == 0) else 0)
    # flame tongues: each column burns to its own height; the index grows
    # upward (with a wobble) so rotating the range makes the fire rise
    base = 176
    for x in range(40, 280):
        env = math.exp(-((x - 160) / 60.0) ** 2)
        tongue = (0.55 + 0.45 * math.sin(x / 9.0) * math.sin(x / 23.0 + 1.3)) ** 2
        hgt = int(env * (80 + 70 * tongue))
        for y in range(base - hgt, base):
            wob = 5 * math.sin(y / 7.0 + x / 15.0)
            g[y][x] = fl_lo + int((base - y) / 2.5 + wob) % 24
    for y in range(168, 186):
        for x in range(70, 250):
            if abs(y - 177 - 5 * math.sin(x / 20.0)) < 6:
                g[y][x] = log_lo + (x // 9 + y // 3) % 6
    for y in range(184, H):
        for x in range(60, 260):
            if rnd.random() < 0.6:
                g[y][x] = em_lo + rnd.randrange(8)
    save(outdir, 'fire', p, g, ['%d-%d:24' % (fl_lo, fl_hi), '%d-%d:7:ping' % (em_lo, em_hi)])


# ---------------------------------------------------------------- tunnel
def tunnel(outdir):
    p = Pal()
    p.add([(0, 0, 0)])
    r_lo, r_hi = p.add(ramp([(255, 0, 64), (255, 128, 0), (255, 255, 0), (0, 255, 64), (0, 200, 255), (64, 64, 255), (200, 0, 255), (255, 0, 96)], 24))
    g = grid()
    for y in range(H):
        for x in range(W):
            dx, dy = x - W / 2, (y - H / 2) * 1.2
            d = math.hypot(dx, dy)
            if d < 4:
                continue
            a = math.atan2(dy, dx)
            k = math.floor(900 / d + a * 24 / (2 * math.pi) * 2) % 24
            g[y][x] = r_lo + k
    save(outdir, 'tunnel', p, g, ['%d-%d:12:rev' % (r_lo, r_hi)])


# ---------------------------------------------------------------- marquee
GLYPHS = {
    'D': ['1110', '1001', '1001', '1001', '1001', '1001', '1110'],
    'R': ['1110', '1001', '1001', '1110', '1010', '1001', '1001'],
    'A': ['0110', '1001', '1001', '1111', '1001', '1001', '1001'],
    'W': ['10001', '10001', '10001', '10101', '10101', '11011', '10001'],
}


def marquee(outdir):
    p = Pal()
    p.add([(10, 6, 20)])
    wall_lo, _ = p.add(ramp([(30, 18, 50), (60, 30, 90)], 4))
    frame_lo, _ = p.add([(80, 80, 90), (140, 140, 150)])
    bulb_lo, bulb_hi = p.add([(255, 240, 120), (150, 110, 30), (90, 60, 20), (60, 40, 15)])
    glow_lo, glow_hi = p.add(ramp([(120, 0, 30), (255, 40, 80), (255, 180, 200)], 10))
    g = grid()
    for y in range(H):
        for x in range(W):
            g[y][x] = wall_lo + ((x // 10 + (y // 5) % 2) % 2)
    x0, y0, x1, y1 = 30, 40, 290, 160
    for y in range(y0, y1):
        for x in range(x0, x1):
            edge = min(x - x0, x1 - 1 - x, y - y0, y1 - 1 - y)
            g[y][x] = frame_lo + (1 if edge < 3 else 0) if edge < 12 else 0
    # chase lights: bulbs around the frame, index steps along the perimeter
    per = []
    for x in range(x0 + 6, x1 - 6, 10):
        per.append((x, y0 + 6))
    for y in range(y0 + 16, y1 - 6, 10):
        per.append((x1 - 7, y))
    for x in range(x1 - 16, x0 + 5, -10):
        per.append((x, y1 - 7))
    for y in range(y1 - 16, y0 + 15, -10):
        per.append((x0 + 6, y))
    for i, (bx, by) in enumerate(per):
        for y in range(by - 3, by + 4):
            for x in range(bx - 3, bx + 4):
                if (x - bx) ** 2 + (y - by) ** 2 <= 10:
                    g[y][x] = bulb_lo + i % 4
    # DRAW in glowing letters: index grows with the distance from each stroke
    word, sc, gap = 'DRAW', 9, 9
    total = sum(len(GLYPHS[ch][0]) for ch in word) * sc + gap * (len(word) - 1)
    ox, oy = (W - total) // 2, 100 - 7 * sc // 2
    for ch in word:
        gl = GLYPHS[ch]
        for gy, rowbits in enumerate(gl):
            for gx, bit in enumerate(rowbits):
                if bit == '1':
                    for y in range(oy + gy * sc, oy + gy * sc + sc):
                        for x in range(ox + gx * sc, ox + gx * sc + sc):
                            g[y][x] = glow_lo + ((x + y) // 4) % 10
        ox += len(gl[0]) * sc + gap
    save(outdir, 'marquee', p, g, ['%d-%d:8' % (bulb_lo, bulb_hi), '%d-%d:9:ping' % (glow_lo, glow_hi)])


# ---------------------------------------------------------------- ocean sunset
def ocean(outdir):
    rnd = random.Random(3)
    p = Pal()
    p.add([(4, 4, 20)])
    sky_lo, _ = p.add(ramp([(30, 10, 60), (160, 40, 90), (255, 120, 60), (255, 200, 120)], 16))
    sun_lo, _ = p.add(ramp([(255, 230, 150), (255, 160, 60)], 4))
    sea_lo, sea_hi = p.add(loop_ramp([(10, 20, 70), (30, 60, 130), (60, 100, 170)], 12))
    gl_lo, gl_hi = p.add(loop_ramp([(255, 140, 60), (255, 220, 140), (255, 255, 230)], 8))
    g = grid()
    horizon = 120
    for y in range(horizon):
        for x in range(W):
            g[y][x] = sky_lo + min(15, y * 16 // horizon)
    for y in range(horizon):
        for x in range(W):
            d = math.hypot(x - 160, (y - 112) * 1.1)
            if d < 34 and y < horizon:
                g[y][x] = sun_lo + min(3, int(d / 9))
    for y in range(horizon, H):
        depth = (y - horizon + 1)
        for x in range(W):
            wave = int((y * 3 + 6 * math.sin(x / (8 + depth / 4.0) + y / 3.0)) / 2)
            g[y][x] = sea_lo + wave % 12
            width = 18 + depth * 0.6
            if abs(x - 160) < width * (0.4 + 0.6 * rnd.random()) and rnd.random() < 0.75:
                g[y][x] = gl_lo + (x // 3 + y) % 8
    save(outdir, 'ocean-sunset', p, g, ['%d-%d:6:rev' % (sea_lo, sea_hi), '%d-%d:7:ping' % (gl_lo, gl_hi)])


# ---------------------------------------------------------------- pinwheel
def pinwheel(outdir):
    p = Pal()
    p.add([(12, 12, 24)])
    bg_lo, _ = p.add(ramp([(20, 20, 40), (40, 40, 70)], 3))
    hub_lo, _ = p.add([(230, 230, 230), (150, 150, 160)])
    sp_lo, sp_hi = p.add(ramp([(255, 0, 0), (255, 255, 0), (0, 255, 0), (0, 255, 255), (0, 0, 255), (255, 0, 255), (255, 0, 32)], 24))
    st_lo, st_hi = p.add([(255, 255, 255), (120, 120, 160), (60, 60, 90), (40, 40, 70)])
    rnd = random.Random(4)
    g = grid()
    for y in range(H):
        for x in range(W):
            g[y][x] = bg_lo + (y * 3 // H)
    for _ in range(90):
        sx, sy = rnd.randrange(W), rnd.randrange(H)
        g[sy][sx] = st_lo + rnd.randrange(4)
    cx, cy = 160, 100
    for y in range(H):
        for x in range(W):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            if d < 90:
                a = (math.atan2(dy, dx) + math.pi) / (2 * math.pi)
                k = int(a * 24 + d / 18) % 24
                g[y][x] = sp_lo + k
            if d < 8:
                g[y][x] = hub_lo + (0 if d < 5 else 1)
    save(outdir, 'pinwheel', p, g, ['%d-%d:12' % (sp_lo, sp_hi), '%d-%d:3' % (st_lo, st_hi)])


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    for fn in (waterfall, fire, tunnel, marquee, ocean, pinwheel):
        fn(out)
        print('wrote', fn.__name__)
