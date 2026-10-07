#!/usr/bin/env python3
"""Generate the palette color cycling example art (PNG + GIMP palette + ranges).

    python3 DEV/tools/cycle-examples.py OUTDIR

Writes OUTDIR/<name>.png, <name>.gpl and <name>.cycle (DRAW --cycle args,
one per line). DEV/tools/make-cycle-examples.sh turns them into .draw
documents with DRAW's batch mode and exports every cycling format.

Every pixel is an exact palette color, laid out so that rotating a palette
range moves something: index grows along the direction of motion, and each
range's colors form a seamless loop (light -> dark -> light).

Besides plain gradients the later scenes use three classic DeluxePaint tricks
(helpers below). They need a flat background behind the moving thing, since
the "off" colors of the range are that background:
  sprite_path  one copy of a sprite per position, one chip each: only entry 0
               is the sprite color, so the sprite hops along (bats)
  streak       a bright head with a fading tail running up the chips (falling
               snow, rising embers, rockets and their bursts)
  timeline     the FIRST chip plays a frame list; several timeline ranges of
               the same length and speed stay in step, one per moving part
               (the snake's tongue, segment by segment)
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


NUDGES = [(0, 0, 1), (0, 0, -1)] + sorted(
    ((r, g, b) for r in range(-3, 4) for g in range(-3, 4) for b in range(-3, 4)
     if (r, g, b) not in ((0, 0, 0), (0, 0, 1), (0, 0, -1))),
    key=lambda d: (abs(d[0]) + abs(d[1]) + abs(d[2]), abs(d[0]), abs(d[1])))


class Pal:
    def __init__(self):
        self.c = []

    def add(self, cols):
        lo = len(self.c)
        self.c.extend(cols)
        return lo, len(self.c) - 1

    def finish(self):
        # unique colors (a chip IS its pixels): nudge exact duplicates by the
        # smallest offset still free, so even dozens of copies of one
        # background color stay invisible against it
        seen = set()
        for i, c in enumerate(self.c):
            if c in seen:
                for d in NUDGES:
                    n = tuple(min(255, max(0, c[k] + d[k])) for k in range(3))
                    if n not in seen:
                        c = n
                        break
            self.c[i] = c
            seen.add(c)
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


# ================================================================ helpers for
# the scenes below. Their speeds are picked so every range repeats within 2 s
# (period = colors / speed, or 2 * (colors - 1) / speed for ping-pong): the
# animated GIF export loops after the least common multiple of the periods.
FONT5 = {
    ' ': ['000', '000', '000', '000', '000', '000', '000'],
    '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
    '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
    '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    'A': ['01110', '10001', '10001', '11111', '10001', '10001', '10001'],
    'B': ['11110', '10001', '10001', '11110', '10001', '10001', '11110'],
    'C': ['01110', '10001', '10000', '10000', '10000', '10001', '01110'],
    'D': ['11110', '10001', '10001', '10001', '10001', '10001', '11110'],
    'E': ['11111', '10000', '10000', '11110', '10000', '10000', '11111'],
    'H': ['10001', '10001', '10001', '11111', '10001', '10001', '10001'],
    'I': ['111', '010', '010', '010', '010', '010', '111'],
    'K': ['10001', '10010', '10100', '11000', '10100', '10010', '10001'],
    'M': ['10001', '11011', '10101', '10101', '10001', '10001', '10001'],
    'N': ['10001', '11001', '10101', '10011', '10001', '10001', '10001'],
    'P': ['11110', '10001', '10001', '11110', '10000', '10000', '10000'],
    'R': ['11110', '10001', '10001', '11110', '10100', '10010', '10001'],
    'S': ['01111', '10000', '10000', '01110', '00001', '00001', '11110'],
    'T': ['11111', '00100', '00100', '00100', '00100', '00100', '00100'],
    'U': ['10001', '10001', '10001', '10001', '10001', '10001', '01110'],
    'W': ['10001', '10001', '10001', '10101', '10101', '11011', '10001'],
    'Y': ['10001', '10001', '01010', '00100', '00100', '00100', '00100'],
}


def text_width(s, sc):
    return sum((len(FONT5[c][0]) + 1) * sc for c in s) - sc


def draw_text(g, s, ox, oy, sc, pick):
    """Block letters at scale sc; pick(x, y) gives each pixel's index."""
    for ch in s:
        gl = FONT5[ch]
        for gy, bits in enumerate(gl):
            for gx, bit in enumerate(bits):
                if bit == '1':
                    for y in range(oy + gy * sc, oy + gy * sc + sc):
                        for x in range(ox + gx * sc, ox + gx * sc + sc):
                            put(g, x, y, pick(x, y))
        ox += (len(gl[0]) + 1) * sc


def put(g, x, y, i):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = i


def stamp(g, rows, x0, y0, i, sc=1):
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch == 'x':
                for yy in range(y0 + dy * sc, y0 + dy * sc + sc):
                    for xx in range(x0 + dx * sc, x0 + dx * sc + sc):
                        put(g, xx, yy, i)


def sprite_path(p, on, off, n):
    """Range showing `on` at one chip at a time; the rest is the background.
    Draw copy k of a sprite with chip lo + k: rotating walks it along."""
    return p.add([on] + [off] * (n - 1))


def streak(p, head, tail, off, n, phase=0):
    """Range with a head color running up the chips and a tail behind it;
    at step 0 the head is on chip lo + phase."""
    cols = [head] + [off] * (n - 1)
    for i, c in enumerate(tail):
        cols[n - 1 - i] = c
    return p.add([cols[(e - phase) % n] for e in range(n)])


def timeline(p, frames, on, off):
    """Range whose FIRST chip shows `on` at step s when frames[s] is true.
    Forward rotation puts entry (-s mod n) on that chip."""
    n = len(frames)
    return p.add([on if frames[(-e) % n] else off for e in range(n)])


def scale(c, f):
    return tuple(int(round(v * f)) for v in c)


