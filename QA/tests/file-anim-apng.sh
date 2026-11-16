#!/bin/bash
# =============================================================================
# file-anim-apng.sh — QA test: a sheet with frames exports as an animated PNG
# (Animation 3.3, TOOLS/ANIM-EXPORT ANIM_APNG_export%).
#
# One APNG frame per frame shown, in loop order (ping-pong written out), each
# up for hold / fps s exactly (fcTL delay_num / delay_den); loops forever
# (acTL num_plays 0) or plays once (1); RGBA, so half-transparent pixels keep;
# ANIM_EXPORT_SCALE 2 doubles every pixel. The default image (IDAT) is frame
# 1, so a plain PNG viewer shows that.
#
# Exported through the batch CLI (`--export-anim out.apng`, throwaway HOME,
# no window). Read back by a python stdlib APNG reader (every chunk CRC, the
# zlib streams, sequence numbers, delays, each frame's RGBA against its cell)
# and by ffprobe / ImageMagick (an outside reader agrees).
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour, frame 1 also a half-transparent pixel; 4 frames at 10 fps,
# frame 2 held 3. The half-transparent pixel is black: LAYERS_flatten& (every
# export) composites with QB64's _BLEND onto a transparent image, which darkens
# the colour of a partly transparent pixel (pre-existing) - black stays black,
# so this checks what the APNG writer keeps: the alpha level.
# =============================================================================
info "=== Animation: animated PNG (APNG) export ==="

