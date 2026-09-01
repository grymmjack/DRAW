#!/bin/bash
# After my fix: filling, then clicking a menu (inert) must leave a clean undo stack —
# a single Ctrl+Z undoes the fill (no phantom menu-click state).
info "=== Undo after menu click ==="
canvas_focus b
wait_for 0.3 "ready"
key f ; wait_for 0.2 "fill tool"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG red"
GX=$(( CANVAS_CX + 30 )); GY=$(( CANVAS_CY - 20 )); GW=50; GH=40
park_mouse ; snap_region "$GX" "$GY" "$GW" "$GH" "um-empty"; EMPTY="$SNAP_RESULT"
click "$CANVAS_CX" "$CANVAS_CY" ; wait_for 0.4 "filled red"
key grave ; park_mouse ; snap_region "$GX" "$GY" "$GW" "$GH" "um-filled"; FILLED="$SNAP_RESULT"
assert_regions_differ "$EMPTY" "$FILLED" "sanity: fill changed the canvas"
# click a menu (inert now), then a single undo
click 395 6 ; wait_for 0.4 "EFFECTS open"
key Escape ; wait_for 0.3 "menu closed"
key ctrl+z ; wait_for 0.5 "undo once"
key grave ; park_mouse ; snap_region "$GX" "$GY" "$GW" "$GH" "um-undone"; UNDONE="$SNAP_RESULT"
assert_regions_same "$EMPTY" "$UNDONE" "single Ctrl+Z must restore pre-fill state (clean undo stack)"
assert_no_crash ; assert_window_exists
info "=== done ==="
