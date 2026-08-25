#!/bin/bash
# =============================================================================
# seam-paste-then-switch.sh — SEAM TEST: paste float → tool switch
# Paste engages the MOVE tool as a floating (clone-mode) selection. Switching to
# another tool must COMMIT the float onto the layer cleanly — leaving real,
# erasable pixels, not a stuck floating overlay. This guards the paste→switch
# seam and confirms committed paste content is on a real layer (erasable).
# =============================================================================

info "=== SEAM: paste float → tool switch commits cleanly ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw content and copy it --
info "Draw content, select all, copy"
drag $(( CANVAS_CX - 22 )) $CANVAS_CY $(( CANVAS_CX + 22 )) $CANVAS_CY
wait_for 0.3 "Stroke"
key ctrl+a
wait_for 0.4 "Select all"
key ctrl+c
wait_for 0.3 "Copy"
assert_no_crash

# -- Paste (creates a floating clone via the MOVE tool) --
info "Paste (Ctrl+V) — floating clone via MOVE"
key ctrl+v
wait_for 0.5 "Pasted float"
assert_no_crash

# -- THE SEAM: switch to the brush; the float must commit (not stick) --
info "Switch to brush (B) — float must commit onto the layer"
key b
wait_for 0.5 "Tool switched; float committed"
assert_no_crash

# -- Deselect, snap the content region --
key ctrl+d
wait_for 0.3 "Deselect"
park_mouse
snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 14 )) 60 28 "seam-paste-committed"
COMMITTED="$SNAP_RESULT"

# -- Prove the committed paste is on a REAL layer: erase it away --
info "Erase over the committed paste — must be reachable (on layer)"
key e
wait_for 0.3 "Eraser"
drag $(( CANVAS_CX - 22 )) $CANVAS_CY $(( CANVAS_CX + 22 )) $CANVAS_CY
wait_for 0.3 "Erase"
drag $(( CANVAS_CX - 22 )) $(( CANVAS_CY - 6 )) $(( CANVAS_CX + 22 )) $(( CANVAS_CY - 6 ))
wait_for 0.3 "Erase 2"
park_mouse
snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 14 )) 60 28 "seam-paste-erased"
ERASED="$SNAP_RESULT"
assert_regions_differ "$COMMITTED" "$ERASED" "Committed paste must be erasable (on a real layer, not a stuck float)"
screenshot "seam-paste-erased"

# -- Cleanup --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo"
assert_no_crash
assert_window_exists
info "=== SEAM paste-then-switch test COMPLETE ==="
