#!/usr/bin/env python3
"""
make-command-icons.py - draw command button icons from ASCII-art glyphs, in the
look of each theme's own toolbox / bar icons. Pure Python (zlib only), no PIL.

For each theme it writes
    ASSETS/THEMES/<theme>/IMAGES/COMMANDS/TOOLBOX/<name>.png   11x11 (toolbox frame + glyph)
    ASSETS/THEMES/<theme>/IMAGES/COMMANDS/<name>.png           16x16 (transparent + glyph)
<name> is the command's file name from PLANS/_/COMMAND-ICONS.csv (its slug) or cmd-<id>.

THE LOOK is sampled from the theme, not hard coded:
  - 11x11: frame, bevel and face are copied from IMAGES/TOOLBOX/<--ref11> (marquee-rect.png:
    no group-corner marker); the ink is the most common non-face colour of its glyph area.
  - 16x16: the ink is the one opaque colour of IMAGES/EDITBAR/<--ref16> (eb-copy.png).
  So rerunning this gives a new theme matching icons.

SPECS: every *.txt in DEV/tools/command-icons/ (or --spec FILE|DIR, repeatable).

    [name]                    an icon to write
    [@name]                   a shared piece (picture or badge): only used, never written
    # comment                 (outside a grid; a trailing "  # ..." on a directive is a comment too)
    11:                       a literal grid; the 11px face is 9x9, keep pictures 7x7 (2px clear)
    ..###..
    ...                       a blank line ends a grid
    16:                       16x16 canvas; keep pictures about 10x10 (3px clear)
    about: what the picture shows (for the work list / review kit; repeatable, joined)
    use: @piece               start from a piece (both sizes; a literal grid of a size wins)
    flip: h | v               mirror the picture so far
    rot: 90 | 180 | 270       turn it clockwise
    badge: @piece [pos] [11|16] [noring]
                              stamp a small piece (its 11: ~3x3, 16: ~5x5) at pos, clearing a 1px
                              ring round it; pos br (default) bl tr tl t b l r c
    text: PNG [pos] [11|16|both]
                              tiny 3x5 letters A-Z 0-9 % + - . / ? ! ( ) : x ( _ = gap ), placed like a
                              badge with a ring; default pos b, size 16

  Glyph chars: '#' ink, '+' half tone (11: between ink and face; 16: ink at 50% alpha),
  '.' background. Pictures are centred; a size with no grid falls back to the other's.
  Directives run in file order after the base grid / use:.

  DEV/tools/make-command-icons.py --write                  # write every icon, DEFAULT + DARK
      (never replaces a PNG it did not make or that was edited since - see written.json;
       --force overrides. Refuses names of commands that already have art: use cmd-<id>.
       Reviewed icons are installed with DEV/tools/command-icons-kit.py --install instead.)
  DEV/tools/make-command-icons.py --write --only 'annotate-*,capture-screen'
  DEV/tools/make-command-icons.py --only-from DEV/tools/command-icons/view.txt --dry-run --preview v.png
  DEV/tools/make-command-icons.py --themes DEFAULT
  DEV/tools/make-command-icons.py --missing                # commands with a text tile and no spec yet
  DEV/tools/make-command-icons.py --list

The preview sheet numbers each icon (its index is printed) and shows the 11 and 16 at
--scale plus a 1x copy; --cols sets icons per row, --preview-themes which themes show.
"""
import argparse, csv, fnmatch, glob, os, struct, sys, zlib
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
THEMES = os.path.join(ROOT, "ASSETS", "THEMES")
DEFAULT_SPEC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "command-icons")
CSV_PATH = os.path.join(ROOT, "PLANS", "_", "COMMAND-ICONS.csv")


