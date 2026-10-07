#!/bin/bash
# =============================================================================
# dock-startup.sh — QA test: a floating window that STARTS docked shows.
# The Advanced Color Picker initializes lazily (its size comes from its init),
# and a docked window only draws once the layout gives it a rect - so started
# docked it never appeared until DOCK_native_init_docked. Here it starts in the
# outermost right column; hiding it (Ctrl+Shift+M) must change the right edge,
# which only happens if it was showing.
# QA-OPTIONS: WORKSPACE=default ADV_COLOR_PICKER_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;advcolorpicker DOCK_RIGHT_2=AUTO;toolbox|organizer|drawer DOCK_RIGHT_3=AUTO;advbar
# =============================================================================

info "=== Dock: window docked at startup Test ==="
wait_for 1.2 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

snap_region $(( VIEWPORT_W - 100 )) 40 90 120 "right-edge-acp"; A0="$SNAP_RESULT"
screenshot "dock-startup-acp"
canvas_focus
key ctrl+shift+m
wait_for 0.6 "picker hidden"
park_mouse
wait_for 0.3 "settle"
snap_region $(( VIEWPORT_W - 100 )) 40 90 120 "right-edge-none"; A1="$SNAP_RESULT"
assert_regions_differ "$A0" "$A1" "the docked Advanced Color Picker was showing at startup"

assert_no_crash
assert_window_exists
info "=== Dock: window docked at startup Test PASSED ==="
