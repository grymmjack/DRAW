#!/bin/bash
# =============================================================================
# effect-isolate-repro.sh — REPRO for BUG-J
#
# Apply an effect, open Blend Last Effect (Ctrl+Shift+F), click ISOLATE ONTO NEW
# LAYER, and check that the new layer actually received the composited result
# (BUG-J: it comes out empty). ISOLATE button centre computed at viewport
# (479,262) for the 958x514 QA screen (dialog 256x224 centred; button at
# buffer (8,106)+ (240,22)).
# =============================================================================

info "=== REPRO: Isolate onto new layer from Blend Last (BUG-J) ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10; do key bracketright; done
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
for dy in -30 -20 -10 0 10 20 30; do
    drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + dy ))
done
key grave ; wait_for 0.3 "Block drawn"
assert_no_crash

# How many layers now? (record count region for later comparison — use a screenshot)
screenshot "J-before-effect"

# Apply Add Noise (a clearly-visible effect) via its dialog.
open_effect 5 0 ; wait_for 0.5 "Add Noise dialog"
key Return ; wait_for 0.7 "Add Noise applied"
assert_no_crash

# Open Blend Last Effect (Ctrl+Shift+F) and screenshot to locate ISOLATE.
key ctrl+shift+f ; wait_for 0.6 "Blend Last dialog open"
screenshot "J-blend-dialog"

# Click ISOLATE ONTO NEW LAYER.
click 479 262 ; wait_for 0.8 "Isolate clicked"
assert_no_crash
screenshot "J-after-isolate"

# DECISIVE: hide Layer 2 (effect layer) and Background so only the isolated
# Layer 3 remains visible. If Layer 3 holds the composite, the block still shows;
# if it is EMPTY (BUG-J) the canvas goes transparent.
click 16 46 ; wait_for 0.3 "Hide Layer 2 (eye)"
click 16 66 ; wait_for 0.3 "Hide Background (eye)"
key grave ; wait_for 0.2 "pointer hidden"
park_mouse
screenshot "J-only-layer3"

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 20 )); GW=80; GH=40
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "J-canvas-content"
screenshot "J-layers-panel"
assert_no_crash
assert_window_exists
info "=== REPRO complete — inspect J-* screenshots ==="
