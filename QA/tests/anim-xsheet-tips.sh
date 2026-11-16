#!/bin/bash
# =============================================================================
# anim-xsheet-tips.sh — QA test: hovering a tag or a frame note on the X-sheet
# shows its whole text in a tooltip.
#
# Rick, 2026-11-08: "for a tag that is a single frame, or a note, can we have
# the hover over it show a tooltip of the full thing? it's clipped."
#
# Dump: TIP active source idx (source 13 = X-sheet; idx 1000 + tag, 2000 +
# frame), ANIMXS / ANIMXSF (frame spans), ANIMXST tags row, ANIMXSN notes row.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 TOOLTIPS_DISABLED=FALSE
# =============================================================================
info "=== Animation: X-sheet tag / note tooltips ==="

XT_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XT_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XT_DIR="/tmp/draw-qa-xstips-$$"
mkdir -p "$XT_DIR"
magick -size 96x16 xc:none -fill '#c04040' -draw 'rectangle 3,4 8,9' -fill '#40c040' -draw 'rectangle 20,4 25,9' \
    -fill '#4040c0' -draw 'rectangle 37,4 42,9' "PNG32:$XT_DIR/plain.png"
python3 "$XT_PY" put "$XT_DIR/plain.png" "$XT_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

xt_line() { grep -m1 "^$1 " "$XT_DUMP" 2>/dev/null; }
xt_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ XON _ XY1 _ _ _ XRH XTW _ <<< "$(xt_line ANIMXS)"
    XF=($(xt_line ANIMXSF))
    TR=($(xt_line ANIMXST))
    NR_Y=""; read -r _ NR_Y _ <<< "$(xt_line ANIMXSN)"
}
xt_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
xt_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
xt_box() { type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "box"; }
xt_fx() { echo $(( ${XF[$(( 3 * $1 - 1 ))]:-0} + ${XTW:-0} / 2 )); }
xt_head() { click "$(xt_fx "$1")" $(( ${XY1:-0} + 1 + ${XRH:-0} / 2 )); wait_for 0.4 "header $1"; }
xt_tip() { # X Y -> TIP_ACT TIP_SRC TIP_IDX after resting there
    hover "$1" "$2"; wait_for 0.3 "rest"; hover $(( $1 + 1 )) "$2"; wait_for 2.0 "tooltip delay"
    read -r _ TIP_ACT TIP_SRC TIP_IDX _ <<< "$(xt_line TIP)"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XT_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xt_key ctrl+0
xt_read; [[ "$XON" == -1 ]] || xt_key KP_8
xt_read
if [[ "$XON" != -1 || "${XTW:-0}" -lt 1 ]]; then
    fail "X-sheet: on '$XON', tick '${XTW:-}'"
else
    # a one-frame tag with a long name on frame 2
    xt_head 2; xt_palette "tag frames"; xt_box "walk-cycle-left-foot-down"; xt_read
    if [[ "${TR[2]:-}" != 1 ]]; then
        fail "no tag on the TAGS row: '${TR[*]:-}'"
    else
        xt_tip $(( (TR[3] + TR[4]) / 2 )) $(( TR[1] + XRH / 2 ))
        [[ "$TIP_ACT" == -1 && "$TIP_SRC" == 13 && "$TIP_IDX" == 1001 ]] && pass "hovering the one-frame tag shows its tooltip" \
            || fail "tag tooltip: TIP '$TIP_ACT $TIP_SRC $TIP_IDX' (wanted -1 13 1001)"
        screenshot "xstips-tag"
    fi
    # a long note on frame 3, cut by a note on frame 4
    xt_head 3; xt_palette "frame note"; xt_box "left foot plants, weight shifts forward"
    xt_head 4; xt_palette "frame note"; xt_box "pass"; xt_read
    if [[ -z "$NR_Y" ]]; then
        fail "no NOTES row"
    else
        xt_tip "$(xt_fx 3)" $(( NR_Y + XRH / 2 ))
        [[ "$TIP_ACT" == -1 && "$TIP_SRC" == 13 && "$TIP_IDX" == 2003 ]] && pass "hovering frame 3's note shows its tooltip" \
            || fail "note tooltip: TIP '$TIP_ACT $TIP_SRC $TIP_IDX' (wanted -1 13 2003)"
        xt_tip "$(xt_fx 4)" $(( NR_Y + XRH / 2 ))
        [[ "$TIP_ACT" == -1 && "$TIP_IDX" == 2004 ]] && pass "moving on to frame 4's note shows that one" || fail "frame 4 note tooltip: TIP '$TIP_ACT $TIP_SRC $TIP_IDX'"
        xt_tip "$(xt_fx 6)" $(( XY1 + 1 + XRH / 2 ))
        [[ "$TIP_SRC" != 13 ]] && pass "off the tags / notes rows: no X-sheet tooltip" || fail "header row: TIP '$TIP_ACT $TIP_SRC $TIP_IDX'"
    fi
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$XT_DIR"
assert_window_exists
