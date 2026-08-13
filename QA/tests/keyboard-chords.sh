#!/bin/bash
# =============================================================================
# keyboard-chords.sh — T5: keyboard chords + modifier combos.
#
# Exercises the modifier-qualified key chords with clearly observable canvas
# effects, across the Ctrl and Ctrl+Shift tiers. Undo/redo is DRAW's #1 bug area
# (unified HISTORY system), so it gets the most coverage:
#   Ctrl+Z        — undo            (action 301)
#   Ctrl+Y        — redo            (action 302)
#   Ctrl+Shift+Z  — redo, alt combo (action 302; the 3-key modifier tier)
#   Ctrl+A / Esc  — select all, then deselect (non-destructive)
#
# The per-combo SDL2-safe chord handling (hold mods, tap base, release) lives in
# the qa-harness driver's driver_input_key.
# =============================================================================

CEN_X=481; CEN_Y=242
R_X=430; R_Y=224; R_W=110; R_H=40      # snap box framing a stroke at y=242

info "=== Keyboard chords + modifier combos (T5) ==="
canvas_focus b
wait_for 0.3 "brush tool ready"

# Baseline blank canvas.
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-blank"
BLANK="$SNAP_RESULT"

# Paint a stroke.
drag $(( CEN_X - 40 )) $CEN_Y $(( CEN_X + 40 )) $CEN_Y
wait_for 0.3 "stroke settled"
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-painted"
PAINTED="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$PAINTED" "brush stroke must paint (setup)"

# --- Ctrl+Z : undo -> back to blank -----------------------------------------
info "Ctrl+Z — undo"
key ctrl+z
wait_for 0.3 "undo settled"
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-undone"
assert_regions_same "$BLANK" "$SNAP_RESULT" "Ctrl+Z must undo the stroke (canvas returns to blank)"

# --- Ctrl+Y : redo -> stroke back -------------------------------------------
info "Ctrl+Y — redo"
key ctrl+y
wait_for 0.3 "redo settled"
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-redone"
assert_regions_same "$PAINTED" "$SNAP_RESULT" "Ctrl+Y must redo the stroke (canvas returns to painted)"

# --- Ctrl+Shift+Z : redo via the alt 3-key combo ----------------------------
info "Ctrl+Shift+Z — redo (alt combo)"
key ctrl+z                              # undo again first
wait_for 0.3 "undo settled"
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-undone2"
assert_regions_same "$BLANK" "$SNAP_RESULT" "Ctrl+Z must undo again (setup for redo-alt)"
key ctrl+shift+z
wait_for 0.3 "redo-alt settled"
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-redone2"
assert_regions_same "$PAINTED" "$SNAP_RESULT" "Ctrl+Shift+Z must redo the stroke (3-key modifier combo)"
assert_no_crash

# --- Ctrl+A : select all is handled (Ctrl tier), then Esc deselects ----------
# We assert only that the whole-canvas selection chord runs cleanly and Esc
# clears it (the CLEAR semantics of Delete depend on layer opacity, covered
# elsewhere). This keeps the modifier-combo coverage without a layer-fill
# dependency.
info "Ctrl+A select-all then Esc deselect (handled cleanly)"
key ctrl+a
wait_for 0.3 "select all settled"
assert_no_crash
key Escape
wait_for 0.3 "deselected"
park_mouse
snap_region $R_X $R_Y $R_W $R_H "kc-after-selectall"
assert_regions_same "$PAINTED" "$SNAP_RESULT" \
    "Ctrl+A + Esc must leave the painted stroke intact (select-all then deselect, no destructive change)"
assert_no_crash

assert_window_exists
info "=== Keyboard chords + modifier combos (T5) PASSED ==="
