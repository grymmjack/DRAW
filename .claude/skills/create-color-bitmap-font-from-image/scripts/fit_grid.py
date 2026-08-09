#!/usr/bin/env python3
"""
fit_grid.py — locate the character grid in a source image and emit a spec for
build_cbf.py.

Screenshots of retro machines are almost never at native resolution: they come
scaled by some non-integer factor, with blur.  You cannot just crop on integer
boundaries — you have to find where each *dot centre* landed.

Method
------
1. Row bands are found as contiguous runs of scanlines containing lit pixels.
2. For each band you supply the text it contains (only you can read the image).
   That fixes the dot count, so ink_span / n_chars is a hard LOWER bound on the
   character pitch.
3. The pitch is then *measured* by autocorrelating the band's column profile —
   a line of text is periodic at the cell pitch — taking the first peak at or
   above that bound, with parabolic interpolation for sub-pixel precision.
   One scale is shared by every row, because one screenshot has one scale.
4. Only the per-row offsets are searched, by maximising the variance of the
   sampled dots: an aligned grid hits dot centres and the values are bimodal,
   a drifting grid samples the blur between dots and they collapse to the mean.

The scale is measured rather than searched because searching it is degenerate —
any grid can raise a crispness score simply by spreading out to sample more
background.

This gets you close, not exact.  ALWAYS verify with `inspect_cbf.py --art` and
nudge x/y by tenths of a pixel until the glyphs are clean.

    python3 fit_grid.py shot.png --cell 7x8 \
        --row "abcdefghijklmnopqrstuvwxyz" \
        --row "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
        --row -                      # skip this band

Rows are matched to the detected bands in order; "-" skips a band.
"""
from __future__ import annotations

import argparse
import json

import numpy as np
from PIL import Image


def find_bands(lit, min_h=3):
    prof = lit.sum(1)
    out, start = [], None
    for i, v in enumerate(prof):
        if v > 0 and start is None:
            start = i
        elif v == 0 and start is not None:
            if i - start >= min_h:
                out.append((start, i - 1))
            start = None
    if start is not None:
        out.append((start, len(prof) - 1))
    return out


def sample_grid(val, x0, y0, sx, sy, ndots, nrows):
    xs = np.clip((x0 + (np.arange(ndots) + 0.5) * sx).astype(int), 0, val.shape[1] - 1)
    ys = np.clip((y0 + (np.arange(nrows) + 0.5) * sy).astype(int), 0, val.shape[0] - 1)
    return val[np.ix_(ys, xs)]


def crispness(vals):
    """Variance of the sampled dots.

    When the grid is aligned every sample sits on a dot centre, so values pile
    up at the extremes (fully lit / fully dark) and variance peaks.  A drifting
    grid samples the blur between dots and the values collapse toward the mean.
    Cheap, and needs no reference font.
    """
    return float(vals.var())


def measure_pitch(band, n_chars, cell_w):
    """Pixels per dot, from the autocorrelation of the band's column profile.

    A row of text is periodic at the character pitch, so the autocorrelation
    peaks at every whole number of cells.  ink_span / n_chars is a hard lower
    bound on the pitch (the ink of the first and last glyphs is inset within
    their cells), so we search upward from it and take the first strong peak.
    """
    prof = band.sum(0).astype(float)
    prof -= prof.mean()
    n = len(prof)
    ac = np.correlate(prof, prof, "full")[n - 1:]
    if ac[0] <= 0:
        return None
    ac /= ac[0]
    floor = n / n_chars                     # ink span / chars <= true pitch
    lo, hi = max(int(floor * 0.98), 2), min(int(floor * 1.25) + 1, n - 2)
    if hi <= lo:
        return None
    k = lo + int(np.argmax(ac[lo:hi]))
    a, b, c = ac[k - 1], ac[k], ac[k + 1]
    denom = a - 2 * b + c
    frac = 0.5 * (a - c) / denom if denom != 0 else 0.0
    return max((k + np.clip(frac, -1, 1)) / cell_w, floor / cell_w)


