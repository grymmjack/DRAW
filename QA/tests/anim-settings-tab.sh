#!/bin/bash
# =============================================================================
# anim-settings-tab.sh — QA test: Settings > Animation (GUI/SETTINGS-TABS,
# TOOLS/ANIM-XLANE lane colours, TOOLS/ANIM-XWIDGET opacity default).
#
# Rick 2026-11-16: "one new tab in settings for animation with colors of
# lanes, widget opacity, etc. and a checkbox: default x-sheet zoom override:
# [x] show all".
#
# The run's cfg sets ANIM_WIDGET_OPACITY=50, X's lane colour FF0000 and
# ANIM_LANE_THICKNESS=3, XSHEET_CONTRAST=30:
#   - the layer armed: the transform widget at half opacity (alpha 128)
#   - Ctrl+Alt+Shift+wheel down over it: fainter; Ctrl+Alt+Shift+middle-click:
#     back to 128 (the default), not full
#   - the Animation panel's LANES page: X's swatch is the red set, Y's the
#     default green
#   - ANIM > Animation Settings... (the command palette): Settings opens on
#     its ANIMATION tab, showing those values (SETANIM); Escape closes it
#     with nothing changed
#
# Dump: XWG (alpha = field 5), ANIMPLP (LANES rows), ANIMPL (pad), ANIMP,
# <dump>.settings (SETTINGS tab ... / SETANIM fitAll opacity colours thickness contrast).
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0 LIGHTBOX_PANES=1 ANIM_WIDGET_OPACITY=50 ANIM_LANE_COLORS=FF0000 ANIM_LANE_THICKNESS=3 XSHEET_CONTRAST=30
# =============================================================================
info "=== Animation: Settings > Animation (lane colours, widget opacity) ==="

ST_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
ST_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
ST_DIR="/tmp/draw-qa-animset-$$"
mkdir -p "$ST_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$ST_DIR/plain.png"
python3 "$ST_PY" put "$ST_DIR/plain.png" "$ST_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

st_line() { grep -m1 "^$1 " "$ST_DUMPF" 2>/dev/null; }
st_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ P_VIS _ P_X P_Y _ _ P_SC _ <<< "$(st_line ANIMP)"
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ L_PAD _ <<< "$(st_line ANIMPL)"
    Q=($(st_line ANIMPLP))
    W=($(st_line XWG))
}
st_vx() { echo $(( P_X + $1 * P_SC / 100 )); }
st_vy() { echo $(( P_Y + $1 * P_SC / 100 )); }
st_rowy() { local e; for e in "${Q[@]:16}"; do [[ "${e%%:*}" == "$1" ]] && { local r="${e#*:}"; echo "${r%%:*}"; return; }; done; }
st_px() { # VX VY -> the pixel's RRGGBB
    snap_region "$1" "$2" 1 1 "px$1_$2"
    magick "$SNAP_RESULT" -format '%[hex:p{0,0}]' info: 2>/dev/null | cut -c1-6
}
st_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.5 "$1"
}
st_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; st_read; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$ST_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key ctrl+0; wait_for 0.6 "fit"
park_mouse; key KP_8; wait_for 0.6 "lightbox"
st_cmd "arm layer for recording"
st_read
if [[ "${W[1]:-}" != -1 ]]; then
    fail "the widget did not show: XWG [${W[*]}]"
else
    [[ "${W[5]}" == 128 ]] && pass "ANIM_WIDGET_OPACITY=50: the widget at half opacity (alpha ${W[5]})" || fail "widget alpha '${W[5]}' (want 128)"
    # over the widget's box: its top-left handle, nudged inside
    HX=$(( ${W[6]} + 3 )); HY=$(( ${W[7]} + 3 ))
    with_mods "ctrl+alt+shift" scroll_down "$HX" "$HY"; wait_for 0.5 "fade"
    st_read
    [[ "${W[5]}" -lt 128 ]] && pass "Ctrl+Alt+Shift+wheel down over it: fainter (alpha ${W[5]})" || fail "fade: alpha '${W[5]}'"
    with_mods "ctrl+alt+shift" middle_click "$HX" "$HY"; wait_for 0.5 "fade reset"
    st_read
    [[ "${W[5]}" == 128 ]] && pass "Ctrl+Alt+Shift+middle-click: back to the default (128), not full" || fail "reset: alpha '${W[5]}' (want 128)"
fi

# -- the LANES page's swatches --
[[ "$P_VIS" == -1 ]] || { st_cmd "toggle animation panel"; st_read; }
if [[ "${Q[2]:-0}" == 0 ]]; then
    fail "no LANES chip: [${Q[*]}]"
else
    st_hclick "$(st_vx $(( ${Q[2]} + ${Q[4]} / 2 )))" "$(st_vy $(( ${Q[3]} + ${Q[5]} / 2 )))"
    Y1=$(st_rowy 1); Y2=$(st_rowy 2)
    C1=$(st_px "$(st_vx "$L_PAD")" "$(st_vy $(( Y1 + 5 )))")
    C2=$(st_px "$(st_vx "$L_PAD")" "$(st_vy $(( Y2 + 5 )))")
    [[ "${C1^^}" == FF0000 ]] && pass "the LANES page: X's swatch is the red set in the cfg" || fail "X swatch '$C1' (want FF0000) at row $Y1 pad $L_PAD"
    [[ "${C2^^}" == 6AC46A ]] && pass "Y's swatch: the default green (6AC46A), the list padded" || fail "Y swatch '$C2' (want 6AC46A)"
    screenshot "anim-settings-lanes"
fi

# -- the tab --
rm -f "$ST_DUMPF.settings"
st_cmd "animation settings"
wait_for 1.0 "settings"
for _ in 1 2 3 4 5 6 7 8 9 10; do grep -q '^SETANIM ' "$ST_DUMPF.settings" 2>/dev/null && break; sleep 0.2; done # (written a moment later)
S="$(tr -d '\r' < "$ST_DUMPF.settings" 2>/dev/null)"
screenshot "anim-settings-tab"
read -r _ S_TAB _ <<< "$(grep -m1 '^SETTINGS ' <<< "$S")"
read -r _ S_FIT S_OP S_CLR S_TH S_CT _ <<< "$(grep -m1 '^SETANIM ' <<< "$S")"
[[ "$S_TAB" == 9 ]] && pass "ANIM > Animation Settings...: Settings on its ANIMATION tab" || fail "settings tab: [$S]"
[[ "$S_OP" == 50 && "$S_FIT" == 0 && "$S_CLR" == FF0000* && "$S_TH" == 3 && "$S_CT" == 30 ]] && pass "the tab shows the values (opacity 50, show-all off, X red, lines 3 px, contrast 30)" || fail "tab values: [$S]"
key Escape; wait_for 1.0 "closed"
assert_no_crash
rm -rf "$ST_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
