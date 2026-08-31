#!/bin/bash
# =============================================================================
# effect-redo-silent.sh — BUG-O guard
#
# Ctrl+F (Redo Last Effect) must re-apply the last effect SILENTLY with its last
# settings — NO dialog. Ctrl+Alt+F is the one that reopens the dialog.
#   * Apply Crystallize (a K-wired effect) via its dialog.
#   * Snap the canvas.
#   * Press Ctrl+F -> effect re-applies (region changes) and NO dialog appears.
# Crystallize = PIXELATE cat 4 child 0.
# =============================================================================

info "=== BUG-O: Ctrl+F redo applies last effect silently ==="

canvas_focus b
wait_for 0.3 "Brush ready"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 21*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG colour"
for dy in -20 -10 0 10 20; do
    drag $(( CANVAS_CX - 55 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 55 )) $(( CANVAS_CY + dy ))
done
key grave ; wait_for 0.3 "Content drawn"

# Apply Add Noise once (via dialog). Add Noise is NON-idempotent — each apply adds
# more grain — so a successful silent re-apply is detectable by a region diff
# (Crystallize is idempotent: re-applying it leaves the pixels unchanged, so it
# can't be used to prove Ctrl+F re-applied). Add Noise = NOISE cat 5 child 0.
open_effect 5 0 ; wait_for 0.5 "Add Noise dialog"
key Return ; wait_for 0.7 "Applied"
assert_no_crash

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 18 )); GW=80; GH=36
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "O-before-redo"
BEFORE="$SNAP_RESULT"

# Ctrl+F — must re-apply silently (no dialog). Second Add Noise pass = more grain.
key ctrl+f ; wait_for 0.7 "Ctrl+F redo"
screenshot "O-after-ctrlf"          # inspect: canvas only, NO dialog visible
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "O-after-redo"
AFTER="$SNAP_RESULT"

assert_regions_differ "$BEFORE" "$AFTER" "Ctrl+F must re-apply the effect silently (BUG-O)"
assert_no_crash
assert_window_exists
info "=== BUG-O test complete ==="
