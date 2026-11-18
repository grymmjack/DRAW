#!/bin/bash
# =============================================================================
# xform-widget.sh — QA test: the transform widget on an armed layer
# (TOOLS/ANIM-XWIDGET).
#
# Rick 2026-11-16: "a unified transform tool for x, y, w, h, w+h (scale),
# rotation, (pivot x/y) ... as we adjust the art with the widget a little tip
# box shows the old value -> new value".
#
#   - not armed: no widget; armed: the widget round frame 1's drawing (a 4x10
#     block at 2,3) in the current lightbox pane
#   - the bottom-right corner dragged 4 px right: SCALE X 200 (the box twice
#     as wide, its top-left corner where it was: X 2), pixels kept; a tip
#     while dragging (screenshot)
#   - Ctrl+Z: one undo step - no SCALE / X keys
#   - the knob, Shift-dragged a quarter turn round the pivot: ROTATE 90
#   - Ctrl+Z; the knob Ctrl-dragged 40 degrees: ROTATE 45 (the program's angle
#     snap, Snap Degrees 45 - Rick 2026-11-16)
#   - Ctrl+Z, then the pivot dragged 2 px right: PIVOT X 10, the drawing
#     where it was (X 0)
#
# Dump: XWG shown slot drag hover alpha + handles x y (TL TR BR BL T R B L knob
# pivot), LLN (keys), ANIMC (pixels), ANIMLBP (panes), ANIM.
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0 LIGHTBOX_PANES=1 ANGLE_SNAP_DEGREES=45 ANGLE_SNAP_PIXEL_ART=FALSE
# =============================================================================
info "=== Animation: the transform widget on an armed layer ==="

XW_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XW_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
XW_DIR="/tmp/draw-qa-xwidget-$$"
mkdir -p "$XW_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$XW_DIR/plain.png"
python3 "$XW_PY" put "$XW_DIR/plain.png" "$XW_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

xw_line() { grep -m1 "^$1 " "$XW_DUMPF" 2>/dev/null; }
xw_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(xw_line ANIM)"
    C="$(xw_line ANIMC | cut -d' ' -f2-)"
    LLN="$(xw_line LLN | cut -d' ' -f5-)"
    W=($(xw_line XWG))
    local p k; p=($(xw_line ANIMLBP)); PW=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
