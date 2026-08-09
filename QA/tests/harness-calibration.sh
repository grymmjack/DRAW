#!/bin/bash
# =============================================================================
# harness-calibration.sh — QA test: viewport→screen coordinate mapping
#
# This test exists because a wrong DECORATION_H silently broke the whole suite.
# The harness derived the title-bar height from _NET_FRAME_EXTENTS as
# "top - 3×left_shadow", which on KDE Breeze evaluated to 33 physical px and
# was then ADDED to a window origin that was already the client area. Every
# click landed 16.5 viewport px too low and every capture was cropped 16.5 px
# too low.
#
# It was invisible because the error was SELF-CONSISTENT: clicks and captures
# were shifted by the same amount, so the harness agreed with itself. Only
# assertions that cross into DRAW's real geometry could see it — and when they
# failed they said "regions are identical (action had no effect?)", which reads
# like a product bug.
#
# So: pin the mapping explicitly at three heights, with failure messages that
# name the real cause. If several of these fail at once, suspect DECORATION_H
# or _update_win_pos, NOT the features under test.
#
#   TOP    (y≈6)    menu bar          — 12px tall
#   MIDDLE (y≈26)   layer panel row 0 — 20px tall
#   BOTTOM (y≈503)  status bar        — 11px tall
#
# Each band is smaller than the 16.5px error, so any drift moves a click or a
# capture clean off its target.
# =============================================================================

info "=== Harness Calibration Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# ---------------------------------------------------------------------------
# TOP anchor — the menu bar is only MENU_BAR_H (12) px tall.
# Snap the bar itself, NOT the dropdown area: a click that misses the bar may
# still land on the canvas and draw a dot, which would change a taller region
# and mask the failure. Restricting the snap to the bar means only a real hit
# on the FILE label (which highlights it) can change these pixels.
# ---------------------------------------------------------------------------
info "TOP: menu bar click lands on the menu bar"
park_mouse
snap_region "$WORK_LEFT" 0 300 "$MENU_BAR_H" "cal-menubar-idle"
MENUBAR_IDLE="$SNAP_RESULT"

click $(( WORK_LEFT + 12 )) $(( MENU_BAR_H / 2 ))
wait_for 0.5 "FILE menu opened"
park_mouse
snap_region "$WORK_LEFT" 0 300 "$MENU_BAR_H" "cal-menubar-open"
MENUBAR_OPEN="$SNAP_RESULT"
assert_regions_differ "$MENUBAR_IDLE" "$MENUBAR_OPEN" \
    "TOP anchor: clicking the FILE label must highlight the menu bar (if identical, viewport y=$(( MENU_BAR_H / 2 )) is not landing on the ${MENU_BAR_H}px menu bar — check DECORATION_H)"

key Escape
wait_for 0.4 "Menu closed"
assert_no_crash

# ---------------------------------------------------------------------------
# MIDDLE anchor — layer panel row 0's eye icon.
# Row 0 spans y = LP_HEADER_H .. LP_HEADER_H+19, so its centre is y=26 and the
# eye hit-zone is localX < 14. A 16px downward drift puts this click on row 1,
# which is empty on a fresh document — the classic "action had no effect".
# ---------------------------------------------------------------------------
info "MIDDLE: layer row 0 eye icon toggles layer 0"
# LAYER_PANEL_render sets panelY% = 0 — the panel starts at the TOP of the
# window and the menu bar draws over its own strip, so the list begins at
# HEADER_HEIGHT (16), NOT at MENU_BAR_H + 16. Row 0 is therefore y=16..35 and
# its centre is 26. Derived from source here rather than from the harness's
# LP_Y so this test keeps its value as an independent check.
LP_PANEL_TOP=0
LP_HEADER_H=16
LAYER_ENTRY_H=20
EYE_X=$(( LP_X + 7 ))
ROW0_Y=$(( LP_PANEL_TOP + LP_HEADER_H + LAYER_ENTRY_H / 2 ))

# Put content on layer 0 so hiding it is visible on the canvas.
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 20 ))
wait_for 0.4 "Stroke drawn on layer 0"
park_mouse
snap_region "$WORK_LEFT" "$WORK_TOP" "$WORK_W" "$WORK_H" "cal-layer-visible"
LAYER_VISIBLE="$SNAP_RESULT"

click "$EYE_X" "$ROW0_Y"
wait_for 0.5 "Layer 0 hidden"
park_mouse
snap_region "$WORK_LEFT" "$WORK_TOP" "$WORK_W" "$WORK_H" "cal-layer-hidden"
LAYER_HIDDEN="$SNAP_RESULT"
assert_regions_differ "$LAYER_VISIBLE" "$LAYER_HIDDEN" \
    "MIDDLE anchor: clicking (${EYE_X},${ROW0_Y}) must hide layer 0 (if identical, the click is landing on row 1 — ${LAYER_ENTRY_H}px of drift — check DECORATION_H)"

# Restore visibility
click "$EYE_X" "$ROW0_Y"
wait_for 0.5 "Layer 0 shown"
park_mouse
snap_region "$WORK_LEFT" "$WORK_TOP" "$WORK_W" "$WORK_H" "cal-layer-reshown"
LAYER_RESHOWN="$SNAP_RESULT"
assert_regions_same "$LAYER_VISIBLE" "$LAYER_RESHOWN" \
    "MIDDLE anchor: re-showing layer 0 restores the canvas"
assert_no_crash

# ---------------------------------------------------------------------------
# BOTTOM anchor — the status bar is the last STATUS_H (11) px of the window.
# This is the one that exposed the bug: with 16.5px of drift the captured band
# fell past the window's bottom edge and contained the DESKTOP, so it never
# changed no matter what DRAW did.
# ---------------------------------------------------------------------------
info "BOTTOM: status bar band tracks the active tool"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) "$VIEWPORT_W" "$STATUS_H" "cal-status-brush"
STATUS_BRUSH="$SNAP_RESULT"

key l
wait_for 0.5 "Line tool active"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) "$VIEWPORT_W" "$STATUS_H" "cal-status-line"
STATUS_LINE="$SNAP_RESULT"
assert_regions_differ "$STATUS_BRUSH" "$STATUS_LINE" \
    "BOTTOM anchor: status bar must show LINE instead of BRUSH (if identical, the captured band is below the window and shows the desktop — check DECORATION_H)"

key b
wait_for 0.5 "Brush tool restored"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) "$VIEWPORT_W" "$STATUS_H" "cal-status-brush2"
STATUS_BRUSH2="$SNAP_RESULT"
assert_regions_same "$STATUS_BRUSH" "$STATUS_BRUSH2" \
    "BOTTOM anchor: switching back to BRUSH restores the status bar"

# -- Cleanup --
key ctrl+z
wait_for 0.4 "Undo stroke"
assert_no_crash
assert_window_exists
info "=== Harness Calibration Test PASSED ==="
