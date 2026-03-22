#!/bin/bash
# ============================================================================
# tool-marquee.sh — QA test for DRAW's Marquee (rectangular selection) tool
# Tests: marquee drag, Select All, Deselect, Invert Selection
# Harness: requires click, drag, key, wait_for, snap_region,
#          assert_no_crash, assert_regions_differ, assert_window_exists, info
# ============================================================================

info "=== tool-marquee.sh: Marquee Selection Tool QA ==="

# -- Setup: focus canvas, draw visible content first --------------------------
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# Draw a visible stroke so marching ants appear over content
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 30 ))
wait_for 0.3 "Drew visible stroke"
assert_no_crash

# -- Switch to marquee tool ---------------------------------------------------
key m
wait_for 0.3 "switch to marquee tool"
assert_no_crash

# -- Snap canvas BEFORE selection ---------------------------------------------
SNAP_X=$(( CANVAS_CX - 80 ))
SNAP_Y=$(( CANVAS_CY - 60 ))
park_mouse
BEFORE=$(snap_region $SNAP_X $SNAP_Y 160 120 "marquee-before")

# -- Drag a rectangular selection on canvas -----------------------------------
DRAG_X1=$(( CANVAS_CX - 25 ))
DRAG_Y1=$(( CANVAS_CY - 20 ))
DRAG_X2=$(( CANVAS_CX + 25 ))
DRAG_Y2=$(( CANVAS_CY + 20 ))
drag $DRAG_X1 $DRAG_Y1 $DRAG_X2 $DRAG_Y2
wait_for 0.5 "marching ants should appear"
assert_no_crash

# -- Snap canvas AFTER selection, assert marching ants visible ----------------
park_mouse
AFTER_DRAG=$(snap_region $SNAP_X $SNAP_Y 160 120 "marquee-after-drag")
assert_regions_differ "$BEFORE" "$AFTER_DRAG" \
    "Marching ants should be visible after marquee drag"

# -- Test Select All (Ctrl+A) ------------------------------------------------
info "Testing Select All (Ctrl+A)"
key ctrl+a
wait_for 0.5 "select all"
assert_no_crash
park_mouse
AFTER_SELECTALL=$(snap_region $SNAP_X $SNAP_Y 160 120 "marquee-after-selectall")
assert_regions_differ "$AFTER_DRAG" "$AFTER_SELECTALL" \
    "Select All should change selection from partial to full canvas"

# -- Test Deselect (Ctrl+D) ---------------------------------------------------
info "Testing Deselect (Ctrl+D)"
key ctrl+d
wait_for 0.5 "deselect"
assert_no_crash
park_mouse
AFTER_DESELECT=$(snap_region $SNAP_X $SNAP_Y 160 120 "marquee-after-deselect")
assert_regions_differ "$AFTER_SELECTALL" "$AFTER_DESELECT" \
    "Deselect should remove selection (no marching ants)"

# -- Test Invert Selection: select all first, then invert ---------------------
info "Testing Invert Selection (Ctrl+Shift+I)"
key ctrl+a
wait_for 0.3 "select all before invert"
park_mouse
BEFORE_INVERT=$(snap_region $SNAP_X $SNAP_Y 160 120 "marquee-before-invert")
key ctrl+shift+i
wait_for 0.5 "invert selection"
assert_no_crash
park_mouse
AFTER_INVERT=$(snap_region $SNAP_X $SNAP_Y 160 120 "marquee-after-invert")
info "Invert selection completed without crash"

# -- Cleanup: deselect and restore brush tool ---------------------------------
key ctrl+d
wait_for 0.3 "final deselect"
key b
wait_for 0.3 "restore brush tool"

assert_window_exists
info "=== tool-marquee.sh: PASSED ==="
