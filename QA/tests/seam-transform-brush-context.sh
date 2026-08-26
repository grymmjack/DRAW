#!/bin/bash
# =============================================================================
# seam-transform-brush-context.sh — Phase 2A.2b: transform keys route by context
#
# Home/End/PgUp/PgDn migrated to central dispatch with CTX_CUSTOM_BRUSH_ACTIVE:
#   - no custom brush  -> flip/scale the LAYER   (315/316/318/317)
#   - custom brush live -> flip/scale the BRUSH  (1105/1106/1107/1108)
#
# This validates the BRUSH branch: with a custom brush captured, pressing Home
# must flip the BRUSH and leave the LAYER pixels untouched. If the context bit
# were wrong, Home would flip the layer and the assert_regions_same would FAIL.
# =============================================================================

# -- Known state: brush, big size, pointer hidden --
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw an asymmetric L-shape --
info "Drawing asymmetric L-shape"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Top line"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Left line (L-shape)"
assert_no_crash

# -- Marquee-select the content and capture it as a custom brush (Ctrl+B) --
info "Marquee select + capture custom brush (Ctrl+B) -> CTX_CUSTOM_BRUSH_ACTIVE"
key m
wait_for 0.2 "Marquee tool"
drag $(( CANVAS_CX - 25 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 25 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Selection drawn"
key ctrl+b
wait_for 0.4 "Custom brush captured"
assert_no_crash
park_mouse

snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "brushctx-before"
BEFORE="$SNAP_RESULT"

# -- Home with a brush active: must flip the BRUSH, NOT the layer --
info "Home (brush active) -> flips brush, layer untouched"
key Home
wait_for 0.3 "Brush flipped H (layer unchanged)"
assert_no_crash
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "brushctx-afterHome"
AFTER="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER" "Home routed to the BRUSH (layer pixels unchanged) — CTX_CUSTOM_BRUSH_ACTIVE routing works"
