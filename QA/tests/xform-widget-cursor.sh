#!/bin/bash
# =============================================================================
# xform-widget-cursor.sh — QA test: the arrow over the animation transform
# widget (TOOLS/ANIM-XWIDGET) - its handles and its OPACITY / TINT bar - not
# the tool's cursor (Rick 2026-11-17, screenshots: the paint cursor over the
# bar; "none of the handles are, rotate, scale, etc.").
#   - the Brush tool, a layer armed for recording: over the canvas away from
#     the widget, the tool's cursor (not the arrow)
#   - over the ROTATE handle, a corner, an edge middle, the pivot: the arrow
#   - over the bar's OPACITY slider, the TINT chip: the arrow
# Dump: CURSOR <id> <flip> (0 = CURSOR_NULL, the system arrow) | XWG shown slot
# drag hover alpha (hx hy) x 10 | XWB link + the bar's parts x y w h.
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0 LIGHTBOX_PANES=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Animation: the arrow over the transform widget ==="

XC_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XC_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
XC_DIR="/tmp/draw-qa-xwcur-$$"
mkdir -p "$XC_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$XC_DIR/plain.png"
python3 "$XC_PY" put "$XC_DIR/plain.png" "$XC_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

xc_line() { grep -m1 "^$1 " "$XC_DUMPF" 2>/dev/null; }
xc_read() { W=($(xc_line XWG)); B=($(xc_line XWB)); }
xc_cur() { # X Y -> CUR (the cursor id there)
    hover "$1" "$2"; wait_for 0.25 "pointer there"; hover $(( $1 + 1 )) "$2"; wait_for 0.35 "render"
    read -r _ CUR _ <<< "$(xc_line CURSOR)"
}
xc_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
xc_hx() { echo "${W[$(( 6 + ($1 - 1) * 2 ))]}"; } # handle n's x (XWG: 5 fields, then hx hy per handle)
xc_hy() { echo "${W[$(( 7 + ($1 - 1) * 2 ))]}"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XC_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key ctrl+0; wait_for 0.6 "zoom"
park_mouse; key KP_8; wait_for 0.8 "the lightbox"
park_mouse; key b; wait_for 0.4 "Brush tool"
xc_cmd "arm layer for recording"
hover 300 250; wait_for 0.3 "render"; xc_read
if [[ "${W[1]:-}" != -1 || -z "${B[2]:-}" ]]; then
    fail "the widget does not show [XWG ${W[*]:-}] [XWB ${B[*]:-}]"
    rm -rf "$XC_DIR"; assert_no_crash; exit 0
fi
pass "a layer armed: the widget shows"

# away from the widget, over the pane: the tool's cursor
TLX=$(xc_hx 1); TLY=$(xc_hy 1); BRX=$(xc_hx 3); BRY=$(xc_hy 3)
info "widget box $TLX,$TLY - $BRX,$BRY; bar [${B[*]:1}]"
xc_cur $(( (TLX + BRX) / 2 + 3 )) $(( (TLY + BRY) / 2 + 3 )); IN=$CUR
(( IN != 0 )) && pass "inside the box, off the handles: the tool's cursor ($IN)" || fail "inside the box the arrow ($IN) - the brush lost its cursor"

for h in 9:ROTATE 1:corner 6:edge 10:pivot; do
    n=${h%%:*}; nm=${h#*:}
    xc_cur "$(xc_hx "$n")" "$(xc_hy "$n")"
    (( CUR == 0 )) && pass "over the $nm handle: the arrow" || fail "over the $nm handle at $(xc_hx "$n"),$(xc_hy "$n"): cursor $CUR (want 0, the arrow)"
done
for p in 1:OPACITY 3:TINT; do
    n=${p%%:*}; nm=${p#*:}
    x=$(( B[2 + (n - 1) * 4] + B[4 + (n - 1) * 4] / 2 )); y=$(( B[3 + (n - 1) * 4] + B[5 + (n - 1) * 4] / 2 ))
    xc_cur "$x" "$y"
    (( CUR == 0 )) && pass "over the bar's $nm: the arrow" || fail "over the bar's $nm at $x,$y: cursor $CUR (want 0, the arrow)"
done
screenshot "xform-widget-cursor"
rm -rf "$XC_DIR"
assert_no_crash
info "=== Transform widget cursor done ==="
