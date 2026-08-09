#!/usr/bin/env python3
"""
build_cbf.py — slice glyphs out of a source image and write a DRAW Color
Bitmap Font (.bmp).

Driven by a small JSON spec so a font is reproducible and re-tweakable:

{
  "source": "chargen.png",
  "cell":   [7, 8],              # glyph cell in SOURCE DOTS (not screen px)
  "bg":     [0, 0, 0],           # colour that becomes transparent; "auto" = most common
  "threshold": 90,               # dots dimmer than this snap to bg (see below)
  "gain":   1.0,                 # brighten lit dots (blurred captures read dark)
  "trim":   false,               # true = proportional (crop each cell to its ink)
  "gap":    1,                   # blank columns kept after ink when trimming
  "rows": [
    {"text": "abcdefghijklmnopqrstuvwxyz", "x": 98.0, "y": 212.5, "sx": 2.92, "sy": 2.88},
    {"text": "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "x": 98.0, "y": 260.5}
  ]
}

x / y are the top-left of the first cell in the source image; sx / sy are how
many source pixels one dot occupies (default 1.0 — set these when the source is
an upscaled screenshot).  Each dot is sampled at its CENTRE, which is what makes
a non-integer upscale recoverable.

`threshold` matters more than anything else here.  A scaled screenshot has blur,
so a dot that should be off still samples as a dim smear of its neighbours — and
since the CBF loader only makes *exactly* the background colour transparent, an
unthresholded crop comes out as a solid block with nothing transparent at all.
Raise it until `inspect_cbf.py --art` shows clean glyph shapes.  A source that is
already at native resolution can leave it at 0.

Every character named across all rows is collected; the sheet is emitted in
strict ASCII 33..126 order because that is how DRAW maps glyphs positionally.
Missing characters are reported and filled with a blank cell so the ordering
never shifts.

    python3 build_cbf.py spec.json --out "MY-FONT.bmp"
    python3 build_cbf.py spec.json --out F.bmp --preview p.png
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cbf   # noqa: E402


def sample(img, y, x):
    """Bilinear RGB sample, clamped to the image."""
    w, h = img.size
    x = min(max(x, 0), w - 1.001)
    y = min(max(y, 0), h - 1.001)
    x0, y0 = int(x), int(y)
    fx, fy = x - x0, y - y0
    p = img.load()
    out = []
    for k in range(3):
        a = p[x0, y0][k] * (1 - fx) + p[x0 + 1, y0][k] * fx
        b = p[x0, y0 + 1][k] * (1 - fx) + p[x0 + 1, y0 + 1][k] * fx
        out.append(int(round(a * (1 - fy) + b * fy)))
    return tuple(out)


def extract(spec, base_dir):
    src_path = spec["source"]
    if not os.path.isabs(src_path):
        src_path = os.path.join(base_dir, src_path)
    img = Image.open(src_path).convert("RGB")
    cw, ch = spec["cell"]

    cells = {}
    for row in spec["rows"]:
        sx = float(row.get("sx", spec.get("sx", 1.0)))
        sy = float(row.get("sy", spec.get("sy", 1.0)))
        x0, y0 = float(row["x"]), float(row["y"])
        for i, c in enumerate(row["text"]):
            if c == " ":
                continue
            px = [[sample(img, y0 + (r + 0.5) * sy, x0 + ((i * cw) + k + 0.5) * sx)
                   for k in range(cw)] for r in range(ch)]
            cells[c] = px
    return img, cells


def resolve_bg(spec, cells):
    bg = spec.get("bg", "auto")
    if bg != "auto":
        return tuple(bg)
    counts = Counter(p for grid in cells.values() for row in grid for p in row)
    return counts.most_common(1)[0][0]


def clean(cells, bg, threshold, gain):
    """Snap dim dots to the background and optionally brighten the lit ones.

    Without this a blurred capture yields no transparent pixels at all: DRAW
    only treats the *exact* background colour as transparent, and blur means
    almost nothing lands on it exactly.
    """
    lit_total = 0
    for grid in cells.values():
        for r, row in enumerate(grid):
            for c, px in enumerate(row):
                if max(px) < threshold:
                    row[c] = bg
                else:
                    lit_total += 1
                    if gain != 1.0:
                        v = tuple(min(255, int(round(k * gain))) for k in px)
                        row[c] = v if v != bg else tuple(min(255, k + 1) for k in bg)
    return lit_total


def to_image(grid, bg, trim, gap):
    h, w = len(grid), len(grid[0])
    lit = [c for c in range(w) if any(grid[r][c] != bg for r in range(h))]
    if trim and lit:
        lo, hi = lit[0], lit[-1] + gap
        hi = min(hi, w - 1)
    else:
        lo, hi = 0, w - 1
    im = Image.new("RGB", (hi - lo + 1, h), bg)
    p = im.load()
    for r in range(h):
        for c in range(lo, hi + 1):
            p[c - lo, r] = grid[r][c]
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("--out", required=True)
    ap.add_argument("--preview", metavar="PNG")
    ap.add_argument("--preview-text",
                    default="The quick brown fox jumps over 13 lazy dogs! {#$%&@}")
    a = ap.parse_args()

    spec = json.load(open(a.spec))
    base = os.path.dirname(os.path.abspath(a.spec))
    _img, cells = extract(spec, base)
    bg = resolve_bg(spec, cells)
    trim = bool(spec.get("trim", False))
    gap = int(spec.get("gap", 1))

    threshold = int(spec.get("threshold", 0))
    gain = float(spec.get("gain", 1.0))
    total = sum(len(g) * len(g[0]) for g in cells.values())
    lit = clean(cells, bg, threshold, gain)
    print(f"threshold {threshold}, gain {gain}: {lit}/{total} dots lit "
          f"({100.0 * lit / max(total, 1):.0f}%)")
    if threshold and lit > total * 0.75:
        print("  WARN  almost everything is lit — raise `threshold`, or the glyphs "
              "will be solid blocks")
    if lit < total * 0.05:
        print("  WARN  almost nothing is lit — lower `threshold`, or check x/y/sx/sy")

    missing = [c for c in cbf.FULL_SET if c not in cells]
    if missing:
        print(f"WARN  {len(missing)} of 94 printable chars absent from the spec, "
              f"emitted blank: {''.join(missing)}")

    cw, chh = spec["cell"]
    glyphs = []
    for c in cbf.FULL_SET:
        if c in cells:
            glyphs.append(to_image(cells[c], bg, trim, gap))
        else:
            glyphs.append(Image.new("RGB", (cw, chh), bg))

    cbf.write(a.out, glyphs, bg=bg,
              marker=(255, 255, 255) if bg != (255, 255, 255) else (255, 0, 255))
    sheet = cbf.read(a.out)
    print(sheet.summary())

    if a.preview:
        sheet.render(a.preview_text, scale=6).save(a.preview)
        print("preview:", a.preview)


if __name__ == "__main__":
    main()
