#!/bin/bash
# =============================================================================
# transform-overlay.sh — QA test: Transform overlay mode
# Tests: Enter transform mode, verify overlay appears, Escape to cancel
# Note: Transform is accessed via menu/command, not a toolbar hotkey
# =============================================================================

info "=== Transform Overlay Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw content to transform --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Top line"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Left line (L-shape)"
assert_no_crash

# -- Select all: Ctrl+A --
info "Selecting all (Ctrl+A)"
key ctrl+a
wait_for 0.8 "Selection made"
assert_no_crash

# -- Snap the full work area before transform (larger region captures handles) --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "xform-overlay-before"
BEFORE="$SNAP_RESULT"

# -- Enter transform mode via Command Palette --
# Ctrl+T = Text Tool with Custom Font (action 116), NOT Transform. Transform
# overlay (actions 325-329) has no hotkey — invoke via Edit menu or palette.
info "Entering transform mode via command palette"
key question
wait_for 0.4 "Palette opened"
type_text "transform scale"
wait_for 0.3 "Filter applied"
key Return
wait_for 1.0 "Transform overlay active"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "xform-overlay-active"
ACTIVE="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$ACTIVE" "Transform overlay handles should be visible"
screenshot "transform-overlay-active"

# -- Cancel transform: Escape --
info "Cancelling transform (Escape)"
key Escape
wait_for 0.5 "Transform cancelled"
assert_no_crash

# -- Deselect: Ctrl+D --
key ctrl+d
wait_for 0.3 "Deselected"

# -- Cleanup --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Transform Overlay Test PASSED ==="
