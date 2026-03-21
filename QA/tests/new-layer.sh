#!/bin/bash
# QA/tests/new-layer.sh — Test adding and undoing a new layer
#
# Layer panel: LEFT dock, x=0..100 viewport px, y=12..80

LAYER_PANEL_X=0
LAYER_PANEL_Y=12
LAYER_PANEL_W=100
LAYER_PANEL_H=68

key b
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "settle"

# ── Add a new layer ───────────────────────────────────────────────────────────
before_add=$(snap_region $LAYER_PANEL_X $LAYER_PANEL_Y $LAYER_PANEL_W $LAYER_PANEL_H "before-add")

info "Adding new layer (Ctrl+Shift+N)"
key ctrl+shift+n
wait_for 0.8 "layer add settle"
assert_no_crash

after_add=$(snap_region $LAYER_PANEL_X $LAYER_PANEL_Y $LAYER_PANEL_W $LAYER_PANEL_H "after-add")
screenshot "new-layer-added"
assert_regions_differ "$before_add" "$after_add" "layer panel changed after Ctrl+Shift+N"

# ── Undo the new layer ────────────────────────────────────────────────────────
before_undo=$(snap_region $LAYER_PANEL_X $LAYER_PANEL_Y $LAYER_PANEL_W $LAYER_PANEL_H "before-undo")

info "Undoing layer add (Ctrl+Z)"
key ctrl+z
wait_for 1.0 "undo layer settle"
assert_no_crash

after_undo=$(snap_region $LAYER_PANEL_X $LAYER_PANEL_Y $LAYER_PANEL_W $LAYER_PANEL_H "after-undo")
screenshot "new-layer-undone"
assert_regions_differ "$before_undo" "$after_undo" "layer panel changed after Ctrl+Z"

assert_window_exists