# ---------------------------------------------------------------- PNG I/O ----
def png_read(path):
    """-> (w, h, rows) with rows[y][x] = (r, g, b, a). 8-bit gray/RGB/palette/GA/RGBA, non-interlaced."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(path + ": not a PNG")
    pos, idat, plte, trns = 8, b"", None, None
    while pos < len(data):
        ln, typ = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + ln]
        pos += 12 + ln
        if typ == b"IHDR":
            w, h, depth, ctype, _, _, interlace = struct.unpack(">IIBBBBB", body)
        elif typ == b"PLTE":
            plte = [tuple(body[i:i + 3]) for i in range(0, len(body), 3)]
        elif typ == b"tRNS":
            trns = body
        elif typ == b"IDAT":
            idat += body
        elif typ == b"IEND":
            break
    if depth != 8 or interlace:
        raise ValueError("%s: only 8-bit non-interlaced PNGs are supported" % path)
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    raw, stride, prev, rows, i = zlib.decompress(idat), w * bpp, bytearray(w * bpp), [], 0
    for _ in range(h):
        ft, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if ft == 1: line[x] = (line[x] + a) & 255
            elif ft == 2: line[x] = (line[x] + b) & 255
            elif ft == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif ft == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        prev = line
        row = []
        for x in range(w):
            px = line[x * bpp:(x + 1) * bpp]
            if ctype == 0: row.append((px[0], px[0], px[0], 255))
            elif ctype == 2: row.append((px[0], px[1], px[2], 255))
            elif ctype == 3:
                r, g, b = plte[px[0]]
                row.append((r, g, b, trns[px[0]] if trns and px[0] < len(trns) else 255))
            elif ctype == 4: row.append((px[0], px[0], px[0], px[1]))
            else: row.append(tuple(px))
        rows.append(row)
    return w, h, rows


def png_write(path, rows):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "wb") as f:
        f.write(png_bytes(rows))


def png_bytes(rows):
    h, w = len(rows), len(rows[0])
    raw = b"".join(b"\x00" + bytes(c for px in row for c in px) for row in rows)

    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b) & 0xFFFFFFFF)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# --------------------------------------------------------------- the font ----
FONT_ROWS = """
A .#. #.# ### #.# #.#   B ##. #.# ##. #.# ##.   C .## #.. #.. #.. .##   D ##. #.# #.# #.# ##.
E ### #.. ##. #.. ###   F ### #.. ##. #.. #..   G .## #.. #.# #.# .##   H #.# #.# ### #.# #.#
I ### .#. .#. .#. ###   J ..# ..# ..# #.# .#.   K #.# #.# ##. #.# #.#   L #.. #.. #.. #.. ###
M #.# ### ### #.# #.#   N ##. #.# #.# #.# #.#   O .#. #.# #.# #.# .#.   P ##. #.# ##. #.. #..
Q .#. #.# #.# #.# .##   R ##. #.# ##. #.# #.#   S .## #.. .#. ..# ##.   T ### .#. .#. .#. .#.
U #.# #.# #.# #.# ###   V #.# #.# #.# #.# .#.   W #.# #.# ### ### #.#   X #.# #.# .#. #.# #.#
Y #.# #.# .#. .#. .#.   Z ### ..# .#. #.. ###   0 ### #.# #.# #.# ###   1 .#. ##. .#. .#. ###
2 ##. ..# .#. #.. ###   3 ##. ..# .#. ..# ##.   4 #.# #.# ### ..# ..#   5 ### #.. ##. ..# ##.
6 .## #.. ### #.# ###   7 ### ..# .#. .#. .#.   8 ### #.# ### #.# ###   9 ### #.# ### ..# ##.
% #.# ..# .#. #.. #.#   + ... .#. ### .#. ...   - ... ... ### ... ...   . ... ... ... ... .#.
/ ..# ..# .#. #.. #..   ? ##. ..# .#. ... .#.   ! .#. .#. .#. ... .#.   _ ... ... ... ... ...
( .#. #.. #.. #.. .#.   ) .#. ..# ..# ..# .#.   x ... #.# .#. #.# ...   : ... .#. ... .#. ...
"""
FONT = {}
for _tok in [t for t in FONT_ROWS.split("   ")]:
    _p = _tok.split()
    for _i in range(0, len(_p), 6):
        FONT[_p[_i]] = _p[_i + 1:_i + 6]


def font_rows(ch):
    g = FONT.get(ch)
    if g is None or len(g) != 5:
        sys.exit("text: no 3x5 glyph for %r" % ch)
    return g


def text_grid(txt):
    rows = ["" for _ in range(5)]
    for i, ch in enumerate(txt):
        g = font_rows(ch.upper() if ch.isalpha() and ch != "x" else ch)
        for y in range(5):
            rows[y] += ("." if i else "") + g[y]
    return rows


# --------------------------------------------------------------- the spec ----
DIRECTIVES = ("use", "flip", "rot", "badge", "text", "about")


def spec_files(paths):
    out = []
    for p in paths:
        if os.path.isdir(p):
            out += sorted(glob.glob(os.path.join(p, "*.txt")))
        elif os.path.isfile(p):
            out.append(p)
        else:
            sys.exit("no spec file or folder: " + p)
    return out


def read_specs(files):
    """-> {name: {'11': rows, '16': rows, 'ops': [(key, args)], 'file': path, 'line': n}}"""
    entries = {}
    for path in files:
        name, size = None, None
        with open(path) as f:
            for n, line in enumerate(f, 1):
                t = line.strip()
                if size and t == "":
                    size = None
                    continue
                if size and (t.startswith("[") or t.startswith("#") and not set(t) <= set("#+.")
                             or t.partition(":")[0].strip().lower() in DIRECTIVES + ("11", "16")):
                    size = None  # a header / directive / comment also ends a grid
                if size:
                    if not set(t) <= set("#+."):
                        sys.exit("%s:%d: a glyph row may only hold # + ." % (path, n))
                    entries[name][size].append(t)
                    continue
                if t == "" or t.startswith("#"):
                    continue
                if t.startswith("[") and t.endswith("]"):
                    name = t[1:-1].strip()
                    if name in entries:
                        e = entries[name]
                        sys.exit("%s:%d: [%s] is also defined at %s:%d" % (path, n, name, e["file"], e["line"]))
                    entries[name] = {"ops": [], "file": path, "line": n}
                    continue
                if name is None:
                    sys.exit("%s:%d: text before any [name]" % (path, n))
                if t in ("11:", "16:"):
                    size = t[:2]
                    entries[name][size] = []
                    continue
                key, sep, val = t.partition(":")
                key = key.strip().lower()
                if not sep or key not in DIRECTIVES:
                    sys.exit("%s:%d: expected 11: / 16: / %s: - got %r" % (path, n, " / ".join(DIRECTIVES), t))
                if key == "about":
                    entries[name]["about"] = (entries[name].get("about", "") + " " + val.strip()).strip()
                    continue
                val = val.split("  #")[0].strip()
                entries[name]["ops"].append((key, val.split(), "%s:%d" % (path, n)))
    for nm, e in entries.items():
        for sz in ("11", "16"):
            rows = e.get(sz)
            if rows is None:
                continue
            if not rows:
                sys.exit("%s:%d [%s] %s: empty grid" % (e["file"], e["line"], nm, sz))
            if len({len(r) for r in rows}) > 1:
                sys.exit("%s:%d [%s] %s: rows differ in length" % (e["file"], e["line"], nm, sz))
            lim = 9 if sz == "11" else 16
            if len(rows) > lim or len(rows[0]) > lim:
                sys.exit("%s:%d [%s] %s: grid is %dx%d, max %dx%d" % (e["file"], e["line"], nm, sz, len(rows[0]), len(rows), lim, lim))
    return entries


# ------------------------------------------------------------ composition ----
CANVAS = {"11": 9, "16": 16}
MARGIN = {"11": 0, "16": 1}


def blank(n):
    return [["."] * n for _ in range(n)]


def put_centred(canvas, grid):
    n = len(canvas)
    gh, gw = len(grid), len(grid[0])
    ox, oy = (n - gw) // 2, (n - gh) // 2
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch != ".":
                canvas[oy + y][ox + x] = ch


def place(canvas, grid, pos, size, ring, where):
    n, m = len(canvas), MARGIN[size]
    gh, gw = len(grid), len(grid[0])
    if gw > n - 2 * m or gh > n - 2 * m:
        sys.exit("%s: %dx%d does not fit the %spx canvas" % (where, gw, gh, size))
    xs = {"l": m, "c": (n - gw) // 2, "r": n - m - gw}
    ys = {"t": m, "c": (n - gh) // 2, "b": n - m - gh}
    P = {"br": ("r", "b"), "bl": ("l", "b"), "tr": ("r", "t"), "tl": ("l", "t"),
         "t": ("c", "t"), "b": ("c", "b"), "l": ("l", "c"), "r": ("r", "c"), "c": ("c", "c")}
    if pos not in P:
        sys.exit("%s: unknown position %r (br bl tr tl t b l r c)" % (where, pos))
    ox, oy = xs[P[pos][0]], ys[P[pos][1]]
    if ring:  # clear the 1px neighbourhood of the stamped pixels
        for y, row in enumerate(grid):
            for x, ch in enumerate(row):
                if ch == ".":
                    continue
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        X, Y = ox + x + dx, oy + y + dy
                        if 0 <= X < n and 0 <= Y < n:
                            canvas[Y][X] = "."
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch != ".":
                canvas[oy + y][ox + x] = ch


def transform(canvas, op, arg, where):
    if op == "flip":
        if arg == "h":
            return [row[::-1] for row in canvas]
        if arg == "v":
            return canvas[::-1]
        sys.exit("%s: flip: h or v" % where)
    turns = {"90": 1, "180": 2, "270": 3}.get(arg)
    if turns is None:
        sys.exit("%s: rot: 90, 180 or 270" % where)
    for _ in range(turns):
        canvas = [list(r) for r in zip(*canvas[::-1])]
    return canvas


def compose(entries, name, size, stack=()):
    """-> a CANVAS[size] square of chars, or None when the entry has nothing for this size.
    The base is this size's literal grid, else the first use:, else (16px) the 11: grid;
    then flip / rot / badge / text run in order. A base-less entry with a badge / text
    for this size starts from a blank canvas."""
    if name in stack:
        sys.exit("use: loop through " + " -> ".join(stack + (name,)))
    e = entries.get(name)
    if e is None:
        sys.exit("no piece [%s]" % name)
    ops = e["ops"]
    canvas = None
    if size in e:
        canvas = blank(CANVAS[size])
        put_centred(canvas, e[size])
    else:
        use = next((args for k, args, _ in ops if k == "use"), None)
        if use:
            canvas = compose(entries, use[0], size, stack + (name,))
        elif size == "16" and "11" in e:
            canvas = blank(16)
            put_centred(canvas, e["11"])
    for key, args, where in ops:
        if key == "use":
            continue
        if key in ("badge", "text"):
            allow = ("11", "16", "both") if key == "text" else ("11", "16")
            sizes = [x for x in args[1:] if x in allow] or (["16"] if key == "text" else ["11", "16"])
            if "both" in sizes:
                sizes = ["11", "16"]
            if size not in sizes:
                continue
            if canvas is None:
                canvas = blank(CANVAS[size])
            pos = next((x for x in args[1:] if x not in allow + ("noring",)), "b" if key == "text" else "br")
            if key == "text":
                if not args:
                    sys.exit("%s: text: needs letters" % where)
                g = text_grid(args[0])
            else:
                piece = entries.get(args[0]) if args else None
                if piece is None:
                    sys.exit("%s: no piece [%s]" % (where, args[0] if args else ""))
                g = piece.get(size)
                if g is None:
                    sub = compose(entries, args[0], size, stack + (name,))
                    if sub is None:
                        continue
                    g = trim(sub)
            place(canvas, g, pos, size, "noring" not in args, where)
        elif canvas is not None:
            canvas = transform(canvas, key, args[0] if args else "", where)
    return canvas


def trim(canvas):
    ys = [y for y, r in enumerate(canvas) if any(c != "." for c in r)]
    xs = [x for x in range(len(canvas[0])) if any(r[x] != "." for r in canvas)]
    if not ys:
        return ["."]
    return ["".join(canvas[y][xs[0]:xs[-1] + 1]) for y in range(ys[0], ys[-1] + 1)]


# -------------------------------------------------------------- the style ----
def mix(a, b, t=0.5):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(4))


def theme_style(theme, ref11, ref16):
    def find(sub, nm):
        for th in (theme, "DEFAULT"):
            p = os.path.join(THEMES, th, "IMAGES", sub, nm)
            if os.path.isfile(p):
                return p
        sys.exit("no reference icon %s/%s in %s or DEFAULT" % (sub, nm, theme))
    w, h, frame = png_read(find("TOOLBOX", ref11))
    if (w, h) != (11, 11):
        sys.exit("%s: toolbox reference must be 11x11" % ref11)
    face = frame[1][1]
    ink11 = Counter(frame[y][x] for y in range(2, 9) for x in range(2, 9) if frame[y][x] != face)
    if not ink11:
        sys.exit("%s: no glyph pixels to take the ink colour from" % ref11)
    ink11 = ink11.most_common(1)[0][0]
    blank11 = [row[:] for row in frame]
    for y in range(1, 10):
        for x in range(1, 10):
            blank11[y][x] = face
    _, _, bar = png_read(find("EDITBAR", ref16))
    ink16 = Counter(px for row in bar for px in row if px[3] == 255)
    ink16 = ink16.most_common(1)[0][0] if ink16 else (202, 202, 202, 255)
    bar_bg = (16, 16, 16, 255)  # preview only: the bar face 16px icons sit on (THEME.CFG)
    for th in (theme, "DEFAULT"):
        cfg = os.path.join(THEMES, th, "THEME.CFG")
        if os.path.isfile(cfg):
            for ln in open(cfg, errors="replace"):
                k, _, v = ln.partition("=")
                if k.strip() == "EDIT_BAR_BG_COLOR":
                    try:
                        bar_bg = tuple(int(c) for c in v.split("'")[0].split(",")[:3]) + (255,)
                    except ValueError:
                        pass
            break
    return {"blank11": blank11, "face": face, "ink11": ink11, "ink16": ink16, "bar_bg": bar_bg}


def render11(style, canvas):
    img = [row[:] for row in style["blank11"]]
    col = {"#": style["ink11"], "+": mix(style["face"], style["ink11"])}
    for y in range(9):
        for x in range(9):
            if canvas[y][x] in col:
                img[y + 1][x + 1] = col[canvas[y][x]]
    return img


def render16(style, canvas):
    ink = style["ink16"]
    col = {"#": ink, "+": ink[:3] + (128,)}
    return [[col.get(ch, (0, 0, 0, 0)) for ch in row] for row in canvas]


# ------------------------------------------------------------ the preview ----
def contact_sheet(path, groups, scale, cols):
    """groups: list of (label, [(img, bg), ...]). Each group: number, the images at scale, 1x copies."""
    gap = 2 * scale
    cell = 16 * scale
    per = max(len(g[1]) for g in groups)
    gw = per * (cell + scale) + 20
    gh = 12 + cell + 4 + 16
    ncol = min(cols, len(groups))
    W = gap + ncol * (gw + gap)
    H = gap + ((len(groups) + ncol - 1) // ncol) * (gh + gap)
    sheet = [[(56, 56, 56, 255)] * W for _ in range(H)]

    def put(x0, y0, im, bg, sc):
        for y in range(len(im) * sc):
            for x in range(len(im[0]) * sc):
                px = im[y // sc][x // sc]
                a = px[3] / 255
                sheet[y0 + y][x0 + x] = tuple(round(px[i] * a + bg[i] * (1 - a)) for i in range(3)) + (255,)

    for gi, (label, cells) in enumerate(groups):
        gx = gap + (gi % ncol) * (gw + gap)
        gy = gap + (gi // ncol) * (gh + gap)
        lab = text_grid(str(label))
        for y, row in enumerate(lab):
            for x, ch in enumerate(row):
                if ch == "#":
                    for dy in range(2):
                        for dx in range(2):
                            sheet[gy + y * 2 + dy][gx + x * 2 + dx] = (230, 200, 90, 255)
        x = gx
        for im, bg in cells:
            if im:
                put(x, gy + 12, im, bg, scale)
                put(gx + (x - gx) // (cell + scale) * 18, gy + 12 + cell + 4, im, bg, 1)
            x += cell + scale
    png_write(path, sheet)


# ------------------------------------------------------------------- main ----
def csv_rows():
    if not os.path.isfile(CSV_PATH):
        return []
    with open(CSV_PATH, newline="") as f:
        return list(csv.DictReader(f))


MANIFEST = os.path.join(DEFAULT_SPEC, "written.json")


class Writer:
    """Writes icon PNGs without clobbering art it did not make.

    written.json (next to the specs) records the sha1 of every file these scripts
    wrote. A target is written when it is absent, or present with exactly the bytes
    recorded for it (ours, untouched since). A file with no record, or edited since,
    is KEPT and reported - unless force. Same bytes already there = nothing to do."""

    def __init__(self, force=False):
        import hashlib, json
        self.h, self.json, self.force = hashlib, json, force
        try:
            self.m = json.load(open(MANIFEST))
        except (OSError, ValueError):
            self.m = {}
        self.wrote, self.same, self.kept = 0, 0, []

    def write(self, path, data):
        rel = os.path.relpath(path, ROOT)
        new = self.h.sha1(data).hexdigest()
        if os.path.exists(path):
            cur = self.h.sha1(open(path, "rb").read()).hexdigest()
            if cur == new:
                self.m[rel] = new
                self.same += 1
                return
            if self.m.get(rel) != cur and not self.force:
                self.kept.append(rel)
                return
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)
        self.m[rel] = new
        self.wrote += 1

    def close(self):
        with open(MANIFEST, "w") as f:
            self.json.dump(dict(sorted(self.m.items())), f, indent=0)
        msg = "wrote %d, unchanged %d" % (self.wrote, self.same)
        if self.kept:
            msg += ", KEPT %d existing file(s) not made by this script or edited since (--force to replace):\n  " % len(self.kept)
            msg += "\n  ".join(self.kept)
        print(msg)


def art_taken(rows):
    """{file stem: 'command (id)'} for names that already belong to a command WITH art -
    a command icon there would also show for that command."""
    out = {}
    for r in rows:
        if r.get("art_now", "tile") != "tile":
            out[r["file_name"][:-4]] = "%s (#%s, %s)" % (r["command"], r["action_id"], r["art_now"])
    return out


def check_names(names, rows):
    taken = art_taken(rows)
    bad = [n for n in names if n in taken]
    if bad:
        sys.exit("refusing: these names belong to a command that already has art - name the icon\n"
                 "cmd-<action id> instead:\n  " + "\n  ".join("%s -> %s" % (n, taken[n]) for n in bad))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--spec", action="append", help="spec file or folder (repeatable; default DEV/tools/command-icons/)")
    ap.add_argument("--themes", default="DEFAULT,DARK", help="comma list (default DEFAULT,DARK)")
    ap.add_argument("--only", help="comma list of names or globs")
    ap.add_argument("--only-from", action="append", help="only the icons defined in this spec file (repeatable)")
    ap.add_argument("--ref11", default="marquee-rect.png", help="IMAGES/TOOLBOX icon to copy the frame from")
    ap.add_argument("--ref16", default="eb-copy.png", help="IMAGES/EDITBAR icon to take the bar ink from")
    ap.add_argument("--preview", help="write a numbered contact sheet PNG here")
    ap.add_argument("--preview-themes", help="themes on the sheet (default: the first of --themes)")
    ap.add_argument("--scale", type=int, default=6, help="preview zoom (default 6)")
    ap.add_argument("--cols", type=int, default=6, help="preview icons per row (default 6)")
    ap.add_argument("--write", action="store_true", help="write the icon PNGs into the themes (default: write nothing)")
    ap.add_argument("--force", action="store_true", help="with --write: also replace files not made by this script / edited since")
    ap.add_argument("--dry-run", action="store_true", help="write no icon files (the default; kept for old command lines)")
    ap.add_argument("--list", action="store_true", help="print the icon names in the specs")
    ap.add_argument("--pieces", action="store_true", help="work on the shared [@pieces] instead (preview only, never written)")
    ap.add_argument("--json", help="write {name: {about, file, line}} for the selected icons here")
    ap.add_argument("--missing", action="store_true", help="commands still on a text tile with no spec entry")
    a = ap.parse_args()

    entries = read_specs(spec_files(a.spec or [DEFAULT_SPEC]))
    icons = [n for n in entries if not n.startswith("@")]
    rows = csv_rows()
    known = {r["file_name"][:-4] for r in rows} | {"cmd-" + r["action_id"] for r in rows}
    if rows:
        for n in icons:
            if n not in known:
                print("warning: [%s] (%s:%d) is no command's file name in %s" % (
                    n, os.path.relpath(entries[n]["file"], ROOT), entries[n]["line"], os.path.relpath(CSV_PATH, ROOT)), file=sys.stderr)
    if a.missing:
        have = set(icons)
        seen = set()
        for r in rows:
            nm = r["file_name"][:-4]
            if r["art_now"] == "tile" and nm not in have and "cmd-" + r["action_id"] not in have and nm not in seen:
                seen.add(nm)
                print("%s\t%s\t%s\t%s" % (r["action_id"], r["category"], nm, r["command"]))
        print("%d missing" % len(seen), file=sys.stderr)
        return
    if a.list:
        for n in icons:
            print(n)
        return
    names = icons
    if a.pieces:
        names, a.write = [n for n in entries if n.startswith("@")], False
    if a.only_from:
        allowed = set()
        for f in a.only_from:
            allowed |= set(read_specs([f]))
        names = [n for n in names if n in allowed]
    if a.only:
        pats = [s.strip() for s in a.only.split(",") if s.strip()]
        names = [n for n in names if any(fnmatch.fnmatchcase(n, p) for p in pats)]
        if not names:
            sys.exit("--only matched nothing")
    if a.json:
        import json
        with open(a.json, "w") as f:
            json.dump({n: {"about": entries[n].get("about", ""), "file": os.path.relpath(entries[n]["file"], ROOT),
                           "line": entries[n]["line"]} for n in names}, f, indent=1)
    themes = [t.strip() for t in a.themes.split(",") if t.strip()]
    pthemes = [t.strip() for t in (a.preview_themes or themes[0]).split(",") if t.strip()]
    styles = {t: theme_style(t, a.ref11, a.ref16) for t in set(themes) | set(pthemes)}

    if a.dry_run:
        a.write = False
    if a.write:
        check_names(names, rows)
    wr = Writer(a.force) if a.write else None
    groups = []
    for i, nm in enumerate(names, 1):
        c11, c16 = compose(entries, nm, "11"), compose(entries, nm, "16")
        for t in themes:
            st, base = styles[t], os.path.join(THEMES, t, "IMAGES", "COMMANDS")
            if not wr:
                continue
            if c11:
                wr.write(os.path.join(base, "TOOLBOX", nm + ".png"), png_bytes(render11(st, c11)))
            if c16:
                wr.write(os.path.join(base, nm + ".png"), png_bytes(render16(st, c16)))
        if a.preview:
            cells = []
            for t in pthemes:
                st = styles[t]
                cells += [(render11(st, c11) if c11 else None, st["bar_bg"]), (render16(st, c16) if c16 else None, st["bar_bg"])]
            groups.append((i, cells))
            print("%d\t%s" % (i, nm))
    if wr:
        wr.close()
    elif not a.preview and not a.json:
        print("nothing written (pass --write to write the PNGs, --preview for a sheet)")
    if a.preview and groups:
        contact_sheet(a.preview, groups, a.scale, a.cols)
        print("preview", a.preview, "- per icon: " + ", ".join(t + " 11 / 16" for t in pthemes) + ", then 1x")


if __name__ == "__main__":
    main()
