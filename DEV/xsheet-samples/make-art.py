#!/usr/bin/env python3
"""DEV/xsheet-samples/make-art.py OUT - the art for the X-sheet holds + lanes examples
(SAMPLES/XSHEET/), written as Aseprite files DRAW opens with layers, groups and linked cels
(a linked run = a per-layer hold). The motion is NOT drawn: build.sh opens each in DRAW and
adds the keyframe lanes on the X-sheet the way a user would (drive.sh).

  bounce   - a ball drawn once, held all 12 frames; Y / SCALE X / SCALE Y / PIVOT Y lanes
  parallax - sky held; group "scenery" (hills, trees) drifting by its own X lane, the trees
             faster (their own X on top); a two-drawing bird flapping (holds) moved by X and
             bobbed by a Y modulator
  title    - background held; group "card" (plate, star) faded in and out by the group's
             OPACITY; the star spun by ROTATE and grown by SCALE; the plate flickering by a
             TINT noise modulator
"""
import math, os, struct, sys, zlib

FW = FH = 32
NF = 12


def chunk(ctype, data): return struct.pack('<IH', 6 + len(data), ctype) + data


def layer(name, kind=0, level=0, flags=3):  # kind 0 image, 1 group; flags 1 visible + 2 editable
    n = name.encode()
    return chunk(0x2004, struct.pack('<HHHHHHB3s', flags, kind, level, 0, 0, 0, 255, b'\0' * 3) + struct.pack('<H', len(n)) + n)


def cel(li, img):
    return chunk(0x2005, struct.pack('<HhhBHh5s', li, 0, 0, 255, 2, 0, b'\0' * 5) + struct.pack('<HH', FW, FH) + zlib.compress(bytes(img)))


def linked(li, frame0):  # frame0: the 0-based frame whose cel this one shows
    return chunk(0x2005, struct.pack('<HhhBHh5s', li, 0, 0, 255, 1, 0, b'\0' * 5) + struct.pack('<H', frame0))


def frame(chunks, dur=83):
    body = b''.join(chunks)
    return struct.pack('<IHHH2sI', 16 + len(body), 0xF1FA, len(chunks), dur, b'\0\0', len(chunks)) + body


def write_ase(path, layers, cels):
    """layers: [(name, kind, level)] bottom first; cels[f] = list of (layer index, img or int frame0)."""
    frames = []
    for f in range(NF):
        ch = [layer(*L) for L in layers] if f == 0 else []
        for li, c in cels[f]:
            ch.append(linked(li, c) if isinstance(c, int) else cel(li, c))
        frames.append(frame(ch))
    body = b''.join(frames)
    hdr = struct.pack('<IHHHHHIHII', 128 + len(body), 0xA5E0, NF, FW, FH, 32, 1, 83, 0, 0)
    hdr += struct.pack('<B3sH', 0, b'\0' * 3, 0) + struct.pack('<BBhhHH', 1, 1, 0, 0, 0, 0)
    hdr += b'\0' * (128 - len(hdr))
    open(path, 'wb').write(hdr + body)


# --- tiny raster helpers (RGBA lists FW x FH) ---
def blank(): return [0] * (FW * FH * 4)


def px(img, x, y, c):
    if 0 <= x < FW and 0 <= y < FH:
        o = (y * FW + x) * 4
        img[o:o + 4] = list(c) + ([255] if len(c) == 3 else [])


