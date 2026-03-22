#!/bin/bash
# ============================================================================
# tool-polygon-select.sh — QA test for DRAW's Polygon drawing tool
# Tests: place 3 vertices, close polygon, verify shape, undo
# Harness: requires canvas_focus, click, key, drag, wait_for, snap_region,
#          park_mouse, assert_no_crash, assert_regions_differ,
#          assert_window_exists, info
# ============================================================================

info "=== tool-polygon-select.sh: Polygon Tool QA ==="

# -- Setup: focus canvas and switch to polygon tool ----------------------------
canvas_focus p
wait_for 0.3 "Polygon tool ready"

# -- Increase brush size for visibility ---------------------------------------
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"

# -- Hide pointer arrow -------------------------------------------------------
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas BEFORE polygon -----------------------------------------------
SNAP_X=$(( CANVAS_CX - 30 ))
SNAP_Y=$(( CANVAS_CY - 30 ))
park_mouse
BEFORE=$(snap_region $SNAP_X $SNAP_Y 160 120 "polygon-before")
assert_no_crash

# -- Click 3 vertices of a triangle around canvas center ----------------------
info "Placing triangle vertices"

# Vertex 1: top center
V1_X=$CANVAS_CX
V1_Y=$(( CANVAS_CY - 25 ))
click $V1_X $V1_Y
wait_for 0.2 "vertex 1 (top)"
assert_no_crash

# Vertex 2: bottom right
V2_X=$(( CANVAS_CX + 20 ))
V2_Y=$(( CANVAS_CY + 20 ))
click $V2_X $V2_Y
wait_for 0.2 "vertex 2 (bottom right)"
assert_no_crash

# Vertex 3: bottom left
V3_X=$(( CANVAS_CX - 20 ))
V3_Y=$(( CANVAS_CY + 20 ))
click $V3_X $V3_Y
wait_for 0.2 "vertex 3 (bottom left)"
assert_no_crash

# -- Close polygon by pressing Return -----------------------------------------
info "Closing polygon with Return"
key Return
wait_for 0.5 "polygon commit"
assert_no_crash

# -- Snap canvas AFTER polygon, assert shape was drawn ------------------------
park_mouse
AFTER_POLY=$(snap_region $SNAP_X $SNAP_Y 160 120 "polygon-after-draw")
assert_regions_differ "$BEFORE" "$AFTER_POLY" \
    "Polygon triangle should be visible on canvas after commit"

# -- Undo the polygon ---------------------------------------------------------
info "Undoing polygon with Ctrl+Z"
key ctrl+z
wait_for 0.5 "undo polygon"
assert_no_crash

# -- Snap canvas AFTER undo, assert canvas restored ---------------------------
park_mouse
AFTER_UNDO=$(snap_region $SNAP_X $SNAP_Y 160 120 "polygon-after-undo")
assert_regions_differ "$AFTER_POLY" "$AFTER_UNDO" \
    "Undo should change canvas from polygon state"

# -- Cleanup: restore brush tool ----------------------------------------------
key b
wait_for 0.3 "restore brush tool"

assert_window_exists
info "=== tool-polygon-select.sh: PASSED ==="
