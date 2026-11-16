#!/bin/bash
# =============================================================================
# animbrush-load.sh — QA test: load an AnimBrush from a file (TOOLS/ANIM-BRUSH, A5).
#
#   - ANIM > AnimBrush > Load... (the command palette, the file dialog):
#       a strip PNG (a row of squares), an animated GIF (full frames), an
#       optimized GIF (partial frames, disposal), an APNG (partial frames,
#       blend over, dispose background), a PNG with frames (drAn)
#     each gives its frames as cels, cropped to what is drawn in any of them
#   - a picture without frames: no AnimBrush, the brush stays as it was
#   - a drop on an empty Drawer bin: the AnimBrush goes in that bin
#   - a drop of a picture without frames on a bin: a plain brush, as before
#
# Expected CRCs are worked out here from the frames. Dump: ABR / ABRC, ABBIN.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEFAULT_DSET_BRUSHES_FILE=QA/fixtures/drawer-40.dset DRAWER_MINI_PALETTE=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== AnimBrush: load from a file ==="

LD_DIR="/tmp/draw-qa-abload-$$"
mkdir -p "$LD_DIR"
LD_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"

# three 16x16 frames: a 2x3 bar moving right, each its own colour
LD_COLORS=(ff2020 20d020 2040ff)
for k in 0 1 2; do
    x=$(( 2 + k * 3 ))
    magick -size 16x16 xc:none -fill "#${LD_COLORS[$k]}" -draw "rectangle $x,4 $(( x + 1 )),6" "PNG32:$LD_DIR/f$k.png"
done
magick "$LD_DIR/f0.png" "$LD_DIR/f1.png" "$LD_DIR/f2.png" +append "PNG32:$LD_DIR/strip.png"
magick -dispose Background -delay 10 "$LD_DIR/f0.png" "$LD_DIR/f1.png" "$LD_DIR/f2.png" -loop 0 "$LD_DIR/anim.gif"
# partial frames at offsets: 1 the red bar (dispose none), 2 a green 2x3 at (5,4) (dispose
# background), 3 a blue 2x3 at (8,4) - a player shows red / red+green / red+blue
magick -delay 10 -dispose none "$LD_DIR/f0.png" -dispose background \( -size 2x3 xc:'#20d020' -set page 16x16+5+4 \) \
    -dispose none \( -size 2x3 xc:'#2040ff' -set page 16x16+8+4 \) -loop 0 "$LD_DIR/opt.gif"
magick -size 20x16 xc:none -fill '#808080' -draw "rectangle 3,3 9,9" "PNG32:$LD_DIR/plain.png"
for k in 0 1 2; do magick "$LD_DIR/f$k.png" -depth 8 "RGBA:$LD_DIR/f$k.rgba"; done
# a 64x16 sheet of 4 frames (drAn), an L of its own colour in each
LD_SC=(c04040 40c040 4040c0 c0c040); LD_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 ))
    LD_DRAW+=(-fill "#${LD_SC[$n]}" -draw "rectangle $(( x + 5 )),5 $(( x + 7 )),5" -draw "rectangle $(( x + 5 )),6 $(( x + 5 )),9")
    (( n > 0 )) && LD_DRAW+=(-draw "point $(( x + 7 )),$(( 6 + n ))")
done
magick -size 64x16 xc:none "${LD_DRAW[@]}" "PNG32:$LD_DIR/sheetplain.png"
magick "$LD_DIR/sheetplain.png" -depth 8 "RGBA:$LD_DIR/sheet.rgba"
python3 "$LD_PY" put "$LD_DIR/sheetplain.png" "$LD_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")"

cat > "$LD_DIR/fx.py" <<'EOF'
import sys, struct, zlib
def crc(b): return '0' if not any(b) else format(zlib.crc32(b), 'x')
def bgra(raw, w, x, y):
    r, g, b, a = raw[(y * w + x) * 4:(y * w + x) * 4 + 4]
    return bytes((b, g, r, a)) if a else bytes(4)
