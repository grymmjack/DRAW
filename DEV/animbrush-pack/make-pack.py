#!/usr/bin/env python3
"""Make DRAW's AnimBrush example pack.

  make-pack.py OUTDIR

writes
  OUTDIR/animbrush-pack.dset        a Drawer brush set: bins 1-15 are AnimBrushes (DSA1 block)
  OUTDIR/brushes/NAME.png           each brush as a strip with frame data (drAn chunk):
                                    ANIM > AnimBrush > Load... takes it, File > Open shows its frames
  OUTDIR/preview/NAME.gif           4x previews (for the docs page)
  OUTDIR/scenes/NAME-base.png       each scene's background, drawn in frame 1 only, on a
                                    sheet of 24 frames of 160x120 at 12 fps (drAn chunk)
  OUTDIR/pack.txt                   bin, name, size, cels, the order and step it is made for

No libraries: the art is drawn here pixel by pixel, PNGs are written with zlib,
GIF previews go through ImageMagick (`magick`).

Formats: TOOLS/ANIM-BRUSH.BM (AB_slots_blob$: count, per slot: slot n cw ch + the
strip's BGRA rows), GUI/DRAWER.BM (a .dset slot image: hasImage -1, w, h, w*h
&HAARRGGBB little-endian), the drAn chunk: .claude/instructions/draw-fileformat.md.
"""
import math, os, random, struct, subprocess, sys, zlib

# ---------------------------------------------------------------- palette ---
# Endesga 32 (by ENDESGA), the colours named for what they are used for here
E = dict(rust='be4a2f', clay='d77643', sand='ead4aa', tan='e4a672', wood='b86f50', bark='733e39',
         plum='3e2731', wine='a22633', red='e43b44', orange='f77622', amber='feae34', yellow='fee761',
         lime='63c74d', green='3e8948', pine='265c42', deep='193c3e', navy='124e89', blue='0099db',
         cyan='2ce8f5', white='ffffff', mist='c0cbdc', grey='8b9bb4', slate='5a6988', stone='3a4466',
         night='262b44', ink='181425', pink='ff0044', grape='68386c', rose='b55088', coral='f6757a',
         skin='e8b796', dusk='c28569')


def C(name, a=255):
    h = E.get(name, name)
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(3)) + (255,)


BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dith(x, y, t):  # TRUE where an ordered dither of level t (0..1) puts the second colour
    return t * 16 > BAYER4[y & 3][x & 3] + 0.5


