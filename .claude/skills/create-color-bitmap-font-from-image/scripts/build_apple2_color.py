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
SCANLINE_DIM = 0.35             # brightness of the dark half of each scanline pair


def glyph_mask(codepoint, ft):
    """7x8 dot mask. PrintChar21 has a true 7px advance and sits at rows 0-7."""
    im = Image.new("L", (24, 24), 0)
    ImageDraw.Draw(im).text((0, 0), chr(codepoint), font=ft, fill=255)
    p = im.load()
    return [[1 if p[x, y] > 127 else 0 for x in range(CELL_W)] for y in range(CELL_H)]


def render_cell(mask, phase, phosphor=None, gain=1.0, hscale=1, vscale=1,
                scanlines=False):
    """Colourise one 7x8 mask and blow it up to the output cell.

    hscale/vscale express the CRT's dot aspect: a 40-column dot is about square
    (hscale 2 when rows are doubled for scanlines), an 80-column dot is half as
    wide (hscale 1).  That is the whole difference between the two modes — the
    bitmaps are identical, the dot clock is not.

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
    else:
        px = [[tuple(int(round(v * gain)) for v in phosphor) if mask[r][c] else (0, 0, 0)
               for c in range(CELL_W)] for r in range(CELL_H)]

    out = Image.new("RGB", (CELL_W * hscale, CELL_H * vscale), (0, 0, 0))
    ip = out.load()
    for r in range(CELL_H):
        for c in range(CELL_W):
            if not mask[r][c]:
                continue                       # stays background -> transparent
            base = tuple(int(v) for v in px[r][c]) if phosphor else \
                tuple(int(v) for v in px[r, c])
            for sy in range(vscale):
                dim = scanlines and ((r * vscale + sy) % 2 == 1)
                col = tuple(max(1, int(round(v * SCANLINE_DIM))) for v in base) if dim \
                    else (base if any(base) else (1, 1, 1))
                for sx in range(hscale):
                    ip[c * hscale + sx, r * vscale + sy] = col
    return out


def build(out_path, phase=0, phosphor=None, gain=1.0, hscale=1, vscale=1,
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
    kw = dict(phosphor=phosphor, gain=gain, hscale=hscale, vscale=vscale,
              scanlines=scanlines)

    glyphs = [render_cell(glyph_mask(ord(ch), ft), phase, **kw) for ch in cbf.FULL_SET]

    if mousetext:
        glyphs.append(Image.new("RGB", (CELL_W * hscale, CELL_H * vscale), (0, 0, 0)))
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
    "APPLE-][-40-COLUMNS-COLOR":       dict(hscale=1, vscale=1, scanlines=False),
    "APPLE-][-40-COLUMNS-WHITE":       dict(hscale=1, vscale=1, scanlines=False, phosphor="white"),
    "APPLE-][-40-COLUMNS-AMBER":       dict(hscale=1, vscale=1, scanlines=False, phosphor="amber"),
    "APPLE-][-40-COLUMNS-GREEN":       dict(hscale=1, vscale=1, scanlines=False, phosphor="green"),
    "APPLE-][-40-COLUMNS-COLOR-SCAN":  dict(hscale=1, vscale=1, scanlines=True),
    "APPLE-][-40-COLUMNS-WHITE-SCAN":  dict(hscale=1, vscale=1, scanlines=True, phosphor="white"),
    "APPLE-][-40-COLUMNS-AMBER-SCAN":  dict(hscale=1, vscale=1, scanlines=True, phosphor="amber"),
    "APPLE-][-40-COLUMNS-GREEN-SCAN":  dict(hscale=1, vscale=1, scanlines=True, phosphor="green"),
    "APPLE-][-40-COLUMNS-COLOR-CRT":   dict(hscale=2, vscale=2, scanlines=True),
    "APPLE-][-40-COLUMNS-WHITE-CRT":   dict(hscale=2, vscale=2, scanlines=True, phosphor="white"),
    "APPLE-][-40-COLUMNS-AMBER-CRT":   dict(hscale=2, vscale=2, scanlines=True, phosphor="amber"),
    "APPLE-][-40-COLUMNS-GREEN-CRT":   dict(hscale=2, vscale=2, scanlines=True, phosphor="green"),
    "APPLE-][-80-COLUMNS-COLOR-CRT":   dict(hscale=1, vscale=2, scanlines=True),
    "APPLE-][-80-COLUMNS-WHITE-CRT":   dict(hscale=1, vscale=2, scanlines=True, phosphor="white"),
    "APPLE-][-80-COLUMNS-AMBER-CRT":   dict(hscale=1, vscale=2, scanlines=True, phosphor="amber"),
    "APPLE-][-80-COLUMNS-GREEN-CRT":   dict(hscale=1, vscale=2, scanlines=True, phosphor="green"),
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
    ap.add_argument("--out", default=os.path.join(FONT_DIR, "APPLE-][-40-COLUMNS-COLOR.bmp"))
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
        hs = 2 if (a.columns == 40 and a.scanlines) else 1
        vs = 2 if a.scanlines else 1
        build(a.out, phase=a.phase,
              phosphor=PHOSPHORS[a.phosphor] if a.phosphor else None,
              hscale=hs, vscale=vs, scanlines=a.scanlines,
              mousetext=not a.no_mousetext, iie=not a.iigs)
        print(cbf.read(a.out).summary())