def flame(g, cx, base, h, hw, lo, n, core):
    """Teardrop candle flame; the index rises with height, so it flickers up."""
    for y in range(base - h, base + 1):
        t = (base - y) / h  # 0 at the base, 1 at the tip
        w = hw * (1 - t) ** 0.8 * math.sqrt(max(0.0, 1 - (1 - min(1.0, t * 3.0)) ** 2))
        for x in range(int(cx - w) - 1, int(cx + w) + 2):
            dx = abs(x + 0.5 - cx)
            if dx > w:
                continue
            rel = dx / max(w, 0.5)
            if t < 0.4 and rel < 0.45:
                put(g, x, y, core[0] if t < 0.12 else core[1])
            else:
                put(g, x, y, lo + int(t * n * 1.4 + rel * 2) % n)


def candle(g, cx, top, bottom, hw, wax_lo, wax_n, wick):
    """Wax cylinder lit from the front, with a melted rim and a few drips."""
    for y in range(top, bottom):
        for x in range(cx - hw, cx + hw + 1):
            dx = (x - cx) / (hw + 0.5)
            g[y][x] = wax_lo + max(0, min(wax_n - 1, int(wax_n * math.cos((dx + 0.15) * 1.3))))
    for x in range(cx - hw + 2, cx + hw - 1):
        g[top][x] = wax_lo + wax_n - 1
    for y in range(top - 5, top + 1):
        put(g, cx, y, wick)


def tri_in(u, v, a, b, c):
    def side(p1, p2):
        return (u - p2[0]) * (p1[1] - p2[1]) - (p1[0] - p2[0]) * (v - p2[1])
    d1, d2, d3 = side(a, b), side(b, c), side(c, a)
    return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))


def heart_in(x, y):
    """(x^2 + y^2 - 1)^3 - x^2 y^3 <= 0, y up: the classic heart curve."""
    return (x * x + y * y - 1) ** 3 - x * x * y ** 3 <= 0


def heart_k(x, y):
    """How far out (x, y) is, in heart sizes: < 1 inside, 1 on the outline."""
    lo, hi = 0.0, 4.0
    for _ in range(18):
        mid = (lo + hi) / 2
        if mid > 0 and heart_in(x / mid, y / mid):
            hi = mid
        else:
            lo = mid
    return hi


def catmull(pts, steps):
    """Catmull-Rom spline through pts, `steps` samples per segment."""
    out = []
    q = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(q) - 2):
        p0, p1, p2, p3 = q[i - 1], q[i], q[i + 1], q[i + 2]
        for k in range(steps):
            t = k / steps
            out.append(tuple(0.5 * (2 * p1[j] + (p2[j] - p0[j]) * t
                                    + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t * t
                                    + (3 * p1[j] - p0[j] - 3 * p2[j] + p3[j]) * t ** 3) for j in range(2)))
    out.append(pts[-1])
    return out


FLAME = [(150, 30, 0), (255, 110, 10), (255, 190, 50), (255, 240, 160)]


# ---------------------------------------------------------------- candles
def candles(outdir):
    p = Pal()
    p.add([(8, 5, 4)])
    wall_lo, _ = p.add(ramp([(10, 6, 5), (40, 24, 18)], 8))
    wood_lo, _ = p.add(ramp([(24, 12, 6), (70, 38, 18), (120, 70, 32)], 6))
    wax_lo, _ = p.add(ramp([(120, 92, 70), (230, 210, 175), (255, 248, 228)], 7))
    wick, _ = p.add([(25, 18, 14)])
    core = p.add([(150, 180, 255), (255, 252, 235)])
    fl = [p.add(loop_ramp(FLAME, 12)) for _ in range(3)]
    halo_lo, halo_hi = p.add(loop_ramp([(40, 24, 18), (80, 46, 24), (125, 72, 32)], 10))
    g = grid()
    table = 150
    cs = [(100, 62), (160, 88), (220, 44)]  # x, height
    lights = [(cx, table - hgt - 16) for cx, hgt in cs]
    # the wall: a glow around each flame that breathes (ping-pong), dimming
    # into the static wall shades at its edge
    for y in range(table):
        for x in range(W):
            d = min(math.hypot(x - lx, (y - ly) * 1.15) for lx, ly in lights)
            if d < 46:
                g[y][x] = halo_lo + int(d / 4.6) % 10
            else:
                g[y][x] = wall_lo + max(0, 7 - int((d - 46) / 14))
    for y in range(table, H):
        for x in range(W):
            if y < table + 3:
                g[y][x] = wood_lo + 5 - (y - table)
            else:
                g[y][x] = wood_lo + int((y - table) / 9 + 1.5 * math.sin(x / 31.0 + y / 6.0)) % 3
    rnd = random.Random(5)
    for i, (cx, hgt) in enumerate(cs):
        top = table - hgt
        candle(g, cx, top, table, 11, wax_lo, 7, wick)
        for dx0 in (-8, -3, 5):  # drips down the front
            for y in range(top, top + rnd.randrange(6, 20)):
                g[y][cx + dx0] = wax_lo + 6
        # each flame its own range at its own speed: they flicker apart
        flame(g, cx + 0.5, top - 3, 30, 7.5, fl[i][0], 12, core)
    cyc = ['%d-%d:%d' % (lo, hi, sps) for (lo, hi), sps in zip(fl, (12, 18, 24))]
    save(outdir, 'candles', p, g, cyc + ['%d-%d:9:ping' % (halo_lo, halo_hi)])


