#!/usr/bin/env python3
"""Read / add PNG chunks for QA tests (stdlib only).

  png-chunk.py get IN TYPE              -> payload as hex, or "none"
  png-chunk.py put IN OUT TYPE HEX      -> copy IN to OUT with a TYPE chunk
                                           (payload HEX) inserted before IEND
  png-chunk.py types IN                 -> chunk types in order
"""
import struct
import sys
import zlib


def chunks(data):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        sys.exit("not a PNG")
    p = 8
    while p + 8 <= len(data):
        n, = struct.unpack(">I", data[p:p + 4])
        t = data[p + 4:p + 8].decode("latin-1")
        yield p, t, data[p + 8:p + 8 + n]
        p += 12 + n
        if t == "IEND":
            break


def main(a):
    data = open(a[1], "rb").read()
    if a[0] == "get":
        for _, t, body in chunks(data):
            if t == a[2]:
                print(body.hex())
                return
        print("none")
    elif a[0] == "types":
        print(" ".join(t for _, t, _ in chunks(data)))
    elif a[0] == "put":
        body = bytes.fromhex(a[4])
        t = a[3].encode("latin-1")
        new = struct.pack(">I", len(body)) + t + body + struct.pack(">I", zlib.crc32(t + body) & 0xFFFFFFFF)
        iend = [p for p, t2, _ in chunks(data) if t2 == "IEND"][0]
        open(a[2], "wb").write(data[:iend] + new + data[iend:])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
