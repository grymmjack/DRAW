#!/usr/bin/env python3
"""Tiny dependency-free PNG/GPL writer for color cycling fixtures and examples.

    python3 DEV/tools/cycle-fixture.py OUTDIR      # writes OUTDIR/bands.png + bands.gpl

Used by DEV/tools/test-cycle-exports.sh (and the example generator) to build art
whose pixels are exact palette colors, so DRAW's --cycle ranges own them.
"""
import struct, sys, zlib, os


def write_png(path, w, h, px):
    """px[y][x] = (r, g, b, a)"""
    raw = b''.join(b'\x00' + bytes(c for p in row for c in p) for row in px)

    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def write_gpl(path, name, cols):
    with open(path, 'w') as f:
        f.write('GIMP Palette\nName: %s\nColumns: 16\n#\n' % name)
        for i, (r, g, b) in enumerate(cols):
            f.write('%3d %3d %3d\tc%d\n' % (r, g, b, i))


def bands(outdir):
    """16 colors; ranges 1-4 / 5-8 / 9-13 (index 12 duplicates 3); 14 static.
    Row 15 is transparent so exporters exercise the transparent index."""
    pal = [(0, 0, 0)] + [(30 + i * 14, 60, 220 - i * 12) for i in range(14)] + [(255, 255, 255)]
    pal[12] = pal[3]
    write_gpl(os.path.join(outdir, 'bands.gpl'), 'bands', pal)
    px = [[pal[1 + (x // 4) % 14] + (255,) for x in range(56)] for y in range(16)]
    px[15] = [(0, 0, 0, 0)] * 56
    write_png(os.path.join(outdir, 'bands.png'), 56, 16, px)


if __name__ == '__main__':
    bands(sys.argv[1] if len(sys.argv) > 1 else '.')
