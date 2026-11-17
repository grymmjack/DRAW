#!/bin/bash
# =============================================================================
# xform-widget-bar.sh — QA test: the transform widget's bar and its fade
# (TOOLS/ANIM-XWIDGET).
#
# Rick 2026-11-16: "opacity slider, and tint color chip ... clicking the chip
# on the tint changes the tint, left clicking opens color mixer to choose,
# shift+lclick = use current fg color ... a slider for opacity we can type a
# value into ... ctrl+alt+shift+wheel should adjust that widgets opacity".
#
#   - the OPACITY slider dragged to its middle: an OPACITY key ~50; Ctrl+Z
#     takes the whole drag back
#   - its value clicked, 25 typed: OPACITY 25
#   - Shift+click on the TINT chip: the tint colour = FG, TINT 50 keyed (it
#     was 0)
#   - a click on the chip: it follows the FG colour (XWB link = the layer);
#     again: stops
#   - Ctrl+Alt+Shift+wheel down over the widget: the widget fainter (alpha);
#     Ctrl+Alt+Shift+middle-click over it: back to full
#
# Dump: XWG shown slot drag hover alpha ..., XWB link + parts (OPACITY slider,
# its value, TINT chip, TINT slider, its value: x y w h), LLN, ANIM.
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0 LIGHTBOX_PANES=1
# =============================================================================
info "=== Animation: the transform widget's bar (opacity, tint) and fade ==="

XB_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XB_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
XB_DIR="/tmp/draw-qa-xwbar-$$"
mkdir -p "$XB_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$XB_DIR/plain.png"
python3 "$XB_PY" put "$XB_DIR/plain.png" "$XB_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

xb_line() { grep -m1 "^$1 " "$XB_DUMPF" 2>/dev/null; }
xb_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(xb_line ANIM)"
    LLN="$(xb_line LLN | cut -d' ' -f5-)"
    W=($(xb_line XWG))
    B=($(xb_line XWB))
}
# bar part n (1 OPACITY slider, 2 its value, 3 TINT chip, 4 TINT slider, 5 its value): x y w h
xb_px() { echo "${B[$(( 2 + ($1 - 1) * 4 ))]}"; }
xb_py() { echo "${B[$(( 3 + ($1 - 1) * 4 ))]}"; }
xb_pw() { echo "${B[$(( 4 + ($1 - 1) * 4 ))]}"; }
xb_ph() { echo "${B[$(( 5 + ($1 - 1) * 4 ))]}"; }
xb_mid() { echo $(( $(xb_px "$1") + $(xb_pw "$1") / 2 )) $(( $(xb_py "$1") + $(xb_ph "$1") / 2 )); }
xb_lane() { tr ' ' '\n' <<< "$LLN" | grep "^$1=" | cut -d= -f2; }
xb_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
xb_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
xb_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
xb_s() { echo "widget [${W[*]:1:5}] bar [${B[*]}] keys [$LLN]"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XB_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xb_key ctrl+0
xb_key KP_8
xb_cmd "arm layer for recording"
xb_read
if [[ "${W[1]}" != -1 || -z "${B[2]:-}" || "${B[2]}" == 0 ]]; then
    fail "the widget / its bar: $(xb_s)"
else
    screenshot "xform-widget-bar"
    # -- the OPACITY slider: from its right end to its middle --
    SX=$(xb_px 1); SW=$(xb_pw 1); read -r _ SY <<< "$(xb_mid 1)"
    drag $(( SX + SW - 1 )) "$SY" $(( SX + SW / 2 )) "$SY"; wait_for 0.6 "opacity slider"
    xb_read
    OP="$(xb_lane 6)"
    [[ "$OP" == 0:4[6-9]:* || "$OP" == 0:5[0-4]:* ]] && pass "the OPACITY slider dragged to its middle: OPACITY $OP" || fail "opacity slider: OPACITY '$OP' - $(xb_s)"
    xb_key ctrl+z; xb_read
    [[ -z "$(xb_lane 6)" ]] && pass "Ctrl+Z: the slider drag undone in one step" || fail "undo the slider: OPACITY '$(xb_lane 6)'"

    # -- the value, typed --
    read -r VX VY <<< "$(xb_mid 2)"
    xb_hclick "$VX" "$VY"; wait_for 0.6 "the input box"
    type_text "25"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed 25"
    xb_read
    [[ "$(xb_lane 6)" == 0:25:* ]] && pass "the OPACITY value clicked and 25 typed: OPACITY 25" || fail "typed opacity: '$(xb_lane 6)' - $(xb_s)"

    # -- the TINT chip --
    read -r CX CY <<< "$(xb_mid 3)"
    with_mods "shift" click "$CX" "$CY"; wait_for 0.6 "shift+click the chip"
    xb_read
    [[ "$(xb_lane 7)" == 0:50:* ]] && pass "Shift+click on the TINT chip: the FG colour, TINT 50 keyed" || fail "chip shift+click: TINT '$(xb_lane 7)' - $(xb_s)"
    xb_hclick "$CX" "$CY"; xb_read
    [[ "${B[1]}" == 1 ]] && pass "a click on the chip: the tint follows the FG colour" || fail "chip click: link '${B[1]}'"
    screenshot "xform-widget-link"
    xb_hclick "$CX" "$CY"; xb_read
    [[ "${B[1]}" == 0 ]] && pass "again: it stops following" || fail "chip click 2: link '${B[1]}'"

    # -- the fade --
    read -r FX FY <<< "$(xb_mid 1)"
    with_mods "ctrl+alt+shift" scroll_down "$FX" "$FY"; wait_for 0.5 "fade"
    with_mods "ctrl+alt+shift" scroll_down "$FX" "$FY"; wait_for 0.5 "fade"
    xb_read
    [[ "${W[5]:-255}" -lt 255 ]] && pass "Ctrl+Alt+Shift+wheel down over the widget: fainter (alpha ${W[5]})" || fail "fade: alpha '${W[5]:-}'"
    screenshot "xform-widget-faded"
    with_mods "ctrl+alt+shift" middle_click "$FX" "$FY"; wait_for 0.5 "fade reset"
    xb_read
    [[ "${W[5]:-0}" == 255 ]] && pass "Ctrl+Alt+Shift+middle-click over it: full again" || fail "fade reset: alpha '${W[5]:-}'"
fi
assert_no_crash
rm -rf "$XB_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
