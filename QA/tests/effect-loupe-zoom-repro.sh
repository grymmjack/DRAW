#!/bin/bash
# =============================================================================
# effect-loupe-zoom-repro.sh — REPRO harness for BUG-M / BUG-N
#
# Draw a recognizable shape, then open Crystallize at 100% and again at 300%
# zoom, screenshotting each dialog. If the loupe preview shows a DIFFERENT
# canvas patch (offset) at 300% vs 100%, BUG-M is reproduced. Add Noise mono is
# screenshot the same way for BUG-N (2x-tall grain in preview vs apply).
# Not an assertion test — it captures evidence screenshots for inspection.
# =============================================================================

info "=== REPRO: loupe preview at zoom (BUG-M / BUG-N) ==="

canvas_focus b
wait_for 0.3 "Brush ready"
# Draw a bold shape at canvas centre so the loupe has content to frame.
for n in 1 2 3 4 5 6 7 8; do key bracketright; done
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 21*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG colour"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"
drag $(( CANVAS_CX )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX )) $(( CANVAS_CY + 30 ))
key grave ; wait_for 0.3 "Content drawn"
assert_no_crash

# --- Crystallize at 100% (baseline) ---
open_effect 4 0 ; wait_for 0.5 "Crystallize dialog @100%"
screenshot "M-crystallize-100"
key Escape ; wait_for 0.4 "closed"

# --- zoom to 300% (Z+3) then Crystallize ---
key z+3 ; wait_for 0.4 "zoom 300%"
open_effect 4 0 ; wait_for 0.5 "Crystallize dialog @300%"
screenshot "M-crystallize-300"
key Escape ; wait_for 0.4 "closed"

# --- Add Noise mono at 300% then 100% for BUG-N ---
open_effect 5 0 ; wait_for 0.5 "Add Noise dialog @300%"
screenshot "N-addnoise-mono-300"
key Escape ; wait_for 0.3 "closed"
key z+1 ; wait_for 0.4 "zoom 100%"
open_effect 5 0 ; wait_for 0.5 "Add Noise dialog @100%"
screenshot "N-addnoise-mono-100"
key Escape ; wait_for 0.3 "closed"

assert_no_crash
assert_window_exists
info "=== REPRO complete — inspect M-*/N-* screenshots ==="
