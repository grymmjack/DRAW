#!/bin/bash
# =============================================================================
# anim-xsheet-sizing.sh — QA test: sizing the lightbox's bands and the
# X-sheet's name column, the X-sheet's cell thumbnails, names cut short.
#
# Rick 2026-11-09: "can we apply the same thumbnails to the x-strip? ... also
# the same treatment for tooltips when a layers name is occluded? also we would
# like to be able to resize the x-sheet pane on the left that holds the layers
# ... same vertically ... more lightbox, more sequence, more x-sheet ... a way
# to resize that and dynamically fit the frames in for the sequence view".
#
# - X-sheet cells crop to the drawing like the Layers panel thumbnails (here
#   LAYER_THUMBNAIL_MIN_CROP=1): frame 1's 6x6 square fills its 16x16 cell's
#   thumbnail. The old build showed the whole cell (~14% red).
# - The name column's right edge drags (XSHEET_NAME_WIDTH); a name cut short
#   shows whole in a tooltip (TIP source 13, idx 4000 + slot); a double-click
#   on the edge: automatic again.
# - The band's bottom edge (over the transport bar) drags (XSHEET_SIZE /
#   LIGHTBOX_STRIP_SIZE); a double-click: the X-sheet automatic, the strip
#   fitting every frame across.
#
# Dump: ANIMXS (nameW rowH tickW gx ... CURRENT_LAYER), ANIMXSF (frame spans),
# ANIMLB (stripY stripH barY ... stripFirst stripN), TIP.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 TOOLTIPS_DISABLED=FALSE LAYER_THUMBNAIL_MIN_CROP=1 LIGHTBOX_STRIP_FLOW=ROW XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LIGHTBOX_STRIP_SIZE=0
# =============================================================================
info "=== Animation: X-sheet / strip sizing, cell thumbnails, cut names ==="

XZ_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XZ_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XZ_DIR="/tmp/draw-qa-xssize-$$"
mkdir -p "$XZ_DIR"
# 24 frames of 16x16 in one row; frame 1: a 6x6 red square
magick -size 384x16 xc:none -fill '#e02020' -draw 'rectangle 3,4 8,9' -fill '#40c040' -draw 'rectangle 20,4 25,9' "PNG32:$XZ_DIR/plain.png"
python3 "$XZ_PY" put "$XZ_DIR/plain.png" "$XZ_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,24,1,10,0,0).hex())")"