def fit_global(val, lit, jobs, cell, aspect=1.0):
    """One scale for the whole image, one offset per row.

    A single screenshot has a single scale factor, so fitting it per row just
    lets noise pull each row somewhere different.  The scale is *measured* (via
    pitch autocorrelation), not searched — searching it against a crispness
    score is degenerate, because a grid can always raise its score by spreading
    out to sample more background.  Only the offsets are searched.
    """
    cw, chh = cell
    pitches = []
    for text, (y0b, y1b), (x_lo, x_hi) in jobs:
        p = measure_pitch(lit[y0b:y1b + 1, x_lo:x_hi + 1], len(text), cw)
        if p:
            pitches.append(p)
    if not pitches:
        raise SystemExit("could not measure character pitch — is --cell right?")
    # every row's ink must still fit inside the grid, so honour the widest bound
    floor = max((x_hi - x_lo + 1) / (len(text) * cw)
                for text, _, (x_lo, x_hi) in jobs)
    sx = max(float(np.median(pitches)), floor)
    sy = sx / aspect

    offs = []
    for text, (y0b, y1b), (x_lo, x_hi) in jobs:
        ndots = len(text) * cw
        best = None
        for x0 in np.arange(x_lo - 2.0 * sx, x_lo + 1.0 * sx, 0.1):
            if x0 + ndots * sx < x_hi + 1 - sx:
                continue                      # grid too short to cover the ink
            # NO vertical coverage constraint: blur spreads ink beyond the
            # cell, so a lit band is routinely taller than chh * sy.
            for y0 in np.arange(y0b - 1.5 * sy, y0b + 1.0 * sy, 0.1):
                c = crispness(sample_grid(val, x0, y0, sx, sy, ndots, chh))
                if best is None or c > best[0]:
                    best = (c, float(x0), float(y0))
        offs.append(best)
    return sx, sy, pitches, offs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--cell", default="8x8", help="glyph cell in dots, e.g. 7x8")
    ap.add_argument("--row", action="append", default=[],
                    help="text of the next detected band, or '-' to skip it")
    ap.add_argument("--threshold", type=int, default=40)
    ap.add_argument("--aspect", type=float, default=1.0,
                    help="source pixel aspect (sx/sy). 1.0 = square scaling, "
                         "which is right for almost every screenshot")
    ap.add_argument("--out", help="write the spec JSON here")
    a = ap.parse_args()

    cw, chh = (int(v) for v in a.cell.lower().split("x"))
    img = np.asarray(Image.open(a.image).convert("RGB")).astype(int)
    val = img.max(2).astype(float)
    lit = val > a.threshold

    bands = find_bands(lit)
    print(f"image {img.shape[1]}x{img.shape[0]}, cell {cw}x{chh} dots, "
          f"{len(bands)} band(s) detected\n")

    jobs, labels = [], []
    for i, (y0b, y1b) in enumerate(bands):
        cols = np.nonzero(lit[y0b:y1b + 1].sum(0))[0]
        text = a.row[i] if i < len(a.row) else None
        head = f"band {i}: y={y0b}..{y1b} x={cols.min()}..{cols.max()}"
        if not text or text == "-":
            print(f"{head}   (no --row given, skipped)")
            continue
        print(f"{head}   {len(text)} chars")
        jobs.append((text, (y0b, y1b), (int(cols.min()), int(cols.max()))))
        labels.append(text)

    if not jobs:
        print("\nNo --row text supplied — nothing to fit.")
        return

    sx, sy, pitches, offs = fit_global(val, lit, jobs, (cw, chh), a.aspect)
    spread = (max(pitches) - min(pitches)) / sx * 100 if len(pitches) > 1 else 0.0
    print(f"\nglobal scale: sx={sx:.4f} sy={sy:.4f} source px per dot "
          f"(per-row pitch estimates agree to {spread:.1f}%)")
    if spread > 4:
        print("   WARN  rows disagree on pitch — check the --row texts are exact "
              "and that\n         every band really is one line of the same font")

    rows = []
    for text, off in zip(labels, offs):
        if off is None:
            print(f"   FAILED to place {text[:24]!r} — no grid at this scale covers "
                  f"its ink.\n            Check the row text, or pass --aspect / a "
                  f"different --cell.")
            continue
        crisp, x0, y0 = off
        print(f"   x={x0:.2f} y={y0:.2f}  (crispness {crisp:.0f})  {text[:24]!r}")
        rows.append({"text": text, "x": round(x0, 2), "y": round(y0, 2)})

    spec = {"source": a.image, "cell": [cw, chh], "bg": "auto",
            "trim": False, "gap": 1,
            "sx": round(sx, 4), "sy": round(sy, 4), "rows": rows}
    js = json.dumps(spec, indent=2)
    if a.out:
        open(a.out, "w").write(js + "\n")
        print(f"\nwrote {a.out}")
    else:
        print("\n" + js)
    print("\nVerify with:  inspect_cbf.py FONT.bmp --art A B g 0 —  if a glyph is "
          "sheared\nor clipped, nudge that row's x/y by a few tenths and rebuild.")


if __name__ == "__main__":
    main()
