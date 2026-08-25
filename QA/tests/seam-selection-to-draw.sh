#!/bin/bash
# =============================================================================
# seam-selection-to-draw.sh — SEAM TEST: selection → drawing tool (clip)
# A marquee selection must be preserved as a CLIP when switching to a drawing
# tool (TOOLS_reset_all preserves the marquee). Painting a stroke that crosses
# the selection boundary must land INSIDE the selection only; the OUTSIDE must
# stay clean. Then deselecting must release the clip.
# =============================================================================

info "=== SEAM: selection → draw (paint clipped to marquee) ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# Region probes: INSIDE (left of centre) and OUTSIDE (right of centre)
IN_X=$(( CANVAS_CX - 28 ))
OUT_X=$(( CANVAS_CX + 28 ))

# -- Empty baselines --
park_mouse
snap_region $(( IN_X - 12 )) $(( CANVAS_CY - 12 )) 24 24 "seam-sel-in-empty";  IN_EMPTY="$SNAP_RESULT"
snap_region $(( OUT_X - 12 )) $(( CANVAS_CY - 12 )) 24 24 "seam-sel-out-empty"; OUT_EMPTY="$SNAP_RESULT"

# -- Make a rectangular marquee selection covering the LEFT half only --
info "Creating left-half rectangular selection"
key m
wait_for 0.2 "Marquee tool"
drag $(( CANVAS_CX - 48 )) $(( CANVAS_CY - 22 )) $(( CANVAS_CX - 2 )) $(( CANVAS_CY + 22 ))
wait_for 0.4 "Selection drawn"
assert_no_crash

# -- Switch to the brush (selection preserved as clip) and draw a crossing stroke --
info "Switch to brush; draw stroke crossing the selection boundary"
key b
wait_for 0.3 "Brush (selection kept as clip)"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.4 "Crossing stroke drawn"
assert_no_crash

# -- INSIDE must be painted; OUTSIDE must be clipped (unchanged) --
park_mouse
snap_region $(( IN_X - 12 )) $(( CANVAS_CY - 12 )) 24 24 "seam-sel-in-drawn";  IN_DRAWN="$SNAP_RESULT"
snap_region $(( OUT_X - 12 )) $(( CANVAS_CY - 12 )) 24 24 "seam-sel-out-drawn"; OUT_DRAWN="$SNAP_RESULT"
assert_regions_differ "$IN_EMPTY" "$IN_DRAWN" "Paint INSIDE the selection must appear"
assert_regions_same "$OUT_EMPTY" "$OUT_DRAWN" "Paint OUTSIDE the selection must be clipped away"
screenshot "seam-sel-clip"

# -- Deselect releases the clip: a stroke outside now lands --
info "Deselect (Ctrl+D); paint outside must now land"
key ctrl+d
wait_for 0.3 "Deselected"
drag $(( CANVAS_CX + 12 )) $CANVAS_CY $(( CANVAS_CX + 44 )) $CANVAS_CY
wait_for 0.4 "Stroke outside old selection"
park_mouse
snap_region $(( OUT_X - 12 )) $(( CANVAS_CY - 12 )) 24 24 "seam-sel-out-after-deselect"; OUT_AFTER="$SNAP_RESULT"
assert_regions_differ "$OUT_EMPTY" "$OUT_AFTER" "After deselect, paint outside the old selection must land (clip released)"

assert_no_crash
assert_window_exists
info "=== SEAM selection-to-draw test COMPLETE ==="
