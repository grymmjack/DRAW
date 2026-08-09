#!/usr/bin/env python3
"""
tdf-repack.py — deduplicate a TheDraw (.TDF) font corpus into DRAW's shipped bundles.

The wild corpus (~1238 files / 8621 faces / 51 MB) is roughly half duplicates: the same
face reappears in dozens of "collection" bundles under different names. This tool hashes
each face by its *content* (lookup table + glyph block), keeps the first occurrence, and
repacks the survivors into one bundle per font type:

    ASSETS/FONTS/THEDRAW/COLOR.TDF    + COLOR.TDX
    ASSETS/FONTS/THEDRAW/BLOCK.TDF    + BLOCK.TDX
    ASSETS/FONTS/THEDRAW/OUTLINE.TDF  + OUTLINE.TDX

Face records are copied VERBATIM — no re-encoding — so the output is byte-identical to the
source for every glyph and cannot introduce rendering drift. Only the bundle header and the
face ordering are new.

The .TDX sidecar is a DRAW-specific fixed-record index so the app can list thousands of
faces without walking the whole bundle, and can SEEK straight to one face's glyph block.
See GUI/TDF-FONT.BI for the matching QB64 TYPE.

    .TDX layout (little-endian, packed):
        "DRAWTDX1"  8 bytes magic
        u32         faceCount
        faceCount * 32-byte records:
            u32  offset     absolute offset of the FF00AA55 record in the .TDF
            u32  blockSize  glyph block length
            u8   type       0=outline 1=block 2=color
            u8   spacing    font's own inter-glyph gap
            u8   glyphCount defined glyphs, 0..94
            u8   maxH       TRUE max glyph height in cells (measured, clamped 255)
            u8   maxW       TRUE max glyph width in cells  (measured, clamped 255)
            u8   nameLen
            char name[16]
            char pad[2]

Usage:
    python3 DEV/tdf-repack.py <corpus-dir> [-o ASSETS/FONTS/THEDRAW] [--manifest]

@author Rick Christy <grymmjack@gmail.com>
"""

import argparse
import hashlib
import os
import struct
import sys
from collections import Counter

TDF_ID = b"TheDraw FONTS file"
CTRL_Z = 0x1A
FONT_INDICATOR = 0xFF00AA55
CHAR_TABLE_SIZE = 94  # '!'..'~'
INVALID_GLYPH = 0xFFFF
NAME_FIELD = 12  # bytes always reserved for the name

TYPE_NAMES = {0: "OUTLINE", 1: "BLOCK", 2: "COLOR"}

TDX_MAGIC = b"DRAWTDX1"
TDX_REC = struct.Struct("<IIBBBBBB16s2s")  # 32 bytes
assert TDX_REC.size == 32


class Face:
    """One parsed font record, kept as its verbatim source bytes plus decoded metadata."""

    __slots__ = ("name", "ftype", "spacing", "block_size", "raw", "glyph_count",
                 "max_w", "max_h", "digest", "source")

    def __init__(self, name, ftype, spacing, block_size, raw, glyph_count,
                 max_w, max_h, digest, source):
        self.name = name
        self.ftype = ftype
        self.spacing = spacing
        self.block_size = block_size
        self.raw = raw
        self.glyph_count = glyph_count
        self.max_w = max_w
        self.max_h = max_h
        self.digest = digest
        self.source = source


def measure_glyph(blk, off, ftype):
    """Walk one glyph's byte stream and return its TRUE (cells_wide, cells_tall).

    The two declared width/height bytes are advisory — parts of the corpus carry values as
    absurd as 244x223, which at 8x16 px per cell would allocate a 1952x3568 image for a
    single character. Counting cells between CR (13) separators up to the NUL terminator is
    what the glyph actually occupies.
    """
    n = len(blk)
    if off + 2 > n:
        return 0, 0
    p = off + 2  # skip declared width/height
    w = h = run = 0
    rows_seen = False
    while p < n:
        ch = blk[p]
        p += 1
        if ch == 0:
            break
        if ch == 13:  # newline
            w = max(w, run)
            run = 0
            h += 1
            rows_seen = True
            continue
        if ch == ord('&'):  # end marker
            continue
        run += 1
        rows_seen = True
        if ftype == 2 and p < n:  # colour faces: every glyph byte carries an attribute byte
            p += 1
    w = max(w, run)
    if run > 0 or not rows_seen:
        h += 1
    return min(w, 255), min(h, 255)


