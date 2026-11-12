"""Shared art kit for DRAW's animated example scenes (DEV/animscenes/).

Reuses DEV/animbrush-pack/make-pack.py (Img, the Endesga 32 palette, PNG / drAn / .dset
writers) and adds: ASCII sprites, a scene sheet writer for any frame count, a pack writer,
and a few drawing helpers. Every scene module (scenes/NAME.py) builds:

  OUT/NAME/NAME-pack.dset      its own AnimBrush pack (Drawer brush set, every bin an AnimBrush)
  OUT/NAME/brushes/BRUSH.png   each brush as a strip with a drAn chunk (ANIM > AnimBrush > Load)
  OUT/NAME/preview/BRUSH.gif   4x previews for the docs / field kit
  OUT/NAME/NAME-base.png       the sheet: the background in frame 1 (Layer Same on Every Frame
                               spreads it), drAn = frames / size / fps
  OUT/NAME/NAME-bg.png         the background alone
  OUT/NAME/pack.txt            bin, brush, size, cels, what it is for
"""
import importlib.util, math, os, random, struct, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('make_pack', os.path.join(HERE, '..', 'animbrush-pack', 'make-pack.py'))
_mp = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_mp)

Img, C, mix, dith, E = _mp.Img, _mp.C, _mp.mix, _mp.dith, _mp.E
write_png, png_chunk, strip_of, write_dset, gif_preview, flame = (
    _mp.write_png, _mp.png_chunk, _mp.strip_of, _mp.write_dset, _mp.gif_preview, _mp.flame)
FIRE = _mp.FIRE


def hexc(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def col(name_or_hex, a=255):
    if isinstance(name_or_hex, tuple):
        return name_or_hex
    if name_or_hex in E:
        return C(name_or_hex, a)
    return hexc(name_or_hex.lstrip('#'), a)


def dran(fw, fh, count, fps=12):
    return png_chunk(b'drAn', struct.pack('<10h', 1, fw, fh, 0, 0, count, 1, fps, 0, 0))


# ------------------------------------------------------------- sprites ------
def sprite(rows, cmap, scale=1):
    """ASCII art -> Img. rows: list of equal-length strings; cmap: char -> colour name /
    hex / tuple; '.' and ' ' are transparent."""
    h, w = len(rows), max(len(r) for r in rows)
    s = Img(w * scale, h * scale)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in '. ':
                continue
            c = col(cmap[ch])
            for j in range(scale):
                for i in range(scale):
                    s.set(x * scale + i, y * scale + j, c)
    return s


def pad(img, w, h, ox=None, oy=None):
    """img centred (or at ox, oy) on a w x h canvas."""
    o = Img(w, h)
    o.blit(img, (w - img.w) // 2 if ox is None else ox, (h - img.h) // 2 if oy is None else oy)
    return o


def flip_h(img):
    o = Img(img.w, img.h)
    for y in range(img.h):
        for x in range(img.w):
            o.p[y * img.w + x] = img.p[y * img.w + img.w - 1 - x]
    return o


def recolor(img, a, b):
    o = Img(img.w, img.h)
    o.p = [(col(b) if (p is not None and p[:3] == col(a)[:3]) else p) for p in img.p]
    return o


def same_size(cels):
    w = max(c.w for c in cels); h = max(c.h for c in cels)
    return [c if (c.w, c.h) == (w, h) else pad(c, w, h) for c in cels]


def dots(img, pts, c):
    for x, y in pts:
        img.set(x, y, col(c))


def vgrad(img, x0, y0, x1, y1, stops):
    """Vertical dithered gradient through colour stops (list of names)."""
    n = len(stops) - 1
    for y in range(int(y0), int(y1) + 1):
        t = (y - y0) / max(1, (y1 - y0)) * n
        k = min(n - 1, int(t)); f = t - k
        for x in range(int(x0), int(x1) + 1):
            img.set(x, y, col(stops[k + 1]) if dith(x, y, f) else col(stops[k]))


def ring(img, cx, cy, r, c, th=1.0):
    for y in range(int(cy - r - 2), int(cy + r + 3)):
        for x in range(int(cx - r - 2), int(cx + r + 3)):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if abs(d - r) <= th * 0.5:
                img.set(x, y, col(c))


# ------------------------------------------------------------- outputs ------
class Scene:
    def __init__(s, name, out, w=160, h=120, frames=48, cols=8, fps=12):
        s.name, s.w, s.h, s.frames, s.cols, s.fps = name, w, h, frames, cols, fps
        s.dir = os.path.join(out, name)
        for d in ('brushes', 'preview'):
            os.makedirs(os.path.join(s.dir, d), exist_ok=True)
        s.pack = []    # (slot, name, cels, note)

    def brush(s, slot, name, cels, note=''):
        cels = same_size(cels)
        s.pack.append((slot, name, cels, note))

    def write_pack(s):
        lines = []
        for slot, name, cels, note in s.pack:
            w, h = cels[0].w, cels[0].h
            write_png(os.path.join(s.dir, 'brushes', name + '.png'), strip_of(cels), dran(w, h, len(cels)))
            gif_preview(os.path.join(s.dir, 'preview', name + '.gif'), cels, os.path.join(s.dir, 'tmp'),
                        scale=max(3, 64 // max(w, h)), delay=8)
            lines.append('%2d  %-12s %3dx%-3d %2d cels  %s' % (slot, name, w, h, len(cels), note))
        write_dset(os.path.join(s.dir, s.name + '-pack.dset'), [(sl, c) for sl, _, c, _ in s.pack])
        open(os.path.join(s.dir, 'pack.txt'), 'w').write('\n'.join(lines) + '\n')
        try:
            os.rmdir(os.path.join(s.dir, 'tmp'))
        except OSError:
            pass
        return lines

    def write_base(s, bg, every=None):
        """The sheet: bg in frame 1 (the driver spreads it with Layer Same on Every Frame).
        every: optional fn(frame0, Img) drawing per-frame extras into a frame's cell."""
        rows = (s.frames + s.cols - 1) // s.cols
        sheet = Img(s.cols * s.w, rows * s.h)
        sheet.blit(bg, 0, 0)
        write_png(os.path.join(s.dir, s.name + '-base.png'), sheet, dran(s.w, s.h, s.frames, s.fps))
        write_png(os.path.join(s.dir, s.name + '-bg.png'), bg)

    def write_sheet(s, fname, cells):
        """A sheet with per-frame content (a list of Img, one per frame) - e.g. a layer
        drawn in Python that the driver opens as its own document."""
        rows = (s.frames + s.cols - 1) // s.cols
        sheet = Img(s.cols * s.w, rows * s.h)
        for f, c in enumerate(cells):
            sheet.blit(c, (f % s.cols) * s.w, (f // s.cols) * s.h)
        write_png(os.path.join(s.dir, fname), sheet, dran(s.w, s.h, s.frames, s.fps))

    def seconds(s):
        return s.frames / float(s.fps)

    def t(s, frame):  # frame (1-based) -> seconds from the start
        return (frame - 1) / float(s.fps)


def pixel_of(img, x, y):
    p = img.get(x, y)
    return '%02x%02x%02x' % p[:3] if p else None
