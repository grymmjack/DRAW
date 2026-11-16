#!/bin/bash
# =============================================================================
# animbrush-step-modes.sh — QA test: AnimBrush step modes, orders and cel keys
# (TOOLS/ANIM-BRUSH, A2).
#
#   - Cel follows the frame (the default): a stamp on frame f uses cel
#     seq(f - anchor); the pick up's frame gets cel 1; Alt+\ makes the
#     current frame cel 1; Alt+] / Alt+[ shift the cels by one
#   - Next cel each click: each press uses the next cel; Alt+[ / Alt+] step
#     back / on, Alt+\ goes back to cel 1
#   - Every frame at once: one press stamps every frame, each with its cel -
#     one undo step (Ctrl+Z takes all of it away, Ctrl+Y puts it back)
#   - Orders forward / reverse / ping-pong / once over 6 frames and 4 cels
#   - The brush between presses shows the cel the next stamp uses
#
# Dump: ABR (n cur ...), ABRS step order anchor clickPos mode, ABRP f:cel per
# frame - which cel is on the current layer at the last stamp's spot in each
# frame's cell ("-" nothing, "0" not a cel).
# Fixture: a 96x16 sheet of 6 frames of 16x16, transparent; frame k a 4x4
# square of its own colour at (6, 6). The cels are picked up from frames 3-6 (selected)
# onto the stamps' own empty layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== AnimBrush: step modes, orders, cel keys ==="

SM_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
SM_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
SM_DIR="/tmp/draw-qa-abstep-$$"
mkdir -p "$SM_DIR"
SM_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
SM_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 ))
    SM_DRAW+=(-fill "#${SM_COLORS[$n]}" -draw "rectangle $(( x + 6 )),6 $(( x + 9 )),9")
done
magick -size 96x16 xc:none "${SM_DRAW[@]}" "PNG32:$SM_DIR/plain.png"
SM_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,12,0,0).hex())")
python3 "$SM_PY" put "$SM_DIR/plain.png" "$SM_DIR/sheet.png" drAn "$SM_BLOB"

