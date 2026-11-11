#!/bin/bash
# =============================================================================
# animbrush-transforms.sh — QA test: AnimBrush transforms on every cel, eraser
# mode, lightbox panes (TOOLS/ANIM-BRUSH, A3).
#
#   - Rotate 90 CW / CCW, Scale 2x Horizontal, Apply Outline change EVERY cel
#     (not just the one shown); the brush shows its cel afterwards
#   - Flip H (drawn at stamp time) flips every frame's stamp
#   - the Eraser with an AnimBrush erases each frame's cel shape (every frame
#     at once), one undo step
#   - in the lightbox, a stamp in another frame's pane uses THAT frame's cel
#
# Dump: ABR / ABRC / ABRS / ABRP (TOOLS/ANIM-BRUSH), ANIMC (per cell CRC over
# both layers), ANIMLBP (panes). Expected CRCs are worked out here.
# Fixture: a 64x16 sheet of 4 frames of 16x16, transparent; frame k an
# L of its own colour in the 3x5 box at (5, 5).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== AnimBrush: transforms, eraser, panes ==="

TR_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
TR_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
TR_DIR="/tmp/draw-qa-abtrans-$$"
mkdir -p "$TR_DIR"
TR_COLORS=(c04040 40c040 4040c0 c0c040)
TR_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 ))
    TR_DRAW+=(-fill "#${TR_COLORS[$n]}" -draw "rectangle $(( x + 5 )),5 $(( x + 7 )),5" -draw "rectangle $(( x + 5 )),6 $(( x + 5 )),9")
    (( n > 0 )) && TR_DRAW+=(-draw "point $(( x + 7 )),$(( 6 + n ))") # each L a little different
done
magick -size 64x16 xc:none "${TR_DRAW[@]}" "PNG32:$TR_DIR/plain.png"
magick "$TR_DIR/plain.png" -depth 8 "RGBA:$TR_DIR/plain.rgba"
TR_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$TR_PY" put "$TR_DIR/plain.png" "$TR_DIR/sheet.png" drAn "$TR_BLOB"

cat > "$TR_DIR/exp.py" <<'EOF'
# cels OP            -> "1:crc .. 4:crc" (each frame's 3x5 L at (5,5), after OP)
# cells X Y FLIP     -> ANIMC tokens: layer 1 as drawn + layer 2 with each frame's
#                       cel (flipped if FLIP) stamped at cell (X, Y)
# erased X Y         -> ANIMC tokens: layer 1 with each frame's cel shape erased at (X, Y)
import sys, zlib
W = 64
raw = open(sys.argv[1], 'rb').read()
def px(x, y):
    r, g, b, a = raw[(y * W + x) * 4:(y * W + x) * 4 + 4]
    return bytes((b, g, r, a)) if a else bytes(4)
def cel(f):  # rows of BGRA pixels
    return [[px(f * 16 + 5 + x, 5 + y) for x in range(3)] for y in range(5)]
def crc(rows): b = b''.join(b''.join(r) for r in rows); return '0' if not any(b) else format(zlib.crc32(b), 'x')
def rot_cw(c): h, w = len(c), len(c[0]); return [[c[h - 1 - x][y] for x in range(h)] for y in range(w)]
def rot_ccw(c): h, w = len(c), len(c[0]); return [[c[x][w - 1 - y] for x in range(h)] for y in range(w)]
def dbl_h(c): return [[p for p in r for _ in (0, 1)] for r in c]
def cell(f):
    rows = [[px(f * 16 + x, y) for x in range(16)] for y in range(16)]
    return rows
mode = sys.argv[2]
if mode == 'cels':
    op = sys.argv[3]
    f = {'none': lambda c: c, 'cw': rot_cw, 'ccw': rot_ccw, '2xh': dbl_h}[op]
    print(' '.join('%d:%s' % (k + 1, crc(f(cel(k)))) for k in range(4)))
elif mode == 'cells':
    sx, sy, flip = int(sys.argv[3]), int(sys.argv[4]), sys.argv[5] == '1'
    out = []
    for k in range(4):
        l1 = cell(k)
        l2 = [[bytes(4)] * 16 for _ in range(16)]
        c = cel(k)
        if flip: c = [list(reversed(r)) for r in c]
        for y in range(5):
            for x in range(3):
                if c[y][x][3]: l2[sy + y][sx + x] = c[y][x]
        b = b''.join(b''.join(r) for r in l1) + b''.join(b''.join(r) for r in l2)
        out.append(format(zlib.crc32(b), 'x'))
    print(' '.join(out))
