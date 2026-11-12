"""pngchunks.py FILE [TYPE...] - print a PNG's chunk types; with TYPEs, exit 1 unless all are there."""
import struct, sys
d = open(sys.argv[1], 'rb').read()
i, seen = 8, []
while i + 8 <= len(d):
    n, t = struct.unpack('>I4s', d[i:i + 8])
    seen.append(t.decode('latin1')); i += 12 + n
print(' '.join(seen))
sys.exit(0 if all(t in seen for t in sys.argv[2:]) else 1)
