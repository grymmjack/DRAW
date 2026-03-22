#!/bin/bash
# ============================================================================
# tool-wand.sh — QA test for DRAW's Magic Wand selection tool
# Tests: fill a region, wand-select it, verify selection, undo
# Harness: requires click, key, wait_for, snap_region,
#          assert_no_crash, assert_regions_differ, assert_window_exists, info
# ============================================================================

info "=== tool-wand.sh: Magic Wand Selection Tool QA ==="

# -- Setup: focus canvas, draw content so wand has something to select --------
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# Draw a visible stroke to create distinct colored pixels for wand
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 30 ))
wait_for 0.3 "Drew visible stroke"
assert_no_crash

# -- Switch to magic wand tool ------------------------------------------------
key w
wait_for 0.3 "switch to magic wand tool"
assert_no_crash

# -- Snap canvas BEFORE wand selection ----------------------------------------
SNAP_X=$(( CANVAS_CX - 80 ))
SNAP_Y=$(( CANVAS_CY - 60 ))
park_mouse
snap_region $SNAP_X $SNAP_Y 160 120 "wand-before"
BEFORE="$SNAP_RESULT"

# -- Click on the drawn area to wand-select ----------------------------------
info "Clicking drawn area with magic wand"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "wand selection + marching ants"
assert_no_crash

# -- Snap canvas AFTER wand selection, assert selection visible ---------------
park_mouse
snap_region $SNAP_X $SNAP_Y 160 120 "wand-after-select"
AFTER_WAND="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_WAND" \
    "Magic wand selection should produce visible marching ants"

# -- Cleanup: deselect, undo stroke, restore brush tool -----------------------
info "Cleaning up: deselect and undo"
key ctrl+d
wait_for 0.3 "deselect wand selection"
assert_no_crash

key ctrl+z
wait_for 0.3 "undo stroke"
assert_no_crash

key b
wait_for 0.3 "restore brush tool"

assert_window_exists
info "=== tool-wand.sh: PASSED ==="
