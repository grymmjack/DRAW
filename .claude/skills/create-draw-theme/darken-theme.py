#!/usr/bin/env python3
"""
darken-theme.py — turn a DRAW THEME.CFG into a DARKER variant by lowering the
LIGHTNESS (HLS) of every RGB/RGBA color line, leaving hue and saturation intact
so accent colors stay recognizable. Near-white values (text, highlights, icon
strokes) are protected so contrast stays readable. Non-color lines (ints, floats,
strings, palette indices, bit patterns) pass through untouched.

DRAW's DEFAULT theme is already dark-grey, so this pushes it toward true black
(deeper panels, higher contrast). To instead FLIP a light theme dark, pass
--invert (inverts lightness). Alpha is preserved. Fast first pass — hand-tune
afterward for polish.

Usage:
    python3 darken-theme.py [--invert] [--gamma G] [--protect P] <in> [<out>]
      <out> omitted -> edit <in> in place.  Defaults: gamma 1.6, protect 0.82.
"""
import colorsys
import re
import sys

# KEY = R,G,B  or  KEY = R,G,B,A  (tolerant of surrounding whitespace)
COLOR_RE = re.compile(
    r'^(\s*[^=#;]+?\s*=\s*)(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(\s*,\s*(\d{1,3}))?\s*$'
)

GAMMA = 1.6      # >1 darkens; higher = darker
PROTECT = 0.82   # keep lightness at/above this as-is (bright text/icons/highlights)
INVERT = False


def map_lightness(r, g, b):
    h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
    if INVERT:
        l = 1.0 - l
    elif l < PROTECT:
        l = l ** GAMMA
    r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)
    return (int(round(r2 * 255)), int(round(g2 * 255)), int(round(b2 * 255)))


def transform_line(line):
    m = COLOR_RE.match(line.rstrip('\n'))
    if not m:
        return line
    r, g, b = int(m.group(2)), int(m.group(3)), int(m.group(4))
    if not all(0 <= c <= 255 for c in (r, g, b)):
        return line
    nr, ng, nb = map_lightness(r, g, b)
    prefix = m.group(1)
    if m.group(6) is not None:
        return f"{prefix}{nr},{ng},{nb},{m.group(6)}\n"
    return f"{prefix}{nr},{ng},{nb}\n"


def main():
    global GAMMA, PROTECT, INVERT
    args = sys.argv[1:]
    pos = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--invert':
            INVERT = True
        elif a == '--gamma':
            i += 1; GAMMA = float(args[i])
        elif a == '--protect':
            i += 1; PROTECT = float(args[i])
        else:
            pos.append(a)
        i += 1
    if not pos:
        print(__doc__)
        sys.exit(1)
    src = pos[0]
    dst = pos[1] if len(pos) > 1 else pos[0]
    with open(src, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    out = [transform_line(ln) for ln in lines]
    with open(dst, 'w', encoding='utf-8') as f:
        f.writelines(out)
    changed = sum(1 for a, b in zip(lines, out) if a != b)
    print(f"darken-theme: {changed} color lines inverted -> {dst}")


if __name__ == '__main__':
    main()