# ------------------------------------------------------------------ image ---
class Img:
    def __init__(s, w, h, fill=None):
        s.w, s.h = w, h
        s.p = [fill] * (w * h)

    def get(s, x, y):
        if 0 <= x < s.w and 0 <= y < s.h:
            return s.p[y * s.w + x]
        return None

    def set(s, x, y, c):
        x, y = int(math.floor(x)), int(math.floor(y))
        if c is None or not (0 <= x < s.w and 0 <= y < s.h):
            return
        if c[3] < 255:
            u = s.p[y * s.w + x]
            if u is not None and u[3] > 0:
                a = c[3] / 255.0
                c = tuple(int(round(u[i] * (1 - a) + c[i] * a)) for i in range(3)) + (max(u[3], c[3]),)
        s.p[y * s.w + x] = c

    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                s.set(x, y, c)

    def ellipse(s, cx, cy, rx, ry, c):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                dx = (x + 0.5 - cx) / max(rx, 0.01)
                dy = (y + 0.5 - cy) / max(ry, 0.01)
                if dx * dx + dy * dy <= 1.0:
                    s.set(x, y, c)

    def disc(s, cx, cy, r, c):
        s.ellipse(cx, cy, r, r, c)

    def line(s, x0, y0, x1, y1, c):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        e = dx + dy
        while True:
            s.set(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * e
            if e2 >= dy:
                e += dy; x0 += sx
            if e2 <= dx:
                e += dx; y0 += sy

    def blit(s, o, x, y):
        for j in range(o.h):
            for i in range(o.w):
                c = o.p[j * o.w + i]
                if c is not None and c[3] > 0:
                    s.set(x + i, y + j, c)

    def outline(s, c):  # a 1 px outline around the drawn pixels (4-neighbours)
        o = [list(r) for r in [s.p]][0][:]
        for y in range(s.h):
            for x in range(s.w):
                if s.p[y * s.w + x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        u = s.get(x + dx, y + dy)
                        if u is not None and u[3] > 200:
                            o[y * s.w + x] = c
                            break
        s.p = o


# ------------------------------------------------------------------- files ---
def png_chunk(typ, data):
    return struct.pack('>I', len(data)) + typ + data + struct.pack('>I', zlib.crc32(typ + data) & 0xFFFFFFFF)


def write_png(path, img, extra=b''):
    raw = bytearray()
    for y in range(img.h):
        raw.append(0)
        for x in range(img.w):
            raw += bytes(img.p[y * img.w + x] or (0, 0, 0, 0))
    b = b'\x89PNG\r\n\x1a\n' + png_chunk(b'IHDR', struct.pack('>IIBBBBB', img.w, img.h, 8, 6, 0, 0, 0))
    b += png_chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + extra + png_chunk(b'IEND', b'')
    open(path, 'wb').write(b)


def dran(fw, fh, count, fps=12):  # the drAn chunk, v1: frames on the sheet
    return png_chunk(b'drAn', struct.pack('<10h', 1, fw, fh, 0, 0, count, 1, fps, 0, 0))


def bgra(c):
    return bytes((c[2], c[1], c[0], c[3])) if c and c[3] else bytes(4)


def i16(v):
    return struct.pack('<h', v)


# --------------------------------------------------------------- brushes ----
def flame(img, cx, base, height, maxw, sway, flick, colors):
    """A teardrop flame standing on y = base, `colors` outer -> core."""
    n = len(colors)
    for k, col in enumerate(colors):
        sc = 1.0 - k * (0.9 / n)  # each inner layer smaller
        h = height * (sc ** 0.8)
        w = maxw * sc
        top = base - h
        for y in range(int(top), int(base) + 1):
            t = (y + 0.5 - top) / h  # 0 at the tip, 1 at the base
            if t < 0 or t > 1.02:
                continue
            hw = w * (t ** 0.75) * 0.5
            if t > 0.75:
                hw *= math.sqrt(max(0.0, 1 - ((t - 0.75) / 0.3) ** 2))
            hw += flick * math.sin(y * 1.7 + k) * (1 - t) * 0.6
            x0 = cx + sway * (1 - t) ** 2
            for x in range(int(math.floor(x0 - hw)), int(math.ceil(x0 + hw))):
                if abs(x + 0.5 - x0) <= hw:
                    img.set(x, y, col)


FIRE = [C('red'), C('orange'), C('amber'), C('yellow')]
SWAY6 = [-1.2, 0.4, 1.3, 0.2, -0.8, 1.0]
FLICK6 = [0.6, -0.4, 0.8, -0.7, 0.3, -0.5]


def b_torch():
    cels = []
    for k in range(6):
        c = Img(9, 18)
        c.rect(3, 11, 5, 17, C('bark')); c.rect(3, 11, 3, 17, C('wood'))  # handle
        c.rect(2, 10, 6, 11, C('slate')); c.rect(2, 10, 6, 10, C('grey'))   # cup
        flame(c, 4.5, 10, 9 + (k % 3 == 1), 5.5, SWAY6[k], FLICK6[k], FIRE)
        cels.append(c)
    return cels


def b_campfire():
    cels = []
    rnd = random.Random(7)
    sparks = [[(rnd.randint(4, 15), rnd.randint(0, 5)) for _ in range(2)] for _ in range(6)]
    for k in range(6):
        c = Img(20, 16)
        flame(c, 7, 13, 9 + (k % 2), 6, SWAY6[k], FLICK6[k], FIRE)
        flame(c, 13, 13, 8 + ((k + 1) % 3 == 0), 6, SWAY6[(k + 2) % 6], FLICK6[(k + 3) % 6], FIRE)
        flame(c, 10, 13, 12 + (k % 3 == 2), 7, SWAY6[(k + 4) % 6], FLICK6[(k + 1) % 6], FIRE)
        for x, y in sparks[k]:
            c.set(x, y, C('yellow' if k % 2 else 'amber'))
        c.line(1, 14, 18, 11, C('bark')); c.line(1, 15, 18, 12, C('wood'))  # logs
        c.line(1, 11, 18, 14, C('bark')); c.line(1, 12, 18, 15, C('wood'))
        c.set(1, 12, C('tan')); c.set(18, 12, C('tan'))
        cels.append(c)
    return cels


def b_smoke():  # 8 cels, rises 1 px a cel, a puff every 8 px: loops seamlessly
    cels = []
    for k in range(8):
        c = Img(10, 26)
        for j in range(4):
            yb = 25 - ((j * 8 + k) % 32) * 0.8  # height above the base
            t = (25 - yb) / 25.0                 # 0 at the base -> 1 at the top
            r = 1.6 + t * 2.4
            a = int(215 * (1 - t) ** 0.7)
            x = 5 + math.sin((j * 8 + k) * 0.35) * 1.5
            if a > 8:
                c.disc(x, yb, r, mix(C('mist'), C('grey'), t)[:3] + (a,))
                c.disc(x - r * 0.3, yb - r * 0.3, r * 0.55, C('white')[:3] + (int(a * 0.8),))
        cels.append(c)
    return cels


def b_star():
    sizes = [0, 1, 2, 3, 3, 2, 1, 0]
    cels = []
    for k, s in enumerate(sizes):
        c = Img(7, 7)
        col = C('white') if s >= 2 else C('mist')
        for i in range(1, s + 1):
            fade = C('mist') if i == s and s > 1 else col
            for x, y in ((3 + i, 3), (3 - i, 3), (3, 3 + i), (3, 3 - i)):
                c.set(x, y, fade)
        if s == 3:
            for d in (1, -1):
                c.set(3 + d, 3 + d, C('grey')); c.set(3 + d, 3 - d, C('grey'))
        c.set(3, 3, C('white') if s else C('grey'))
        cels.append(c)
    return cels


def b_firefly():
    glow = [0.0, 0.25, 0.6, 1.0, 1.0, 0.6, 0.25, 0.0]
    cels = []
    for g in glow:
        c = Img(7, 7)
        if g > 0:
            c.disc(3.5, 3.5, 3.5, C('lime')[:3] + (int(90 * g),))
            c.disc(3.5, 3.5, 2.2, C('yellow')[:3] + (int(190 * g),))
        c.set(3, 3, C('white') if g > 0.5 else (C('yellow') if g > 0 else C('green')))
        cels.append(c)
    return cels


def b_flag():
    cels = []
    for k in range(6):
        c = Img(14, 14)
        c.rect(0, 0, 0, 13, C('grey')); c.set(0, 0, C('amber'))
        for x in range(1, 14):
            off = math.sin(k * math.pi / 3 - x * 0.7) * 1.2 * (x / 13.0) ** 0.7
            for y in range(1, 7):
                yy = y + off
                col = C('red') if y < 4 else C('wine')
                if (x + k) % 6 in (0, 1) and y < 6:
                    col = mix(col, C('ink'), 0.25)
                c.set(x, yy, col)
            c.set(x, 1 + off, C('coral'))
        cels.append(c)
    return cels


def b_bat():
    tips = [-3, -1, 3, 1]  # wing tip height per cel: up, mid, down, mid
    cels = []
    for t in tips:
        c = Img(17, 10)
        cx, cy = 8, 4
        for side in (-1, 1):
            for i in range(1, 9):
                top = cy - 1 + t * (i / 8.0) - (1 if i in (3, 4) and t < 0 else 0)
                bot = top + (2 if i < 6 else 1) + (0 if i % 3 == 0 else 1)
                for y in range(int(round(top)), int(round(bot)) + 1):
                    c.set(cx + side * i, y, C('ink') if y < bot else C('stone'))
        c.rect(cx - 1, cy - 1, cx + 1, cy + 3, C('ink'))
        c.set(cx - 1, cy - 2, C('ink')); c.set(cx + 1, cy - 2, C('ink'))  # ears
        c.set(cx - 1, cy, C('pink')); c.set(cx + 1, cy, C('pink'))       # eyes
        cels.append(c)
    return cels


def b_ghost():
    cels = []
    for k in range(4):
        c = Img(12, 15)
        bob = [0, -1, -1, 0][k]
        body = C('white')[:3] + (200,)
        c.ellipse(6, 6 + bob, 5, 5.5, body)
        c.rect(1, 6 + bob, 10, 11 + bob, body)
        for x in range(1, 11):  # wavy hem
            h = 12 + bob + (1 if (x + k) % 4 < 2 else 0)
            c.rect(x, 12 + bob, x, h, body)
        c.rect(1, 6 + bob, 1, 11 + bob, C('mist')[:3] + (200,))
        c.rect(3, 5 + bob, 4, 7 + bob, C('ink')); c.rect(7, 5 + bob, 8, 7 + bob, C('ink'))
        c.set(3, 5 + bob, C('slate')); c.set(7, 5 + bob, C('slate'))
        c.ellipse(6, 9.5 + bob, 1.3, 1.0 + (k % 2) * 0.5, C('stone'))
        cels.append(c)
    return cels


def b_owl():
    cels = []
    for k in range(12):
        c = Img(11, 14)
        c.ellipse(5.5, 8.5, 5, 5.5, C('bark'))       # body
        c.ellipse(5.5, 9.5, 3, 3.6, C('tan'))        # belly
        for y in (8, 10, 12):
            c.set(4, y, C('dusk')); c.set(7, y, C('dusk'))
        c.ellipse(5.5, 4.5, 5, 4, C('wood'))         # head
        c.set(1, 0, C('bark')); c.set(2, 1, C('bark')); c.set(9, 0, C('bark')); c.set(8, 1, C('bark'))
        lid = {9: 1, 10: 2, 11: 1}.get(k, 0)         # 0 open, 1 half, 2 shut
        for ex in (3, 7):
            if lid == 2:
                c.rect(ex - 1, 4, ex + 1, 4, C('ink'))
            else:
                c.disc(ex + 0.5, 4.5, 1.6, C('amber'))
                c.set(ex, 4 if lid == 0 else 5, C('ink'))
                if lid == 1:
                    c.rect(ex - 1, 3, ex + 1, 3, C('wood'))
        c.set(5, 6, C('orange'))                     # beak
        c.set(3, 13, C('amber')); c.set(4, 13, C('amber')); c.set(7, 13, C('amber')); c.set(8, 13, C('amber'))
        cels.append(c)
    return cels


def b_waterfall():  # 16x16, 4 cels; the pattern repeats every 16 px down and moves 4 px a cel
    rnd = random.Random(11)
    streaks = []
    for x in range(16):
        for _ in range(2):
            streaks.append((x, rnd.randint(0, 15), rnd.randint(2, 6), rnd.choice(['cyan', 'cyan', 'white', 'mist'])))
    cels = []
    for k in range(4):
        c = Img(16, 16)
        for y in range(16):
            for x in range(16):
                edge = x in (0, 15)
                c.set(x, y, C('navy') if edge else (C('blue') if (x * 7 + y * 3) % 5 else mix(C('blue'), C('navy'), 0.4)))
        for x, y0, ln, col in streaks:
            for i in range(ln):
                c.set(x, (y0 + k * 4 + i) % 16, C(col) if i else mix(C(col), C('blue'), 0.5))
        cels.append(c)
    return cels


def b_splash():
    rnd = random.Random(5)
    cels = []
    for k in range(4):
        c = Img(26, 11)
        c.ellipse(13, 8, 12, 3, C('cyan')[:3] + (190,))
        c.ellipse(13, 8, 8, 2, C('white')[:3] + (230,))
        for _ in range(12):
            x = rnd.uniform(3, 23)
            h = abs(math.sin(k * math.pi / 4 + x)) * 6
            r = rnd.choice([0.8, 1.2, 1.5])
            c.disc(x, 8 - h, r, C(rnd.choice(['white', 'white', 'cyan', 'mist'])))
        cels.append(c)
    return cels


def b_ripple():
    cels = []
    for k in range(8):
        c = Img(17, 7)
        for j in range(2):
            t = ((k + j * 4) % 8) / 8.0
            rx, ry = 1.5 + t * 7, 0.6 + t * 2.4
            col = mix(C('white'), C('cyan'), t)
            a = int(255 * (1 - t) ** 0.6)
            n = 40
            for i in range(n):
                th = 2 * math.pi * i / n
                c.set(8.5 + math.cos(th) * rx - 0.5, 3.5 + math.sin(th) * ry - 0.5, col[:3] + (a,))
        cels.append(c)
    return cels


def b_grass():  # 3 cels, made for ping-pong (left, upright, right)
    blades = [(1, 6, 'green'), (3, 8, 'lime'), (4, 6, 'green'), (6, 9, 'lime'), (8, 5, 'green')]
    cels = []
    for lean in (-1, 0, 1):
        c = Img(10, 10)
        for bx, h, col in blades:
            for i in range(h):
                t = i / max(h - 1, 1)
                x = bx + lean * round(t * t * 2)
                c.set(x, 9 - i, C(col) if i < h - 1 else C('yellow' if col == 'lime' else 'lime'))
        cels.append(c)
    return cels


def b_butterfly():
    spans = [3, 2, 0, 2]  # wing half-width per cel: open, half, shut, half
    cels = []
    for s in spans:
        c = Img(9, 7)
        for side in (-1, 1):
            if s:
                for i in range(1, s + 1):
                    c.rect(4 + side * i, 1, 4 + side * i, 3, C('orange'))
                    c.rect(4 + side * i, 4, 4 + side * i, 5, C('amber'))
                c.set(4 + side * s, 1, C('ink'))
            else:
                c.rect(4 + side, 0, 4 + side, 3, C('orange'))
        c.rect(4, 1, 4, 5, C('ink'))
        c.set(3, 0, C('ink')); c.set(5, 0, C('ink'))
        cels.append(c)
    return cels


def b_bird():
    tips = [-2, 0, 2, 0]
    cels = []
    for t in tips:
        c = Img(13, 7)
        cx, cy = 6, 3
        for side in (-1, 1):
            c.line(cx, cy, cx + side * 3, cy - 1 + t // 2, C('ink'))
            c.line(cx + side * 3, cy - 1 + t // 2, cx + side * 6, cy + t, C('ink'))
            c.line(cx + side * 1, cy + 1, cx + side * 3, cy + t // 2, C('stone'))
            c.line(cx + side * 3, cy + t // 2, cx + side * 5, cy + t, C('stone'))
        c.set(cx, cy + 1, C('ink'))
        cels.append(c)
    return cels


# bin, name, builder, order, step, what it is for
PACK = [
    (1, 'torch', b_torch, 'forward', 'every frame', 'a wall torch: stamp it, then Alt+] for the next one so they don\'t flicker together'),
    (2, 'campfire', b_campfire, 'forward', 'every frame', 'logs and three tongues of fire'),
    (3, 'smoke', b_smoke, 'forward', 'every frame', 'rising smoke that loops seamlessly (8 cels)'),
    (4, 'star', b_star, 'forward', 'every frame', 'a twinkle; scatter several with different Alt+] offsets'),
    (5, 'firefly', b_firefly, 'forward', 'every frame', 'a glow that pulses on and off'),
    (6, 'flag', b_flag, 'forward', 'every frame', 'a pennant on its pole (stamp the pole on a tower top)'),
    (7, 'bat', b_bat, 'forward', 'Move Brush, every frame', 'four wing beats; fly it along a path'),
    (8, 'ghost', b_ghost, 'forward', 'Move Brush, every 2 frames', 'a bobbing, see-through ghost'),
    (9, 'owl', b_owl, 'forward', 'every frame', 'sits still, blinks once every 12 frames'),
    (10, 'waterfall', b_waterfall, 'forward', 'every frame', '16x16 tile: stack copies straight down, no offsets, and it flows as one'),
    (11, 'splash', b_splash, 'forward', 'every frame', 'foam where falling water lands'),
    (12, 'ripple', b_ripple, 'forward', 'every frame', 'rings on still water'),
    (13, 'grass', b_grass, 'ping-pong', 'every frame', 'three cels, made for Ping-Pong: it sways'),
    (14, 'butterfly', b_butterfly, 'forward', 'Move Brush, every frame', 'flutters along a path'),
    (15, 'bird', b_bird, 'forward', 'Move Brush, every 2 frames', 'a distant bird for the sky'),
]


def strip_of(cels):
    w, h = cels[0].w, cels[0].h
    s = Img(w * len(cels), h)
    for k, c in enumerate(cels):
        s.blit(c, k * w, 0)
    return s


def write_dset(path, brushes):
    b = b'DST1' + i16(1) + i16(1) + i16(1)  # magic, version, brush mode, slot 1 picked
    by_slot = {slot: cels for slot, cels in brushes}
    for slot in range(1, 31):
        cels = by_slot.get(slot)
        if not cels:
            b += i16(0); continue
        c = cels[0]
        b += i16(-1) + i16(c.w) + i16(c.h) + b''.join(bgra(p) for p in c.p)
    b += b'DSA1' + i16(len(brushes))
    for slot, cels in brushes:
        w, h = cels[0].w, cels[0].h
        b += i16(slot) + i16(len(cels)) + i16(w) + i16(h)
        for y in range(h):
            for c in cels:
                b += b''.join(bgra(c.p[y * w + x]) for x in range(w))
    open(path, 'wb').write(b)


def gif_preview(path, cels, tmp, scale=4, delay=8):
    os.makedirs(tmp, exist_ok=True)
    files = []
    for k, c in enumerate(cels):
        f = os.path.join(tmp, '%02d.png' % k)
        write_png(f, c); files.append(f)
    subprocess.run(['magick', '-dispose', 'background', '-delay', str(delay)] + files +
                   ['-scale', '%d%%' % (scale * 100), '-loop', '0', path], check=True)
    for f in files:
        os.remove(f)


# ---------------------------------------------------------------- scenes ----
W, H, FRAMES, COLS = 160, 120, 24, 6


def sky(img, top, mid, bot, y_mid, y_bot):
    for y in range(H):
        if y <= y_mid:
            t, a, b = y / max(y_mid, 1), top, mid
        else:
            t, a, b = min(1.0, (y - y_mid) / max(y_bot - y_mid, 1)), mid, bot
        for x in range(W):
            img.set(x, y, b if dith(x, y, t) else a)


def ridge(img, base, amp, f1, f2, col, ph=0.0):
    for x in range(W):
        top = base - amp * (0.6 * math.sin(x * f1 + ph) + 0.4 * math.sin(x * f2 + ph * 2.3))
        for y in range(int(top), H):
            img.set(x, y, col)


def static_stars(img, n, seed, ymax):
    rnd = random.Random(seed)
    for _ in range(n):
        img.set(rnd.randrange(W), rnd.randrange(ymax), C(rnd.choice(['grey', 'slate', 'mist'])))


def scene_castle():
    s = Img(W, H)
    sky(s, C('ink'), C('night'), C('stone'), 50, 90)
    static_stars(s, 45, 3, 70)
    s.disc(130, 22, 9, C('sand')); s.disc(127, 20, 2, C('tan')); s.disc(133, 26, 1.5, C('tan')); s.disc(134, 18, 1, C('tan'))
    ridge(s, 86, 6, 0.05, 0.13, C('night'))
    stone, dark, lit = C('stone'), C('night'), C('amber')
    # towers and keep
    for x0, x1, top in ((36, 54, 34), (106, 124, 34), (54, 106, 48)):
        s.rect(x0, top, x1, 100, stone)
        s.rect(x1 - 3, top, x1, 100, dark)
        for mx in range(x0, x1 + 1, 6):  # merlons
            s.rect(mx, top - 4, min(mx + 2, x1), top - 1, stone)
        for y in range(top + 4, 100, 5):  # brick courses
            for x in range(x0 + ((y // 5) % 2) * 3, x1 - 3, 6):
                s.set(x, y, dark)
    for wx, wy in ((44, 46), (114, 46), (62, 58), (97, 58), (44, 62), (114, 62)):
        s.rect(wx, wy, wx + 1, wy + 3, lit); s.set(wx, wy, C('orange'))
    s.rect(70, 72, 90, 100, C('ink')); s.ellipse(80, 72, 10, 7, C('ink'))  # gate
    for x in range(72, 90, 3):
        s.rect(x, 68, x, 92, C('slate'))
    for y in range(72, 93, 4):
        s.rect(71, y, 89, y, C('slate'))
    s.rect(69, 93, 91, 100, C('ink'))
    # ground and path
    for y in range(100, H):
        t = (y - 100) / 20.0
        for x in range(W):
            s.set(x, y, C('pine') if dith(x, y, t * 0.7) else C('deep'))
        hw = 11 + (y - 100) * 1.4
        for x in range(int(80 - hw), int(80 + hw)):
            s.set(x, y, C('slate') if (x + y) % 7 else C('stone'))
    return s


def tree_pine(img, cx, base, h, col):
    for i in range(int(h)):
        y = base - i
        hw = (h - i) * 0.32 * (1.0 if (i % 6) > 1 else 0.8)
        img.rect(cx - hw, y, cx + hw, y, col)


def scene_campfire():
    s = Img(W, H)
    sky(s, C('ink'), C('night'), C('deep'), 40, 80)
    static_stars(s, 30, 9, 50)
    s.disc(28, 18, 6, C('mist')); s.disc(30, 16, 6, C('night'))  # crescent
    for i, cx in enumerate(range(-4, W + 10, 11)):
        tree_pine(s, cx + (i * 37 % 7), 92, 34 + (i * 53 % 17), C('deep'))
    for cx, h in ((6, 90), (152, 95)):
        tree_pine(s, cx, 100, h, C('ink'))
    # ground, lit by the fire around (80, 100)
    for y in range(88, H):
        for x in range(W):
            d = math.hypot((x - 80) / 1.6, (y - 101) * 1.3)
            t = max(0.0, 1 - d / 34.0) * 0.8
            base = C('plum') if dith(x, y, (y - 88) / 40.0) else C('ink')
            c = base
            if t > 0:
                c = C('bark') if dith(x, y, t * 1.2) else base
                if t > 0.55:
                    c = C('dusk') if dith(x, y, (t - 0.55) * 2.2) else C('bark')
            s.set(x, y, c)
    # stones round the fire
    for sx in range(68, 94, 4):
        s.ellipse(sx, 106 - (1 if sx in (72, 88) else 0), 2.2, 1.6, C('grey'))
        s.set(sx - 1, 105, C('mist'))
    # log bench and the owl's tree
    s.rect(24, 98, 52, 102, C('bark')); s.rect(24, 98, 52, 98, C('wood')); s.ellipse(24, 100, 2, 2.5, C('tan'))
    s.rect(129, 8, 134, 100, C('plum')); s.rect(129, 8, 129, 100, C('bark'))
    s.rect(106, 46, 129, 48, C('plum')); s.rect(106, 46, 129, 46, C('bark'))
    s.ellipse(107, 44, 4, 2, C('pine'))
    return s


def scene_waterfall():
    s = Img(W, H)
    sky(s, C('navy'), C('blue'), C('mist'), 30, 70)
    for cx, cy in ((30, 18), (120, 12)):  # clouds
        for dx, r in ((-6, 4), (0, 6), (7, 5), (12, 3)):
            s.disc(cx + dx, cy, r, C('white'))
        s.rect(cx - 9, cy + 2, cx + 14, cy + 4, C('mist'))
    # mountains with snow
    for x in range(W):
        top = 52 - 18 * abs(math.sin(x * 0.035 + 0.6)) - 6 * math.sin(x * 0.11)
        for y in range(int(top), 75):
            s.set(x, y, C('slate') if (x + y) % 9 else C('stone'))
            if y < top + 3 and top < 42:
                s.set(x, y, C('white'))
    # cliffs either side of the falls (x 72..87)
    for x in range(W):
        if 70 <= x <= 89:
            continue
        d = min(abs(x - 70), abs(x - 89))
        top = 26 + d * 0.15 + 3 * math.sin(x * 0.3)
        for y in range(int(top), 96):
            t = (y - top) / 70.0
            c = C('wood') if dith(x, y, t) else C('tan')
            if (x * 3 + y * 5) % 23 == 0 or (x * 7 + y) % 31 == 0:
                c = C('bark')
            s.set(x, y, c)
        s.rect(x, top - 2, x, top + 1, C('lime')); s.set(x, top + 2, C('green'))
    s.rect(70, 26, 89, 94, C('navy'))  # behind the falls
    s.rect(70, 26, 70, 94, C('bark')); s.rect(89, 26, 89, 94, C('bark'))
    # pond and banks
    for y in range(92, H):
        hw = 60 - (y - 92) * 1.2
        for x in range(int(80 - hw), int(80 + hw)):
            s.set(x, y, C('navy') if dith(x, y, (y - 92) / 30.0) else C('blue'))
    for y in range(92, H):
        for x in range(W):
            hw = 60 - (y - 92) * 1.2
            if abs(x - 80) >= hw:
                s.set(x, y, C('green') if dith(x, y, (y - 92) / 28.0) else C('lime'))
    rnd = random.Random(4)
    for _ in range(14):
        x, y = rnd.randrange(W), rnd.randrange(108, H)
        if abs(x - 80) > 60 - (y - 92) * 1.2:
            s.set(x, y, C(rnd.choice(['yellow', 'white', 'pink'])))
    for x in range(30, 130, 9):
        s.rect(x, 97, x + 3, 97, C('cyan'))
    return s


# stamps the scene builder (and the docs) use, cell px of the brush's middle
SCENES = {
    'castle-night': scene_castle,
    'campfire-night': scene_campfire,
    'waterfall-day': scene_waterfall,
}


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else 'animbrush-pack-out'
    for d in ('brushes', 'preview', 'scenes'):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    built = []
    lines = []
    for slot, name, fn, order, step, note in PACK:
        cels = fn()
        built.append((slot, cels))
        w, h = cels[0].w, cels[0].h
        write_png(os.path.join(out, 'brushes', name + '.png'), strip_of(cels), dran(w, h, len(cels)))
        gif_preview(os.path.join(out, 'preview', name + '.gif'), cels, os.path.join(out, 'tmp'),
                    scale=max(3, 48 // max(w, h)), delay=8 if name != 'grass' else 12)
        lines.append('%2d  %-10s %2dx%-3d %2d cels  %-9s  %-26s %s' % (slot, name, w, h, len(cels), order, step, note))
    write_dset(os.path.join(out, 'animbrush-pack.dset'), built)
    open(os.path.join(out, 'pack.txt'), 'w').write('\n'.join(lines) + '\n')
    sheet_w, sheet_h = COLS * W, (FRAMES // COLS) * H
    for name, fn in SCENES.items():
        bg = fn()
        sheet = Img(sheet_w, sheet_h)
        sheet.blit(bg, 0, 0)  # frame 1 only: Layer Same on Every Frame spreads it
        write_png(os.path.join(out, 'scenes', name + '-base.png'), sheet, dran(W, H, FRAMES))
        write_png(os.path.join(out, 'scenes', name + '-bg.png'), bg)
    try:
        os.rmdir(os.path.join(out, 'tmp'))
    except OSError:
        pass
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
