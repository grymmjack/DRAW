"""brush-gifs.py DIR... - an animated GIF beside every AnimBrush strip (DIR/*/brushes/*.png):
the strip's drAn chunk gives cel size, columns x rows and fps. 1:1 and transparent, so the
GIF loads straight back into DRAW (ANIM > AnimBrush > Load from GIF)."""
import struct, subprocess, sys, glob, os, tempfile

def dran(f):
    d = open(f, 'rb').read(); i = 8
    while i < len(d):
        n, t = struct.unpack('>I4s', d[i:i + 8])
        if t == b'drAn': return struct.unpack('<8h', d[i + 8:i + 24])
        i += 12 + n

def cels_from_pack(f):
    # NAME-pack.txt: " 3  planet  150x100  4 cels  ..." - the cel count when a grid is not full
    name = os.path.splitext(os.path.basename(f))[0]; bdir = os.path.dirname(f)
    for p in glob.glob(os.path.join(os.path.dirname(bdir), '*-pack.txt')):
        for line in open(p):
            w = line.split()
            if len(w) > 4 and w[1] == name and w[4] == 'cels': return int(w[3])
    return None

n = 0
for root in sys.argv[1:]:
    for f in sorted(glob.glob(os.path.join(root, '*', 'brushes', '*.png'))):
        a = dran(f)
        if not a: print('no drAn:', f); continue
        _, cw, ch, gut, mar, cols, rows, fps = a
        count = cels_from_pack(f) or cols * rows
        delay = max(2, round(100 / max(1, fps)))
        with tempfile.TemporaryDirectory() as t:
            frames = []
            for k in range(count):
                c, r = k % cols, k // cols
                x, y = mar + c * (cw + gut), mar + r * (ch + gut)
                out = os.path.join(t, '%03d.png' % k)
                subprocess.run(['magick', f, '-crop', '%dx%d+%d+%d' % (cw, ch, x, y), '+repage', out], check=True)
                frames.append(out)
            g = f[:-4] + '.gif'
            subprocess.run(['magick', '-dispose', 'Background', '-delay', str(delay), *frames, '-loop', '0', g], check=True)
        n += 1
print(n, 'GIFs')
