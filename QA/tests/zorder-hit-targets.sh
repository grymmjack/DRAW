#!/bin/bash
# =============================================================================
# zorder-hit-targets.sh — T1: z-order & hit-target regression suite
#
# Guards the Z1–Z4 refactor (one declarative z-stack: render order == input
# hit-test order). Each assertion maps to a specific fix:
#
#   A  Z1     — the POINTER/cursor renders ON TOP of the floating Preview
#               window (the reported "cursor is UNDER the preview pane" bug).
#   B  Z2/Z3  — the floating Preview is FRONT-MOST for INPUT over the toolbar it
#               overlaps: a click on the Preview must NOT leak through and switch
#               the tool in the toolbar beneath it (no double-fire).
#   C  Z4     — bare canvas STILL receives tool input after REGION_CANVAS was
#               registered as the z-stack floor (the floor must not shadow tools).
#
# Geometry (QA/DRAW.qa.cfg): viewport 958x514 @2x; toolbar docked RIGHT at
# x 862..958; Preview floats at logical (830,383) size 120x100, overlapping the
# LOWER toolbar; launches visible (PREVIEW_VISIBLE=1). Canvas is centred at
# (481,242), spanning x 321..641, y 142..342.
#
# NOTE on the cursor: with the brush tool DRAW draws a hollow-square cursor
# outline into its own software-pointer layer (composited ABOVE floating windows
# by Z1), which the offscreen capture backend CAN grab. Over DOCKED chrome DRAW
# instead shows the OS arrow cursor (not capturable, and never the z-order bug —
# docked panels never occluded the software cursor), so cursor-on-top is asserted
# only over the floating Preview.
# =============================================================================

# Preview body point over the toolbar. The brush hollow-square cursor lands on
# the Preview surface here, clear of the title bar and the tooltip strip below.
PV_CX=900; PV_CY=430
# Preview geometric center — click target for the input leak test.
PV_MX=890; PV_MY=433
# Toolbar strip ABOVE the Preview: shows the active-tool highlight and is never
# under the Preview, so it changes ONLY if the active tool actually changes.
TB_X=864; TB_Y=16; TB_W=90; TB_H=350
# Canvas snap box — frames the horizontal stroke drawn at y=CANVAS_CY (242)
# across x CANVAS_CX-40..+40 (441..521). Box x 430..540, y 226..262.
CV_X=430; CV_Y=226; CV_W=110; CV_H=36

info "=== Z-order & hit-target suite (T1) ==="
canvas_focus b
wait_for 0.3 "brush tool ready"
# Do NOT hide the pointer (no `key grave`): Part A needs the pointer VISIBLE to
# assert it renders on top. park_mouse keeps the parked pointer out of every
# content snap, so a visible pointer never pollutes the toolbar/canvas diffs.

# ---------------------------------------------------------------------------
# A — Z1: cursor renders ON TOP of the floating Preview window. This is the
# exact reported regression ("preview pane cursor is UNDER the preview pane").
# If the sampled box is unchanged, the cursor is being drawn beneath the Preview.
# ---------------------------------------------------------------------------
info "A — cursor must render on top of the floating Preview (Z1)"
assert_cursor_on_top $PV_CX $PV_CY "cursor must render ON TOP of the floating Preview window (Z1)"
assert_no_crash

# ---------------------------------------------------------------------------
# B — Z2/Z3: the floating Preview is front-most for INPUT over the toolbar.
# Baseline the toolbar's active-tool highlight (brush selected), click the
# Preview body where it overlaps the toolbar, and re-snap: a leak-through would
# switch tools and change the highlight strip. It must stay IDENTICAL.
# ---------------------------------------------------------------------------
info "B — click on Preview must not leak to the toolbar beneath (Z2/Z3)"
key b
wait_for 0.2 "brush re-selected (known active tool)"
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "zt-toolbar-before"
TB_BEFORE="$SNAP_RESULT"

click $PV_MX 410
click $PV_MX $PV_MY
click $PV_MX 458
wait_for 0.3 "clicks settled"
assert_no_crash

park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "zt-toolbar-after"
assert_regions_same "$TB_BEFORE" "$SNAP_RESULT" \
    "clicking the floating Preview must NOT switch tools in the toolbar beneath it (z-order: front-most wins, no leak-through)"
screenshot "zt-after-preview-clicks"

# ---------------------------------------------------------------------------
# C — Z4: bare canvas still receives tool input. Registering REGION_CANVAS as
# the z-stack floor must not shadow tool dispatch on the canvas.
# ---------------------------------------------------------------------------
info "C — bare canvas still receives tool input (Z4 floor must not shadow)"
key b
wait_for 0.2 "brush active"
park_mouse
snap_region $CV_X $CV_Y $CV_W $CV_H "zt-canvas-before"
CV_BEFORE="$SNAP_RESULT"

drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "stroke settled"
assert_no_crash

park_mouse
snap_region $CV_X $CV_Y $CV_W $CV_H "zt-canvas-after"
assert_regions_differ "$CV_BEFORE" "$SNAP_RESULT" \
    "bare canvas must still receive tool input after REGION_CANVAS floor registered (Z4)"

# Undo the probe stroke so the test leaves no dirty document.
key ctrl+z
wait_for 0.2 "undo settled"
assert_no_crash

assert_window_exists
info "=== Z-order & hit-target suite (T1) PASSED ==="
