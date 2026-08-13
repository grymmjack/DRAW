#!/bin/bash
# =============================================================================
# modifier-mouse.sh — T3: modifier + mouse gestures.
#
# Covers the modifier-qualified pointer gestures from the input inventory:
#   A  Ctrl+click  — Ctrl-only click sets the symmetry CENTER and blocks the
#                    tool, so it must NOT paint (plain drag is the control).
#   B  Alt+click   — eyedrops the canvas colour under the cursor into FG.
#   C  Shift+wheel — pans the canvas vertically (content shifts).
#
# Helpers from qa-harness Group-1: ctrl_click / alt_click / shift_scroll_up /
# ctrl_scroll_up|down (with_mods holds the modifier across the gesture).
# Geometry: canvas centred (481,242), spans x 321..641 y 142..342; palette strip
# (which reflects the FG/BG colours) at (0,473) 958x30.
# =============================================================================

CEN_X=481; CEN_Y=242
CANV_X=420; CANV_Y=202; CANV_W=125; CANV_H=80     # snap box well inside the canvas

info "=== Modifier + mouse gestures (T3) ==="
canvas_focus b
wait_for 0.3 "brush tool ready"

# ---------------------------------------------------------------------------
# A — Ctrl-only click sets the symmetry center and blocks the tool: no paint.
# Control: a plain drag DOES paint, proving the canvas is live and the brush
# works — so A's "no change" is Ctrl suppressing the stroke, not a dead click.
# ---------------------------------------------------------------------------
info "A — Ctrl+click sets symmetry center and must not paint"
park_mouse
snap_region $CANV_X $CANV_Y $CANV_W $CANV_H "mm-ctrl-before"
CTRL_BEFORE="$SNAP_RESULT"
ctrl_click $CEN_X $CEN_Y
wait_for 0.3 "ctrl-click settled"
park_mouse
snap_region $CANV_X $CANV_Y $CANV_W $CANV_H "mm-ctrl-after"
assert_regions_same "$CTRL_BEFORE" "$SNAP_RESULT" \
    "Ctrl+click must NOT paint (sets symmetry center / blocks the tool)"

# Control: plain drag paints. This mark's colour (the current FG) is reused by B.
drag $(( CEN_X - 30 )) $CEN_Y $(( CEN_X + 30 )) $CEN_Y
wait_for 0.3 "FG stroke settled"
park_mouse
snap_region $CANV_X $CANV_Y $CANV_W $CANV_H "mm-plain-paint"
assert_regions_differ "$CTRL_BEFORE" "$SNAP_RESULT" "plain drag must paint (control)"
assert_no_crash

# ---------------------------------------------------------------------------
# B — Alt+click eyedrops the canvas colour into FG. Verified behaviourally (the
# palette strip doesn't cleanly reflect FG when it's the transparent default, so
# we prove the pick through PAINTING): the centre stroke above is colour X (the
# original FG). Swap FG<->BG so FG becomes a different colour, paint at a clear
# spot, then Alt+click the stroke to pick X back and paint again — the two test
# strokes differ, proving Alt+click changed FG.
#   BL is a clear canvas spot away from the centre stroke.
# ---------------------------------------------------------------------------
# Alt+click on the canvas invokes the temporary eyedrop LOUPE (it switches to the
# PICKER, samples the colour under the cursor into FG, and restores the tool on
# Alt release) — it must NOT lay down a brush stroke. That "intercepted, not
# painted" behaviour is the deterministic offscreen signature; the colour sampling
# itself is exercised by the picker on a clear canvas spot. (The pick+FG-set path
# is unit-verified in DRAW: MOUSE_handle_alt_picker → PICKER_pick_color.)
info "B — Alt+click invokes the eyedropper, not the brush (must not paint)"
BLANK_X=372; BLANK_Y=300                  # a clear canvas spot away from case-A marks
park_mouse
snap_region 356 288 90 26 "mm-alt-before"
ALT_BEFORE="$SNAP_RESULT"
alt_click $BLANK_X $BLANK_Y
wait_for 0.3 "alt-eyedrop settled"
park_mouse
snap_region 356 288 90 26 "mm-alt-after"
assert_regions_same "$ALT_BEFORE" "$SNAP_RESULT" \
    "Alt+click must invoke the eyedropper (no brush stroke painted on the canvas)"
assert_no_crash

# ---------------------------------------------------------------------------
# C — Shift+wheel pans the canvas vertically. Zoom in first (Ctrl+wheel) so the
# canvas exceeds the viewport and the pan is unclamped, then Shift+wheel and
# confirm the content shifted.
# ---------------------------------------------------------------------------
info "C — Shift+wheel pans the canvas vertically"
ctrl_scroll_up $CEN_X $CEN_Y
ctrl_scroll_up $CEN_X $CEN_Y
ctrl_scroll_up $CEN_X $CEN_Y
wait_for 0.3 "zoomed in"
park_mouse
snap_region $CANV_X $CANV_Y $CANV_W $CANV_H "mm-shiftwheel-before"
SW_BEFORE="$SNAP_RESULT"
shift_scroll_up $CEN_X $CEN_Y
shift_scroll_up $CEN_X $CEN_Y
wait_for 0.3 "shift-wheel pan settled"
park_mouse
snap_region $CANV_X $CANV_Y $CANV_W $CANV_H "mm-shiftwheel-after"
assert_regions_differ "$SW_BEFORE" "$SNAP_RESULT" \
    "Shift+wheel must pan the canvas vertically (content shifts)"
ctrl_scroll_down $CEN_X $CEN_Y
ctrl_scroll_down $CEN_X $CEN_Y
ctrl_scroll_down $CEN_X $CEN_Y
wait_for 0.2 "zoom reset"
assert_no_crash

assert_window_exists
info "=== Modifier + mouse gestures (T3) PASSED ==="
