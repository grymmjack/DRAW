#!/bin/bash
# =============================================================================
# animbrush-pickup-edges.sh — QA test: AnimBrush pick up, the edges
# (TOOLS/ANIM-BRUSH, A1).
#
#   - a magic-wand selection: every cel takes the selection's SHAPE (frame 1's
#     L), so a blob inside the box but outside the L in frames 2-4 is left out
#   - the brush stash: Pattern Mode (F3) puts the AnimBrush away with its cels,
#     Color Mode (F1) brings it back, cels and all, on cel 1
#   - Ctrl+B after an AnimBrush: a plain one-picture brush (no cels)
#   - a picture without frames: Pick Up does nothing (the marquee stays)
#
# Dump: ABR / ABRC (TOOLS/ANIM-BRUSH AB_dump$), ANIMSEL, ANIMLBP, VIEW.
# Fixture: a 64x16 sheet of 16x16 frames, transparent; frame k an L of its own
# colour; frames 2-4 also a 2x2 blob inside the L's box.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== AnimBrush: pick up edges ==="

AE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
AE_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
AE_DIR="/tmp/draw-qa-abedge-$$"
mkdir -p "$AE_DIR"
AE_COLORS=(c04040 40c040 4040c0 c0c040)
AE_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 ))
    AE_DRAW+=(-fill "#${AE_COLORS[$n]}" -draw "rectangle $(( x + 2 )),2 $(( x + 3 )),10" -draw "rectangle $(( x + 2 )),9 $(( x + 8 + n )),10")
    (( n > 0 )) && AE_DRAW+=(-fill '#e08020' -draw "rectangle $(( x + 5 )),$(( 3 + n )) $(( x + 6 )),$(( 4 + n ))")
done
magick -size 64x16 xc:none "${AE_DRAW[@]}" "PNG32:$AE_DIR/plain.png"
magick "$AE_DIR/plain.png" -depth 8 "RGBA:$AE_DIR/plain.rgba"
AE_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$AE_PY" put "$AE_DIR/plain.png" "$AE_DIR/sheet.png" drAn "$AE_BLOB"
cp "$AE_DIR/plain.png" "$AE_DIR/noframes.png"

# expected "frame:crc ..." for a box BX BY BW BH in frame 1 whose shape is frame
# 1's pixels of colour MASKHEX (the wand's pick), frames 1..4
cat > "$AE_DIR/exp.py" <<'EOF'
import sys, zlib
W = 64
raw = open(sys.argv[1], 'rb').read()
bx, by, bw, bh = map(int, sys.argv[2:6]); mask = bytes.fromhex(sys.argv[6])
px_at = lambda x, y: raw[(y * W + x) * 4:(y * W + x) * 4 + 4]
out = []
for f in range(1, 5):
    b = bytearray()
    for py in range(bh):
        for px in range(bw):
            inside = px_at(bx + px, by + py)[:3] == mask and px_at(bx + px, by + py)[3]
            r, g, bb, a = px_at(bx + px + (f - 1) * 16, by + py)
            b += bytes((bb, g, r, a)) if (inside and a) else bytes(4)
    out.append('%d:%s' % (f, '0' if not any(b) else format(zlib.crc32(bytes(b)), 'x')))
print(' '.join(out))
EOF

