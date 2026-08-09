#!/usr/bin/env python3
"""
build_apple2_color.py — worked example for the create-color-bitmap-font-from-image skill.

Builds the "APPLE ][" family of DRAW Color Bitmap Fonts: the NTSC composite
artifact colouring of Apple II 40-column text, monochrome phosphor variants,
and CRT-scanline versions at both 40 and 80 columns.

WHERE THE SHAPES COME FROM
--------------------------
Not from cropping the reference screenshot.  That capture is a ~2.92x
*non-integer* upscale with composite blur, so a single lit dot bleeds ~1 dot to
its right; thresholding it back to a 7x8 mask corrupted 91 of 94 glyphs, worst
on diagonals (Q M W V X N).

Shapes come from PrintChar21.ttf (Kreative Korp), which is a true 7x8 Apple II
cell — no glyph overflows it, and it carries MouseText as well.  Apple2.ttf was
used first but is an 8x8-em font whose 'p' and 'q' descenders need NINE rows,
so both were silently clipped.  The two fonts disagree on exactly six glyphs
(% ( , p q t); rendering each through the fitted NTSC model and comparing to
the screenshot picked PrintChar21 6/6.

WHERE THE COLOUR COMES FROM
---------------------------
Apple II text is 1-bit.  The colour is an NTSC artifact, measured off the
screenshot and fitted in ntsc.py.  Monochrome variants get no artifact colour
at all, which is correct: that is exactly what a mono monitor showed, and why
80-column text was unreadable on a colour set.

Usage:
    python3 build_apple2_color.py                 # rebuild the shipped 40-col colour font
    python3 build_apple2_color.py --all           # build the whole family
    python3 build_apple2_color.py --columns 80 --phosphor amber --scanlines --out X.bmp
"""
from __future__ import annotations

import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cbf                                        # noqa: E402
from ntsc import colorize_cell, PARAMS            # noqa: E402

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
TTF = os.path.join(REPO, "ASSETS", "FONTS", "COMPUTERS", "PrintChar21.ttf")
FONT_DIR = os.path.join(REPO, "ASSETS", "FONTS", "COLOR_BITMAP")

CELL_W, CELL_H = 7, 8           # the Apple II text cell, 40- and 80-column alike

# MouseText lives at U+0080..U+009F, but $46/$47 differ between ROM revisions:
# the //e Enhanced has the "running man" pair there, the IIGS has menu icons.
# PrintChar21 keeps the //e glyphs at U+E011/U+E012. The reference screenshot is
# a //e, and matching confirmed it (U+E012 was an exact 0-dot match for $47,
# against 24 differing dots for U+0087), so the //e set is the default.
MOUSETEXT_FIRST = 0x80
MOUSETEXT_IIE_OVERRIDES = {0x46: 0xE011, 0x47: 0xE012}

# Phosphor colours. P1 green and P3 amber are the classic monitor approximations;
# "white" is the P4 mono tube. None of these carry artifact colour by design.
PHOSPHORS = {
    "white": (255, 255, 255),
    "amber": (255, 176, 0),
    "green": (51, 255, 51),
}
# Brightness of the dark row of each scanline pair. 1.0 = no scanline at all.
# 0.78 keeps the stripe readable without the heavy banding 0.35 produced.
SCANLINE_DIM = 0.78


def glyph_mask(codepoint, ft):
    """7x8 dot mask. PrintChar21 has a true 7px advance and sits at rows 0-7."""
    im = Image.new("L", (24, 24), 0)
    ImageDraw.Draw(im).text((0, 0), chr(codepoint), font=ft, fill=255)
    p = im.load()
    return [[1 if p[x, y] > 127 else 0 for x in range(CELL_W)] for y in range(CELL_H)]


