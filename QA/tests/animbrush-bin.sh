#!/bin/bash
# =============================================================================
# animbrush-bin.sh — QA test: an AnimBrush in a Drawer brush bin (TOOLS/ANIM-BRUSH, A4).
#
#   - a .dset with an AnimBrush block (DSA1) loads that bin with its cels
#   - picking the bin gives the AnimBrush back, every cel
#   - hovering the bin plays it, and the Preview's Quick Look shows the cel playing
#   - Shift+click stores a picked-up AnimBrush in an empty bin (every cel)
#   - Ctrl+B drops it; clicking the bin brings it back
#   - dragging the bin onto another swaps them, cels and all
#   - a plain brush stored over an AnimBrush bin makes it one picture again
#   - Save Drawer Set writes the DSA1 block; a relaunch loads it again
#   - a .draw with a "drAb" chunk loads its AnimBrush bin; Ctrl+S writes it
#     back and a reload still has it
#
# Dump: ABBIN slot:n:cw:ch:stripCrc, ABQL hoverSlot hoverCel qlSlot qlCel qlCrc,
# ABR / ABRC (the brush), DRAWERL / DRAWERR (the bin grid).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 PREVIEW_VISIBLE=1 PREVIEW_BIN_QUICK_LOOK=1 PREVIEW_W=200 PREVIEW_H=200 ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== AnimBrush: Drawer bins ==="

BN_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
BN_DIR="/tmp/draw-qa-abbin-$$"
mkdir -p "$BN_DIR"
BN_COLORS=(c04040 40c040 4040c0 c0c040)
BN_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 ))
    BN_DRAW+=(-fill "#${BN_COLORS[$n]}" -draw "rectangle $(( x + 5 )),5 $(( x + 7 )),5" -draw "rectangle $(( x + 5 )),6 $(( x + 5 )),9")
    (( n > 0 )) && BN_DRAW+=(-draw "point $(( x + 7 )),$(( 6 + n ))")
done
magick -size 64x16 xc:none "${BN_DRAW[@]}" "PNG32:$BN_DIR/plain.png"
magick "$BN_DIR/plain.png" -depth 8 "RGBA:$BN_DIR/plain.rgba"
BN_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$BN_PY" put "$BN_DIR/plain.png" "$BN_DIR/sheet.png" drAn "$BN_BLOB"

cat > "$BN_DIR/fx.py" <<'EOF'
# fixtures and expected CRCs
#   dset OUT              -> a brush .dset: slot 1 a 3x3 brush, slot 2 an AnimBrush
#                            of 3 cels 2x2 (red / green / blue, one clear pixel each)
#   dsetcels              -> "crc crc crc" (slot 2's cels) and the strip crc on line 2
#   sheetstrip RGBA       -> the strip crc of the sheet's 4 L cels (3x5 at (5,5))
#   sheetcels RGBA        -> their cel crcs
#   draw SRC OUT          -> SRC (a .draw with slot 40 = 7x5) + a drAb chunk: slot 40
#                            gets 2 cels 7x5; prints the strip crc
#   dsa FILE              -> the DSA1 block of a .dset: "slot:n:cw:ch:crc ..."
import sys, struct, zlib
def i16(v): return struct.pack('<h', v)
def crc(b): return '0' if not any(b) else format(zlib.crc32(b), 'x')
def strip(cels, w, h):  # cels: list of h rows of w BGRA pixels
    return b''.join(b''.join(b''.join(c[y]) for c in cels) for y in range(h))
