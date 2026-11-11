#!/usr/bin/env python3
"""Generate the Swatches panel fixtures (QA/tests/swatches-*.sh).

swatches-ramps.gpl  8 columns x 20 rows of ramps (each column a hue, rows
                    lighter), a #SWS:SPACE gap, a named color: taller than the
                    floating panel, so it scrolls.
swatches-pad.aco    a Photoshop swatch file laid out 6 wide: 4 rows of ramps,
                    each row padded with black to 6 (Photoshop has no empty
                    cell); version 1 + version 2 (names). Loading it guesses
                    6 columns and turns the black filler into empty cells.
Run from anywhere: writes next to this script.
"""
import os, struct, colorsys
here = os.path.dirname(os.path.abspath(__file__))

rows = []
for r in range(20):
    for c in range(8):
        h = c / 8.0
        l = 0.15 + 0.7 * r / 19.0
        rr, gg, bb = colorsys.hls_to_rgb(h, l, 0.8)
        rows.append((int(rr * 255), int(gg * 255), int(bb * 255)))
with open(os.path.join(here, 'swatches-ramps.gpl'), 'w') as f:
    f.write('GIMP Palette\nName: QA Ramps\nColumns: 8\n#\n')
    for i, (r, g, b) in enumerate(rows):
        if i == 5:
            f.write('#SWS:SPACE\n')
        nm = 'Named Teal' if i == 2 else '%02x%02x%02x' % (r, g, b)
        f.write('%3d %3d %3d\t%s\n' % (r, g, b, nm))

# .aco: 4 ramps of 4 lightening steps across, padded to 6 with black
ents = []
for r in range(4):
    for c in range(6):
        if c < 4:
            rr, gg, bb = colorsys.hls_to_rgb(r / 4.0, 0.2 + 0.18 * c, 0.9)
            ents.append((int(rr * 255), int(gg * 255), int(bb * 255), 'Ramp %d.%d' % (r, c)))
        else:
            ents.append((0, 0, 0, ''))
def rec(e):
    return struct.pack('>HHHHH', 0, e[0] * 257, e[1] * 257, e[2] * 257, 0)
b = struct.pack('>HH', 1, len(ents)) + b''.join(rec(e) for e in ents)
b += struct.pack('>HH', 2, len(ents))
for e in ents:
    nm = e[3]
    b += rec(e) + struct.pack('>I', len(nm) + 1) + nm.encode('utf-16-be') + b'\0\0'
with open(os.path.join(here, 'swatches-pad.aco'), 'wb') as f:
    f.write(b)
print('wrote swatches-ramps.gpl (%d colors), swatches-pad.aco (%d entries)' % (len(rows), len(ents)))