def rect(img, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(img, x, y, c)


def disc(img, cx, cy, r, c, shade=None):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            d = math.hypot(x + .5 - cx, y + .5 - cy)
            if d <= r:
                col = c
                if shade and (x + .5 - cx) + (y + .5 - cy) > r * .6:
                    col = shade
                px(img, x, y, col)


def build_bounce(out):
    floor = blank()
    rect(floor, 0, 29, FW - 1, 31, (70, 52, 40))
    rect(floor, 0, 29, FW - 1, 29, (120, 92, 64))
    ball = blank()
    disc(ball, 16, 23.5, 5, (230, 60, 60), shade=(160, 30, 40))
    px(ball, 14, 20, (255, 210, 210)); px(ball, 15, 20, (255, 210, 210)); px(ball, 14, 21, (255, 210, 210))
    layers = [('floor', 0, 0), ('ball', 0, 0)]
    cels = [[(0, floor), (1, ball)]] + [[(0, 0), (1, 0)] for _ in range(NF - 1)]
    write_ase(os.path.join(out, 'bounce.aseprite'), layers, cels)


def build_parallax(out):
    sky = blank()
    for y in range(FH):
        t = y / (FH - 1)
        rect(sky, 0, y, FW - 1, y, (int(90 + 80 * t), int(140 + 60 * t), int(220 - 20 * t)))
    disc(sky, 25, 6, 3, (255, 236, 160))
    hills = blank()
    for x in range(4, 28):  # a mound clear of the cell's edges: it drifts left without a gap
        h = int(9 * math.sin((x - 4) / 24 * math.pi))
        rect(hills, x, 30 - h, x, 31, (70, 140, 80))
    trees = blank()
    for tx in (8, 17, 26):
        rect(trees, tx, 25, tx, 31, (90, 60, 40))
        disc(trees, tx + .5, 23, 3, (40, 110, 60), shade=(30, 80, 45))
    up = blank(); down = blank()
    for b, wing in ((up, -2), (down, 2)):
        rect(b, 15, 10, 17, 11, (40, 40, 50))
        px(b, 13, 10 + wing // 2, (40, 40, 50)); px(b, 14, 10 + wing // 2, (40, 40, 50))
        px(b, 18, 10 + wing // 2, (40, 40, 50)); px(b, 19, 10 + wing // 2, (40, 40, 50))
        px(b, 12, 10 + wing, (40, 40, 50)); px(b, 20, 10 + wing, (40, 40, 50))
        px(b, 18, 9, (240, 180, 60))
    # bottom first: sky, scenery (group: hills, trees), bird
    layers = [('sky', 0, 0), ('scenery', 1, 0), ('hills', 0, 1), ('trees', 0, 1), ('bird', 0, 0)]
    cels = []
    for f in range(NF):
        if f == 0:
            row = [(0, sky), (2, hills), (3, trees), (4, up)]
        elif f == 1:
            row = [(0, 0), (2, 0), (3, 0), (4, down)]
        else:  # the bird flaps: up on odd frames, down on even (two drawings, held / linked)
            row = [(0, 0), (2, 0), (3, 0), (4, 0 if f % 2 == 0 else 1)]
        cels.append(row)
    write_ase(os.path.join(out, 'parallax.aseprite'), layers, cels)


def build_title(out):
    bg = blank()
    for y in range(FH):
        for x in range(FW):
            v = 24 + ((x // 4 + y // 4) % 2) * 8
            px(bg, x, y, (v, v, v + 16))
    plate = blank()
    rect(plate, 4, 9, 27, 22, (60, 70, 160))
    rect(plate, 5, 8, 26, 23, (60, 70, 160))
    rect(plate, 5, 9, 26, 9, (110, 120, 220))
    star = blank()
    cx, cy = 16, 16
    for y in range(FH):
        for x in range(FW):
            dx, dy = x + .5 - cx, y + .5 - cy
            a = math.atan2(dy, dx); r = math.hypot(dx, dy)
            lim = 4 + 3 * (0.5 + 0.5 * math.cos(5 * a))
            if r <= lim:
                px(star, x, y, (255, 220, 70) if r < lim - 1.2 else (230, 150, 30))
    # bottom first: bg, card (group: plate, star)
    layers = [('bg', 0, 0), ('card', 1, 0), ('plate', 0, 1), ('star', 0, 1)]
    cels = [[(0, bg), (2, plate), (3, star)]] + [[(0, 0), (2, 0), (3, 0)] for _ in range(NF - 1)]
    write_ase(os.path.join(out, 'title.aseprite'), layers, cels)


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    build_bounce(out); build_parallax(out); build_title(out)
    print('wrote', ', '.join(n + '.aseprite' for n in ('bounce', 'parallax', 'title')), 'in', out)
