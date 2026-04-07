#!/bin/bash
# =============================================================================
# tool-move.sh — QA test: Move Tool
# Tests: Activate (V), drag layer content, undo, nudge with arrow keys
# =============================================================================

info "=== Move Tool Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a dot near center to have moveable content --
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Dot placed"
assert_no_crash

# -- Snap canvas BEFORE move --
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 60 )) 120 120 "move-before"
BEFORE="$SNAP_RESULT"

# -- Switch to move tool (V) --
info "Activate move tool (V)"
key v
wait_for 0.3 "Move tool active"
assert_no_crash

# -- Drag content to new position --
info "Drag layer content"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 20 ))
wait_for 0.5 "Content moved"
assert_no_crash

# -- Snap canvas AFTER move --
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 60 )) 120 120 "move-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Move tool should change pixel positions"
screenshot "move-after-drag"

# -- Undo move --
info "Undo move (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Move undone"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 60 )) 120 120 "move-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should restore original position"

# -- Test nudge with arrow keys --
info "Test nudge (arrow keys)"
key Right
wait_for 0.2 "Nudge right"
key Right
wait_for 0.2 "Nudge right again"
key Down
wait_for 0.2 "Nudge down"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 60 )) 120 120 "move-nudge"
NUDGE="$SNAP_RESULT"
assert_regions_differ "$UNDO" "$NUDGE" "Arrow keys should nudge layer content"

# -- Undo nudges --
key ctrl+z
wait_for 0.2 "Undo nudge"
key ctrl+z
wait_for 0.2 "Undo nudge"
key ctrl+z
wait_for 0.2 "Undo nudge"

# -- Undo the original dot --
key ctrl+z
wait_for 0.3 "Undo dot"
assert_no_crash

# -- Switch back to brush --
key b
wait_for 0.2 "Brush restored"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Move Tool Test PASSED ==="
