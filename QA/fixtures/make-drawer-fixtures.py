#!/usr/bin/env python3
"""Generate the Drawer fixtures for QA/tests/drawer-slots.sh (2.8: 96 bins per mode).

  drawer-40.dset  a brush .dset: the classic 30 slots (slot 1 has a 3x3 brush)
                  plus the extension block (DSX1) with slots 31..40; slot 40
                  holds a 7x5 brush. An older DRAW reads only the 30.
  drawer-40.draw  SAMPLES/COLOR CYCLING/candles.draw with a "drAx" chunk added:
                  brush slot 40 = 7x5, pattern slot 35 = 4x4.

Formats: GUI/DRAWER.BM (DRAWER_save_slot_image, DRAWER_put_grad_record,
DRAWER_write_ext_draw). INTEGER = int16 LE, a slot image = hasImage (-1 / 0),
w, h, w*h _UNSIGNED LONG (&HAARRGGBB, little-endian).
"""
import os, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
GMAX = 16  # GRADIENT_MAX_STOPS


def i16(v):
    return struct.pack('<h', v)


def slot(w=0, h=0, argb=0xFFFF0000):
    if w < 1:
        return i16(0)
    return i16(-1) + i16(w) + i16(h) + struct.pack('<I', argb) * (w * h)


def grad_record():
    b = i16(0) * 5 + b'\0' * 32 + i16(-1) + struct.pack('<f', 0.0)
    b += (struct.pack('<f', 0.0) + struct.pack('<I', 0)) * GMAX
    b += (struct.pack('<f', 0.0) + i16(0)) * GMAX
    b += i16(0) * GMAX
    return b


def make_dset(path):
    b = b'DST1' + i16(1) + i16(1) + i16(1)       # magic, version 1, brush mode, slot 1 picked
    b += slot(3, 3, 0xFF00FF00)                  # slot 1
    b += slot() * 29                             # slots 2..30
    b += b'DSX1' + i16(40)                       # extension: up to slot 40
    for i in range(31, 41):
        b += slot(7, 5, 0xFF2040FF) if i == 40 else slot()
    open(path, 'wb').write(b)


def png_chunk(typ, data):
    return struct.pack('>I', len(data)) + typ + data + struct.pack('>I', zlib.crc32(typ + data) & 0xFFFFFFFF)


def make_draw(src, path):
    png = open(src, 'rb').read()
    assert png[-12:-8] == b'\0\0\0\0' and png[-8:-4] == b'IEND', 'IEND is not last'
    raw = i16(1) + i16(40)                       # DRAWER_EXT_VERSION, last slot
    for i in range(31, 41):
        raw += slot(7, 5, 0xFFFFA000) if i == 40 else slot()   # brush
        raw += slot(4, 4, 0xFF008080) if i == 35 else slot()   # pattern
        raw += slot()                                          # gradient
        raw += grad_record()
    chunk = png_chunk(b'drAx', struct.pack('<i', len(raw)) + zlib.compress(raw, 9))
    open(path, 'wb').write(png[:-12] + chunk + png[-12:])


if __name__ == '__main__':
    make_dset(os.path.join(HERE, 'drawer-40.dset'))
    make_draw(os.path.join(ROOT, 'SAMPLES', 'COLOR CYCLING', 'candles.draw'), os.path.join(HERE, 'drawer-40.draw'))
    print('wrote drawer-40.dset, drawer-40.draw')
