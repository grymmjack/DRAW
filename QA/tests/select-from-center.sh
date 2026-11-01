#!/bin/bash
# =============================================================================
# select-from-center.sh — Ctrl while dragging a rectangle / ellipse selection
# draws it FROM the press point as its center, as the Rect / Ellipse drawing
# tools do (Rick, 2026-10-11). A short mark (CX-5..CX+5) is selected by a
# Ctrl-drag from its center to one side, then Deleted: from center the box
# spans both halves and the whole mark goes; from the corner only its right
# half would.
# =============================================================================

info "=== Rect / ellipse selection from center (Ctrl) ==="
canvas_focus b
key bracketright; key bracketright; key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

BOX=36
one_case() { # NAME DX TOOLKEYS...
    local name=$1 x=$2 y=$CANVAS_CY
    shift 2
    park_mouse
    snap_region $(( x - BOX/2 )) $(( y - BOX/2 )) $BOX $BOX "fc-$name-blank"; local blank="$SNAP_RESULT"
    key b; wait_for 0.2 "Brush"; key grave
    drag $(( x - 5 )) $y $(( x + 5 )) $y; wait_for 0.3 "mark"
    "$@"                                          # pick the selection tool
    ctrl_drag $x $y $(( x + 14 )) $(( y + 10 )); wait_for 0.4 "Ctrl-drag from the center"
    key Delete; wait_for 0.4 "Delete"
    key ctrl+d; wait_for 0.2 "Deselect"
    park_mouse
    snap_region $(( x - BOX/2 )) $(( y - BOX/2 )) $BOX $BOX "fc-$name-after"
    assert_regions_same "$blank" "$SNAP_RESULT" \
        "$name: Ctrl drew the selection from its center - the whole mark (both halves) was selected and deleted" 30
}
rect_tool() { key m; wait_for 0.3 "Rect marquee"; }
ellipse_tool() { key question; wait_for 0.5 "palette"; type_text "ellipse select"; wait_for 0.3 "filter"; key Return; wait_for 0.4 "Ellipse select"; }

one_case rect $(( CANVAS_CX - 50 )) rect_tool
one_case ellipse $(( CANVAS_CX + 30 )) ellipse_tool

key b; wait_for 0.2 "Brush"
screenshot "select-from-center"
assert_no_crash
assert_window_exists