sm_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
sm_line() { grep -m1 "^$1 " "$SM_DUMPF" 2>/dev/null; }
sm_read() {
    sm_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(sm_line ANIM)"
    read -r _ S_ON S_X S_Y S_W S_H _ <<< "$(sm_line ANIMSEL)"
    read -r _ AB_N AB_CUR AB_W AB_H AB_MERGED AB_SF AB_ON _ <<< "$(sm_line ABR)"
    read -r _ ST_STEP ST_ORD ST_ANCHOR ST_CLICK ST_MODE _ <<< "$(sm_line ABRS)"
    AB_P=$(sm_line ABRP | cut -d' ' -f2-)
    read -r _ _ _ _ V_TOOL _ <<< "$(sm_line VIEW)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(sm_line ANIMLB)"
    local p k; p=($(sm_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
sm_s() { echo "frame ${A_CUR:-?} cel ${AB_CUR:-?}/${AB_N:-?} step ${ST_STEP:-?} order ${ST_ORD:-?} anchor ${ST_ANCHOR:-?} click ${ST_CLICK:-?} mode ${ST_MODE:-?} | ${AB_P:-}"; }
sm_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
sm_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
sm_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
sm_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
sm_stamp() { # CX CY - one click at cell px (CX, CY) in the current frame's pane
    sm_read
    click "$(sm_px "$1")" "$(sm_py "$2")"; wait_for 0.4 "stamp"
}
# hover over cell px (CX, CY) of the current pane: the brush shows the next cel
sm_hover_read() { sm_read; hover "$(sm_px "$1")" "$(sm_py "$2")"; wait_for 0.3 "hover"; hover "$(sm_px "$1")" "$(( $(sm_py "$2") + 1 ))"; wait_for 0.3 "hover"
    read -r _ AB_N AB_CUR _ <<< "$(sm_line ABR)"; }
sm_expect_p() { # WANT LABEL - the ABRP line (frame:cel ...)
    sm_read
    [[ "$AB_P" == "$1" ]] && pass "$2" || fail "$2: [$AB_P], wanted [$1]"
}
sm_strip() { # F [shift] - click frame F in the lightbox strip
    local x1 sy sf cw ch pad
    read -r _ _ x1 _ _ _ sy _ _ _ _ _ sf _ cw ch _ _ _ pad _ <<< "$(sm_line ANIMLB)"
    local x=$(( x1 + pad + ($1 - sf) * (cw + pad) + cw / 2 )) y=$(( sy + pad + ch / 2 ))
    if [[ "${2:-}" == shift ]]; then with_mods shift click "$x" "$y"; else click "$x" "$y"; fi
    wait_for 0.4 "strip $1"
}
sm_undo_all() { local k; for (( k = 0; k < $1; k++ )); do sm_key ctrl+z; done; }

info "Launching DRAW with a 96x16 sheet of 6 frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$SM_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
sm_key KP_0
sm_read
if [[ "$A_COUNT" != 6 || -z "${PX:-}" ]]; then
    fail "lightbox: $A_COUNT frames, current pane '${PX:-}'"
else
    # -- pick up frames 3-6 (4 cels): selected in the strip (6, then Shift+3 - frame 3 current);
    #    with nothing selected a pick up takes every frame (animbrush-pickup) --
    sm_key KP_5; sm_key KP_5; sm_read
    sm_strip 6; sm_strip 3 shift; sm_read
    sm_key m
    mouse_down "$(sm_px 6)" "$(sm_py 6)"; hover "$(sm_px 8)" "$(sm_py 8)"; sleep 0.2; hover "$(sm_px 9)" "$(sm_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    sm_cmd "animbrush: pick up (the"; sm_read
    if [[ "$AB_N" != 4 || "$AB_W" != 4 || "$AB_H" != 4 || "$A_CUR" != 3 ]]; then
        fail "pick up from frame 3: $(sm_s) (n $AB_N ${AB_W}x$AB_H)"
    else
        pass "4 cels of 4x4 from frames 3-6"
        sm_strip 3; sm_read # one frame selected again (the stamps below go by frame, not by the selection)
        [[ "$ST_STEP" == 0 && "$ST_ORD" == 0 && "$ST_ANCHOR" == 3 && "$ST_MODE" == 0 ]] && pass "default: cel follows the frame, forward, the pick up's frame (3) gets cel 1" || fail "defaults: $(sm_s)"
        sm_key ctrl+shift+n; sm_read # the stamps go on an empty layer

        # -- cel follows the frame --
        sm_hover_read 2 2
        [[ "$AB_CUR" == 1 ]] && pass "follows: over frame 3 the brush shows cel 1" || fail "follows, hover frame 3: cel $AB_CUR"
        sm_stamp 2 2
        sm_key KP_5; sm_hover_read 2 2
        [[ "$AB_CUR" == 2 ]] && pass "follows: on frame 4 the brush shows cel 2" || fail "follows, hover frame 4: cel $AB_CUR"
        sm_stamp 2 2
        sm_expect_p "1:- 2:- 3:1 4:2 5:- 6:-" "follows: frame 3 got cel 1, frame 4 cel 2"
        # Alt+\ on frame 1: frame 1 gets cel 1
        sm_key KP_1; sm_key alt+backslash; sm_read
        [[ "$ST_ANCHOR" == 1 ]] && pass "Alt+\\ on frame 1: the anchor is frame 1" || fail "Alt+\\: $(sm_s)"
        sm_stamp 2 2
        sm_expect_p "1:1 2:- 3:1 4:2 5:- 6:-" "follows after Alt+\\: frame 1 got cel 1"
        # Alt+] : the current frame shows the next cel
        sm_key alt+bracketright; sm_hover_read 2 2
        [[ "$AB_CUR" == 2 ]] && pass "Alt+]: frame 1 now shows cel 2" || fail "Alt+]: cel $AB_CUR, $(sm_s)"
        sm_key alt+bracketleft; sm_hover_read 2 2
        [[ "$AB_CUR" == 1 ]] && pass "Alt+[: back to cel 1" || fail "Alt+[: cel $AB_CUR, $(sm_s)"
        sm_undo_all 3
        sm_expect_p "1:- 2:- 3:- 4:- 5:- 6:-" "undo x3: the follow stamps are gone"

        # -- next cel each click --
        sm_cmd "animbrush step: next cel each click"; sm_read
        [[ "$ST_STEP" == 1 && "$ST_MODE" == 1 && "$ST_CLICK" == 0 ]] && pass "step: next cel each click" || fail "click mode: $(sm_s)"
        sm_stamp 2 2;   sm_expect_p "1:1 2:- 3:- 4:- 5:- 6:-" "click 1: cel 1"
        sm_stamp 12 2;  sm_expect_p "1:2 2:- 3:- 4:- 5:- 6:-" "click 2 (another spot, same frame): cel 2"
        sm_stamp 2 12;  sm_expect_p "1:3 2:- 3:- 4:- 5:- 6:-" "click 3: cel 3"
        sm_hover_read 8 8
        [[ "$AB_CUR" == 4 && "$ST_CLICK" == 3 ]] && pass "between clicks the brush shows the next cel (4)" || fail "next cel shown: cel $AB_CUR, $(sm_s)"
        sm_key alt+bracketleft; sm_key alt+bracketleft
        sm_stamp 12 12; sm_expect_p "1:2 2:- 3:- 4:- 5:- 6:-" "Alt+[ twice: the next click uses cel 2"
        sm_key alt+backslash
        sm_stamp 7 2;   sm_expect_p "1:1 2:- 3:- 4:- 5:- 6:-" "Alt+\\: back to cel 1"
        sm_undo_all 5
        sm_expect_p "1:- 2:- 3:- 4:- 5:- 6:-" "undo x5: the click stamps are gone"

        # -- every frame at once: one undo step --
        sm_cmd "animbrush step: every frame at once"; sm_read
        [[ "$ST_STEP" == 2 && "$ST_MODE" == 2 ]] && pass "step: every frame at once" || fail "all mode: $(sm_s)"
        sm_key KP_5; sm_stamp 2 2 # on frame 2
        sm_expect_p "1:1 2:2 3:3 4:4 5:1 6:2" "one click on frame 2: every frame got its cel (forward, anchor 1)"
        screenshot "animbrush-every-frame"
        sm_key ctrl+z
        sm_expect_p "1:- 2:- 3:- 4:- 5:- 6:-" "Ctrl+Z once takes the whole every-frame stamp away"
        sm_key ctrl+y
        sm_expect_p "1:1 2:2 3:3 4:4 5:1 6:2" "Ctrl+Y puts it back"
        sm_key ctrl+z

        # -- the orders (every frame at once shows the whole sequence) --
        for ord in "reverse:4 3 2 1 4 3" "ping-pong:1 2 3 4 3 2" "once:1 2 3 4 4 4" "forward:1 2 3 4 1 2"; do
            name=${ord%%:*}; seq=(${ord#*:})
            sm_cmd "animbrush order: $name"; sm_read
            sm_stamp 2 2
            want=""; for f in 1 2 3 4 5 6; do want+=" $f:${seq[$((f - 1))]}"; done
            sm_expect_p "${want# }" "order $name: ${seq[*]}"
            sm_key ctrl+z
        done
        sm_read
        [[ "$ST_ORD" == 0 ]] && pass "order back to forward" || fail "order: $(sm_s)"

        # -- an every-frame stamp across a cell edge stays in each cell: the
        #    brush (4 wide) at cell x 13 covers x 13-15 of its own cell only -
        #    the cells' CRCs (both layers) are worked out here --
        sm_key KP_1; sm_stamp 15 8; sm_read
        read -r _ CELLS <<< "$(sm_line ANIMC)"
        WANT=$(python3 - "${SM_COLORS[@]}" <<'PY'
import sys, zlib
cols = [bytes.fromhex(c) for c in sys.argv[1:]]
bgra = lambda c: bytes((c[2], c[1], c[0], 255))
out = []
for f in range(6):
    l1 = bytearray(16 * 16 * 4); l2 = bytearray(16 * 16 * 4)
    for y in range(6, 10):
        for x in range(6, 10): l1[(y * 16 + x) * 4:(y * 16 + x) * 4 + 4] = bgra(cols[f])
    cel = f % 4 + 1                      # forward, anchor 1
    for y in range(6, 10):
        for x in range(13, 16): l2[(y * 16 + x) * 4:(y * 16 + x) * 4 + 4] = bgra(cols[cel + 1])
    out.append(format(zlib.crc32(bytes(l1) + bytes(l2)), 'x'))
print(' '.join(out))
PY
)
        [[ "$CELLS" == "$WANT" ]] && pass "a stamp across the cell edge is cut at each cell's edge (no bleed)" || fail "edge stamp cells [$CELLS], wanted [$WANT]"
        sm_key ctrl+z
    fi
fi
rm -rf "$SM_DIR"
assert_window_exists
info "=== AnimBrush: step modes PASSED ==="