# ---------------------------------------------------------------- hanukkah
def hanukkah(outdir):
    p = Pal()
    p.add([(6, 8, 22)])
    wall_lo, _ = p.add(ramp([(6, 8, 24), (30, 34, 70)], 8))
    gold_lo, _ = p.add(ramp([(90, 60, 10), (200, 150, 40), (255, 228, 130)], 7))
    wax_lo, _ = p.add(ramp([(70, 100, 170), (170, 200, 245), (235, 245, 255)], 5))
    wick, _ = p.add([(25, 18, 14)])
    core = p.add([(150, 180, 255), (255, 252, 235)])
    fl = [p.add(loop_ramp(FLAME, 10)) for _ in range(3)]
    halo_lo, halo_hi = p.add(loop_ramp([(30, 34, 70), (75, 62, 72), (130, 96, 64)], 10))
    tx_lo, tx_hi = p.add(loop_ramp([(40, 70, 160), (120, 170, 255), (240, 250, 255)], 10))
    g = grid()
    cx, cup = 160, 104
    # nine lights: four arms each side of the raised shamash
    holders = [(cx + 18 * k, cup) for k in (-4, -3, -2, -1)] + [(cx, cup - 14)] + \
              [(cx + 18 * k, cup) for k in (1, 2, 3, 4)]
    lights = [(x, y - 30) for x, y in holders]
    for y in range(H):
        for x in range(W):
            d = min(math.hypot(x - lx, (y - ly) * 1.2) for lx, ly in lights)
            if d < 30:
                g[y][x] = halo_lo + int(d / 3) % 10
            else:
                g[y][x] = wall_lo + max(0, 7 - int((d - 30) / 12))

    def gold(x, y):
        return gold_lo + max(0, min(6, int(3.5 + 3 * math.sin(x / 6.0 + y / 9.0))))

    for y in range(cup, 186):  # arms (half circles), stem, foot
        for x in range(cx - 80, cx + 81):
            d = math.hypot(x - cx, y - cup)
            arm = any(abs(d - 18 * k) < 2.2 for k in (1, 2, 3, 4))
            stem = abs(x - cx) <= 3 and y < 176
            foot = y >= 176 and abs(x - cx) <= 14 + (y - 176) * 2
            if arm or stem or foot:
                g[y][x] = gold(x, y)
    for y in range(cup - 14, cup):
        for x in range(cx - 3, cx + 4):
            g[y][x] = gold(x, y)
    for i, (hx, hy) in enumerate(holders):
        for y in range(hy - 4, hy + 1):  # cup
            for x in range(hx - 5, hx + 6):
                g[y][x] = gold(x, y)
        candle(g, hx, hy - 24, hy - 4, 3, wax_lo, 5, wick)
        flame(g, hx + 0.5, hy - 27, 15, 4.2, fl[i % 3][0], 10, core)
    msg = 'HAPPY HANUKKAH'
    draw_text(g, msg, (W - text_width(msg, 2)) // 2, 12, 2, lambda x, y: tx_lo + ((x + y) // 3) % 10)
    cyc = ['%d-%d:%d' % (lo, hi, sps) for (lo, hi), sps in zip(fl, (10, 15, 20))]
    save(outdir, 'hanukkah', p, g, cyc + ['%d-%d:9:ping' % (halo_lo, halo_hi), '%d-%d:9:ping' % (tx_lo, tx_hi)])


# ---------------------------------------------------------------- halloween
BAT_UP = ['x...........x', 'xx.........xx', 'xxx..x.x..xxx', '.xxxxxxxxxxx.',
          '..xxxxxxxxx..', '.....xxx.....', '......x......']
BAT_DOWN = ['.....x.x.....', '....xxxxx....', '..xxxxxxxxx..', '.xxxxxxxxxxx.',
            'xxx..xxx..xxx', 'xx....x....xx', 'x...........x']


def pumpkin_face(u, v):
    for s in (-1, 1):
        if tri_in(u * s, v, (0.14, -0.04), (0.6, -0.04), (0.38, -0.46)):
            return True
    if tri_in(u, v, (-0.12, 0.18), (0.12, 0.18), (0.0, -0.02)):
        return True
    if abs(u) < 0.66:
        top = 0.2 + 0.2 * (1 - (u / 0.66) ** 2)
        bot = top + 0.3 * math.sqrt(max(0.0, 1 - (u / 0.66) ** 2))
        if top < v < bot:
            if abs(u - 0.16) < 0.08 and v < top + 0.13:
                return False  # a tooth hanging down
            if abs(u + 0.22) < 0.08 and v > bot - 0.12:
                return False  # and one standing up
            return True
    return False


def halloween(outdir):
    rnd = random.Random(7)
    p = Pal()
    sky = (22, 10, 42)
    p.add([sky])
    moon_lo, _ = p.add(ramp([(170, 160, 120), (240, 230, 180), (255, 250, 222)], 5))
    mglow_lo, _ = p.add([(44, 28, 66), (32, 18, 54)])
    star_lo, _ = p.add([(200, 190, 230), (120, 110, 160)])
    blk_lo, _ = p.add([(6, 2, 10), (16, 9, 24)])
    hill_lo, _ = p.add([(14, 8, 22), (30, 18, 40)])
    pk_lo, _ = p.add(ramp([(110, 40, 0), (210, 95, 10), (255, 165, 45)], 6))
    stem_lo, _ = p.add([(50, 70, 20), (90, 110, 30)])
    face_lo, face_hi = p.add(loop_ramp([(120, 30, 0), (230, 120, 10), (255, 210, 60), (255, 250, 170)], 12))
    fog_lo, fog_hi = p.add(loop_ramp([(30, 18, 40), (62, 52, 82), (104, 96, 124)], 12))
    b1_lo, b1_hi = sprite_path(p, (0, 0, 0), sky, 10)
    b2_lo, b2_hi = sprite_path(p, (0, 0, 0), sky, 8)
    g = grid()
    mx, my = 270, 40
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - mx, y - my)
            if d < 26:
                lit = 1 - math.hypot(x - mx + 8, y - my + 8) / 40
                g[y][x] = moon_lo + max(0, min(4, int(lit * 6)))
            elif d < 32:
                g[y][x] = mglow_lo
            elif d < 38:
                g[y][x] = mglow_lo + 1
    for ccx, ccy, cr in ((262, 34, 5), (276, 50, 4), (266, 52, 2.5), (281, 33, 3)):
        for y in range(int(ccy - cr), int(ccy + cr) + 1):
            for x in range(int(ccx - cr), int(ccx + cr) + 1):
                if math.hypot(x - ccx, y - ccy) <= cr:
                    g[y][x] = moon_lo + (0 if math.hypot(x - ccx, y - ccy) > cr - 1.5 else 1)
    for _ in range(45):
        x, y = rnd.randrange(W), rnd.randrange(130)
        if g[y][x] == 0:
            g[y][x] = star_lo + rnd.randrange(2)
    for x in range(W):
        hill = int(150 + 5 * math.sin(x / 37.0) + 3 * math.sin(x / 13.0))
        for y in range(hill, H):
            g[y][x] = hill_lo + (0 if y < hill + 5 else 1)

    def branch(x, y, ang, ln, th, depth):
        for k in range(int(ln)):
            px, py = x + math.cos(ang) * k, y + math.sin(ang) * k
            r = th * (1 - 0.4 * k / ln)
            for yy in range(int(py - r), int(py + r) + 1):
                for xx in range(int(px - r), int(px + r) + 1):
                    if (xx - px) ** 2 + (yy - py) ** 2 <= r * r:
                        put(g, xx, yy, blk_lo)
        if depth:
            ex, ey = x + math.cos(ang) * ln, y + math.sin(ang) * ln
            for da in (-0.55, 0.45):
                branch(ex, ey, ang + da + rnd.uniform(-0.15, 0.15), ln * 0.7, th * 0.62, depth - 1)

    branch(34, 160, -math.pi / 2 + 0.08, 42, 4.5, 4)
    for tx, th, tw in ((112, 22, 9), (205, 26, 10), (296, 20, 8)):  # tombstones
        base = 156
        for y in range(base - th, base + 4):
            for x in range(tx - tw, tx + tw + 1):
                if y > base - th + tw or math.hypot(x - tx, y - (base - th + tw)) <= tw:
                    g[y][x] = blk_lo + 1
    # drifting fog over the ground (fades into the hill color)
    for y in range(160, H):
        for x in range(W):
            if g[y][x] == hill_lo + 1 and math.sin(x / 23.0 + y / 5.0) + 0.6 * math.sin(x / 11.0 - y / 3.0) > 0.2:
                g[y][x] = fog_lo + int(x / 6 + 2 * math.sin(y / 4.0)) % 12
    for pcx, pcy, rx, ry in ((160, 162, 38, 28), (92, 178, 22, 16), (232, 180, 19, 14)):
        for y in range(pcy - ry - 6, pcy - ry + 2):  # stem
            for x in range(pcx - 2, pcx + 3):
                g[y][x] = stem_lo + (1 if x < pcx else 0)
        for y in range(pcy - ry, pcy + ry + 1):
            for x in range(pcx - rx, pcx + rx + 1):
                u, v = (x - pcx) / rx, (y - pcy) / ry
                if u * u + v * v > 1:
                    continue
                if pumpkin_face(u, v):  # candle light flickering inside
                    g[y][x] = face_lo + int(math.hypot(u, v * 1.4) * 9 + rnd.random() * 2.5) % 12
                    continue
                rib = abs(math.sin(u * math.pi * 2.0))
                lit = 0.5 + 0.5 * (-0.45 * u - 0.45 * v + 0.75 * math.sqrt(max(0.0, 1 - u * u - v * v)))
                g[y][x] = pk_lo + max(0, min(5, int(lit * 6 * (0.65 + 0.35 * rib))))
    # two bat flocks: one bat per position, flapping (up/down poses alternate)
    for i in range(10):
        x, y = 92 + i * 14, int(38 + 9 * math.sin(i * 0.8))
        stamp(g, BAT_UP if i % 2 == 0 else BAT_DOWN, x - 6, y - 3, b1_lo + i)
    for i in range(8):  # the near flock, twice the size
        x, y = 290 - i * 28, int(100 + 8 * math.sin(i * 0.9 + 1))
        stamp(g, BAT_UP if i % 2 == 0 else BAT_DOWN, x - 13, y - 7, b2_lo + i, 2)
    save(outdir, 'halloween', p, g, ['%d-%d:11:ping' % (face_lo, face_hi), '%d-%d:6' % (fog_lo, fog_hi),
                                     '%d-%d:10' % (b1_lo, b1_hi), '%d-%d:8' % (b2_lo, b2_hi)])


