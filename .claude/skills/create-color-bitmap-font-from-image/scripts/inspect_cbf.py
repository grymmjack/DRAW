#!/usr/bin/env python3
"""
inspect_cbf.py — verify a .bmp parses as a DRAW Color Bitmap Font, exactly the
way GUI/FONT-LIST.BM's CBF_detect%/CBF_load_cache would, and preview it.

    python3 inspect_cbf.py FONT.bmp                     # summary
    python3 inspect_cbf.py FONT.bmp --art A B 3         # ASCII art of glyphs
    python3 inspect_cbf.py FONT.bmp --render "HELLO" -o out.png --scale 8
    python3 inspect_cbf.py DIR                          # check a whole folder
"""
from __future__ import annotations

import argparse
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cbf   # noqa: E402


def check(path, verbose=True):
    try:
        sheet = cbf.read(path)
    except Exception as exc:                       # noqa: BLE001
        print(f"REJECT  {path}\n        {exc}")
        return None

    problems = []
    if sheet.width < 10 or sheet.sheet_height < 3:
        problems.append("too small — CBF_detect% requires w>=10 and h>=3")
    if len(sheet) < 2:
        problems.append("fewer than 2 glyphs — CBF_detect% would reject")
    if len(sheet) > cbf.GLYPH_MAX:
        problems.append(f"more than CBF_GLYPH_MAX ({cbf.GLYPH_MAX}) glyphs — extras ignored")
    if len(sheet) < 94:
        missing = chr(cbf.FIRST_CHAR + len(sheet))
        problems.append(f"only {len(sheet)} glyphs — mapping stops before {missing!r}; "
                        f"a full printable set is 94")
    if len(sheet) >= 33 and len(sheet) < 65:
        problems.append("stops inside the uppercase range — some letters unmapped")
    # a glyph whose every pixel equals bg renders as nothing at all
    blank = [i for i in range(len(sheet)) if sheet.glyph_image(i).getcolors(2) ==
             [(sheet.widths[i] * sheet.height, sheet.bg)]]
    # A deliberate spacer past the ASCII range is a layout choice, not a defect.
    blank = [i for i in blank if cbf.FIRST_CHAR + i <= cbf.LAST_ASCII]
    if blank:
        def label(i):
            code = cbf.FIRST_CHAR + i
            return repr(chr(code)) if code <= cbf.LAST_ASCII else f"code {code}"
        chars = " ".join(label(i) for i in blank[:8])
        problems.append(f"{len(blank)} fully-background glyph(s) render as nothing: {chars}")

    if verbose:
        print(sheet.summary())
        for p in problems:
            print(f"  WARN       {p}")
        if not problems:
            print("  OK         loads cleanly as a CBF font")
    return sheet


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("target", help=".bmp file or a directory of them")
    ap.add_argument("--art", nargs="*", metavar="CHAR", help="print ASCII art for these chars")
    ap.add_argument("--render", metavar="TEXT")
    ap.add_argument("-o", "--out", default="cbf_preview.png")
    ap.add_argument("--scale", type=int, default=6)
    ap.add_argument("--bg", default=None, help="preview background, e.g. '32,32,40'")
    a = ap.parse_args()

    if os.path.isdir(a.target):
        for f in sorted(glob.glob(os.path.join(a.target, "*.bmp")) +
                        glob.glob(os.path.join(a.target, "*.BMP"))):
            check(f)
            print()
        sys.exit(0)

    sheet = check(a.target)
    if sheet is None:
        sys.exit(1)

    if a.art:
        for ch in a.art:
            gi = sheet.char_map.get(ord(ch))
            print(f"\n{ch!r}  (glyph {gi})")
            print("  unmapped" if gi is None else sheet.ascii_art(gi))

    if a.render:
        bg = tuple(int(v) for v in a.bg.split(",")) if a.bg else None
        sheet.render(a.render, scale=a.scale, bg=bg).save(a.out)
        print(f"\nwrote {a.out}")
