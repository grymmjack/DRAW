#!/usr/bin/env python3
"""Write QA/fixtures/aseprite-frames.aseprite: 16x8, RGBA, two layers, three frames.

Frame 1 is the picture an import must show: on "bg" a dark blue fill; on "ink" an
opaque black 2x2 block, a 50%-alpha red 2x2 block and a 50%-alpha white 2x2 block.
Frames 2 and 3 draw different things on "ink" (frame 3 links frame 2's bg cel),
so an import that paints every frame on top of the other shows extra pixels.
Re-run to regenerate; the expected frame-1 picture is aseprite-frames-f1.png.
"""
import struct, zlib, os
W, H = 16, 8
here = os.path.dirname(os.path.abspath(__file__))

def chunk(ctype, data): return struct.pack('<IH', 6 + len(data), ctype) + data
def layer(name, flags=3):  # visible + editable, normal layer, normal blend, opacity 255
    n = name.encode()
    return chunk(0x2004, struct.pack('<HHHHHHB3s', flags, 0, 0, 0, 0, 0, 255, b'\0' * 3) + struct.pack('<H', len(n)) + n)
def cel(li, x, y, w, h, px):
    return chunk(0x2005, struct.pack('<HhhBHh5s', li, x, y, 255, 2, 0, b'\0' * 5) + struct.pack('<HH', w, h) + zlib.compress(bytes(px)))
def linked(li, frame):
    return chunk(0x2005, struct.pack('<HhhBHh5s', li, 0, 0, 255, 1, 0, b'\0' * 5) + struct.pack('<H', frame))
def frame(chunks, dur=100):
    body = b''.join(chunks)
    return struct.pack('<IHHH2sI', 16 + len(body), 0xF1FA, len(chunks), dur, b'\0\0', len(chunks)) + body
def block(w, h, rgba): return list(rgba) * (w * h)

bg = block(W, H, (16, 32, 96, 255))
ink1 = [0] * (W * H * 4)
def put(img, x, y, rgba, w=2, h=2):
    for j in range(h):
        for i in range(w):
            o = ((y + j) * W + x + i) * 4; img[o:o + 4] = rgba
put(ink1, 2, 3, (0, 0, 0, 255)); put(ink1, 7, 3, (255, 0, 0, 128)); put(ink1, 12, 3, (255, 255, 255, 128))
ink2 = [0] * (W * H * 4); put(ink2, 0, 0, (0, 255, 0, 255), 16, 1)
ink3 = [0] * (W * H * 4); put(ink3, 0, 7, (255, 255, 0, 255), 16, 1)
frames = [
    frame([layer('bg'), layer('ink'), cel(0, 0, 0, W, H, bg), cel(1, 0, 0, W, H, ink1)]),
    frame([cel(0, 0, 0, W, H, bg), cel(1, 0, 0, W, H, ink2)]),
    frame([linked(0, 1), cel(1, 0, 0, W, H, ink3)]),
]
body = b''.join(frames)
hdr = struct.pack('<IHHHHHIHII', 128 + len(body), 0xA5E0, len(frames), W, H, 32, 1, 100, 0, 0)
hdr += struct.pack('<B3sH', 0, b'\0' * 3, 0) + struct.pack('<BBhhHH', 1, 1, 0, 0, 0, 0)
hdr += b'\0' * (128 - len(hdr))
open(os.path.join(here, 'aseprite-frames.aseprite'), 'wb').write(hdr + body)

# expected frame 1: ink over bg, normal blending
out = []
for p in range(W * H):
    b = bg[p * 4:p * 4 + 4]; s = ink1[p * 4:p * 4 + 4]; a = s[3] / 255
    out += [round(s[k] * a + b[k] * (1 - a)) for k in range(3)] + [255]
ppm = os.path.join(here, 'aseprite-frames-f1.rgba'); open(ppm, 'wb').write(bytes(out))
os.system(f"magick -size {W}x{H} -depth 8 rgba:'{ppm}' '{os.path.join(here, 'aseprite-frames-f1.png')}'"); os.remove(ppm)
print("wrote aseprite-frames.aseprite + aseprite-frames-f1.png")
