#!/bin/bash
# =============================================================================
# anim-xsheet-layer-controls.sh — QA test: eye, lock and opacity on the
# X-sheet's layer rows; a right-click opens the layers panel's menu (field kit
# T-22, Rick 2026-11-08: "an eye icon in front of the layer and lock status
# and opacity, simple controls like that ... right click on the layer the same
# way in the XSHEET as it is in layer panel").
#
# Name column: eye (show / hide), lock (the alpha lock), then the name, then
# the opacity box (wheel +/- 5 %, Shift 1 %; drag up / down; click to type).
# The old build had only the name.
#
# Dump: ANIMXS, ANIMXSR (row y), ANIMXSL (eyeX lockX opX opW + per row: slot
# visible lock opacity%), POPUP (an open popup menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=1
# =============================================================================
info "=== Animation: X-sheet layer controls ==="

XL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XL_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XL_DIR="/tmp/draw-qa-xslayer-$$"
mkdir -p "$XL_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 3,4 8,9' -fill '#40c040' -draw 'rectangle 20,4 25,9' "PNG32:$XL_DIR/plain.png"
python3 "$XL_PY" put "$XL_DIR/plain.png" "$XL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

xl_line() { grep -m1 "^$1 " "$XL_DUMP" 2>/dev/null; }
xl_read() { # XS_*, ROW1_Y, L_EYE L_LOCK L_OPX L_OPW, V1 K1 O1 (row 1: visible lock opacity%)
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ XS_ON XS_SHOWN XS_X1 XS_Y1 XS_X2 XS_Y2 XS_NW XS_RH XS_TW XS_GX _ <<< "$(xl_line ANIMXS)"
    read -r _ _ _ ROW1_Y _ <<< "$(grep -m1 '^ANIMXSR 1 ' "$XL_DUMP")"
    read -r _ L_EYE L_LOCK L_OPX L_OPW _S1 V1 K1 O1 _ <<< "$(xl_line ANIMXSL)"
}
xl_y() { echo $(( ROW1_Y + XS_RH / 2 )); }
xl_opx() { echo $(( L_OPX + L_OPW / 2 )); }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key KP_0; wait_for 0.8 "Lightbox"
xl_read
if [[ "${XS_SHOWN:-}" != -1 || -z "${ROW1_Y:-}" ]]; then
    fail "X-sheet: shown '${XS_SHOWN:-}', row 1 y '${ROW1_Y:-}'"
else
    pass "X-sheet shown, row 1 at y $ROW1_Y (visible '${V1:-}' lock '${K1:-}' opacity '${O1:-}')"
    # aim at where the controls are (the old build: its dump has no ANIMXSL - use the same offsets)
    EX=$(( ${L_EYE:-$(( XS_X1 + 2 ))} + 4 )); LX=$(( ${L_LOCK:-$(( XS_X1 + 13 ))} + 3 ))
    OX=$(( ${L_OPX:-$(( XS_GX - 20 ))} + ${L_OPW:-16} / 2 ))

    click "$EX" "$(xl_y)"; wait_for 0.4 "eye"; xl_read
    [[ "$V1" == 0 ]] && pass "eye click: the layer is hidden" || fail "eye click: visible '${V1:-}', wanted 0"
    click "$EX" "$(xl_y)"; wait_for 0.4 "eye"; xl_read
    [[ "$V1" == -1 ]] && pass "eye again: shown" || fail "eye again: visible '${V1:-}', wanted -1"

    click "$LX" "$(xl_y)"; wait_for 0.4 "lock"; xl_read
    [[ "$K1" == -1 ]] && pass "lock click: alpha-locked" || fail "lock click: lock '${K1:-}', wanted -1"
    click "$LX" "$(xl_y)"; wait_for 0.4 "lock"; xl_read
    [[ "$K1" == 0 ]] && pass "lock again: unlocked" || fail "lock again: lock '${K1:-}', wanted 0"

    scroll_down "$OX" "$(xl_y)"; sleep 0.12; scroll_down "$OX" "$(xl_y)"; wait_for 0.4 "wheel"; xl_read
    [[ "$O1" == 90 ]] && pass "wheel down x2 over the opacity box: 90 %" || fail "wheel over opacity: '${O1:-}', wanted 90"
    mouse_down "$OX" "$(xl_y)"; hover "$OX" $(( $(xl_y) - 10 )); sleep 0.15; hover "$OX" $(( $(xl_y) + 20 )); sleep 0.2; mouse_up; wait_for 0.4 "drag"; xl_read
    [[ "$O1" == 70 ]] && pass "drag the opacity box 20 px down: 70 %" || fail "drag opacity down 20 px: '${O1:-}', wanted 70"
    click "$OX" "$(xl_y)"; wait_for 0.8 "input box"; type_text "35"; key Return; wait_for 0.6 "typed"; xl_read
    [[ "$O1" == 35 ]] && pass "click the opacity box, type 35: 35 %" || fail "typed opacity: '${O1:-}', wanted 35"
    screenshot "anim-xsheet-layer-controls"

    # right-click on the layer's row: the layers panel's menu
    NX=$(( XS_X1 + 30 ))
    click "$NX" "$(xl_y)" 3; wait_for 0.6 "right-click"; xl_read
    if grep -q '^POPUP ' "$XL_DUMP"; then pass "right-click on the row: a menu opens ($(xl_line POPUP))"; else fail "right-click on the row: no popup menu"; fi
    screenshot "anim-xsheet-layer-menu"
    key Escape; wait_for 0.3 "Escape"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$XL_DIR"
assert_window_exists
