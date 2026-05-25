#!/bin/bash
# =============================================================================
# hold-key-modifiers.sh — QA test: Hold-key tool modifiers
# Tests:
#   - Hold E while painting: temporary eraser
#   - Hold F in wand-mode: tool switch suppressed (F is the wand-mode flood key)
# These are KEYBOARD_handle_eraser_hold / KEYBOARD_tools internal context-aware
# behaviors that Phase 6 deliberately left inline (the action-ID model doesn't
# fit "hold to temp-switch" patterns).
# =============================================================================

info "=== Hold-Key Modifiers Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a stroke to have something to erase --
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.4 "Brush stroke drawn"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "hold-e-before"
BEFORE_HOLD_E="$SNAP_RESULT"

# -- Hold E + drag to temp-erase. Then release E and verify tool returns to brush. --
info "Hold E + drag (temporary eraser)"
draw_focus
local hax hay hbx hby
read -r hax hay <<< "$(_abs $(( CANVAS_CX - 20 )) "$CANVAS_CY")"
read -r hbx hby <<< "$(_abs $(( CANVAS_CX + 20 )) "$CANVAS_CY")"
xdotool keydown e
sleep 0.25   # let KEYBOARD_handle_eraser_hold register the held-E state
xdotool mousemove "$hax" "$hay"
sleep 0.1
xdotool mousedown 1
sleep 0.1
xdotool mousemove "$hbx" "$hby"
sleep 0.2
xdotool mouseup 1
sleep 0.15
xdotool keyup e
sleep 0.3   # let tool revert from eraser back to brush

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "hold-e-after"
AFTER_HOLD_E="$SNAP_RESULT"
assert_regions_differ "$BEFORE_HOLD_E" "$AFTER_HOLD_E" "Hold E + drag should temp-erase"
assert_no_crash

# Cleanup undo
key ctrl+z
wait_for 0.3 "Undo erase"
key ctrl+z
wait_for 0.3 "Undo stroke"

# -- Wand-mode F suppression: switch to wand (W), press F, verify tool DOESN'T
# -- become Fill (F suppression is in KEYBOARD_tools "f" inline check when
# -- MARQUEE.MAGIC_WAND_MODE is TRUE).
info "Wand mode F suppression"
key w
wait_for 0.3 "Wand tool"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "wand-status"
WAND_STATUS="$SNAP_RESULT"

# Press F (would normally switch to Fill, but is suppressed in wand mode)
key f
wait_for 0.3 "F pressed (should be suppressed)"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "wand-after-f"
WAND_AFTER_F="$SNAP_RESULT"
assert_regions_same "$WAND_STATUS" "$WAND_AFTER_F" "F should not switch tool while wand is active"
assert_no_crash

# Cleanup
key b
wait_for 0.2 "Brush"

assert_window_exists
info "=== Hold-Key Modifiers Test PASSED ==="