def cel_bytes(c): return b''.join(b''.join(r) for r in c)
def dset_cels():
    out = []
    for k, (r, g, b) in enumerate([(200, 40, 40), (40, 200, 40), (40, 40, 200)]):
        px = bytes((b, g, r, 255))
        c = [[px, px], [px, px]]
        c[k % 2][k // 2] = bytes(4)
        out.append(c)
    return out
def slot_img(w, h, data): return i16(-1) + i16(w) + i16(h) + data
mode = sys.argv[1]
if mode == 'dset':
    cels = dset_cels()
    b = b'DST1' + i16(1) + i16(1) + i16(1)
    b += slot_img(3, 3, bytes((0, 255, 0, 255)) * 9)
    b += slot_img(2, 2, cel_bytes(cels[0]))
    b += i16(0) * 28
    b += b'DSA1' + i16(1) + i16(2) + i16(3) + i16(2) + i16(2) + strip(cels, 2, 2)
    open(sys.argv[2], 'wb').write(b)
elif mode == 'dsetcels':
    cels = dset_cels()
    print(' '.join(crc(cel_bytes(c)) for c in cels)); print(crc(strip(cels, 2, 2)))
elif mode in ('sheetstrip', 'sheetcels'):
    raw = open(sys.argv[2], 'rb').read()
    def px(x, y):
        r, g, b, a = raw[(y * 64 + x) * 4:(y * 64 + x) * 4 + 4]
        return bytes((b, g, r, a)) if a else bytes(4)
    cels = [[[px(f * 16 + 5 + x, 5 + y) for x in range(3)] for y in range(5)] for f in range(4)]
    print(crc(strip(cels, 3, 5)) if mode == 'sheetstrip' else ' '.join(crc(cel_bytes(c)) for c in cels))
elif mode == 'draw':
    png = open(sys.argv[2], 'rb').read()
    cels = []
    for k in range(2):
        px = bytes((0, 160 if k else 40, 255, 255))
        cels.append([[px if (x + y + k) % 2 else bytes(4) for x in range(7)] for y in range(5)])
    raw = i16(1) + i16(1) + i16(40) + i16(2) + i16(7) + i16(5) + strip(cels, 7, 5)
    data = struct.pack('<i', len(raw)) + zlib.compress(raw, 9)
    chunk = struct.pack('>I', len(data)) + b'drAb' + data + struct.pack('>I', zlib.crc32(b'drAb' + data) & 0xFFFFFFFF)
    open(sys.argv[3], 'wb').write(png[:-12] + chunk + png[-12:])
    print(crc(strip(cels, 7, 5)))
elif mode == 'dsa':
    b = open(sys.argv[2], 'rb').read()
    p = b.find(b'DSA1')
    if p < 0: print('none'); sys.exit()
    p += 4; c, = struct.unpack_from('<h', b, p); p += 2; out = []
    for _ in range(c):
        i, n, cw, ch = struct.unpack_from('<4h', b, p); p += 8
        sz = n * cw * ch * 4; out.append('%d:%d:%d:%d:%s' % (i, n, cw, ch, crc(b[p:p + sz]))); p += sz
    print(' '.join(out))
EOF
bn_fx() { python3 "$BN_DIR/fx.py" "$@"; }
bn_fx dset "$BN_DIR/ab.dset"
{ read -r DSET_CELS; read -r DSET_STRIP; } <<< "$(bn_fx dsetcels)"
SHEET_STRIP=$(bn_fx sheetstrip "$BN_DIR/plain.rgba")
SHEET_CELS=$(bn_fx sheetcels "$BN_DIR/plain.rgba")

bn_line() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
bn_read() {
    dk_settle
    read -r _ AB_N AB_CUR AB_W AB_H _ _ AB_ON AB_BW AB_BH AB_BCRC <<< "$(bn_line ABR)"
    AB_CELS=$(bn_line ABRC | cut -d' ' -f2- | tr ' ' '\n' | cut -d: -f2 | tr '\n' ' ' | sed 's/ $//'); [[ "$(bn_line ABRC)" == "" ]] && AB_CELS=""
    BINS=$(grep -m1 '^ABBIN' "$DK_DUMP" | cut -s -d' ' -f2-)
    read -r _ _ A_COUNT A_CUR _ <<< "$(bn_line ANIM)"
}
bn_s() { echo "brush n=${AB_N:-?} ${AB_W:-?}x${AB_H:-?} on=${AB_ON:-?} cels [${AB_CELS:-}] | bins [${BINS:-}]"; }
# centre of bin $1 as it is laid out now; 1 = that row is not showing
bin_xy() {
    local DL_COLS DL_VIS DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY DL_ROW0 i r c
    read -r _ DL_COLS _ DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(bn_line DRAWERL)"
    read -r _ DL_ROW0 _ <<< "$(bn_line DRAWERR)"
    [[ -n "$DL_COLS" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
bn_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
bn_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
bn_launch() { # extra args
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$*"
    draw_launch 15
    wait_for 1.5 "loaded"
    assert_no_crash
    dk_begin
    bn_read
}
bn_pane() { # PX PY PW PH of the current frame's pane
    local p k; p=($(bn_line ANIMLBP)); PX=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
bn_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
bn_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }

info "Launching with the AnimBrush .dset as the brush set and a 4-frame sheet"
bn_launch "--option DEFAULT_DSET_BRUSHES_FILE=$BN_DIR/ab.dset $BN_DIR/sheet.png"
[[ "$BINS" == "2:3:2:2:$DSET_STRIP" ]] && pass "a .dset's AnimBrush bin loads with its 3 cels (slot 2)" || fail "bins after load: [$BINS], wanted [2:3:2:2:$DSET_STRIP]"

if ! bin_xy 2; then
    fail "bin 2 not showing"
else
    # -- pick it --
    click "$BX" "$BY"; wait_for 0.6 "pick bin 2"; dk_park; bn_read
    [[ "$AB_N" == 3 && "$AB_W" == 2 && "$AB_H" == 2 && "$AB_ON" == -1 && "$AB_CELS" == "$DSET_CELS" ]] \
        && pass "picking the bin gives the AnimBrush back: 3 cels of 2x2" || fail "pick bin 2: $(bn_s), wanted cels [$DSET_CELS]"

    # -- hover: it plays, in the bin and in the Quick Look --
    bin_xy 2; hover "$BX" "$BY"; sleep 0.3; hover $(( BX + 1 )) "$BY"; sleep 0.3
    SEEN=""; QLOK=0; QLN=0; DC=($DSET_CELS)
    for i in $(seq 1 10); do
        read -r _ HS HC QS QC QCRC <<< "$(bn_line ABQL)"
        [[ "$HS" == 2 && "$HC" -ge 1 ]] && SEEN="$SEEN $HC"
        if [[ "$QS" == 2 && "${QC:-0}" -ge 1 ]]; then QLN=$((QLN + 1)); [[ "$QCRC" == "${DC[$((QC - 1))]}" ]] && QLOK=$((QLOK + 1)); fi
        sleep 0.13
    done
    U=$(echo $SEEN | tr ' ' '\n' | sort -u | grep -c .)
    (( U >= 2 )) && pass "hovering the bin plays it (cels seen:$SEEN)" || fail "hover: cels seen [$SEEN]"
    (( QLN >= 5 && QLOK == QLN )) && pass "the Preview's Quick Look shows the cel playing ($QLOK/$QLN reads)" || fail "quick look: $QLOK of $QLN reads showed the right cel ($(bn_line ABQL))"
    screenshot "animbrush-bin-hover"
    dk_park
fi

# -- pick up from the sheet, store in bin 3 --
bn_key KP_0; bn_read; bn_pane
if [[ -z "$PX" ]]; then
    fail "no pane for the current frame: $(bn_line ANIM) | $(bn_line ANIMLBP)"
else
    bn_key KP_1; bn_read; bn_pane
    bn_key m
    mouse_down "$(bn_px 5)" "$(bn_py 5)"; hover "$(bn_px 6)" "$(bn_py 7)"; sleep 0.2; hover "$(bn_px 7)" "$(bn_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    bn_cmd "animbrush: pick up (the"; bn_read
    [[ "$AB_N" == 4 && "$AB_CELS" == "$SHEET_CELS" ]] && pass "picked up 4 cels from the sheet" || fail "pick up: $(bn_s), wanted [$SHEET_CELS]"
    bin_xy 3 && { with_mods shift click "$BX" "$BY"; wait_for 0.6 "store"; }
    dk_park; bn_read
    [[ "$BINS" == "2:3:2:2:$DSET_STRIP 3:4:3:5:$SHEET_STRIP" ]] && pass "Shift+click stores the AnimBrush in bin 3, every cel" || fail "after store: [$BINS], wanted 3:4:3:5:$SHEET_STRIP"
    screenshot "animbrush-bin-stored"

    bn_key ctrl+b; bn_read
    [[ "$AB_N" == 0 ]] && pass "Ctrl+B drops it" || fail "Ctrl+B: $(bn_s)"
    bin_xy 3; click "$BX" "$BY"; wait_for 0.6 "pick bin 3"; dk_park; bn_read
    [[ "$AB_N" == 4 && "$AB_W" == 3 && "$AB_H" == 5 && "$AB_CELS" == "$SHEET_CELS" ]] && pass "clicking bin 3 brings the 4 cels back" || fail "bin 3: $(bn_s)"

    # -- drag bin 3 onto bin 5: swapped, cels and all --
    bin_xy 3; X3=$BX; Y3=$BY; bin_xy 5
    dk_drag "$X3" "$Y3" "$BX" "$BY"; dk_park; bn_read
    [[ "$BINS" == "2:3:2:2:$DSET_STRIP 5:4:3:5:$SHEET_STRIP" ]] && pass "dragging bin 3 onto bin 5 moves the cels with it" || fail "after drag: [$BINS]"

    # -- a plain brush over the AnimBrush bin 2 (drop the AnimBrush first) --
    bn_key ctrl+b
    bn_key m
    mouse_down "$(bn_px 1)" "$(bn_py 1)"; hover "$(bn_px 5)" "$(bn_py 5)"; sleep 0.2; hover "$(bn_px 10)" "$(bn_py 11)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    bn_key ctrl+b; bn_read
    bin_xy 2 && { with_mods shift click "$BX" "$BY"; wait_for 0.6 "store plain"; }
    dk_park; bn_read
    [[ "$BINS" == "5:4:3:5:$SHEET_STRIP" ]] && pass "a plain brush stored over bin 2 makes it one picture" || fail "after plain store: [$BINS]"
    bn_key ctrl+b

    # -- Save Drawer Set: the DSA1 block --
    bn_cmd "save drawer set"; wait_for 1.0 "the save dialog"
    for (( i = 0; i < 30; i++ )); do key BackSpace; done
    type_text "$BN_DIR/out.dset"; wait_for 0.3 "typed"; key Return; wait_for 1.5 "saved"
    GOT=$(bn_fx dsa "$BN_DIR/out.dset" 2>/dev/null)
    [[ "$GOT" == "5:4:3:5:$SHEET_STRIP" ]] && pass "Save Drawer Set writes bin 5's cels (DSA1)" || fail "saved .dset DSA1 block: [${GOT:-no file}]"
fi

if [[ -f "$BN_DIR/out.dset" ]]; then
    info "Relaunching with the saved set"
    bn_launch "--option DEFAULT_DSET_BRUSHES_FILE=$BN_DIR/out.dset"
    [[ "$BINS" == "5:4:3:5:$SHEET_STRIP" ]] && pass "the saved set loads bin 5 with its 4 cels" || fail "reloaded set bins: [$BINS]"
fi

# -- a .draw with a drAb chunk, saved back and reloaded --
DRAB_STRIP=$(bn_fx draw "$DRAW_ROOT/QA/fixtures/drawer-40.draw" "$BN_DIR/ab.draw")
info "Opening a .draw whose bin 40 is an AnimBrush (drAb)"
bn_launch "$BN_DIR/ab.draw"
[[ "$BINS" == "40:2:7:5:$DRAB_STRIP" ]] && pass "a .draw's drAb chunk loads bin 40 with 2 cels" || fail ".draw bins: [$BINS], wanted [40:2:7:5:$DRAB_STRIP]"
wake_draw
key ctrl+s; wait_for 2.0 "saved"
grep -qa 'drAb' "$BN_DIR/ab.draw" && pass "Ctrl+S writes the drAb chunk" || fail "no drAb chunk in the saved .draw"
bn_launch "$BN_DIR/ab.draw"
[[ "$BINS" == "40:2:7:5:$DRAB_STRIP" ]] && pass "a reload still has bin 40's 2 cels" || fail "reloaded .draw bins: [$BINS]"

rm -rf "$BN_DIR"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
info "=== AnimBrush: Drawer bins PASSED ==="
