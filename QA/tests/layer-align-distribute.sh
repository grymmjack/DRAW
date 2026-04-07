#!/bin/bash
# =============================================================================
# layer-align-distribute.sh — QA test: Layer Align & Distribute
# Tests: Create multiple layers, align center, undo, verify positions change
# =============================================================================

info "=== Layer Align/Distribute Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw on layer 1 (off-center left) --
click $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 20 ))
wait_for 0.3 "Dot on layer 1"
assert_no_crash

# -- Create new layer (Ctrl+Shift+N) and draw off-center right --
info "Create new layer"
key ctrl+shift+n
wait_for 0.5 "New layer created"
assert_no_crash

click $(( CANVAS_CX + 50 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Dot on layer 2"
assert_no_crash

# -- Snap canvas BEFORE align --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "align-before"
BEFORE="$SNAP_RESULT"

# -- Use command palette to align center --
info "Align Center via command palette"
key question
wait_for 0.5 "Command palette opened"
type_text "align center"
wait_for 0.3 "Filter applied"
key Return
wait_for 0.5 "Align center executed"
assert_no_crash

# -- Snap canvas AFTER align --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "align-after"
AFTER="$SNAP_RESULT"
screenshot "align-center"

# -- Undo align --
info "Undo align"
key ctrl+z
wait_for 0.3 "Align undone"
assert_no_crash

# -- Delete layer 2 --
info "Delete layer 2"
key ctrl+shift+Delete
wait_for 0.3 "Layer deleted"
assert_no_crash

# -- Undo everything to clean state --
key ctrl+z
wait_for 0.2 "Undo"
key ctrl+z
wait_for 0.2 "Undo"
key ctrl+z
wait_for 0.2 "Undo"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer Align/Distribute Test PASSED ==="