def parse_bundle(data, source):
    """Yield Face objects from one .TDF file. Raises ValueError on a malformed header."""
    if len(data) < 20:
        raise ValueError("file too short")
    if data[0] != len(TDF_ID) + 1:
        raise ValueError("id length mismatch")
    if data[1:1 + len(TDF_ID)] != TDF_ID:
        raise ValueError("id mismatch")
    if data[19] != CTRL_Z:
        raise ValueError("missing ctrl-z")

    o = 20
    while o < len(data):
        if data[o] == 0:  # bundle terminator
            break
        start = o
        if o + 4 > len(data):
            break
        if struct.unpack_from("<I", data, o)[0] != FONT_INDICATOR:
            raise ValueError(f"font indicator mismatch at {o}")
        o += 4

        name_len = data[o]
        o += 1
        raw_name = data[o:o + min(name_len, 16)]
        raw_name = raw_name.split(b"\0")[0]
        name = raw_name.decode("latin-1", "replace").strip()
        o += NAME_FIELD + 4  # fixed name field, then 4 magic bytes

        ftype = data[o]
        o += 1
        if ftype not in TYPE_NAMES:
            raise ValueError(f"unsupported type {ftype}")
        spacing = data[o]
        o += 1
        block_size = struct.unpack_from("<H", data, o)[0]
        o += 2

        if o + CHAR_TABLE_SIZE * 2 > len(data):
            raise ValueError("truncated char table")
        lookup = struct.unpack_from(f"<{CHAR_TABLE_SIZE}H", data, o)
        o += CHAR_TABLE_SIZE * 2

        if o + block_size > len(data):
            raise ValueError("truncated glyph block")
        blk = data[o:o + block_size]
        o += block_size

        glyph_count = 0
        max_w = max_h = 0
        for off in lookup:
            if off == INVALID_GLYPH or off >= block_size:
                continue
            glyph_count += 1
            gw, gh = measure_glyph(blk, off, ftype)
            max_w = max(max_w, gw)
            max_h = max(max_h, gh)

        digest = hashlib.blake2b(
            struct.pack(f"<{CHAR_TABLE_SIZE}H", *lookup) + blk, digest_size=16
        ).digest()

        yield Face(name, ftype, spacing, block_size, data[start:o],
                   glyph_count, max_w, max_h, digest, source)


def write_bundle(path, faces):
    """Write a .TDF bundle + its .TDX index. Returns (tdf_bytes, tdx_bytes)."""
    out = bytearray()
    out.append(len(TDF_ID) + 1)
    out += TDF_ID
    out.append(CTRL_Z)

    index = bytearray()
    index += TDX_MAGIC
    index += struct.pack("<I", len(faces))

    for f in faces:
        offset = len(out)
        out += f.raw
        nm = f.name.encode("latin-1", "replace")[:16]
        index += TDX_REC.pack(offset, f.block_size, f.ftype, f.spacing,
                              f.glyph_count, f.max_h, f.max_w, len(nm),
                              nm.ljust(16, b"\0"), b"\0\0")
    out.append(0)  # bundle terminator

    with open(path, "wb") as fh:
        fh.write(out)
    with open(os.path.splitext(path)[0] + ".TDX", "wb") as fh:
        fh.write(index)
    return len(out), len(index)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("corpus", help="directory tree of source .TDF files")
    ap.add_argument("-o", "--outdir", default="ASSETS/FONTS/THEDRAW",
                    help="destination directory (default: %(default)s)")
    ap.add_argument("--manifest", action="store_true",
                    help="also write faces.csv listing every kept face and its origin")
    args = ap.parse_args()

    seen = {}
    kept = {0: [], 1: [], 2: []}
    files = errors = total = dupes = empty = 0
    err_detail = []

    for dirpath, _, filenames in os.walk(args.corpus):
        for fn in sorted(filenames):
            if not fn.lower().endswith(".tdf"):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, args.corpus)
            files += 1
            try:
                with open(path, "rb") as fh:
                    data = fh.read()
                for face in parse_bundle(data, rel):
                    total += 1
                    if face.glyph_count == 0:
                        empty += 1
                        continue
                    if face.digest in seen:
                        dupes += 1
                        continue
                    seen[face.digest] = rel
                    kept[face.ftype].append(face)
            except Exception as exc:  # a malformed bundle must not sink the whole run
                errors += 1
                err_detail.append(f"{rel}: {exc}")

    for group in kept.values():
        group.sort(key=lambda f: (f.name.upper(), f.source))

    os.makedirs(args.outdir, exist_ok=True)
    print(f"scanned {files} files — {total} faces, {dupes} duplicate, "
          f"{empty} empty, {errors} unreadable")
    if err_detail:
        for line in err_detail[:10]:
            print(f"  ! {line}")
        if len(err_detail) > 10:
            print(f"  ! ...and {len(err_detail) - 10} more")

    grand = 0
    for ftype, label in TYPE_NAMES.items():
        faces = kept[ftype]
        if not faces:
            print(f"  {label:<8} no faces — skipped")
            continue
        dest = os.path.join(args.outdir, f"{label}.TDF")
        tdf_sz, tdx_sz = write_bundle(dest, faces)
        grand += tdf_sz + tdx_sz
        widest = max(f.max_w for f in faces)
        tallest = max(f.max_h for f in faces)
        print(f"  {label:<8} {len(faces):>5} faces  {tdf_sz / 1e6:>6.1f} MB"
              f"  + {tdx_sz / 1024:>5.1f} KB index"
              f"   max cell extent {widest}x{tallest}")

    print(f"total shipped: {grand / 1e6:.1f} MB")

    if args.manifest:
        mpath = os.path.join(args.outdir, "faces.csv")
        with open(mpath, "w", encoding="utf-8") as fh:
            fh.write("bundle,index,name,type,spacing,glyphs,max_w,max_h,source\n")
            for ftype, label in TYPE_NAMES.items():
                for i, f in enumerate(kept[ftype]):
                    nm = f.name.replace('"', "'")
                    fh.write(f"{label},{i},\"{nm}\",{label},{f.spacing},"
                             f"{f.glyph_count},{f.max_w},{f.max_h},\"{f.source}\"\n")
        print(f"manifest: {mpath}")

    dist = Counter(f.max_h for group in kept.values() for f in group)
    tall = sum(v for k, v in dist.items() if k > 24)
    print(f"faces taller than 24 cells: {tall} (renderer must clamp)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