def render_cell(mask, phase, phosphor=None, gain=1.0, out_w=CELL_W, vscale=1,
                scanlines=False):
    """Colourise one 7x8 mask and resample it into an out_w x (8*vscale) cell.

    out_w is the FINAL cell width in pixels, not a scale factor, because 80
    columns needs to shrink as well as 40 needs to grow.

    Both column modes use the same 7x8 ROM bitmaps and the same 24 rows of 8
    scanlines — 80-column does not make characters taller, it makes them
    narrower.  With square output pixels and a 4:3 screen the dot aspects are
    (4/3)/(280/192) = 0.914 at 40 columns and (4/3)/(560/192) = 0.457 at 80, so
    7 dots want ~7px and ~3px respectively AT THE SAME HEIGHT:

        40 col  plain 7x8    CRT 14x16
        80 col  plain 3x8    CRT  7x16

    Downsampling uses "any covered dot is lit", which happens to suit this font
    exactly at 3px: 7/3 puts the sample centres on dots 1, 3 and 5, which is
    where Apple II ink lives.  (4px is much worse — 7/4 overlaps nearly every
    dot and the glyphs collapse into solid blocks.)  Colour for a merged pixel
    is the mean of the lit dots it covers.

    Scanlines dim every odd OUTPUT row, and only where the dot is lit.  Unlit
    dots stay pure background so they render transparent: a font has to
    composite over whatever is behind it, and an opaque CRT ground would make
    every glyph carry a black box.

    With vscale=2 that dims the lower row of each doubled pair — a true scanline
    gap, at the cost of a cell twice as tall.  With vscale=1 there is no room
    for a gap, so it dims alternate rows of the glyph itself: not physically a
    scanline, but it reads as CRT striping and costs nothing in size.
    """
    if phosphor is None:
        px = colorize_cell(mask, parity0=phase, gain=gain)
        colour = lambda r, c: tuple(int(v) for v in px[r, c])          # noqa: E731
    else:
        tint = tuple(int(round(v * gain)) for v in phosphor)
        colour = lambda r, c: tint                                      # noqa: E731

    out = Image.new("RGB", (out_w, CELL_H * vscale), (0, 0, 0))
    ip = out.load()
    for r in range(CELL_H):
        for ox in range(out_w):
            lo, hi = ox * CELL_W / out_w, (ox + 1) * CELL_W / out_w
            lit = [c for c in range(CELL_W)
                   if c + 1 > lo and c < hi and mask[r][c]]
            if not lit:
                continue                       # stays background -> transparent
            cols = [colour(r, c) for c in lit]
            base = tuple(int(round(sum(v[k] for v in cols) / len(cols)))
                         for k in range(3))
            for sy in range(vscale):
                dim = scanlines and ((r * vscale + sy) % 2 == 1)
                col = tuple(max(1, int(round(v * SCANLINE_DIM))) for v in base) if dim \
                    else (base if any(base) else (1, 1, 1))
                ip[ox, r * vscale + sy] = col
    return out


def build(out_path, phase=0, phosphor=None, gain=1.0, out_w=CELL_W, vscale=1,
          scanlines=False, mousetext=True, iie=True):
    """Write one sheet.

    Glyph order fixes the character codes, because CBF maps positionally:

        glyphs   0..93    codes  33..126   printable ASCII
        glyph    94       code   127       blank spacer
        glyphs  95..126   codes 128..159   MouseText $40..$5F

    The spacer exists so MouseText starts on a round 128 — where the Apple II
    itself keeps it, and where PrintChar21 maps it.
    """
    ft = ImageFont.truetype(TTF, 8)
    kw = dict(phosphor=phosphor, gain=gain, out_w=out_w, vscale=vscale,
              scanlines=scanlines)

    glyphs = [render_cell(glyph_mask(ord(ch), ft), phase, **kw) for ch in cbf.FULL_SET]

    if mousetext:
        glyphs.append(Image.new("RGB", (out_w, CELL_H * vscale), (0, 0, 0)))
        for i in range(32):
            mt = MOUSETEXT_FIRST + i
            if iie:
                mt = MOUSETEXT_IIE_OVERRIDES.get(0x40 + i, mt)
            glyphs.append(render_cell(glyph_mask(mt, ft), phase, **kw))

    cbf.write(out_path, glyphs, bg=(0, 0, 0), marker=(255, 255, 255))
    return out_path


