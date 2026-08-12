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


# --- recolor mode: map a whole theme into a background/foreground scheme --------
RECOLOR = False
FG = BG_DARK = BG_LIGHT = None


def _hex(s):
    s = s.lstrip('#')
    if len(s) == 3:
        s = ''.join(c * 2 for c in s)
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def _lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def map_lightness(r, g, b):
    if RECOLOR:
        # Luminance ramp: dark chrome (backgrounds) -> BG-dark, mid (borders) ->
        # BG-light, bright (text/icons) -> FG. Mirrors recolor-images.py so the
        # panels/bars match the recolored button images.
        lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        if lum <= 0.5:
            return _lerp(BG_DARK, BG_LIGHT, lum / 0.5)
        return _lerp(BG_LIGHT, FG, (lum - 0.5) / 0.5)
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
    global GAMMA, PROTECT, INVERT, RECOLOR, FG, BG_DARK, BG_LIGHT
    args = sys.argv[1:]
    pos = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--invert':
            INVERT = True
        elif a == '--recolor':
            RECOLOR = True
        elif a == '--fg':
            i += 1; FG = _hex(args[i])
        elif a == '--bg-dark':
            i += 1; BG_DARK = _hex(args[i])
        elif a == '--bg-light':
            i += 1; BG_LIGHT = _hex(args[i])
        elif a == '--gamma':
            i += 1; GAMMA = float(args[i])
        elif a == '--protect':
            i += 1; PROTECT = float(args[i])
        else:
            pos.append(a)
        i += 1
    if RECOLOR and (FG is None or BG_DARK is None or BG_LIGHT is None):
        print("--recolor needs --fg, --bg-dark and --bg-light")
        sys.exit(1)
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
    mode = 'recolored' if RECOLOR else ('inverted' if INVERT else 'darkened')
    print(f"darken-theme: {changed} color lines {mode} -> {dst}")


if __name__ == '__main__':
    main()