AP_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AP_T="$(mktemp -d /tmp/draw-qa-animapng-XXXXXX)"
mkdir -p "$AP_T/home"
AP_DRAW=()
AP_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    AP_DRAW+=(-fill "#${AP_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${AP_DRAW[@]}" -fill "#00000080" -draw "point 1,1" "PNG32:$AP_T/plain.png"
magick "$AP_T/plain.png" -depth 8 "RGBA:$AP_T/plain.rgba"
ap_blob() { python3 -c "import struct,sys;print(struct.pack('<12h',1,16,16,0,0,4,1,10,int(sys.argv[1]),2,1,3).hex())" "$1"; } # LOOPMODE
ap_sheet() { python3 "$AP_PY" put "$AP_T/plain.png" "$AP_T/$2.png" drAn "$(ap_blob "$1")"; } # LOOPMODE NAME
ap_export() { # IN OUT [ARGS...]
    local in=$1 out=$2; shift 2
    rm -f "$out"
    ( cd "$DRAW_ROOT" && HOME="$AP_T/home" XDG_CONFIG_HOME="$AP_T/home/.config" XDG_DATA_HOME="$AP_T/home/.local/share" \
      XDG_CACHE_HOME="$AP_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$in" "$@" --export-anim "$out" \
      </dev/null >>"$AP_T/log.txt" 2>&1 )
    [[ -s "$out" ]] || fail "DRAW wrote no APNG for $(basename "$in"): $(tail -3 "$AP_T/log.txt" | tr '\n' ' ')"
}
# APNG SCALE -> "WxH plays N delays d1/n1 ... cells c1 c2 ..." (cell k = which sheet cell frame k shows, ? = none), or "ERROR ..."
ap_read() {
    python3 - "$1" "$AP_T/plain.rgba" "$2" <<'PY'
import struct, sys, zlib
data = open(sys.argv[1], "rb").read(); sheet = open(sys.argv[2], "rb").read(); sc = int(sys.argv[3])
def cell(k):  # RGBA bytes of sheet cell k (1-4), scaled
    out = bytearray()
    for y in range(16 * sc):
        row = sheet[((y // sc) * 64 + (k - 1) * 16) * 4:((y // sc) * 64 + (k - 1) * 16 + 16) * 4]
        for x in range(16 * sc):
            out += row[(x // sc) * 4:(x // sc) * 4 + 4]
    return bytes(out)
try:
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "signature"
    p = 8; chunks = []
    while p < len(data):
        n, = struct.unpack(">I", data[p:p + 4]); t = data[p + 4:p + 8]; d = data[p + 8:p + 8 + n]
        crc, = struct.unpack(">I", data[p + 8 + n:p + 12 + n])
        assert zlib.crc32(t + d) & 0xffffffff == crc, "CRC of %s" % t
        chunks.append((t, d)); p += 12 + n
    assert chunks[0][0] == b"IHDR" and chunks[-1][0] == b"IEND", "IHDR / IEND"
    w, h, depth, ctype = struct.unpack(">IIBB", chunks[0][1][:10])
    assert (depth, ctype) == (8, 6), "not RGBA 8-bit"
    nf, plays = struct.unpack(">II", [d for t, d in chunks if t == b"acTL"][0])
    frames = []; seq = 0; cur = None
    for t, d in chunks:
        if t == b"fcTL":
            s, fw, fh, fx, fy, dn, dd, dop, bop = struct.unpack(">IIIIIHHBB", d)
            assert s == seq, "fcTL sequence %d, wanted %d" % (s, seq); seq += 1
            cur = {"delay": "%d/%d" % (dn, dd), "z": b"", "size": (fw, fh, fx, fy)}; frames.append(cur)
        elif t == b"IDAT":
            assert len(frames) == 1, "IDAT is not frame 1"; cur["z"] += d
        elif t == b"fdAT":
            s, = struct.unpack(">I", d[:4]); assert s == seq, "fdAT sequence"; seq += 1; cur["z"] += d[4:]
    assert len(frames) == nf, "acTL says %d frames, %d fcTL" % (nf, len(frames))
    cells = []
    for f in frames:
        assert f["size"] == (w, h, 0, 0), "partial frame"
        raw = zlib.decompress(f["z"])  # checks the adler-32 too
        px = b"".join(raw[r * (w * 4 + 1) + 1:(r + 1) * (w * 4 + 1)] for r in range(h))
        assert all(raw[r * (w * 4 + 1)] == 0 for r in range(h)), "row filter"
        cells.append(next((str(k) for k in range(1, 5) if px == cell(k)), "?"))
    print("%dx%d plays %d delays %s cells %s" % (w, h, plays, " ".join(f["delay"] for f in frames), " ".join(cells)))
except Exception as e:
    print("ERROR", e)
PY
}
ap_ffn() { ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 "$1" 2>/dev/null; }

# -- forward: 4 frames, exact delays, every pixel, loops --
ap_sheet 0 fwd
ap_export "$AP_T/fwd.png" "$AP_T/fwd.apng"
AP_R=$(ap_read "$AP_T/fwd.apng" 1)
[[ "$AP_R" == "16x16 plays 0 delays 1/10 3/10 1/10 1/10 cells 1 2 3 4" ]] \
    && pass "forward: a valid APNG (CRCs, zlib, sequence), 16x16 RGBA, 4 frames 1 2 3 4, delays 1/10 3/10 1/10 1/10 s, loops" || fail "forward APNG reads: '$AP_R'"
AP_A=$(python3 -c "import sys;d=open(sys.argv[1],'rb').read();print(d[(1*64+1)*4+3])" "$AP_T/plain.rgba")
[[ "$AP_R" == *"cells 1 "* && "$AP_A" -gt 0 && "$AP_A" -lt 255 ]] && pass "frame 1's half-transparent pixel (alpha $AP_A) kept exactly" || fail "half alpha: fixture alpha '$AP_A', frames '$AP_R'"
AP_FF=$(ap_ffn "$AP_T/fwd.apng")
[[ "$AP_FF" == 4 ]] && pass "ffprobe reads 4 frames" || fail "ffprobe frames: '$AP_FF'"
magick "PNG:$AP_T/fwd.apng" "PNG32:$AP_T/still.png" 2>/dev/null
magick "$AP_T/plain.png" -crop 16x16+0+0 +repage "PNG32:$AP_T/c1.png"
AP_AE=$(magick compare -metric AE "$AP_T/still.png" "$AP_T/c1.png" null: 2>&1 | awk '{print $1}')
[[ "$AP_AE" == 0 ]] && pass "a plain PNG reader shows frame 1" || fail "the default image is not frame 1 ($AP_AE pixels differ)"

# -- ping-pong, once --
ap_sheet 2 ping
ap_export "$AP_T/ping.png" "$AP_T/ping.apng"
AP_R=$(ap_read "$AP_T/ping.apng" 1)
[[ "$AP_R" == "16x16 plays 0 delays 1/10 3/10 1/10 1/10 1/10 3/10 cells 1 2 3 4 3 2" ]] \
    && pass "ping-pong written out: 1 2 3 4 3 2" || fail "ping-pong APNG reads: '$AP_R'"
ap_sheet 3 once
ap_export "$AP_T/once.png" "$AP_T/once.apng"
AP_R=$(ap_read "$AP_T/once.apng" 1)
[[ "$AP_R" == "16x16 plays 1 delays 1/10 3/10 1/10 1/10 cells 1 2 3 4" ]] && pass "play once: num_plays 1" || fail "once APNG reads: '$AP_R'"

# -- 2x --
ap_export "$AP_T/fwd.png" "$AP_T/x2.apng" --option ANIM_EXPORT_SCALE=2
AP_R=$(ap_read "$AP_T/x2.apng" 2)
[[ "$AP_R" == "32x32 plays 0 delays 1/10 3/10 1/10 1/10 cells 1 2 3 4" ]] && pass "ANIM_EXPORT_SCALE 2: 32x32, every pixel doubled" || fail "2x APNG reads: '$AP_R'"

rm -rf "$AP_T"
assert_window_exists
