#!/bin/bash
# =============================================================================
# seam-effects-central.sh — Phase 2A.2b: last-effect shortcuts via CENTRAL DISPATCH
#
# Ctrl+F (Redo Last Effect, 2350) / Ctrl+Alt+F (Recall, 2351) / Ctrl+Shift+F
# (Blend, 2352) migrated from the legacy KEYBOARD.BM _KEYDOWN block to central
# dispatch. Apply a real Effects-menu effect (Glow — it IS tracked as the "last
# effect", unlike Image adjustments), then Ctrl+F must RE-APPLY it (region
# changes) — proving the migrated Ctrl+F fires through the central dispatcher.
# (Also confirmed out-of-band via --developer: [FIRE] action=2350.)
# =============================================================================

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"

info "Draw a thick line of content"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
wait_for 0.3 "Content drawn"
key grave
wait_for 0.1 "Pointer hidden"
assert_no_crash
park_mouse

# -- Apply Glow (a tracked Effects-menu effect) with strong settings --
info "Apply Glow effect (sets the last effect)"
open_effect 1 0
wait_for 0.5 "Glow dialog open"
drag 400 317 560 317
wait_for 0.2 "Radius up"
drag 400 355 580 355
wait_for 0.2 "Intensity up"
key Return
wait_for 0.7 "Glow applied, dialog closed"
assert_no_crash
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "fx-glow1"
GLOW1="$SNAP_RESULT"

# -- Ctrl+F re-applies the last effect (now central-dispatched) --
info "Ctrl+F = Redo Last Effect (central dispatch) — re-applies Glow"
key ctrl+f
wait_for 0.7 "Redo last effect (more glow)"
assert_no_crash
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "fx-glow2"
GLOW2="$SNAP_RESULT"
assert_regions_differ "$GLOW1" "$GLOW2" "Ctrl+F re-applied Glow (central dispatch fired action 2350)"
