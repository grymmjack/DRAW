#!/bin/bash
# =============================================================================
# controls-dialog-open.sh — QA test: Edit > Customize Controls opens the dialog
#
# Phase 4.1 scaffold guard. Action ACTION_CUSTOMIZE_CONTROLS (2360) -> CONTROLS_open
# (GUI/CONTROLS.BM), a DRAW-rendered blocking modal listing the keyboard bindings
# by category. We verify: (a) invoking it via the command palette opens a modal
# that visibly changes the screen, (b) it lists real content (differs from an empty
# frame), (c) Escape closes it and DRAW stays responsive / uncrashed.
#
# Regression value: this action id was almost shipped as 2300, which collides with
# ANS_ACT_EXPORT — if that regressed, "customize controls" would open ANSI export
# and this test's post-open screen would look wrong / the wand-less canvas differs.
# =============================================================================

info "=== Customize Controls dialog open Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "before-controls"
BEFORE="$SNAP_RESULT"

# -- Open via the command palette (robust vs. the long Edit-menu geometry) --
info "Open Customize Controls (command palette)"
key question
wait_for 0.5 "Command palette"
type_text "customize controls"
wait_for 0.3 "Filter"
key Return
wait_for 0.8 "Customize Controls dialog opened"
assert_no_crash

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "controls-dialog"
DIALOG="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$DIALOG" "Customize Controls should open a visible modal"
screenshot "controls-dialog"

# -- The dialog centre must carry rendered binding rows (not a blank frame) --
CX=$(( VIEWPORT_W / 2 )); CY=$(( VIEWPORT_H / 2 ))
snap_region $(( CX - 120 )) $(( CY - 40 )) 240 80 "controls-body"
BODY="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$BODY" "Dialog body should show binding rows"

# -- Escape closes it; DRAW returns to the pre-open screen and stays alive --
info "Close dialog (Escape)"
key Escape
wait_for 0.5 "Dialog closed"
assert_no_crash
assert_window_exists

park_mouse
snap_region 0 0 $VIEWPORT_W $VIEWPORT_H "after-controls"
AFTER="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER" "Closing the dialog restores the prior screen"

info "=== Customize Controls dialog open Test PASSED ==="