elif mode == 'erased':
    sx, sy = int(sys.argv[3]), int(sys.argv[4])
    out = []
    for k in range(4):
        l1 = cell(k); c = cel(k)
        for y in range(5):
            for x in range(3):
                if c[y][x][3]: l1[sy + y][sx + x] = bytes(4)
        b = b''.join(b''.join(r) for r in l1)
        out.append('0' if not any(b) else format(zlib.crc32(b), 'x'))
    print(' '.join(out))
EOF
tr_exp() { python3 "$TR_DIR/exp.py" "$TR_DIR/plain.rgba" "$@"; }

tr_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
tr_line() { grep -m1 "^$1 " "$TR_DUMPF" 2>/dev/null; }
tr_read() {
    tr_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(tr_line ANIM)"
    read -r _ AB_N AB_CUR AB_W AB_H AB_MERGED AB_SF AB_ON AB_BW AB_BH AB_BCRC <<< "$(tr_line ABR)"
    read -r _ ST_STEP ST_ORD ST_ANCHOR ST_CLICK ST_MODE _ <<< "$(tr_line ABRS)"
    AB_CELS=$(tr_line ABRC | cut -d' ' -f2-); [[ "$(tr_line ABRC)" == "ABRC" ]] && AB_CELS=""
    AB_P=$(tr_line ABRP | cut -d' ' -f2-)
    read -r _ CELLS <<< "$(tr_line ANIMC)"
    PANES=($(tr_line ANIMLBP))
    TR_PANE ""
}
TR_PANE() { # F -> PX PY PW PH of the pane showing frame F (default: the current frame)
    local f=${1:-$A_CUR} k; PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#PANES[@]}; k += 5 )); do
        if [[ "${PANES[$k]}" == "$f" ]]; then PX=${PANES[$((k + 1))]}; PY=${PANES[$((k + 2))]}; PW=${PANES[$((k + 3))]}; PH=${PANES[$((k + 4))]}; fi
    done
}
tr_s() { echo "n=${AB_N:-?} cur=${AB_CUR:-?} ${AB_W:-?}x${AB_H:-?} brush ${AB_BW:-?}x${AB_BH:-?} crc ${AB_BCRC:-?} | cels [${AB_CELS:-}]"; }
tr_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
tr_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
tr_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
tr_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
tr_cel_crc() { local a=($2); local t=${a[$(( $1 - 1 ))]:-}; echo "${t#*:}"; }
tr_brush_ok() { # LABEL - the brush shows its own cel AB_CUR
    [[ "$AB_ON" == -1 && "$AB_CUR" -ge 1 && "$AB_BCRC" == "$(tr_cel_crc "$AB_CUR" "$AB_CELS")" ]] && pass "$1" || fail "$1: $(tr_s)"
}
tr_pickup() { # marquee the L box in frame 1 and pick it up
    tr_key KP_1; tr_read
    tr_key m
    mouse_down "$(tr_px 5)" "$(tr_py 5)"; hover "$(tr_px 6)" "$(tr_py 7)"; sleep 0.2; hover "$(tr_px 7)" "$(tr_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    tr_cmd "animbrush: pick up (the"; tr_read
}

info "Launching DRAW with a 64x16 sheet of 4 frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$TR_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
tr_key KP_0
tr_read
BASE_CELLS=$CELLS
if [[ "$A_COUNT" != 4 || -z "${PX:-}" ]]; then
    fail "lightbox: $A_COUNT frames, current pane '${PX:-}'"
else
    tr_pickup
    WANT=$(tr_exp cels none)
    [[ "$AB_N" == 4 && "$AB_W" == 3 && "$AB_H" == 5 && "$AB_CELS" == "$WANT" ]] && pass "picked up 4 cels of 3x5" || fail "pick up: $(tr_s), wanted [$WANT]"

    # -- rotate: every cel --
    tr_cmd "rotate brush 90 cw"; tr_read
    WANT=$(tr_exp cels cw)
    [[ "$AB_W" == 5 && "$AB_H" == 3 && "$AB_BW" == 5 && "$AB_BH" == 3 ]] && pass "Rotate 90 CW: cels and brush 5x3" || fail "rotate cw size: $(tr_s)"
    [[ "$AB_CELS" == "$WANT" ]] && pass "Rotate 90 CW turned every cel" || fail "rotate cw cels [$AB_CELS], wanted [$WANT]"
    tr_brush_ok "... the brush shows its (turned) cel"
    tr_cmd "rotate brush 90 ccw"; tr_read
    WANT=$(tr_exp cels none)
    [[ "$AB_W" == 3 && "$AB_H" == 5 && "$AB_CELS" == "$WANT" ]] && pass "Rotate 90 CCW: every cel back as it was" || fail "rotate ccw: $(tr_s), wanted [$WANT]"

    # -- scale 2x horizontal: every cel twice as wide --
    tr_cmd "scale 2x horizontal"; tr_read
    WANT=$(tr_exp cels 2xh)
    [[ "$AB_W" == 6 && "$AB_H" == 5 && "$AB_BW" == 6 && "$AB_CELS" == "$WANT" ]] && pass "Scale 2x Horizontal: every cel 6x5, pixels doubled" || fail "2x h: $(tr_s), wanted [$WANT]"
    tr_brush_ok "... the brush shows its (doubled) cel"
    tr_pickup
    [[ "$AB_W" == 3 && "$AB_CELS" == "$(tr_exp cels none)" ]] && pass "a new Pick Up starts from the frames again" || fail "re-pick up: $(tr_s)"

    # -- the eraser: every frame at once erases each frame's L (its own cel) --
    tr_cmd "animbrush step: every frame at once"
    tr_key e; tr_read
    click "$(tr_px 6)" "$(tr_py 7)"; wait_for 0.5 "erase"; tr_read
    WANT=$(tr_exp erased 5 5)
    [[ "$CELLS" == "$WANT" ]] && pass "the Eraser with the AnimBrush erased each frame's own L (every frame at once)" || fail "eraser cells [$CELLS], wanted [$WANT]"
    tr_key ctrl+z; tr_read
    [[ "$CELLS" == "$BASE_CELLS" ]] && pass "one Ctrl+Z brings every frame's L back" || fail "after undo cells [$CELLS], wanted [$BASE_CELLS]"
    tr_key b; tr_read
    [[ "$AB_N" == 4 && "$AB_ON" == -1 ]] && pass "back to the Brush: still the AnimBrush" || fail "after eraser -> brush: $(tr_s)"

    # -- flip H: every frame's stamp is flipped --
    tr_key ctrl+shift+n
    tr_key Home; tr_read
    click "$(tr_px 12)" "$(tr_py 8)"; wait_for 0.5 "stamp"; tr_read
    WANT=$(tr_exp cells 11 6 1)
    [[ "$CELLS" == "$WANT" ]] && pass "Flip H: every frame got its cel flipped" || fail "flip cells [$CELLS], wanted [$WANT]"
    tr_key ctrl+z; tr_key Home; tr_read # flip back off
    click "$(tr_px 12)" "$(tr_py 8)"; wait_for 0.5 "stamp"; tr_read
    WANT=$(tr_exp cells 11 6 0)
    [[ "$CELLS" == "$WANT" ]] && pass "Flip H off again: every frame's cel the right way round" || fail "unflipped cells [$CELLS], wanted [$WANT]"
    tr_key ctrl+z

    # -- the lightbox: a stamp in frame 3's pane (current 2) uses frame 3's cel --
    tr_cmd "animbrush step: cel follows the frame"
    tr_key KP_5; tr_read
    TR_PANE 3
    if [[ -z "$PX" ]]; then
        fail "no pane for frame 3 (panes ${PANES[*]})"
    else
        click "$(tr_px 3)" "$(tr_py 3)"; wait_for 0.5 "pane stamp"; tr_read
        [[ "$AB_P" == "1:- 2:- 3:3 4:-" ]] && pass "a stamp in frame 3's pane (current 2) landed in frame 3 with cel 3" || fail "pane stamp: [$AB_P] (current $A_CUR)"
        tr_key ctrl+z
    fi

    # -- outline: every cel grows by 1 px all round --
    tr_cmd "apply outline"; tr_read
    U=$(tr_line ABRC | tr ' ' '\n' | tail -n +2 | cut -d: -f2 | sort -u | wc -l)
    [[ "$AB_W" == 5 && "$AB_H" == 7 && "$AB_BW" == 5 && "$AB_BH" == 7 && "$U" == 4 ]] && pass "Apply Outline: every cel 5x7, still 4 different cels" || fail "outline: $(tr_s)"
    tr_brush_ok "... the brush shows its outlined cel"

fi
rm -rf "$TR_DIR"
assert_window_exists
info "=== AnimBrush: transforms PASSED ==="