# name -> kwargs. Three size tiers, because a scanline GAP needs a row of its own:
#
#   (no suffix)  7x8   native cell, one output pixel per dot
#   -SCAN        7x8   striped: alternate glyph rows dimmed. Not a real scanline
#                      gap, but it reads as one and costs nothing in size, so it
#                      drops in beside the native fonts without a size jump.
#   -CRT        14x16  true scanlines. 40-column dots are ~square so they double
#         (80): 7x16   horizontally too; 80-column dots are half as wide so they
#                      do not. This tier is 2x the native fonts by necessity.
FAMILY = {
    "APPLE-][-40-COLOR":       dict(out_w=7, vscale=1, scanlines=False),
    "APPLE-][-40-WHITE":       dict(out_w=7, vscale=1, scanlines=False, phosphor="white"),
    "APPLE-][-40-AMBER":       dict(out_w=7, vscale=1, scanlines=False, phosphor="amber"),
    "APPLE-][-40-GREEN":       dict(out_w=7, vscale=1, scanlines=False, phosphor="green"),
    "APPLE-][-40-COLOR-SCAN":  dict(out_w=7, vscale=1, scanlines=True),
    "APPLE-][-40-WHITE-SCAN":  dict(out_w=7, vscale=1, scanlines=True, phosphor="white"),
    "APPLE-][-40-AMBER-SCAN":  dict(out_w=7, vscale=1, scanlines=True, phosphor="amber"),
    "APPLE-][-40-GREEN-SCAN":  dict(out_w=7, vscale=1, scanlines=True, phosphor="green"),
    "APPLE-][-40-COLOR-CRT":   dict(out_w=14, vscale=2, scanlines=True),
    "APPLE-][-40-WHITE-CRT":   dict(out_w=14, vscale=2, scanlines=True, phosphor="white"),
    "APPLE-][-40-AMBER-CRT":   dict(out_w=14, vscale=2, scanlines=True, phosphor="amber"),
    "APPLE-][-40-GREEN-CRT":   dict(out_w=14, vscale=2, scanlines=True, phosphor="green"),
    # 80-column plain. There is no aspect-correct 80-col cell shorter than 16:
    # an 80-col dot is half as wide as a 40-col dot, so with square output pixels
    # the smallest honest cell is 1 wide x 2 tall per dot. 7x8 would simply BE
    # the 40-column font, and squeezing to 4x8 would destroy a 7-dot glyph.
    "APPLE-][-80-COLOR":       dict(out_w=3, vscale=1, scanlines=False),
    "APPLE-][-80-WHITE":       dict(out_w=3, vscale=1, scanlines=False, phosphor="white"),
    "APPLE-][-80-AMBER":       dict(out_w=3, vscale=1, scanlines=False, phosphor="amber"),
    "APPLE-][-80-GREEN":       dict(out_w=3, vscale=1, scanlines=False, phosphor="green"),
    "APPLE-][-80-COLOR-CRT":   dict(out_w=7, vscale=2, scanlines=True),
    "APPLE-][-80-WHITE-CRT":   dict(out_w=7, vscale=2, scanlines=True, phosphor="white"),
    "APPLE-][-80-AMBER-CRT":   dict(out_w=7, vscale=2, scanlines=True, phosphor="amber"),
    "APPLE-][-80-GREEN-CRT":   dict(out_w=7, vscale=2, scanlines=True, phosphor="green"),
}


def build_family(out_dir, phase=0):
    made = []
    for name, kw in FAMILY.items():
        kw = dict(kw)
        ph = kw.pop("phosphor", None)
        path = os.path.join(out_dir, name + ".bmp")
        build(path, phase=phase, phosphor=PHOSPHORS[ph] if ph else None, **kw)
        made.append(path)
    return made


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(FONT_DIR, "APPLE-][-40-COLOR.bmp"))
    ap.add_argument("--all", action="store_true", help="build the whole family into FONT_DIR")
    ap.add_argument("--out-dir", default=FONT_DIR)
    ap.add_argument("--phase", type=int, default=0, choices=(0, 1),
                    help="0 = glyph rendered as if at an even dot column (stems green); "
                         "1 = odd column (stems violet). Ignored for monochrome.")
    ap.add_argument("--columns", type=int, default=40, choices=(40, 80))
    ap.add_argument("--scanlines", action="store_true")
    ap.add_argument("--phosphor", choices=sorted(PHOSPHORS),
                    help="monochrome phosphor; omit for NTSC artifact colour")
    ap.add_argument("--no-mousetext", action="store_true")
    ap.add_argument("--iigs", action="store_true",
                    help="use the IIGS MouseText $46/$47 menu icons instead of the "
                         "//e Enhanced running-man pair")
    a = ap.parse_args()

    if a.all:
        for p in build_family(a.out_dir, phase=a.phase):
            print(cbf.read(p).summary())
            print()
    else:
        if a.columns == 40:
            ow, vs = (14, 2) if a.scanlines else (7, 1)
        else:
            ow, vs = (7, 2) if a.scanlines else (3, 1)
        build(a.out, phase=a.phase,
              phosphor=PHOSPHORS[a.phosphor] if a.phosphor else None,
              out_w=ow, vscale=vs, scanlines=a.scanlines,
              mousetext=not a.no_mousetext, iie=not a.iigs)
        print(cbf.read(a.out).summary())