# ---------------------------------------------------------------- skull
def skull(outdir):
    rnd = random.Random(8)
    p = Pal()
    bg = (14, 6, 12)
    p.add([bg])
    bone_lo, _ = p.add(ramp([(40, 30, 28), (120, 105, 90), (205, 195, 170), (250, 245, 230)], 10))
    dark, _ = p.add([(22, 8, 8)])
    rim_lo, rim_hi = p.add(loop_ramp([(70, 40, 30), (190, 80, 20), (255, 170, 60)], 8))
    fire_cols = [(100, 0, 0), (210, 40, 0), (255, 130, 0), (255, 220, 70), (255, 255, 210)]
    fn = (24, 20)  # same 1 s period, different step times: the eyes never match
    fl = [p.add(loop_ramp(fire_cols, n)) for n in fn]
    em_lo, em_hi = streak(p, (255, 210, 90), [(255, 120, 20), (170, 45, 0), (80, 18, 0)], bg, 40)
    g = grid()
    cx = 160

    def head(x, y):
        dx = x - cx
        if (dx / 64.0) ** 2 + ((y - 86) / 60.0) ** 2 <= 1:
            return True
        return 110 <= y <= 174 and abs(dx) <= 60 - (y - 110) * 0.5

    for y in range(H):
        for x in range(W):
            if head(x, y):
                nx, ny = (x - cx) / 64.0, (y - 86) / 62.0
                nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny * 0.6))
                lit = 0.3 + 0.7 * max(0.0, -0.45 * nx - 0.35 * ny + 0.82 * nz)
                g[y][x] = bone_lo + min(9, int(lit * 10))
    for y in range(146, 174):  # teeth
        for x in range(cx - 30, cx + 31):
            if y in (146, 159, 160, 173) or (x - cx + 30) % 8 == 0:
                g[y][x] = dark
            else:
                g[y][x] = bone_lo + (8 if y < 153 or 160 < y < 166 else 6)
    for s in (-1, 1):  # nose
        for y in range(120, 136):
            for x in range(cx - 10, cx + 11):
                if ((x - cx - 4 * s) / 4.5) ** 2 + ((y - 127) / 7.0) ** 2 <= 1 and s * (x - cx) >= 0:
                    g[y][x] = dark
    x, y = 172.0, 30.0  # a crack
    while y < 84:
        put(g, int(x), int(y), dark)
        x += rnd.choice((-1, 0, 1, 1))
        y += 1

    def socket(x, y, scx):
        if ((x - scx) / 20.0) ** 2 + ((y - 102) / 17.0) ** 2 > 1:
            return False
        brow = 90 + ((x - 116) if scx < cx else (204 - x)) * 0.25  # angry brow
        return y >= brow

    def fire_at(x, y, k):
        return fl[k][0] + int((119 - y) / 1.4 + 2 * math.sin(x / 3.0 + y / 4.0)) % fn[k]

    for k, scx in enumerate((136, 184)):
        for y in range(80, 124):  # glowing rim, then the fire inside
            for x in range(scx - 24, scx + 25):
                if socket(x, y, scx):
                    g[y][x] = fire_at(x, y, k)
                elif any(socket(x + ax, y + ay, scx) for ax, ay in ((3, 0), (-3, 0), (0, 3), (0, -3), (2, 2), (-2, 2), (2, -2), (-2, -2))):
                    g[y][x] = rim_lo + int(math.atan2(y - 102, x - scx) * 4 / math.pi + 4) % 8
        for x in range(scx - 18, scx + 19):  # flames licking up out of the socket
            top = next(yy for yy in range(80, 124) if socket(x, yy, scx))
            env = math.cos((x - scx) / 19.0 * math.pi / 2)
            h = int(env * (18 + 22 * (0.5 + 0.5 * math.sin(x / 2.3 + scx) * math.sin(x / 5.1))))
            for y in range(top - h, top):
                g[y][x] = fire_at(x, y, k)
    # embers drifting up through the dark (only over the flat background)
    for x in range(W):
        if rnd.random() < 0.16:
            ph = rnd.randrange(40)
            for y in range(H):
                if g[y][x] == 0:
                    g[y][x] = em_lo + (ph - y) % 40
    save(outdir, 'skull', p, g, ['%d-%d:24' % fl[0], '%d-%d:20' % fl[1],
                                 '%d-%d:7:ping' % (rim_lo, rim_hi), '%d-%d:20' % (em_lo, em_hi)])


