#!/bin/bash
# =============================================================================
# edit-stroke-selection.sh — QA test: Stroke selection outline
# Tests: Select All → stroke selection draws outline on canvas
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

# -- Select All via Ctrl+A (more reliable than drag-based marquee via XTEST) --
info "Selecting entire canvas with Ctrl+A"
key Escape
wait_for 0.2 "Clear any active state"
wake_draw
key ctrl+a
wait_for 0.5 "Select All applied"
assert_no_crash

# -- Snap before stroke selection --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "stroke-sel-before"
BEFORE="$SNAP_RESULT"

# -- Apply stroke selection via Command Palette --
info "Opening Command Palette and invoking Stroke Selection"
key shift+slash
wait_for 0.5 "Command palette opened"
type_text "Stroke Selection"
wait_for 0.5 "Typed stroke"
key Return
wait_for 1.0 "Stroke dialog opened"
# The stroke selection shows a modal dialog — press Enter to confirm defaults
key Return
wait_for 1.0 "Stroke selection applied"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "stroke-sel-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Stroke selection should draw outline on canvas"
screenshot "after-stroke-selection"

# -- Undo stroke and deselect --
info "Undoing stroke selection (Ctrl+Z)"
wake_draw
key ctrl+z
wait_for 0.5 "Stroke undone"
key Escape
wait_for 0.2 "Deselect"
assert_no_crash

# -- Cleanup undo history --
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
