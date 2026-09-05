#!/bin/bash
# =============================================================================
# seam-flip-central.sh — Phase 2A.1: Flip H / Flip V via CENTRAL DISPATCH
#
# Validates the dispatched=TRUE migration of:
#   - Flip Horizontal  (key `h`, action 315) — was legacy KEYBOARD_tools
#   - Flip Vertical     (Ctrl+Shift+H, action 316) — was a DEAD documented binding
#
# Doubles as a DOUBLE-FIRE guard: if the central dispatcher AND the legacy
# KEYBOARD_tools both fired 'h', the layer would flip twice (back to original)
# and the "differ" assert below would FAIL. A single clean flip proves the
# skip-list (INPUT_LETTER_DISPATCHED) correctly suppresses the legacy path.
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

# -- Draw an asymmetric L-shape so a flip is visible --
info "Drawing asymmetric L-shape"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Top line"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Left line (L-shape)"
assert_no_crash
park_mouse

snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "flip-before"
BEFORE="$SNAP_RESULT"

# -- Flip Horizontal via 'h' (now central-dispatched) --
info "Flip H via central dispatch (key h)"
key h
wait_for 0.3 "Flipped H"
assert_no_crash
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "flip-afterH"
AFTER_H="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_H" "H flip changed the canvas (central fired once, no double-fire)"

# -- Flip H again → clean round-trip back to original --
info "Flip H again (round-trip)"
key h
wait_for 0.3 "Flipped H back"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "flip-backH"
BACK_H="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$BACK_H" "Second H flip restored the original (clean round-trip)"

# -- Flip Vertical via Ctrl+Shift+H (previously dead; now works) --
info "Flip V via Ctrl+Shift+H (central dispatch)"
key ctrl+shift+h
wait_for 0.3 "Flipped V"
assert_no_crash
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "flip-afterV"
AFTER_V="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_V" "Ctrl+Shift+H flipped V (previously-dead binding now works)"

pass "Flip H + Flip V dispatch centrally (no double-fire; Ctrl+Shift+H revived)"