xz_line() { grep -m1 "^$1 " "$XZ_DUMP" 2>/dev/null; }
xz_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ XON XX1 XY1 XX2 _ XNW XRH XTW XGX _ _ _ _ _ XCUR _ <<< "$(xz_line ANIMXS)"
    XF=($(xz_line ANIMXSF))
    read -r _ _ _ _ _ _ LSY LSH LBY _ _ _ LSF LSN _ <<< "$(xz_line ANIMLB)"
}
xz_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
xz_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
xz_red() { magick "$1" -fuzz 12% -fill white -opaque '#e02020' -fill black +opaque white -colorspace gray -format '%[fx:round(mean*100)]' info: 2>/dev/null; }
xz_tip() { # X Y -> TIP_ACT TIP_SRC TIP_IDX after resting there
    hover "$1" "$2"; wait_for 0.3 "rest"; hover $(( $1 + 1 )) "$2"; wait_for 2.0 "tooltip delay"
    read -r _ TIP_ACT TIP_SRC TIP_IDX _ <<< "$(xz_line TIP)"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XZ_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xz_key ctrl+0
xz_read; [[ "$XON" == -1 ]] || xz_key KP_8
xz_read
if [[ "$XON" != -1 || "${XTW:-0}" -lt 1 ]]; then
    fail "X-sheet: on '$XON', tick '${XTW:-}'"
else
    ROW1_Y=$(( XY1 + 1 + XRH ))

    # -- a cell crops to its drawing (MIN_CROP=1) --
    snap_region $(( XF[2] + 2 )) $(( ROW1_Y + 1 )) $(( XTW - 3 )) $(( XRH - 2 )) "xssize-cell1"
    N=$(xz_red "$SNAP_RESULT")
    (( ${N:-0} >= 60 )) && pass "frame 1's cell: the 6x6 square cropped to fill the thumbnail ($N% red)" \
        || fail "frame 1's cell: ${N:-?}% red, wanted >= 60% (the whole 16x16 cell is ~14%)"

    # -- a long name, the column dragged narrow: cut, with a tooltip --
    xz_palette "rename layer"
    key ctrl+a; type_text "Walk cycle background ink"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "renamed"
    xz_read; NW0=$XNW
    drag $(( XGX - 1 )) $(( ROW1_Y + XRH / 2 )) $(( XX1 + 4 )) $(( ROW1_Y + XRH / 2 )); wait_for 0.6 "drag the column edge left"
    xz_read; NW1=$XNW
    (( NW1 < NW0 - 20 )) && pass "dragging the name column's edge left narrows it ($NW0 -> $NW1 px)" \
        || fail "name column after a drag left: $NW0 -> ${NW1:-?} px"
    xz_tip $(( XX1 + 30 )) $(( ROW1_Y + XRH / 2 ))
    [[ "$TIP_ACT" == -1 && "$TIP_SRC" == 13 && "$TIP_IDX" == $(( 4000 + XCUR )) ]] && pass "the cut name shows whole in a tooltip" \
        || fail "cut name tooltip: TIP '$TIP_ACT $TIP_SRC $TIP_IDX' (wanted -1 13 $(( 4000 + XCUR )))"
    xz_read
    double_click $(( XGX - 2 )) $(( ROW1_Y + XRH / 2 )); wait_for 0.8 "double-click the edge"
    xz_read
    [[ "$XNW" == "$NW0" ]] && pass "a double-click on the edge: automatic again ($XNW px)" || fail "after the double-click: $XNW px, wanted $NW0"
    drag $(( XGX - 1 )) $(( ROW1_Y + XRH / 2 )) $(( XGX + 39 )) $(( ROW1_Y + XRH / 2 )); wait_for 0.6 "drag the column edge right"
    xz_read
    (( XNW >= NW0 + 35 && XNW <= NW0 + 45 )) && pass "dragging it right 40 px widens it ($NW0 -> $XNW px)" || fail "name column after a drag right: $NW0 -> $XNW px, wanted ~$(( NW0 + 40 ))"
    double_click $(( XGX - 2 )) $(( ROW1_Y + XRH / 2 )); wait_for 0.8 "back to automatic"

    # -- the band's bottom edge --
    xz_read; SH0=$LSH; CX=$(( (XX1 + XX2) / 2 ))
    drag "$CX" $(( LBY - 1 )) "$CX" $(( LBY + 39 )); wait_for 0.6 "drag the band edge down"
    xz_read
    (( LSH >= SH0 + 35 && LSH <= SH0 + 45 )) && pass "dragging the X-sheet's bottom edge down 40 px: $SH0 -> $LSH px" \
        || fail "X-sheet band after a drag down: $SH0 -> ${LSH:-?} px, wanted ~$(( SH0 + 40 ))"
    double_click "$CX" $(( LBY - 1 )); wait_for 0.8 "double-click the band edge"
    xz_read
    [[ "$LSH" == "$SH0" ]] && pass "a double-click: the X-sheet band automatic again ($LSH px)" || fail "after the double-click: $LSH px, wanted $SH0"
    screenshot "xssize-xsheet"

    # -- the strip: a double-click on its edge fits all 24 frames --
    xz_key KP_8
    xz_read
    if (( ${LSN:-0} >= 24 )); then
        fail "the strip already shows all 24 frames ($LSN) - the fit is not exercised"
    else
        SN0=$LSN
        double_click "$CX" $(( LBY - 1 )); wait_for 0.8 "double-click the strip edge"
        xz_read
        [[ "$LSN" == 24 && "$LSF" == 1 ]] && pass "a double-click on the strip's edge fits every frame: $SN0 -> $LSN cells" \
            || fail "strip after the double-click: first $LSF, $LSN cells (was $SN0), wanted 1 / 24"
        screenshot "xssize-strip"
    fi
fi
assert_no_crash
rm -rf "$XZ_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
