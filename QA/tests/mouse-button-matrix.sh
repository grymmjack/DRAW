#!/bin/bash
# =============================================================================
# mouse-button-matrix.sh — T2: per-button mouse coverage over the canvas.
#
# Covers every mouse button the input spec calls out, over the canvas where the
# effect is observable:
#   A  LMB  — paints with the FOREGROUND colour.
#   B  RMB  — paints with the BACKGROUND colour (distinct from FG): repainting
#             an FG patch with RMB changes it.
#   C  wheel up / wheel down — with the brush tool and no modifier, changes the
#             brush SIZE (the cursor's hollow-square outline grows / shrinks).
#   D  MMB drag — pans the view (canvas content shifts under a fixed snap box).
#
# Button mapping: DRAW polls QB64 _MOUSEBUTTON where (2)=right (3)=middle, and
# QB64 maps X11 button-3→(2) and X11 button-2→(3). So the harness right_click
# (X11 btn3) drives DRAW's right paint and middle (X11 btn2) drives DRAW's pan —
# the conventions line up. Geometry: canvas centred (481,242), spans x 321..641,
# y 142..342.
# =============================================================================

CEN_X=481; CEN_Y=242         # canvas centre — paint target
PATCH_X=430; PATCH_Y=214; PATCH_W=110; PATCH_H=58   # snap box around the centre
WHEEL_X=385; WHEEL_Y=196     # unpainted canvas spot for the brush-size cursor
PAN_SNAP_X=430; PAN_SNAP_Y=214; PAN_SNAP_W=120; PAN_SNAP_H=70

info "=== Mouse button matrix (T2) ==="
canvas_focus b
wait_for 0.3 "brush tool ready"

# ---------------------------------------------------------------------------
# A — LMB paints (foreground). Baseline the blank patch, LMB-drag across it.
# ---------------------------------------------------------------------------
info "A — LMB paints with the foreground colour"
park_mouse
snap_region $PATCH_X $PATCH_Y $PATCH_W $PATCH_H "mb-blank"
BLANK="$SNAP_RESULT"
drag $(( CEN_X - 35 )) $CEN_Y $(( CEN_X + 35 )) $CEN_Y          # LMB (default button 1)
wait_for 0.3 "FG stroke settled"
park_mouse
snap_region $PATCH_X $PATCH_Y $PATCH_W $PATCH_H "mb-lmb-fg"
FG_PATCH="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$FG_PATCH" "LMB drag must paint the canvas (foreground)"
assert_no_crash

# ---------------------------------------------------------------------------
# B — RMB paints with the BACKGROUND colour. Repaint the same patch with RMB;
# because BG differs from FG, the patch must change again.
# ---------------------------------------------------------------------------
info "B — RMB paints with the background colour (distinct from FG)"
drag $(( CEN_X - 35 )) $CEN_Y $(( CEN_X + 35 )) $CEN_Y 3        # RMB = X11 button 3
wait_for 0.3 "BG stroke settled"
park_mouse
snap_region $PATCH_X $PATCH_Y $PATCH_W $PATCH_H "mb-rmb-bg"
assert_regions_differ "$FG_PATCH" "$SNAP_RESULT" \
    "RMB drag must paint with the BACKGROUND colour (different from the FG stroke)"
assert_no_crash

# Clean the patch back to blank so it doesn't interfere with later cases.
key ctrl+z
key ctrl+z
wait_for 0.3 "strokes undone"

# ---------------------------------------------------------------------------
# C — wheel up / down changes brush size. Hover an unpainted spot so the brush
# hollow-square cursor is visible; snap it, wheel UP to grow, re-snap (differs);
# wheel DOWN to shrink back.
# ---------------------------------------------------------------------------
info "C — wheel up/down changes the brush size (cursor outline grows/shrinks)"
hover $WHEEL_X $WHEEL_Y
wait_for 0.3 "cursor shown"
snap_region $(( WHEEL_X - 20 )) $(( WHEEL_Y - 20 )) 40 40 "mb-brush-small"
SMALL="$SNAP_RESULT"
scroll_up $WHEEL_X $WHEEL_Y
scroll_up $WHEEL_X $WHEEL_Y
scroll_up $WHEEL_X $WHEEL_Y
hover $WHEEL_X $WHEEL_Y
wait_for 0.3 "brush enlarged"
snap_region $(( WHEEL_X - 20 )) $(( WHEEL_Y - 20 )) 40 40 "mb-brush-big"
BIG="$SNAP_RESULT"
assert_regions_differ "$SMALL" "$BIG" "wheel UP must change the brush size (cursor outline grows)"
scroll_down $WHEEL_X $WHEEL_Y
scroll_down $WHEEL_X $WHEEL_Y
scroll_down $WHEEL_X $WHEEL_Y
hover $WHEEL_X $WHEEL_Y
wait_for 0.3 "brush shrunk"
snap_region $(( WHEEL_X - 20 )) $(( WHEEL_Y - 20 )) 40 40 "mb-brush-small2"
assert_regions_differ "$BIG" "$SNAP_RESULT" "wheel DOWN must change the brush size back (cursor outline shrinks)"
assert_no_crash

# ---------------------------------------------------------------------------
# D — MMB drag pans the view. Paint a distinctive mark, snap it, MMB-drag, then
# the mark has moved out of the fixed snap box → the box changes.
# ---------------------------------------------------------------------------
info "D — MMB drag pans the view"
drag $(( CEN_X - 30 )) $CEN_Y $(( CEN_X + 30 )) $CEN_Y          # LMB mark to track
wait_for 0.3 "mark painted"
park_mouse
snap_region $PAN_SNAP_X $PAN_SNAP_Y $PAN_SNAP_W $PAN_SNAP_H "mb-pan-before"
PAN_BEFORE="$SNAP_RESULT"
drag $CEN_X $CEN_Y $(( CEN_X + 70 )) $(( CEN_Y + 50 )) 2        # MMB = X11 button 2 → pan
wait_for 0.3 "pan settled"
park_mouse
snap_region $PAN_SNAP_X $PAN_SNAP_Y $PAN_SNAP_W $PAN_SNAP_H "mb-pan-after"
assert_regions_differ "$PAN_BEFORE" "$SNAP_RESULT" "MMB drag must pan the view (canvas content shifts)"
assert_no_crash

assert_window_exists
info "=== Mouse button matrix (T2) PASSED ==="
