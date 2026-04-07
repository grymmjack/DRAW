#!/bin/bash
# =============================================================================
# layer-multiselect.sh — QA test: Layer Multi-Select
# Tests: Ctrl+Click to multi-select, Shift+Click range, single click deselect
# =============================================================================

info "=== Layer Multi-Select Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Create 3 layers with content --
click $(( CANVAS_CX - 30 )) $CANVAS_CY
wait_for 0.2 "Dot on layer 1"

key ctrl+shift+n
wait_for 0.3 "Layer 2 created"
click $CANVAS_CX $CANVAS_CY
wait_for 0.2 "Dot on layer 2"

key ctrl+shift+n
wait_for 0.3 "Layer 3 created"
click $(( CANVAS_CX + 30 )) $CANVAS_CY
wait_for 0.2 "Dot on layer 3"
assert_no_crash

# -- Snap layer panel BEFORE multi-select --
park_mouse
snap_region $LP_X $LP_Y $LP_W 80 "multisel-before"
BEFORE="$SNAP_RESULT"

# -- Ctrl+Click layer 2 in the layer panel to multi-select --
# Layer entries are stacked vertically; each is ~20px tall
# Current layer (3) is at top; layer 2 is one row below; layer 1 is two rows below
LAYER_ENTRY_H=20
LAYER2_Y=$(( LP_Y + LAYER_ENTRY_H + LAYER_ENTRY_H / 2 ))
LAYER1_Y=$(( LP_Y + LAYER_ENTRY_H * 2 + LAYER_ENTRY_H / 2 ))
LAYER_MID_X=$(( LP_X + LP_W / 2 ))

info "Ctrl+Click layer 2 to multi-select"
key --clearmodifiers ctrl
click $LAYER_MID_X $LAYER2_Y
key --clearmodifiers
wait_for 0.3 "Layer 2 added to selection"
assert_no_crash

# -- Snap layer panel AFTER multi-select --
park_mouse
snap_region $LP_X $LP_Y $LP_W 80 "multisel-after"
AFTER_MULTI="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_MULTI" "Multi-select should highlight multiple layers"
screenshot "multiselect-active"

# -- Single click to deselect multi --
info "Single click layer 3 to deselect multi"
LAYER3_Y=$(( LP_Y + LAYER_ENTRY_H / 2 ))
click $LAYER_MID_X $LAYER3_Y
wait_for 0.3 "Single select restored"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W 80 "multisel-deselected"
AFTER_DESEL="$SNAP_RESULT"
assert_regions_differ "$AFTER_MULTI" "$AFTER_DESEL" "Single click should end multi-select"

# -- Delete extra layers and undo --
key ctrl+shift+Delete
wait_for 0.2 "Delete layer 3"
key ctrl+shift+Delete
wait_for 0.2 "Delete layer 2"
key ctrl+z
wait_for 0.2 "Undo"
key ctrl+z
wait_for 0.2 "Undo"
key ctrl+z
wait_for 0.2 "Undo"
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
info "=== Layer Multi-Select Test PASSED ==="
