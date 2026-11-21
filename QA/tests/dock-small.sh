#!/bin/bash
# =============================================================================
# dock-small.sh — QA test: the small-window rule (DOCK_hide_for_width).
# Two 400px columns plus the toolbox leave the 958px window less than 160px of
# canvas, so the outermost column of the wider side (Swatches, LEFT.1) hides
# for now - the arrangement is not changed. Hiding the Preview (F4) frees the
# room and Swatches come back.
# 2026-11-20: was layers (LEFT.1) + the edit bar (RIGHT.1, F5) - a column is capped
# at its panels' widest (DOCK_col_max_w%), so those two never reached 400 px and
# nothing was squeezed. Swatches and the Preview stretch (1200 / 600 px).
# QA-OPTIONS: WORKSPACE=default DOCK_CUSTOM=1 SWATCHES_VISIBLE=1 DOCK_LEFT_1=WIDTH:400;swatches DOCK_LEFT_2=AUTO;toolbox|organizer|drawer DOCK_RIGHT_1=WIDTH:400;preview
# =============================================================================

info "=== Dock small window Test ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

# the left edge: the toolbox while Swatches are hidden, Swatches otherwise
snap_region 0 30 90 90 "left-squeezed"; S0="$SNAP_RESULT"
screenshot "dock-small-squeezed"
canvas_focus
key F4
wait_for 0.6 "Preview hidden"
park_mouse
wait_for 0.3 "settle"
snap_region 0 30 90 90 "left-roomy"; S1="$SNAP_RESULT"
assert_regions_differ "$S0" "$S1" "with room again the hidden Swatches column comes back"
screenshot "dock-small-roomy"
L1=$(grep -m1 '^DOCK_LEFT_1=' "$QA_CFG" | tr -d '\r')
if [[ -z "$L1" || "$L1" == *swatches* ]]; then
    pass "the rule did not change the arrangement (${L1:-unsaved})"
else
    fail "the arrangement changed (DOCK_LEFT_1='$L1')"
fi

assert_no_crash
assert_window_exists
info "=== Dock small window Test PASSED ==="
