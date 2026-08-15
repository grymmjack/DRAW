#!/bin/bash
# =============================================================================
# effect-redo-last.sh — QA test / regression guard
#
# REDO LAST EFFECT (Ctrl+F) — re-applies the last effect instantly with the same
# settings, no dialog (Photoshop's repeat-filter). Added 2026-08-15.
#
# Applies Drop Shadow once via the menu, then hits Ctrl+F to replay it on the now
# shadowed layer — a second cast — and asserts the sampled region changes again.
# Also exercises Ctrl+Shift+F (Blend Last Effect) opening + OK without crashing.
#   Drop Shadow = open_effect 2 0
# =============================================================================

info "=== Effect: Redo Last Effect (Ctrl+F) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Green stroke; BG red (shadow colour) via FG=red + swap.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 60 )) "$CANVAS_CY" $(( CANVAS_CX + 60 )) "$CANVAS_CY"
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG red"
key x ; wait_for 0.2 "Swap -> BG red (shadow colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Apply Drop Shadow once.
open_effect 2 0 ; wait_for 0.5 "Drop Shadow dialog open"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

# Sample below-right of the stroke where a further shadow cast will fall.
GX=$(( CANVAS_CX - 20 )); GY=$(( CANVAS_CY + 8 )); GW=90; GH=26
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "redo-before"
BEFORE="$SNAP_RESULT"

# Redo the effect instantly (no dialog).
key ctrl+f ; wait_for 0.6 "Redo Last Effect (Ctrl+F)"
assert_no_crash
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "redo-after"
assert_regions_differ "$BEFORE" "$SNAP_RESULT" \
    "Ctrl+F (Redo Last Effect) must re-apply Drop Shadow — a second cast changes the region"

# Blend Last Effect dialog opens + closes cleanly.
key ctrl+shift+f ; wait_for 0.5 "Blend Last Effect dialog"
screenshot "blend-dialog"
key Return ; wait_for 0.5 "Blend closed (OK)"
assert_no_crash
assert_window_exists
info "=== Effect: Redo Last Effect Test PASSED ==="
