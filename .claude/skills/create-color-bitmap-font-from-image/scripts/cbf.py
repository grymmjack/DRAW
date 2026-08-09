"""
cbf.py — read/write/verify DRAW Color Bitmap Font (CBF) spritesheets.

The CBF format is what GUI/FONT-LIST.BM's CBF_detect%/CBF_load_cache/
CBF_render_glyph implement.  This module is a faithful Python mirror of that
loader, so anything it accepts here will load identically inside DRAW.

FORMAT
------
A CBF font is a single .bmp strip:

    height   = glyphHeight + 1        (row 0 is a *marker* row, not pixels)
    row 0    = background colour everywhere, except ONE pixel of any other
               colour at the starting x of each glyph
    rows 1+  = the glyphs, laid out left-to-right, in their real colours
    bg       = the MOST FREQUENT colour in row 0.  Wherever that exact colour
               appears inside a glyph it is rendered TRANSPARENT.

Glyph width is implied: width[i] = markerX[i+1] - markerX[i], and the last
glyph runs to the right edge of the sheet.

Characters are mapped POSITIONALLY, not encoded:

    glyph 0 -> ASCII 33 '!'   glyph 1 -> ASCII 34 '"'  ...  up to ASCII 126 '~'

so a full printable set is 94 glyphs in strict ASCII order.  If a sheet has
fewer than 65 glyphs it stops before 'A' ever gets defined; if it has 33..90
covered but stops before 97, DRAW aliases lowercase onto the uppercase glyphs.
Space (32) is never a glyph — DRAW advances by the average glyph width.
"""

from __future__ import annotations

from collections import Counter
from PIL import Image

FIRST_CHAR = 33          # code of glyph 0
LAST_ASCII = 126         # last printable ASCII, '~'
MAX_CHAR = 255           # highest code CBF_CACHE_CHAR_MAP can hold
FULL_SET = "".join(chr(c) for c in range(FIRST_CHAR, LAST_ASCII + 1))   # 94 chars
GLYPH_MAX = 128          # CBF_GLYPH_MAX in FONT-LIST.BI

# Back-compat alias; prefer LAST_ASCII / MAX_CHAR, which say which one they mean.
LAST_CHAR = LAST_ASCII


class CBFError(ValueError):
    pass


# --------------------------------------------------------------------------
# writing
# --------------------------------------------------------------------------

def write(path, glyphs, bg=(0, 0, 0), marker=(255, 255, 255)):
    """Write a CBF sheet.

    glyphs  : list of PIL RGB Images, all the same height.  Any pixel equal to
              `bg` becomes transparent when DRAW renders the glyph.
    bg      : background / transparent colour.
    marker  : colour of the single marker pixel above each glyph.  Must differ
              from bg; it is never displayed.

    Returns the written PIL Image.
    """
    if not glyphs:
        raise CBFError("no glyphs")
    if len(glyphs) > GLYPH_MAX:
        raise CBFError(f"{len(glyphs)} glyphs exceeds CBF_GLYPH_MAX ({GLYPH_MAX})")
    if tuple(bg) == tuple(marker):
        raise CBFError("marker colour must differ from bg")

    h = glyphs[0].height
    if any(g.height != h for g in glyphs):
        raise CBFError("all glyphs must share one height")
    if any(g.width < 1 for g in glyphs):
        raise CBFError("zero-width glyph")

    total_w = sum(g.width for g in glyphs)
    if total_w < 10 or h + 1 < 3:
        raise CBFError("sheet too small for CBF_detect% (needs w>=10, h>=3)")

    sheet = Image.new("RGB", (total_w, h + 1), tuple(bg))
    px = sheet.load()
    x = 0
    for g in glyphs:
        px[x, 0] = tuple(marker)               # marker pixel = glyph start
        sheet.paste(g.convert("RGB"), (x, 1))
        x += g.width

    # The marker row must have bg as its MOST FREQUENT colour, or the loader
    # will elect the wrong background and every glyph will be mis-sliced.
    row0 = [px[i, 0] for i in range(total_w)]
    if Counter(row0).most_common(1)[0][0] != tuple(bg):
        raise CBFError(
            "marker pixels outnumber background in row 0 — glyphs are too "
            "narrow (need an average width >= 3 for a 1px marker)")

    sheet.save(path)
    return sheet


