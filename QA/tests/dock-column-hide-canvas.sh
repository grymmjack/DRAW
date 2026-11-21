#!/bin/bash
# =============================================================================
# dock-column-hide-canvas.sh — QA test: hiding a docked column moves the canvas
# on screen at once (2026-11-20).
# F4 hides a docked Preview column: the canvas area widens, so the canvas is
# centred again (SCRN.panelShiftX). The GUI-only render path recomputed the
# layout but kept the cached scene, so the canvas stayed where it was - centred
# in the old, narrower area - and the old column's edge stayed on screen, until
# something else dirtied the scene (Ctrl+0). SCREEN_render now re-renders the
# scene when the layout moved the canvas (SCENE_LAY_*).
# Checks: the canvas moves right (CANVR), and the pixels at the new canvas centre
# are the canvas (the transparency checkerboard), not the empty background.
# Dump: CANVR x y w h - the canvas on screen (viewport px).
# QA-OPTIONS: WORKSPACE=default DOCK_CUSTOM=1 DOCK_RIGHT_1=WIDTH:400;preview DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

canvr() { grep -m1 '^CANVR ' "$DK_DUMP" | cut -d' ' -f2-; }

info "=== Hiding a docked column re-centres the canvas ==="
wait_for 0.8 "settle"
key Escape
dk_park; dk_settle
read -r X0 Y0 W0 H0 <<< "$(canvr)"
[[ -n "$X0" ]] || fail "no CANVR line in the dump"
info "canvas before: x=$X0 y=$Y0 ${W0}x${H0}"

canvas_focus
key F4
wait_for 0.8 "Preview column hidden"
dk_park; dk_settle; sleep 0.5
read -r X1 Y1 W1 H1 <<< "$(canvr)"
info "canvas after:  x=$X1 y=$Y1 ${W1}x${H1}"
if (( X1 > X0 )); then pass "the canvas is centred in the wider area (x $X0 -> $X1)"; else fail "the canvas did not move (x $X0 -> $X1)"; fi

# the middle of where the canvas now is: the checkerboard (2+ colours), not background
CX=$(( X1 + W1 / 2 )); CY=$(( Y1 + H1 / 2 ))
snap_region $(( CX - 12 )) $(( CY - 12 )) 24 24 "canvas-centre-after"
N=$(identify -format %k "$SNAP_RESULT" 2>/dev/null)
if [[ "${N:-0}" -ge 2 ]]; then
    pass "the canvas is drawn where it now is ($N colours at its centre)"
else
    fail "the new canvas spot shows ${N:-?} colour(s) - the old scene is still on screen"
fi
screenshot "dock-column-hide-canvas"

assert_no_crash
assert_window_exists
