#!/bin/bash
# =============================================================================
# input-seam-regressions.sh — T6: regressions for the trickiest input seams
# found in the code inventory (.claude/input-inventory/02-keyboard.md §SEAMS).
#
#   A  F11 "Toggle All UI" (action 403) — F11 has THREE physical keycodes across
#      contexts (34048 / 133120 / 15104-block). Verify the normal binding hides
#      all chrome and round-trips exactly on a second press.
#   B  Ctrl+D is DOUBLE-MAPPED: the dispatched binding fires 307 Deselect, but
#      CMD 518 "Default Colors" is also on Ctrl+D. Verify the DESELECT wins — the
#      selection marquee raised by Ctrl+A disappears after Ctrl+D (if 518 had won
#      the marquee would remain).
#   C  Backtick "Toggle Brush Cursors" (action 412) — the grave key is
#      quad-purpose; verify the plain press toggles the brush cursor overlay.
# =============================================================================

VP_W=958; VP_H=514
CEN_X=481; CEN_Y=242

info "=== Input seam regressions (T6) ==="
canvas_focus b
wait_for 0.3 "brush tool ready"

# ---------------------------------------------------------------------------
# A — F11 toggles ALL UI and round-trips (multi-keycode seam).
# ---------------------------------------------------------------------------
info "A — F11 toggles all UI, and round-trips"
park_mouse
snap_region 0 0 $VP_W $VP_H "seam-ui-on"
UI_ON="$SNAP_RESULT"
key F11
wait_for 0.5 "all UI hidden"
park_mouse
snap_region 0 0 $VP_W $VP_H "seam-ui-off"
assert_regions_differ "$UI_ON" "$SNAP_RESULT" "F11 must hide all UI chrome (Toggle All UI, action 403)"
key F11
wait_for 0.5 "all UI restored"
park_mouse
snap_region 0 0 $VP_W $VP_H "seam-ui-restored"
assert_regions_same "$UI_ON" "$SNAP_RESULT" "F11 must restore all UI exactly (multi-keycode round-trip)"
assert_no_crash

# ---------------------------------------------------------------------------
# B — Ctrl+D resolves to 307 Deselect (not 518 Default Colors). The select-all
# marquee draws marching ants at the CANVAS PERIMETER, so we watch the canvas
# top-left corner: blank → ants after Ctrl+A → blank again after Ctrl+D. If 518
# Default Colors had won, the ants would remain.
# ---------------------------------------------------------------------------
info "B — Ctrl+D must Deselect (not Default Colors) — double-mapping seam"
CN_X=314; CN_Y=135; CN_W=32; CN_H=32     # canvas top-left corner (marquee draws here)
park_mouse
snap_region $CN_X $CN_Y $CN_W $CN_H "seam-corner-before"
CORNER_BEFORE="$SNAP_RESULT"
key ctrl+a
wait_for 0.3 "select all — marquee up"
park_mouse
snap_region $CN_X $CN_Y $CN_W $CN_H "seam-corner-selected"
assert_regions_differ "$CORNER_BEFORE" "$SNAP_RESULT" "Ctrl+A must raise a selection marquee at the canvas corner (setup)"
key ctrl+d
wait_for 0.4 "ctrl+d"
park_mouse
snap_region $CN_X $CN_Y $CN_W $CN_H "seam-corner-deselected"
assert_regions_same "$CORNER_BEFORE" "$SNAP_RESULT" \
    "Ctrl+D must Deselect (marquee gone → corner back to blank); if 518 Default Colors had won the marquee would remain"
assert_no_crash

# ---------------------------------------------------------------------------
# C — Backtick toggles the brush-cursor overlay (action 412, quad-purpose grave).
# Hover the canvas so the brush cursor is drawn, snap it, press backtick, hover
# and snap again: the cursor overlay must change.
# ---------------------------------------------------------------------------
info "C — Backtick toggles the brush cursor overlay"
hover $CEN_X $CEN_Y
wait_for 0.3 "cursor shown"
snap_region $(( CEN_X - 20 )) $(( CEN_Y - 20 )) 40 40 "seam-cursor-on"
CURSOR_ON="$SNAP_RESULT"
key grave
wait_for 0.3 "brush cursors toggled"
hover $CEN_X $CEN_Y
wait_for 0.3 "re-hover"
snap_region $(( CEN_X - 20 )) $(( CEN_Y - 20 )) 40 40 "seam-cursor-off"
assert_regions_differ "$CURSOR_ON" "$SNAP_RESULT" \
    "Backtick must toggle the brush cursor overlay (action 412)"
key grave                                # restore
wait_for 0.2 "restored"
assert_no_crash

assert_window_exists
info "=== Input seam regressions (T6) PASSED ==="