mode, d = sys.argv[1], sys.argv[2]
if mode == 'cels':      # the 3 frames (f*, or o* with a 3rd arg) cropped to the union box (x 2..9, y 4..6)
    out, strip = [], []
    fr = [open('%s/f%d.rgba' % (d, k), 'rb').read() for k in range(3)]
    if len(sys.argv) > 3:  # the partial-frame GIF as played: red, red + green, red + blue
        over = lambda a, b: b''.join(b[i:i + 4] if b[i + 3] else a[i:i + 4] for i in range(0, len(a), 4))
        fr = [fr[0], over(fr[0], fr[1]), over(fr[0], fr[2])]
    for k in range(3):
        raw = fr[k]
        rows = [[bgra(raw, 16, x, y) for x in range(2, 10)] for y in range(4, 7)]
        out.append(crc(b''.join(b''.join(r) for r in rows))); strip.append(rows)
    print(' '.join(out))
    print(crc(b''.join(b''.join(b''.join(strip[k][y]) for k in range(3)) for y in range(3))))
elif mode == 'sheet':   # the sheet's 4 cels: the 3x5 box at (5,5) of each frame
    raw = open(d + '/sheet.rgba', 'rb').read(); cels = []
    for f in range(4):
        cels.append([[bgra(raw, 64, f * 16 + 5 + x, 5 + y) for x in range(3)] for y in range(5)])
    print(' '.join(crc(b''.join(b''.join(r) for r in c)) for c in cels))
    print(crc(b''.join(b''.join(b''.join(cels[k][y]) for k in range(4)) for y in range(5))))
elif mode == 'apng':    # an APNG of the 3 frames: 1 full (dispose background), 2 the bar alone
                        # over the cleared canvas (blend over, dispose background), 3 the bar (source)
    def chunk(t, b): return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
    def idat(raw, w, h, x0, y0, fw, fh):
        rows = b''
        for y in range(y0, y0 + fh):
            rows += b'\0' + raw[(y * w + x0) * 4:(y * w + x0 + fw) * 4]
        return zlib.compress(rows)
    def fctl(seq, fw, fh, x, y, dop, bop):
        return chunk(b'fcTL', struct.pack('>IIIIIHHBB', seq, fw, fh, x, y, 1, 10, dop, bop))
    raws = [open('%s/f%d.rgba' % (d, k), 'rb').read() for k in range(3)]
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 16, 16, 8, 6, 0, 0, 0))
    png += chunk(b'acTL', struct.pack('>II', 3, 0))
    png += fctl(0, 16, 16, 0, 0, 1, 0) + chunk(b'IDAT', idat(raws[0], 16, 16, 0, 0, 16, 16))
    png += fctl(1, 2, 3, 5, 4, 1, 1) + chunk(b'fdAT', struct.pack('>I', 2) + idat(raws[1], 16, 16, 5, 4, 2, 3))
    png += fctl(3, 2, 3, 8, 4, 0, 0) + chunk(b'fdAT', struct.pack('>I', 4) + idat(raws[2], 16, 16, 8, 4, 2, 3))
    png += chunk(b'IEND', b'')
    open(d + '/anim.apng', 'wb').write(png)
EOF
{ read -r WANT_CELS; read -r WANT_STRIP; } <<< "$(python3 "$LD_DIR/fx.py" cels "$LD_DIR")"
{ read -r OPT_CELS; read -r _; } <<< "$(python3 "$LD_DIR/fx.py" cels "$LD_DIR" o)"
{ read -r SHEET_CELS; read -r SHEET_STRIP; } <<< "$(python3 "$LD_DIR/fx.py" sheet "$LD_DIR")"
python3 "$LD_DIR/fx.py" apng "$LD_DIR"