# handle n (1 TL 2 TR 3 BR 4 BL 5 T 6 R 7 B 8 L 9 knob 10 pivot): x / y
xw_hx() { echo "${W[$(( 6 + ($1 - 1) * 2 ))]}"; }
xw_hy() { echo "${W[$(( 7 + ($1 - 1) * 2 ))]}"; }
xw_lane() { tr ' ' '\n' <<< "$LLN" | grep "^$1=" | cut -d= -f2; }
xw_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
xw_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
xw_s() { echo "widget [${W[*]:1:5}] keys [$LLN]"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XW_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xw_key ctrl+0
xw_key KP_8
xw_read
C0="$C"
if [[ "$A_COUNT" != 4 || -z "$PW" ]]; then
    fail "start: $A_COUNT frames, pane for frame $A_CUR '${PW:-}'"
else
    [[ "${W[1]}" == 0 ]] && pass "not armed: no widget" || fail "unarmed: $(xw_s)"
    xw_cmd "arm layer for recording"; xw_read
    S=$(( PW / 16 )) # pane px per cell px
    TLX=$(xw_hx 1); TLY=$(xw_hy 1)
    if [[ "${W[1]}" == -1 && "$TLX" == $(( PX + 2 * S )) && "$TLY" == $(( PY + 3 * S )) && "$(xw_hx 3)" == $(( PX + 6 * S )) ]]; then
        pass "armed: the widget round frame 1's drawing (top left at its 2,3; $S px a pixel)"
    else
        fail "the widget: pane $PX,$PY x$S - $(xw_s) TL $TLX,$TLY BR $(xw_hx 3),$(xw_hy 3)"
    fi

    # -- the bottom-right corner, 4 px right: SCALE X 200 --
    BX=$(xw_hx 3); BY=$(xw_hy 3)
    mouse_down "$BX" "$BY"; sleep 0.2
    hover $(( BX + 2 * S )) "$BY"; sleep 0.2
    hover $(( BX + 4 * S )) "$BY"; sleep 0.5
    screenshot "xform-widget-drag"
    mouse_up; wait_for 0.6 "release"
    xw_read
    SX="$(xw_lane 3)"; SY="$(xw_lane 4)"; LX="$(xw_lane 1)"
    if [[ "$SX" == 0:200:* && ( -z "$SY" || "$SY" == 0:100:* ) && "$C" == "$C0" && "$(xw_hx 1)" == "$TLX" && "$(xw_hy 1)" == "$TLY" ]]; then
        pass "the corner dragged 4 px: SCALE X 200, the top-left corner kept (X $LX), the pixels stay"
    else
        fail "corner drag: SCALE X '$SX' Y '$SY' X '$LX', TL now $(xw_hx 1),$(xw_hy 1), pixels $([[ "$C" == "$C0" ]] && echo same || echo CHANGED) - $(xw_s)"
    fi
    xw_key ctrl+z; xw_read
    [[ -z "$(xw_lane 3)$(xw_lane 1)" || ( "$(xw_lane 3)" != 0:200:* ) ]] && pass "Ctrl+Z: the whole drag undone in one step" || fail "undo the corner drag: $(xw_s)"

    # -- the knob, Shift-dragged a quarter turn: ROTATE 90 --
    KX=$(xw_hx 9); KY=$(xw_hy 9); VX=$(xw_hx 10); VY=$(xw_hy 10)
    # a quarter turn clockwise about the pivot (screen y down): (dx, dy) -> (-dy, dx)
    with_mods "shift" drag "$KX" "$KY" $(( VX - (KY - VY) )) $(( VY + (KX - VX) )); wait_for 0.6 "rotate"
    xw_read
    [[ "$(xw_lane 5)" == 0:90:* && "$C" == "$C0" ]] && pass "the knob dragged a quarter turn with Shift: ROTATE 90" || fail "rotate: ROT '$(xw_lane 5)' (knob $KX,$KY pivot $VX,$VY) - $(xw_s)"
    screenshot "xform-widget-rotated"
    xw_key ctrl+z; xw_read

    # -- the knob, Ctrl-dragged 40 degrees: the program's angle snap (Snap Degrees 45) -> ROTATE 45 --
    KX=$(xw_hx 9); KY=$(xw_hy 9); VX=$(xw_hx 10); VY=$(xw_hy 10)
    read -r RX RY <<< "$(awk -v kx="$KX" -v ky="$KY" -v vx="$VX" -v vy="$VY" 'BEGIN { a = 40 * 3.14159265 / 180; dx = kx - vx; dy = ky - vy; printf "%d %d", vx + dx * cos(a) - dy * sin(a) + 0.5, vy + dx * sin(a) + dy * cos(a) + 0.5 }')"
    with_mods "ctrl" drag "$KX" "$KY" "$RX" "$RY"; wait_for 0.6 "rotate"
    xw_read
    [[ "$(xw_lane 5)" == 0:45:* ]] && pass "the knob dragged 40 degrees with Ctrl: ROTATE 45 (the angle snap, Snap Degrees 45)" || fail "ctrl rotate: ROT '$(xw_lane 5)' (to $RX,$RY) - $(xw_s)"
    xw_key ctrl+z; xw_read

    # -- the pivot, 2 px right: PIVOT X 10, the drawing stays --
    VX=$(xw_hx 10); VY=$(xw_hy 10)
    drag "$VX" "$VY" $(( VX + 2 * S )) "$VY"; wait_for 0.6 "pivot"
    xw_read
    PVX="$(xw_lane 8)"; LX="$(xw_lane 1)"
    if [[ "$PVX" == 0:10:* && ( -z "$LX" || "$LX" == 0:0:* ) && "$(xw_hx 1)" == "$TLX" ]]; then
        pass "the pivot dragged 2 px: PIVOT X 10, the drawing where it was"
    else
        fail "pivot: PIVOT X '$PVX' X '$LX' TL $(xw_hx 1) (was $TLX) - $(xw_s)"
    fi
fi
assert_no_crash
rm -rf "$XW_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
