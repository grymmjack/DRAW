#!/usr/bin/env python3
"""
build_apple2_color.py — worked example for the create-color-bitmap-font-from-image skill.

Builds "APPLE ][ 40 COLUMNS COLOR" — a DRAW Color Bitmap Font reproducing the
NTSC composite artifact colouring of Apple II 40-column text.

Why the shapes come from a font file and not from cropping the screenshot: the
reference capture is a ~2.92x *non-integer* upscale with composite blur, so a
single lit dot bleeds ~1 dot to its right.  Thresholding that back to a 7x8
mask loses diagonals (Q, M, W, V, X, N all corrupt).  Apple2.ttf carries the
exact same character generator, verified pixel-for-pixel: at 8px every glyph
fits cols 0..6 / rows 1..8, which is precisely the Apple II 7x8 text cell.
So: shapes from the ROM font, colour from the screenshot-fitted NTSC decoder.

Usage:
    python3 build_apple2_color.py [--out PATH] [--phase 0|1] [--verify DIR]
"""
from __future__ import annotations

import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cbf                      # noqa: E402
from ntsc import colorize_cell, PARAMS   # noqa: E402

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
TTF = os.path.join(REPO, "ASSETS", "FONTS", "COMPUTERS", "Apple2.ttf")
# PrintChar21 is Kreative Korp's Apple II font; it carries the 32 MouseText
# glyphs at U+0080..U+009F, which Apple2.ttf does not have at all.
MOUSETEXT_TTF = os.path.join(REPO, "ASSETS", "FONTS", "COMPUTERS", "PrintChar21.ttf")
OUT = os.path.join(REPO, "ASSETS", "FONTS", "COLOR_BITMAP",
                   "APPLE-][-40-COLUMNS-COLOR.bmp")

CELL_W, CELL_H = 7, 8           # the Apple II 40-column text cell
MOUSETEXT_FIRST = 0x80          # U+0080 in PrintChar21 == MouseText $40


def ttf_mask(ch, ft, dy=1):
    """7x8 dot mask for `ch`.

    Apple2.ttf has an 8px advance and puts the cell at cols 0-6, rows 1-8, so
    dy=1.  PrintChar21 has a true 7px advance and sits at rows 0-7, so dy=0.
    """
    im = Image.new("L", (24, 24), 0)
    ImageDraw.Draw(im).text((0, 0), ch, font=ft, fill=255)
    p = im.load()
    return [[1 if p[x, y + dy] > 127 else 0 for x in range(CELL_W)] for y in range(CELL_H)]


def _cell(mask, phase, gain):
    px = colorize_cell(mask, parity0=phase, gain=gain)
    im = Image.new("RGB", (CELL_W, CELL_H), (0, 0, 0))
    ip = im.load()
    for r in range(CELL_H):
        for c in range(CELL_W):
            ip[c, r] = tuple(int(v) for v in px[r, c])
    return im


def build(out_path, phase=0, gain=1.0, mousetext=True):
    """Write the sheet.

    Glyph order is what fixes the character codes, since CBF maps positionally:

        glyphs   0..93    ASCII 33..126   the printable set
        glyph    94       code 127        blank spacer
        glyphs  95..126   codes 128..159  MouseText $40..$5F

    The spacer exists purely so MouseText starts at 128 rather than 127 —
    that mirrors where the Apple II itself keeps it (the alternate character
    set's $40..$5F, i.e. high-bit-set $C0..$DF) and where PrintChar21 maps it.
    """
    ft = ImageFont.truetype(TTF, 8)
    glyphs = [_cell(ttf_mask(ch, ft), phase, gain) for ch in cbf.FULL_SET]

    if mousetext:
        glyphs.append(Image.new("RGB", (CELL_W, CELL_H), (0, 0, 0)))   # code 127
        mt = ImageFont.truetype(MOUSETEXT_TTF, 8)
        for i in range(32):
            glyphs.append(_cell(ttf_mask(chr(MOUSETEXT_FIRST + i), mt, dy=0), phase, gain))

    cbf.write(out_path, glyphs, bg=(0, 0, 0), marker=(255, 255, 255))
    return out_path


def verify(out_dir):
    """Re-render the screenshot's own text rows so they can be eyeballed side by side."""
    os.makedirs(out_dir, exist_ok=True)
    ft = ImageFont.truetype(TTF, 8)
    rows = ["abcdefghijklmnopqrstuvwxyz",
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
            "0123456789)!@#$%^&*(-_=+`~",
            "[\\]{};:'\",<.>/?|"]
    start_col = [7, 7, 7, 12]
    for n, (text, col0) in enumerate(zip(rows, start_col)):
        w = len(text) * CELL_W
        im = Image.new("RGB", (w, CELL_H), (0, 0, 0))
        ip = im.load()
        for i, ch in enumerate(text):
            mask = ttf_mask(ch, ft)
            # real absolute column -> real phase, exactly as the screenshot had it
            px = colorize_cell(mask, parity0=((col0 + i) * CELL_W) & 1,
                               gain=PARAMS["capture_gain"])
            for r in range(CELL_H):
                for c in range(CELL_W):
                    ip[i * CELL_W + c, r] = tuple(int(v) for v in px[r, c])
        im.resize((w * 6, CELL_H * 6), Image.NEAREST).save(
            os.path.join(out_dir, f"verify_row{n}.png"))
    return out_dir


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--phase", type=int, default=0, choices=(0, 1),
                    help="0 = glyph rendered as if at an even dot column (stems green); "
                         "1 = odd column (stems violet)")
    ap.add_argument("--no-mousetext", action="store_true",
                    help="omit the 32 MouseText glyphs (94-glyph ASCII-only sheet)")
    ap.add_argument("--verify", metavar="DIR",
                    help="also emit dimmed re-renders of the reference rows")
    a = ap.parse_args()
    print("wrote", build(a.out, phase=a.phase, mousetext=not a.no_mousetext))
    print(cbf.read(a.out).summary())
    if a.verify:
        print("verification renders in", verify(a.verify))
