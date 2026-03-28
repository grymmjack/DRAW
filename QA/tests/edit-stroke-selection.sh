#!/bin/bash
# =============================================================================
# edit-stroke-selection.sh — QA test: Stroke selection outline
# Tests: Marquee select → stroke selection draws outline on canvas
# =============================================================================

info "=== Stroke Selection Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a filled area to have clear selection context --
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 15 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 10 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 5 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 5 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $CANVAS_CY $(( CANVAS_CX + 15 )) $CANVAS_CY
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 5 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 5 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 10 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 15 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Filled area drawn"
assert_no_crash

# -- Select a region with marquee --
info "Selecting region with marquee"
key m
wait_for 0.3 "Marquee tool active"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 0.5 "Selection made"
assert_no_crash

# -- Snap before stroke selection --
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 40 )) 80 80 "stroke-sel-before"
BEFORE="$SNAP_RESULT"

# -- Apply stroke selection via Edit menu --
info "Applying Stroke Selection via Edit menu"
key alt+e
wait_for 0.5 "Edit menu opened"
# Navigate to Stroke Selection
key s
wait_for 0.2
key Return
wait_for 0.8 "Stroke selection applied"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 40 )) 80 80 "stroke-sel-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Stroke selection should draw outline on canvas"
screenshot "after-stroke-selection"

# -- Undo --
info "Undoing stroke selection (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Stroke undone"
assert_no_crash

# -- Deselect and cleanup --
key Escape
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Stroke Selection Test PASSED ==="
