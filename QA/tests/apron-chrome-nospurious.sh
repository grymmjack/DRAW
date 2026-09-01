#!/bin/bash
# Repro: fill canvas, change FG, click EFFECTS menu -> canvas must NOT change.
info "=== Fill + menu-click canvas-change repro ==="
canvas_focus b
wait_for 0.3 "ready"
key f ; wait_for 0.2 "fill tool"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
# black-ish chip (leftmost), fill
click $(( 16 + 0*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG A (black)"
click "$CANVAS_CX" "$CANVAS_CY" ; wait_for 0.4 "filled A"
key grave ; park_mouse
# sample the RIGHT side of canvas (not under the EFFECTS dropdown)
GX=$(( CANVAS_CX + 30 )); GY=$(( CANVAS_CY - 20 )); GW=50; GH=40
snap_region "$GX" "$GY" "$GW" "$GH" "fm-afterfill"; A="$SNAP_RESULT"
# change FG to green
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG B (green)"
# click EFFECTS menu root
click 395 6 ; wait_for 0.5 "EFFECTS menu open"
key Escape ; wait_for 0.3 "menu closed"
key grave ; park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "fm-aftermenu"; B="$SNAP_RESULT"
screenshot "fm-aftermenu-full"
assert_regions_same "$A" "$B" "Clicking EFFECTS menu must NOT change the canvas fill"
assert_no_crash ; assert_window_exists
info "=== done ==="
