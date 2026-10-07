#!/bin/bash
# =============================================================================
# dock-small.sh — QA test: the small-window rule (DOCK_hide_for_width).
# Two 400px columns plus the toolbox leave the 958px window less than 160px of
# canvas, so the outermost column of the wider side (the layers, LEFT.1) hides
# for now - the arrangement is not changed. Hiding the edit bar (F5) frees the
# room and the layers come back.
# QA-OPTIONS: WORKSPACE=default DOCK_CUSTOM=1 DOCK_LEFT_1=WIDTH:400;layers DOCK_LEFT_2=AUTO;toolbox|organizer|drawer DOCK_RIGHT_1=WIDTH:400;editbar
# =============================================================================

info "=== Dock small window Test ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

# the left edge: the toolbox while the layers are hidden, the layers otherwise
snap_region 0 30 90 90 "left-squeezed"; S0="$SNAP_RESULT"
screenshot "dock-small-squeezed"
canvas_focus
key F5
wait_for 0.6 "edit bar hidden"
park_mouse
wait_for 0.3 "settle"
snap_region 0 30 90 90 "left-roomy"; S1="$SNAP_RESULT"
assert_regions_differ "$S0" "$S1" "with room again the hidden layers column comes back"
screenshot "dock-small-roomy"
L1=$(grep -m1 '^DOCK_LEFT_1=' "$QA_CFG" | tr -d '\r')
if [[ -z "$L1" || "$L1" == *layers* ]]; then
    pass "the rule did not change the arrangement (${L1:-unsaved})"
else
    fail "the arrangement changed (DOCK_LEFT_1='$L1')"
fi

assert_no_crash
assert_window_exists
info "=== Dock small window Test PASSED ==="