ae_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
ae_line() { grep -m1 "^$1 " "$AE_DUMPF" 2>/dev/null; }
ae_read() {
    ae_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(ae_line ANIM)"
    read -r _ S_ON S_X S_Y S_W S_H S_WAND _ <<< "$(ae_line ANIMSEL)"
    read -r _ AB_N AB_CUR AB_W AB_H AB_MERGED AB_SF AB_ON AB_BW AB_BH AB_BCRC <<< "$(ae_line ABR)"
    AB_CELS=$(ae_line ABRC | cut -d' ' -f2-); [[ "$(ae_line ABRC)" == "ABRC" ]] && AB_CELS=""
    local p k; p=($(ae_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
ae_s() { echo "ABR n=${AB_N:-?} cur=${AB_CUR:-?} ${AB_W:-?}x${AB_H:-?} brush=${AB_ON:-?} ${AB_BW:-?}x${AB_BH:-?} crc=${AB_BCRC:-?} cels [${AB_CELS:-}]"; }
ae_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
ae_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
ae_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
ae_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
ae_cel_crc() { local a=($2); local t=${a[$(( $1 - 1 ))]:-}; echo "${t#*:}"; } # cel K's CRC in "frame:crc .."

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
ae_key KP_0
ae_read
if [[ "$A_COUNT" != 4 || -z "${PX:-}" ]]; then
    fail "lightbox: $A_COUNT frames, current pane '${PX:-}'"
else
    # -- a magic-wand selection on frame 1's L --
    ae_key w
    click "$(ae_px 2)" "$(ae_py 5)"; wait_for 0.6 "wand"; ae_read
    if [[ "$S_ON" != -1 || "$S_WAND" != -1 ]]; then
        fail "the wand did not select frame 1's L: sel $S_ON wand $S_WAND box $S_X,$S_Y ${S_W}x$S_H"
    else
        BX=$S_X; BY=$S_Y; BW=$S_W; BH=$S_H
        info "wand box $BX,$BY ${BW}x$BH"
        WANT=$(python3 "$AE_DIR/exp.py" "$AE_DIR/plain.rgba" "$BX" "$BY" "$BW" "$BH" "${AE_COLORS[0]}")
        ae_cmd "animbrush: pick up (the"; ae_read
        [[ "$AB_N" == 4 && "$AB_W" == "$BW" && "$AB_H" == "$BH" ]] && pass "wand: 4 cels of the wand's box (${BW}x$BH)" || fail "wand pick up: $(ae_s)"
        [[ "$AB_CELS" == "$WANT" ]] && pass "every cel has the L's shape - the blob inside the box is left out" || fail "cels [$AB_CELS], wanted [$WANT]"
        CELS1=$AB_CELS

        # -- the stash: Pattern Mode puts it away, Color Mode brings it back --
        ae_key F3; ae_read
        [[ "$AB_N" == 0 && "$AB_ON" == 0 ]] && pass "F3 Pattern Mode: the AnimBrush is put away" || fail "F3: $(ae_s)"
        ae_key F1; ae_read
        [[ "$AB_N" == 4 && "$AB_CUR" -ge 1 && "$AB_ON" == -1 && "$AB_CELS" == "$CELS1" && "$AB_BCRC" == "$(ae_cel_crc "$AB_CUR" "$CELS1")" ]] \
            && pass "F1 Color Mode: it comes back with its 4 cels, showing cel $AB_CUR" || fail "F1: $(ae_s)"
        ae_key F3; ae_key F1; ae_read
        [[ "$AB_N" == 4 && "$AB_CELS" == "$CELS1" ]] && pass "a second round trip keeps them too" || fail "second round trip: $(ae_s)"
        screenshot "animbrush-edges-stash"

        # -- Ctrl+B: drop it; Ctrl+B again over a marquee: one picture --
        ae_key ctrl+b; ae_read
        [[ "$AB_N" == 0 && "$AB_ON" == 0 ]] && pass "Ctrl+B drops the AnimBrush" || fail "Ctrl+B: $(ae_s)"
        ae_key F3; ae_key F1; ae_read
        [[ "$AB_N" == 0 && "$AB_ON" == 0 ]] && pass "... and the stash is gone with it (F3 / F1 bring nothing back)" || fail "after Ctrl+B + F3/F1: $(ae_s)"
        ae_key m
        mouse_down "$(ae_px 1)" "$(ae_py 1)"; hover "$(ae_px 5)" "$(ae_py 5)"; sleep 0.2; hover "$(ae_px 10)" "$(ae_py 11)"; sleep 0.3
        mouse_up; wait_for 0.6 "marquee"
        ae_key ctrl+b; ae_read
        [[ "$AB_ON" == -1 && "$AB_N" == 0 && -z "$AB_CELS" ]] && pass "Ctrl+B over a marquee: a plain one-picture brush" || fail "plain Ctrl+B: $(ae_s)"
        ae_key ctrl+b
    fi
fi

# -- a picture without frames: nothing to pick up from --
info "Relaunching with the same picture, no frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$AE_DIR/noframes.png"
draw_launch 15
wait_for 1.5 "Picture loaded"
assert_no_crash
park_mouse
ae_key m
mouse_down $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )); hover "$CANVAS_CX" "$CANVAS_CY"; sleep 0.2; hover $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 )); sleep 0.3
mouse_up; wait_for 0.6 "marquee"
ae_cmd "animbrush: pick up (the"; ae_read
[[ "${AB_N:-x}" == 0 && "$AB_ON" == 0 ]] && pass "no frames: Pick Up makes no brush" || fail "no frames: $(ae_s)"
SELNOW=$(ae_line ANIMSEL)
info "ANIMSEL after: ${SELNOW:-<none>}"
rm -rf "$AE_DIR"
assert_window_exists
info "=== AnimBrush: pick up edges PASSED ==="
