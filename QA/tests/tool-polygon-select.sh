#!/bin/bash
# ============================================================================
# tool-polygon-select.sh — QA test for DRAW's Polygon drawing tool
# Tests: place 3 vertices, close polygon, verify shape, undo
# Harness: requires click, key, wait_for, snap_region,
#          assert_no_crash, assert_regions_differ, assert_regions_same,
#          assert_window_exists, info
# ============================================================================

info "=== tool-polygon-select.sh: Polygon Tool QA ==="

# -- Known state: switch to brush tool, click canvas for focus ----------------
key b
wait_for 0.3 "switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "focus canvas"

# -- Switch to polygon tool ---------------------------------------------------
key p
wait_for 0.3 "switch to polygon tool"
assert_no_crash

# -- Snap canvas BEFORE polygon -----------------------------------------------
SNAP_X=$(( CANVAS_CX - 30 ))
SNAP_Y=$(( CANVAS_CY - 30 ))
BEFORE=$(snap_region $SNAP_X $SNAP_Y 60 60 "polygon-before")

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
AFTER_POLY=$(snap_region $SNAP_X $SNAP_Y 60 60 "polygon-after-draw")
assert_regions_differ "$BEFORE" "$AFTER_POLY" \
    "Polygon triangle should be visible on canvas after commit"

# -- Undo the polygon ---------------------------------------------------------
info "Undoing polygon with Ctrl+Z"
key ctrl+z
wait_for 0.5 "undo polygon"
assert_no_crash

# -- Snap canvas AFTER undo, assert canvas restored ---------------------------
AFTER_UNDO=$(snap_region $SNAP_X $SNAP_Y 60 60 "polygon-after-undo")
assert_regions_same "$BEFORE" "$AFTER_UNDO" \
    "Canvas should be restored to original state after undo"

# -- Cleanup: restore brush tool ----------------------------------------------
key b
wait_for 0.3 "restore brush tool"

assert_window_exists
info "=== tool-polygon-select.sh: PASSED ==="
