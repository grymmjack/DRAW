#!/bin/bash
# ============================================================================
# tool-wand.sh — QA test for DRAW's Magic Wand selection tool
# Tests: fill a region, wand-select it, verify selection, undo
# Harness: requires click, key, wait_for, snap_region,
#          assert_no_crash, assert_regions_differ, assert_window_exists, info
# ============================================================================

info "=== tool-wand.sh: Magic Wand Selection Tool QA ==="

# -- Known state: switch to brush tool, click canvas for focus ----------------
key b
wait_for 0.3 "switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "focus canvas"

# -- Draw a filled region to give the wand something to select ----------------
info "Filling canvas center with FG color"
key f
wait_for 0.3 "switch to fill tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "flood fill canvas center"
assert_no_crash

# -- Switch to magic wand tool ------------------------------------------------
key w
wait_for 0.3 "switch to magic wand tool"
assert_no_crash

# -- Snap canvas BEFORE wand selection ----------------------------------------
SNAP_X=$(( CANVAS_CX - 30 ))
SNAP_Y=$(( CANVAS_CY - 30 ))
BEFORE=$(snap_region $SNAP_X $SNAP_Y 60 60 "wand-before")

# -- Click on the filled area to wand-select ----------------------------------
info "Clicking filled area with magic wand"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "wand selection + marching ants"
assert_no_crash

# -- Snap canvas AFTER wand selection, assert selection visible ---------------
AFTER_WAND=$(snap_region $SNAP_X $SNAP_Y 60 60 "wand-after-select")
assert_regions_differ "$BEFORE" "$AFTER_WAND" \
    "Magic wand selection should produce visible marching ants"

# -- Cleanup: deselect, undo fill, restore brush tool -------------------------
info "Cleaning up: deselect and undo fill"
key Escape
wait_for 0.3 "deselect wand selection"
assert_no_crash

key ctrl+z
wait_for 0.3 "undo flood fill"
assert_no_crash

key b
wait_for 0.3 "restore brush tool"

assert_window_exists
info "=== tool-wand.sh: PASSED ==="
