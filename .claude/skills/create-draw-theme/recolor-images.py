#!/usr/bin/env python3
"""
recolor-images.py — recolor a DRAW theme's IMAGES (and cursors) into an arbitrary
background/foreground scheme, preserving the 3D bevel shading and transparency.

DRAW's toolbox/edit/advanced buttons are baked PNGs: a dark GLYPH (near-black) on a
3-shade grey BEVEL (shadow / face / highlight). This maps, per opaque pixel:
  - near-black glyph pixels        -> the FOREGROUND color (flat)
  - everything else (the bevel)    -> a point on the BG-dark..BG-light gradient
    chosen by the pixel's luminance, so the 3D shading survives, just re-hued.
Transparent pixels stay transparent.

That one rule turns the grey buttons into "darker button, light glyph" for a dark
theme, or a purple button with pink glyph, or cyan/violet cyberpunk, etc.

Usage:
    python3 recolor-images.py --fg '#DCDCDC' --bg-dark '#1e1e1e' --bg-light '#5c5c5c' \\
            ASSETS/THEMES/DARK/IMAGES ASSETS/THEMES/DARK/CURSORS
    # optional: --glyph-max 40   luminance <= this counts as glyph (default 40)
    #           --ext png        file extensions to touch (default png)

No system Python packages are touched: if Pillow is missing this self-bootstraps a
venv at ~/.cache/draw-theme-venv and re-runs itself there.
"""
import os
import sys
import subprocess

# --- self-bootstrap Pillow in a private venv (PEP 668 friendly) ---------------
try:
    from PIL import Image
except ImportError:
    venv = os.path.abspath(os.path.expanduser("~/.cache/draw-theme-venv"))
    vpy = os.path.join(venv, "bin", "python")
    if sys.prefix == venv:
        raise  # already inside the venv but Pillow still missing -> real error
    if not os.path.exists(vpy):
        subprocess.check_call([sys.executable, "-m", "venv", venv])
        subprocess.check_call([os.path.join(venv, "bin", "pip"), "install", "--quiet", "Pillow"])
    os.execv(vpy, [vpy] + sys.argv)  # re-run this script inside the venv


def parse_hex(s):
    s = s.lstrip("#")
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def lum(r, g, b):
    return 0.299 * r + 0.587 * g + 0.114 * b


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def recolor_image(path, fg, bg_dark, bg_light, glyph_max):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue  # keep transparent
            L = lum(r, g, b)
            if L <= glyph_max:
                nr, ng, nb = fg
            else:
                nr, ng, nb = lerp(bg_dark, bg_light, L / 255.0)
            px[x, y] = (nr, ng, nb, a)
    im.save(path)


def main():
    args = sys.argv[1:]
    fg = bg_dark = bg_light = None
    glyph_max = 40
    exts = {"png"}
    dirs = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--fg":
            i += 1; fg = parse_hex(args[i])
        elif a == "--bg-dark":
            i += 1; bg_dark = parse_hex(args[i])
        elif a == "--bg-light":
            i += 1; bg_light = parse_hex(args[i])
        elif a == "--glyph-max":
            i += 1; glyph_max = float(args[i])
        elif a == "--ext":
            i += 1; exts = {e.strip().lower().lstrip(".") for e in args[i].split(",")}
        else:
            dirs.append(a)
        i += 1
    if fg is None or bg_dark is None or bg_light is None or not dirs:
        print(__doc__)
        sys.exit(1)

    n = 0
    for d in dirs:
        for root, _, files in os.walk(d):
            for f in files:
                if f.rsplit(".", 1)[-1].lower() in exts:
                    recolor_image(os.path.join(root, f), fg, bg_dark, bg_light, glyph_max)
                    n += 1
    print(f"recolor-images: recolored {n} image(s)  fg={fg} bg=[{bg_dark}..{bg_light}]")


if __name__ == "__main__":
    main()
