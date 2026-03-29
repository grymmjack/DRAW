#!/bin/bash
# =============================================================================
# util-grid-modes.sh — QA test: Grid mode cycling and canvas border
# Tests: Ctrl+' (cycle grid geometry), # (canvas border toggle)
# =============================================================================

info "=== Grid Modes Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"

# -- Increase grid size for visibility (period key = increase grid size) --
info "Increasing grid size for visibility"
key period
key period
key period
key period
key period
wait_for 0.3 "Grid size increased"

# -- Turn grid ON with apostrophe key (_KEYDOWN(39)) --
info "Turning grid ON (apostrophe)"
key apostrophe
wait_for 0.5 "Grid toggled"

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-mode-square"
SQUARE="$SNAP_RESULT"
assert_no_crash

# -- Cycle to Diagonal grid: Ctrl+' --
info "Cycling grid mode (Ctrl+apostrophe)"
key ctrl+apostrophe
wait_for 0.5 "Grid mode cycled"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-mode-diagonal"
DIAGONAL="$SNAP_RESULT"
assert_regions_differ "$SQUARE" "$DIAGONAL" "Grid mode change should alter grid appearance"

# -- Cycle back to original (Diagonal→Isometric→Hex→Square) --
key ctrl+apostrophe
wait_for 0.2 "Isometric"
key ctrl+apostrophe
wait_for 0.2 "Hex"
key ctrl+apostrophe
wait_for 0.2 "Square again"
assert_no_crash

# -- Toggle grid OFF --
key apostrophe
wait_for 0.3 "Grid off"

# -- Test canvas border toggle --
# -- Test canvas border toggle via command palette (# hotkey unreliable on XWayland) --
# At 3x zoom the canvas overflows the work area, making the border invisible.
# Zoom to 1x first so the border is drawn within the visible work area.
info "Zooming to 1x for border visibility"
wake_draw
key ctrl+0
wait_for 0.5 "Zoom reset to 1x"

info "Toggling canvas border"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "border-before"
BORDER_BEFORE="$SNAP_RESULT"

# Send "#" via keysym name to avoid XWayland shift+3 translation issues
wake_draw
key numbersign
wait_for 1.0 "Canvas border toggled"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "border-after"
BORDER_AFTER="$SNAP_RESULT"
# Border color (51,51,51) vs apron (48,48,48) = 1.2% difference,
# which is below the default 2% fuzz in assert_regions_differ.
# Use direct 0% fuzz comparison for this subtle visual change.
local border_diff
border_diff=$(compare -metric AE -fuzz 0% "$BORDER_BEFORE" "$BORDER_AFTER" /dev/null 2>&1 || true)
border_diff=$(echo "$border_diff" | grep -oE '^[0-9]+' | head -1)
info "  [diff] border 0%-fuzz count=${border_diff:-0} f1=$(basename $BORDER_BEFORE) f2=$(basename $BORDER_AFTER)"
if [[ "${border_diff:-0}" -gt 0 ]] 2>/dev/null; then
    pass "Canvas border toggle should change appearance (${border_diff} pixels differ at 0% fuzz)"
else
    fail "Canvas border toggle should change appearance — regions are identical at 0% fuzz"
fi

# -- Toggle border back --
wake_draw
key numbersign
wait_for 0.5 "Canvas border restored"

# -- Restore zoom to default --
wake_draw
key ctrl+equal
wait_for 0.2
key ctrl+equal
wait_for 0.3 "Zoom restored to 3x"
assert_no_crash

assert_window_exists
info "=== Grid Modes Test PASSED ==="