# ---------------------------------------------------------------- snake
def snake(outdir):
    rnd = random.Random(11)
    p = Pal()
    bg = (10, 24, 18)
    p.add([bg])
    gr_lo, _ = p.add(ramp([(20, 30, 14), (50, 60, 24), (80, 70, 30)], 5))
    hd_lo, _ = p.add(ramp([(20, 60, 15), (70, 130, 30), (170, 200, 80)], 6))
    eye_lo, _ = p.add([(255, 220, 40), (0, 0, 0), (40, 10, 10)])
    scales = [(30, 70, 15), (90, 150, 30), (200, 210, 70), (250, 240, 140), (120, 160, 40)]
    ba_lo, ba_hi = p.add(loop_ramp(scales, 12))
    bb_lo, bb_hi = p.add([scale(c, 0.55) for c in loop_ramp(scales, 12)])
    tongue = (225, 40, 70)
    # the tongue's reach at each of 16 steps: dart out, flicker, pull back
    reach = [0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 4, 5, 4, 2, 0]
    segs = [timeline(p, [r >= k for r in reach], tongue, bg) for k in (1, 2, 3, 4, 5)]
    ff_lo, ff_hi = p.add([(220, 255, 120), (150, 200, 60)] + [bg] * 8)
    g = grid()
    for x in range(W):
        top = int(150 + 4 * math.sin(x / 30.0))
        for y in range(top, H):
            g[y][x] = gr_lo + rnd.randrange(5)
    pts = catmull([(6, 188), (40, 166), (84, 180), (120, 160), (140, 126), (176, 104),
                   (212, 108), (238, 110), (252, 108)], 40)
    total = sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))
    best = [[9e9] * W for _ in range(H)]
    s = 0.0
    for i, (px, py) in enumerate(pts):
        if i:
            s += math.dist(pts[i - 1], pts[i])
        w = 2 + 9 * min(1.0, s / total * 1.8)
        for y in range(int(py - w) - 1, int(py + w) + 2):
            for x in range(int(px - w) - 1, int(px + w) + 2):
                d = math.hypot(x - px, y - py)
                if 0 <= x < W and 0 <= y < H and d <= w and d < best[y][x]:
                    best[y][x] = d
                    off = d / w
                    k = int(s / 3.2 + off * 5) % 12  # chevrons slide toward the head
                    g[y][x] = (bb_lo if off > 0.72 else ba_lo) + k
    hx, hy = 258, 107
    for y in range(hy - 12, hy + 12):
        for x in range(hx - 18, hx + 18):
            u = (x - hx) / 16.0
            v = (y - hy) / (10.0 * (1 - max(0.0, u) * 0.35))
            if u * u + v * v <= 1:
                g[y][x] = hd_lo + max(0, min(5, int((0.6 - v * 0.5 - u * 0.1) * 6)))
    for y in range(99, 106):
        for x in range(259, 266):
            if math.hypot(x - 262, y - 102) <= 2.8:
                g[y][x] = eye_lo + (1 if x == 262 else 0)
    put(g, 270, 104, eye_lo + 2)
    for x in range(250, 275):
        put(g, x, 110 if x > 262 else 111, eye_lo + 2)
    # forked tongue: one timeline range per segment, all in step
    for x in range(274, 300):
        k = min(3, (x - 274) // 7)
        y = 109 + int(round(1.2 * math.sin((x - 274) / 4.0)))
        put(g, x, y, segs[k][0])
        put(g, x, y + 1, segs[k][0])
    yb = 109 + int(round(1.2 * math.sin(26 / 4.0)))
    for k in range(11):
        put(g, 300 + k, int(round(yb - k * 0.5)), segs[4][0])
        put(g, 300 + k, int(round(yb + 1 + k * 0.5)), segs[4][0])
    for _ in range(26):  # fireflies
        x, y = rnd.randrange(4, W - 4), rnd.randrange(6, 140)
        if all(g[yy][xx] == 0 for yy in (y, y + 1) for xx in (x, x + 1)):
            c = ff_lo + rnd.randrange(10)
            for yy in (y, y + 1):
                for xx in (x, x + 1):
                    g[yy][xx] = c
    cyc = ['%d-%d:6' % (ba_lo, ba_hi), '%d-%d:6' % (bb_lo, bb_hi)]
    cyc += ['%d-%d:16' % sg for sg in segs]
    save(outdir, 'snake', p, g, cyc + ['%d-%d:9:ping' % (ff_lo, ff_hi)])


# ---------------------------------------------------------------- christmas
def christmas(outdir):
    rnd = random.Random(9)
    p = Pal()
    sky = (8, 14, 40)
    p.add([sky])
    snow_lo, _ = p.add(ramp([(150, 170, 210), (235, 242, 255)], 4))
    tree_lo, _ = p.add(ramp([(6, 40, 20), (20, 90, 40), (70, 160, 80)], 6))
    trunk_lo, _ = p.add(ramp([(50, 28, 12), (100, 60, 28)], 3))
    gift_lo, _ = p.add([(180, 20, 30), (40, 120, 60), (50, 80, 180), (240, 200, 60)])
    far_lo, far_hi = streak(p, (140, 160, 210), [], sky, 48)
    near_lo, near_hi = streak(p, (255, 255, 255), [(255, 255, 255)], sky, 40)
    star_lo, star_hi = p.add(loop_ramp([(200, 140, 20), (255, 220, 60), (255, 255, 220)], 8))
    ray_lo, ray_hi = streak(p, (255, 255, 230), [(255, 220, 90), (160, 120, 50)], sky, 16)
    bulb_lo, bulb_hi = p.add([(255, 40, 40), (90, 10, 10), (40, 255, 80), (10, 80, 20),
                              (70, 130, 255), (10, 30, 90), (255, 210, 40), (100, 70, 10)])
    tx_lo, tx_hi = p.add(loop_ramp([(150, 0, 20), (255, 50, 60), (255, 225, 225)], 10))
    g = grid()
    ground = 166
    # snow: falling flakes are streak ranges down every few columns (far:
    # small and slow, near: 2x2 and faster)
    for x in range(W):
        if x % 3 == 1 and rnd.random() < 0.7:
            ph = rnd.randrange(48)
            for y in range(ground):
                g[y][x] = far_lo + (y + ph) % 48
    for x in range(4, W - 1, 9):
        if rnd.random() < 0.8:
            ph = rnd.randrange(40)
            for y in range(ground):
                g[y][x] = g[y][x + 1] = near_lo + (y + ph) % 40
    for x in range(W):
        top = int(ground + 2 * math.sin(x / 25.0))
        for y in range(top, H):
            g[y][x] = snow_lo + max(0, min(3, 3 - (y - top) // 6 + (1 if (x * 7 + y * 3) % 11 == 0 else 0)))
    tiers = [(34, 82, 36), (64, 118, 52), (96, 154, 68)]
    in_tree = [[False] * W for _ in range(H)]
    for y in range(150, ground + 2):
        for x in range(152, 169):
            g[y][x] = trunk_lo + (2 if x < 157 else 1 if x < 164 else 0)
    for apex, base, hwb in tiers:
        for y in range(apex, base + 1):
            hw = (y - apex) / (base - apex) * hwb
            for x in range(int(160 - hw), int(160 + hw) + 1):
                if y > base - 4 * abs(math.sin(x / 5.0)):
                    continue
                in_tree[y][x] = True
                lit = 0.55 - (x - 160) / (2 * max(hw, 1)) * 0.5 + 0.15 * math.sin(x / 4.0 + y / 3.0)
                g[y][x] = tree_lo + max(0, min(5, int(lit * 6)))
    for bx, bw, bh, c, rib in ((110, 24, 14, 0, 3), (196, 28, 18, 2, 3), (134, 16, 10, 1, 0)):
        for y in range(ground + 1 - bh, ground + 1):
            for x in range(bx, bx + bw):
                ribbon = abs(x - (bx + bw // 2)) <= 1 or y == ground + 1 - bh // 2
                g[y][x] = gift_lo + (rib if ribbon else c)
    # garland bulbs swagging across each tier; colors chase along it
    i = 0
    for apex, base, hwb in tiers:
        n = int(hwb * 1.8 / 9)
        for j in range(n + 1):
            u = j / n * 2 - 1
            y = int(apex + 0.62 * (base - apex) + 7 * (1 - u * u) + u * 6)
            hw = (y - apex) / (base - apex) * hwb
            x = int(160 + u * hw * 0.88)
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                put(g, x + dx, y + dy, bulb_lo + i % 8)
            i += 1
    scx, scy = 160, 24
    for y in range(scy - 15, scy + 15):  # the star on top
        for x in range(scx - 15, scx + 15):
            d = math.hypot(x - scx, y - scy)
            a = (math.atan2(y - scy, x - scx) + math.pi / 2) % (2 * math.pi / 5)
            r = 5.5 + 7.5 * abs(a / (math.pi / 5) - 1)
            if d <= r:
                g[y][x] = star_lo + int(d / 1.8) % 8
    for k in range(8):  # sparkles shooting out of it
        ang = k * math.pi / 4
        if k == 2:
            continue  # straight down is the tree
        ln = 26 if k % 2 == 0 else 18
        for r in range(14, 14 + ln):
            x, y = int(round(scx + r * math.cos(ang))), int(round(scy + r * math.sin(ang)))
            if 0 <= x < W and 0 <= y < H and not in_tree[y][x]:
                g[y][x] = ray_lo + (r - 14) * 13 // ln
    msg = 'MERRY CHRISTMAS'
    draw_text(g, msg, (W - text_width(msg, 2)) // 2, 178, 2, lambda x, y: tx_lo + ((x - y) // 3) % 10)
    save(outdir, 'christmas', p, g, ['%d-%d:24' % (far_lo, far_hi), '%d-%d:40' % (near_lo, near_hi),
                                     '%d-%d:7:ping' % (star_lo, star_hi), '%d-%d:16' % (ray_lo, ray_hi),
                                     '%d-%d:4' % (bulb_lo, bulb_hi), '%d-%d:9:ping' % (tx_lo, tx_hi)])


# ---------------------------------------------------------------- new year
def new_year(outdir):
    rnd = random.Random(10)
    p = Pal()
    sky = (6, 6, 24)
    p.add([sky])
    star_lo, _ = p.add([(160, 160, 200), (90, 90, 130)])
    bld_lo, _ = p.add([(14, 14, 30), (22, 20, 42), (30, 28, 54)])
    win_lo, win_hi = p.add(loop_ramp([(150, 110, 50), (230, 190, 90), (255, 235, 160)], 20))
    gnd, _ = p.add([(10, 10, 20)])
    tx_lo, tx_hi = p.add(loop_ramp([(150, 100, 20), (255, 200, 60), (255, 250, 210)], 10))
    g = grid()
    for _ in range(60):
        x, y = rnd.randrange(W), rnd.randrange(120)
        g[y][x] = star_lo + rnd.randrange(2)
    skyline = [0] * W
    x = 0
    while x < W:
        bw, top = rnd.randrange(14, 34), rnd.randrange(118, 156)
        shade = rnd.randrange(3)
        for xx in range(x, min(W, x + bw)):
            skyline[xx] = top
            for y in range(top, 182):
                g[y][xx] = bld_lo + shade
        for wy in range(top + 4, 178, 6):
            for wx in range(x + 3, min(W, x + bw) - 3, 5):
                if rnd.random() < 0.45:
                    c = win_lo + rnd.randrange(20)
                    for y in range(wy, wy + 3):
                        for xx in range(wx, wx + 2):
                            g[y][xx] = c
        x += bw
    for y in range(182, H):
        for x in range(W):
            g[y][x] = gnd
    # each firework is one streak range: the head climbs the rocket trail
    # (bottom to top), bursts at the center, races out along the spokes
    # (with a fading tail), then a pause while it is off the end
    cyc = []
    shows = [(52, 52, 30, (255, 70, 90)), (125, 36, 30, (90, 255, 120)),
             (196, 60, 30, (100, 160, 255)), (266, 40, 30, (255, 200, 60)),
             (94, 96, 18, (240, 90, 255))]
    for k, (fx, fy, rad, col) in enumerate(shows):
        base = skyline[fx] - 1
        trail = (base - fy - 1) // 5 + 1
        bands = 10
        n = trail + 1 + bands + 6
        n += n % 2  # n / 2 steps a second: every show repeats each 2 s
        lo, hi = streak(p, (255, 255, 255), [col, scale(col, 0.65), scale(col, 0.4), scale(col, 0.22)], sky, n,
                        [0, 3, 1, 4, 2][k] * n // 5)
        for y in range(fy + 1, base + 1):
            if g[y][fx] == 0:
                g[y][fx] = lo + (base - y) // 5
        g[fy][fx] = lo + trail
        a0 = rnd.random()
        for k in range(26):
            ang = (k + a0) * 2 * math.pi / 26
            for r in range(1, rad + 1):
                x = int(round(fx + r * math.cos(ang)))
                y = int(round(fy + r * math.sin(ang) + 6 * (r / rad) ** 2))
                if 0 <= x < W and 0 <= y < H and g[y][x] in (0, star_lo, star_lo + 1):
                    g[y][x] = lo + trail + 1 + (r - 1) * bands // rad
        cyc.append('%d-%d:%d' % (lo, hi, n // 2))
    msg = 'HAPPY NEW YEAR'
    draw_text(g, msg, (W - text_width(msg, 2)) // 2, 184, 2, lambda x, y: tx_lo + ((x + y) // 3) % 10)
    save(outdir, 'new-year', p, g, cyc + ['%d-%d:10' % (win_lo, win_hi), '%d-%d:9:ping' % (tx_lo, tx_hi)])


# ---------------------------------------------------------------- valentine
def valentine(outdir):
    rnd = random.Random(13)
    p = Pal()
    p.add([(60, 0, 20)])
    ray_lo, ray_hi = p.add(loop_ramp([(110, 20, 60), (165, 45, 95), (210, 90, 140)], 16))
    ht_lo, ht_hi = p.add(loop_ramp([(140, 0, 30), (230, 30, 70), (255, 120, 150), (255, 200, 215)], 12))
    edge_lo, _ = p.add([(255, 240, 245), (240, 190, 205)])
    sp_lo, sp_hi = p.add(loop_ramp([(200, 90, 140), (255, 190, 220), (255, 255, 255)], 8))
    tx_lo, tx_hi = p.add(loop_ramp([(255, 110, 150), (255, 200, 220), (255, 250, 252)], 10))
    g = grid()
    hcx, hcy, hs = 160, 82, 56
    for y in range(H):
        for x in range(W):
            k = heart_k((x - hcx) / hs, -(y - hcy) / hs)
            if k < 1.0:  # rings beat outward from the middle
                g[y][x] = ht_lo + int(k * 14) % 12
            elif k < 1.05:
                g[y][x] = edge_lo + (0 if k < 1.025 else 1)
            else:  # a slowly turning sunburst
                a = math.atan2(y - hcy, x - hcx)
                g[y][x] = ray_lo + int((a + math.pi) / (2 * math.pi) * 48) % 16
    msg = 'BE MINE'
    tw = text_width(msg, 3)
    draw_text(g, msg, (W - tw) // 2, 168, 3, lambda x, y: tx_lo + ((x + y) // 4) % 10)
    for _ in range(40):  # twinkling sparkles
        x, y = rnd.randrange(6, W - 6), rnd.randrange(6, H - 6)
        if all(ray_lo <= g[y + dy][x + dx] <= ray_hi for dy in range(-3, 4) for dx in range(-3, 4)):
            c = sp_lo + rnd.randrange(8)
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0), (0, 2), (0, -2)):
                g[y + dy][x + dx] = c
    save(outdir, 'valentine', p, g, ['%d-%d:8' % (ray_lo, ray_hi), '%d-%d:12' % (ht_lo, ht_hi),
                                     '%d-%d:7:ping' % (sp_lo, sp_hi), '%d-%d:9:ping' % (tx_lo, tx_hi)])


# ---------------------------------------------------------------- st patrick's
def st_patricks(outdir):
    rnd = random.Random(12)
    p = Pal()
    p.add([(20, 60, 140)])
    sky_lo, _ = p.add(ramp([(40, 90, 180), (120, 180, 235), (205, 232, 250)], 10))
    cloud_lo, _ = p.add([(255, 255, 255), (220, 228, 240), (185, 195, 215)])
    hill_lo, _ = p.add(ramp([(10, 70, 20), (40, 140, 40), (110, 200, 70)], 8))
    pot_lo, _ = p.add([(10, 10, 12), (35, 35, 40), (75, 75, 85)])
    gold_lo, _ = p.add(ramp([(120, 80, 0), (220, 170, 30), (255, 232, 110)], 5))
    shm_lo, _ = p.add([(8, 50, 16), (40, 170, 60), (120, 225, 110)])
    rb_lo, rb_hi = p.add(ramp([(255, 30, 30), (255, 140, 0), (255, 240, 0), (40, 200, 40), (40, 110, 255),
                               (90, 40, 200), (180, 40, 210), (255, 30, 30)], 21)[:20])
    gl_lo, gl_hi = p.add([(200, 150, 20), (220, 170, 30), (235, 190, 50), (255, 225, 110), (255, 255, 240),
                          (255, 225, 110), (235, 190, 50), (220, 170, 30), (200, 150, 20), (180, 130, 10)])
    tx_lo, tx_hi = p.add(loop_ramp([(60, 200, 80), (190, 240, 110), (255, 235, 110)], 10))
    g = grid()
    for y in range(H):
        for x in range(W):
            g[y][x] = sky_lo + min(9, y * 10 // 150)
    for ccx, ccy in ((60, 54), (210, 30)):  # clouds
        for bx, by, br in ((-16, 4, 10), (0, 0, 14), (16, 4, 11), (30, 7, 8)):
            for y in range(ccy + by - br, ccy + by + br + 1):
                for x in range(ccx + bx - br, ccx + bx + br + 1):
                    d = math.hypot(x - ccx - bx, y - ccy - by)
                    if d <= br and y <= ccy + 10:
                        g[y][x] = cloud_lo + (0 if y < ccy + by - br / 3 else 1 if y < ccy + 6 else 2)
    # the rainbow: spectrum bands that flow outward
    for y in range(H):
        for x in range(W):
            r = math.hypot(x - 150, y - 200)
            if 92 <= r < 134:
                g[y][x] = rb_lo + int((r - 92) / 2) % 20
    for x in range(W):
        back = int(150 + 12 * math.sin(x / 50.0 + 1))
        front = int(174 + 8 * math.sin(x / 37.0))
        for y in range(back, H):
            g[y][x] = hill_lo + (2 + (y - back) // 8 if y < front else 5 + min(2, (y - front) // 6))
    pcx = 263
    for y in range(146, 192):  # the pot
        for x in range(pcx - 30, pcx + 31):
            u, v = (x - pcx) / 28.0, (y - 170) / 20.0
            rim = abs(y - 150) <= 2 and abs(x - pcx) <= 29
            if rim or (y > 150 and u * u + v * v <= 1):
                g[y][x] = pot_lo + (2 if rim and y < 150 else 1 if rim or u < -0.4 else 0)
    coins = []
    for _ in range(70):  # the gold, heaped up, glittering
        u, v = rnd.uniform(-1, 1), rnd.uniform(0, 1)
        if u * u + v * v <= 1:
            coins.append((pcx + u * 25, 147 - v * 13))
    coins.sort(key=lambda c: c[1])
    for ccx, ccy in coins:
        for y in range(int(ccy - 3), int(ccy + 4)):
            for x in range(int(ccx - 4), int(ccx + 5)):
                d = ((x - ccx) / 3.6) ** 2 + ((y - ccy) / 2.6) ** 2
                if d <= 1:
                    g[y][x] = gold_lo + (0 if d > 0.7 else 2 + int(ccy + 3 - y) // 2)
        g[int(ccy) - 1][int(ccx) - 1] = gl_lo + rnd.randrange(10)
    for scx, scy, sz in ((40, 178, 8.5), (118, 186, 6.5), (200, 182, 7.5)):  # shamrocks
        leaf = {}
        for k in range(int(sz * 2.2)):
            for dx in (0, 1):
                leaf[(int(scx + k * 0.45) + dx, int(scy + 2 + k))] = 0
        for y in range(int(scy - sz * 3), int(scy + sz * 3)):
            for x in range(int(scx - sz * 3), int(scx + sz * 3)):
                for a in (math.pi / 2, math.pi / 2 + 2.094, math.pi / 2 - 2.094):
                    # a heart per leaf, its point at the middle
                    lx, ly = x - scx - math.cos(a) * sz * 1.1, -(y - scy) - math.sin(a) * sz * 1.1
                    rx = lx * math.cos(math.pi / 2 - a) - ly * math.sin(math.pi / 2 - a)
                    ry = lx * math.sin(math.pi / 2 - a) + ly * math.cos(math.pi / 2 - a)
                    if heart_in(rx / sz, ry / sz):
                        leaf[(x, y)] = 2 if abs(rx) < sz * 0.12 or ry > sz * 0.55 else 1
        for (x, y), c in leaf.items():
            edge = any((x + dx, y + dy) not in leaf for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            put(g, x, y, shm_lo + (0 if edge else c))
    msg = 'HAPPY ST PATRICKS DAY'
    draw_text(g, msg, (W - text_width(msg, 2)) // 2 + 1, 9, 2, lambda x, y: shm_lo)
    draw_text(g, msg, (W - text_width(msg, 2)) // 2, 8, 2, lambda x, y: tx_lo + ((x + y) // 3) % 10)
    save(outdir, 'st-patricks', p, g, ['%d-%d:10' % (rb_lo, rb_hi), '%d-%d:9:ping' % (gl_lo, gl_hi),
                                       '%d-%d:9:ping' % (tx_lo, tx_hi)])


SCENES = (waterfall, fire, tunnel, marquee, ocean, pinwheel,
          candles, hanukkah, halloween, skull, snake, christmas, new_year, valentine, st_patricks)

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    only = sys.argv[2:]
    for fn in SCENES:
        if only and fn.__name__ not in only:
            continue
        fn(out)
        print('wrote', fn.__name__)