ld_line() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
ld_read() {
    dk_settle
    read -r _ AB_N AB_CUR AB_W AB_H _ _ AB_ON _ _ _ <<< "$(ld_line ABR)"
    AB_CELS=$(ld_line ABRC | cut -s -d' ' -f2- | tr ' ' '\n' | cut -d: -f2 | tr '\n' ' ' | sed 's/ $//')
    BINS=$(grep -m1 '^ABBIN' "$DK_DUMP" | cut -s -d' ' -f2-)
}
ld_s() { echo "n=${AB_N:-?} ${AB_W:-?}x${AB_H:-?} on=${AB_ON:-?} cels [${AB_CELS:-}] bins [${BINS:-}]"; }
ld_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
ld_load() { # FILE (a name in LD_DIR, the dialog's folder)
    ld_cmd "animbrush: load"; wait_for 1.0 "the Load dialog"
    type_text "$1"; wait_for 0.4 "typed"; key Return; wait_for 1.5 "loaded"
    ld_read
}
bin_xy() {
    local DL_COLS DL_VIS DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY DL_ROW0 i r c
    read -r _ DL_COLS _ DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(ld_line DRAWERL)"
    read -r _ DL_ROW0 _ <<< "$(ld_line DRAWERR)"
    [[ -n "$DL_COLS" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
ld_drop() { # FILE BIN - the QA drop hook: a path in <dump>.drop is an OS drop at the pointer
    bin_xy "$2" || { fail "bin $2 not showing"; return 1; }
    hover "$BX" "$BY"; sleep 0.3; hover $(( BX + 1 )) "$BY"; sleep 0.3
    echo "$1" > "$DK_DUMP.drop"
    wait_for 1.5 "dropped"
    ld_read
}

info "Launching (the dialog opens in the fixtures' folder)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="--option LAST_DIR_OPEN=$LD_DIR"
draw_launch 15
wait_for 1.5 "launched"
assert_no_crash
dk_begin
ld_read

ld_load strip.png
[[ "$AB_N" == 3 && "$AB_W" == 8 && "$AB_H" == 3 && "$AB_ON" == -1 && "$AB_CELS" == "$WANT_CELS" ]] \
    && pass "a strip PNG (3 squares): 3 cels, cropped to 8x3 around the bars" || fail "strip: $(ld_s), wanted [$WANT_CELS]"
ld_load anim.gif
[[ "$AB_N" == 3 && "$AB_W" == 8 && "$AB_H" == 3 && "$AB_CELS" == "$WANT_CELS" ]] && pass "an animated GIF: its 3 frames as cels" || fail "gif: $(ld_s), wanted [$WANT_CELS]"
ld_load opt.gif
[[ "$AB_N" == 3 && "$AB_CELS" == "$OPT_CELS" && "$OPT_CELS" != "$WANT_CELS" ]] && pass "a GIF of partial frames at offsets (disposal none / background): as a player shows it" || fail "optimized gif: $(ld_s), wanted [$OPT_CELS]"
ld_load anim.apng
[[ "$AB_N" == 3 && "$AB_W" == 8 && "$AB_H" == 3 && "$AB_CELS" == "$WANT_CELS" ]] && pass "an APNG (partial frames, blend over, dispose): the same 3 cels" || fail "apng: $(ld_s), wanted [$WANT_CELS]"
ld_load sheet.png
[[ "$AB_N" == 4 && "$AB_W" == 3 && "$AB_H" == 5 && "$AB_CELS" == "$SHEET_CELS" ]] && pass "a PNG with frames (drAn): its 4 cells as cels (3x5)" || fail "sheet: $(ld_s), wanted [$SHEET_CELS]"
ld_load plain.png
[[ "$AB_N" == 4 && "$AB_CELS" == "$SHEET_CELS" ]] && pass "a picture without frames: no new AnimBrush, the brush stays" || fail "plain: $(ld_s)"
screenshot "animbrush-load"

# -- drops on the Drawer's bins (bin 1 holds a brush, bins 2.. are empty) --
ld_drop "$LD_DIR/anim.gif" 2
[[ "$BINS" == "2:3:8:3:$WANT_STRIP" && "$AB_N" == 3 ]] && pass "an animated GIF dropped on empty bin 2: an AnimBrush in that bin" || fail "gif drop: $(ld_s)"
ld_drop "$LD_DIR/sheet.png" 1
[[ "$BINS" == "2:3:8:3:$WANT_STRIP 3:4:3:5:$SHEET_STRIP" && "$AB_N" == 4 ]] && pass "dropped on a full bin (1): the first free bin (3) takes it" || fail "sheet drop: $(ld_s)"
ld_drop "$LD_DIR/plain.png" 4
[[ "$BINS" == "2:3:8:3:$WANT_STRIP 3:4:3:5:$SHEET_STRIP" && "$AB_N" == 0 && "$AB_ON" == -1 ]] && pass "a picture without frames dropped on a bin: a plain brush, as before" || fail "plain drop: $(ld_s)"

rm -rf "$LD_DIR"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
info "=== AnimBrush: load PASSED ==="