def write_mono_grid(path, cells, palette=None, bg=(0, 0, 0), marker=(255, 255, 255)):
    """Convenience: build a sheet from monochrome bit-grids.

    cells   : list of 2-D 0/1 sequences (rows of columns).
    palette : optional callable (glyph_index, row, col) -> (r, g, b) for lit
              dots.  Defaults to white.
    """
    if palette is None:
        def palette(_i, _r, _c):
            return (255, 255, 255)

    glyphs = []
    for i, grid in enumerate(cells):
        h, w = len(grid), len(grid[0])
        im = Image.new("RGB", (w, h), tuple(bg))
        p = im.load()
        for r in range(h):
            for c in range(w):
                if grid[r][c]:
                    p[c, r] = tuple(palette(i, r, c))
        glyphs.append(im)
    return write(path, glyphs, bg=bg, marker=marker)


# --------------------------------------------------------------------------
# reading — a line-for-line mirror of CBF_load_cache in GUI/FONT-LIST.BM
# --------------------------------------------------------------------------

class CBFSheet:
    def __init__(self, path):
        self.path = str(path)
        img = Image.open(self.path).convert("RGB")
        self.image = img
        w, h = img.size
        self.width, self.sheet_height = w, h
        self.height = h - 1                       # glyph height
        px = img.load()

        # bg = most frequent colour in row 0
        row0 = [px[x, 0] for x in range(w)]
        counts = Counter(row0)
        if len(counts) < 2:
            raise CBFError("row 0 has <2 distinct colours — not a CBF sheet")
        self.bg = counts.most_common(1)[0][0]

        # glyph starts = every bg -> non-bg transition in row 0
        self.starts = []
        prev_is_bg = True
        for x in range(w):
            if row0[x] != self.bg:
                if prev_is_bg and len(self.starts) < GLYPH_MAX:
                    self.starts.append(x)
                prev_is_bg = False
            else:
                prev_is_bg = True
        if len(self.starts) < 2:
            raise CBFError("fewer than 2 glyphs detected — CBF_detect% would reject this")

        self.widths = [
            (self.starts[i + 1] - self.starts[i]) if i < len(self.starts) - 1
            else (w - self.starts[i])
            for i in range(len(self.starts))
        ]
        self.space_width = sum(self.widths) // len(self.widths)

        # positional ASCII map, with DRAW's uppercase->lowercase aliasing
        self.char_map = {}
        gi = 0
        for ch in range(FIRST_CHAR, FIRST_CHAR + len(self.starts)):
            if ch > MAX_CHAR:
                break
            self.char_map[ch] = gi
            if 65 <= ch <= 90:
                self.char_map[ch + 32] = gi       # later overwritten if real
            gi += 1                               # lowercase glyphs exist

    # -- accessors ---------------------------------------------------------

    def __len__(self):
        return len(self.starts)

    def glyph_image(self, index):
        x = self.starts[index]
        return self.image.crop((x, 1, x + self.widths[index], 1 + self.height))

    def glyph_for(self, ch):
        gi = self.char_map.get(ord(ch))
        return None if gi is None else self.glyph_image(gi)

    def ascii_art(self, index, on="#", off="."):
        im = self.glyph_image(index)
        p = im.load()
        return "\n".join(
            "".join(off if p[c, r] == self.bg else on for c in range(im.width))
            for r in range(im.height))

    def render(self, text, scale=1, bg=None):
        """Render a string the way DRAW's CBF_render_glyph + text layer does."""
        bg = self.bg if bg is None else tuple(bg)
        widths = [self.space_width if c == " " else
                  (self.widths[self.char_map[ord(c)]] if ord(c) in self.char_map else 0)
                  for c in text]
        out = Image.new("RGB", (max(sum(widths), 1), self.height), bg)
        x = 0
        for c, w in zip(text, widths):
            if w == 0:
                continue
            if c != " ":
                out.paste(self.glyph_for(c), (x, 0))
            x += w
        if scale != 1:
            out = out.resize((out.width * scale, out.height * scale), Image.NEAREST)
        return out

    def summary(self):
        mapped = sorted(self.char_map)
        ascii_n = sum(1 for c in mapped if c <= LAST_ASCII)
        extra = [c for c in mapped if c > LAST_ASCII]
        line = (f"  chars      ASCII {ascii_n}/94 mapped "
                f"({chr(mapped[0])!r}..{chr(min(mapped[-1], LAST_ASCII))!r})")
        if extra:
            line += f"\n  extended   codes {extra[0]}..{extra[-1]} ({len(extra)} glyphs)"
        return (f"{self.path}\n"
                f"  sheet      {self.width}x{self.sheet_height} "
                f"(glyph height {self.height})\n"
                f"  background {self.bg}\n"
                f"  glyphs     {len(self.starts)}  "
                f"widths {min(self.widths)}..{max(self.widths)} "
                f"(space advance {self.space_width})\n" + line)


def read(path):
    return CBFSheet(path)
