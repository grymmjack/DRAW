#!/usr/bin/env python3
"""Generate the Swatches panel fixtures (QA/tests/swatches-*.sh).

swatches-ramps.gpl  8 columns x 20 rows of ramps (each column a hue, rows
                    lighter), a #SWS:SPACE gap, a named color: taller than the
                    floating panel, so it scrolls.
swatches-pad.aco    a Photoshop swatch file laid out 6 wide: 4 rows of ramps,
                    each row padded with black to 6 (Photoshop has no empty
                    cell); version 1 + version 2 (names). Loading it guesses
                    6 columns and turns the black filler into empty cells.
swatches-edit.gpl   a small set for the editing tests (swatches-select / -edit /
                    -move / -undo ...), 8 columns:
                      row 0: 1-8   a red ramp ("Red 1".."Red 8")
                      row 1: 9-12  a green ramp, 12 LOCKED; 13 = a row BREAK
                             (row 1 columns 4-7 stay empty: room for a box drag)
                      row 2: 14-19 a blue ramp, 20 an empty cell, 21 "Gold"
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
# the editing set
with open(os.path.join(here, 'swatches-edit.gpl'), 'w') as f:
    f.write('GIMP Palette\nName: QA Edit\nColumns: 8\n#\n')
    for k in range(8):
        v = 60 + k * 25
        f.write('%3d %3d %3d\tRed %d\n' % (v, 0, 0, k + 1))
    for k in range(4):
        v = 60 + k * 50
        if k == 3:
            f.write('#SWS:LOCK\n')
        f.write('%3d %3d %3d\tGreen %d\n' % (0, v, 0, k + 1))
    f.write('#SWS:BREAK\n')
    for k in range(6):
        v = 60 + k * 35
        f.write('%3d %3d %3d\tBlue %d\n' % (0, 0, v, k + 1))
    f.write('#SWS:SPACE\n')
    f.write('%3d %3d %3d\tGold\n' % (255, 200, 0))
print('wrote swatches-ramps.gpl (%d colors), swatches-pad.aco (%d entries)' % (len(rows), len(ents)))

# swatches-groups.ase  an Adobe Swatch Exchange file written here (not by
#                      DRAW): "Ink" (RGB), group "Skin" (3 RGB), group "Sky"
#                      (a CMYK cyan, a 50% Gray). DRAW reads it as
#                      Ink | Skin1 Skin2 Skin3 | Cyan Gray, the group labels
#                      on Skin1 and Cyan.
def ase_name(n):
    return struct.pack('>H', len(n) + 1) + n.encode('utf-16-be') + b'\0\0'
def ase_block(t, data):
    return struct.pack('>HI', t, len(data)) + data
def ase_color(n, model, vals):
    return ase_block(1, ase_name(n) + model + b''.join(struct.pack('>f', v) for v in vals) + struct.pack('>H', 2))
blocks = [ase_color('Ink', b'RGB ', [16/255, 32/255, 48/255]),
          ase_block(0xC001, ase_name('Skin')),
          ase_color('Skin1', b'RGB ', [1.0, 224/255, 189/255]),
          ase_color('Skin2', b'RGB ', [234/255, 192/255, 134/255]),
          ase_color('Skin3', b'RGB ', [141/255, 85/255, 36/255]),
          ase_block(0xC002, b''),
          ase_block(0xC001, ase_name('Sky')),
          ase_color('Cyan', b'CMYK', [1.0, 0.0, 0.0, 0.0]),
          ase_color('Gray', b'Gray', [0.5]),
          ase_block(0xC002, b'')]
with open(os.path.join(here, 'swatches-groups.ase'), 'wb') as f:
    f.write(b'ASEF' + struct.pack('>HHI', 1, 0, len(blocks)) + b''.join(blocks))
