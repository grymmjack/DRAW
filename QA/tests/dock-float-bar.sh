#!/bin/bash
# =============================================================================
# dock-float-bar.sh — QA test: a thin bar floats with a grip (no title), opens
# tall enough for all its icons, resizes by its corner and docks back.
#   float   drag the edit bar's top-edge grip onto the canvas -> DOCK_FLOAT_EDITBAR
#   resize  drag the window's bottom-right corner right       -> wider, saved
#   back    double-click the grip strip                        -> docked again
# A floating window is clamped into the work area at layout time, so the corner
# is computed from the clamped bottom (dock bottom y=490 at 958x514).
# QA-OPTIONS: WORKSPACE=default
# =============================================================================

info "=== Dock: floating thin bar Test ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

slow_drag() {
    local x1=$1 y1=$2 x2=$3 y2=$4 steps=5 i
    mouse_down "$x1" "$y1"
    wait_for 0.2 "grab"
    for (( i = 1; i <= steps; i++ )); do
        hover $(( x1 + (x2 - x1) * i / steps )) $(( y1 + (y2 - y1) * i / steps ))
        wait_for 0.12 "drag"
    done
    wait_for 0.3 "target"
    mouse_up
    wait_for 0.7 "drop"
}

# --- float: the edit bar's grip (its top edge, under the menu bar) ---------------
slow_drag 110 13 480 160
park_mouse
wait_for 0.3 "settle"
F=$(grep -m1 '^DOCK_FLOAT_EDITBAR=' "$QA_CFG" | cut -d= -f2 | tr -d '\r')
if [[ -n "$F" ]]; then pass "edit bar floating (DOCK_FLOAT_EDITBAR=$F)"; else fail "edit bar did not float"; fi
IFS=, read -r FX FY FW FH <<< "$F"
if [[ -n "$FH" && "$FH" -ge 300 ]]; then
    pass "it opened tall enough for its icons (h=$FH)"
else
    fail "floating bar too short (h='$FH')"
fi
screenshot "dock-float-bar"

# --- resize by the bottom-right corner ------------------------------------------
CX=$(( FX + FW - 2 )); CY=$(( FY + FH - 2 )); (( CY > 488 )) && CY=488
snap_region $(( FX - 10 )) 60 $(( FW + 60 )) 200 "bar-narrow"; B0="$SNAP_RESULT"
slow_drag $CX $CY $(( CX + 40 )) $(( CY - 60 ))
park_mouse
wait_for 0.3 "settle"
snap_region $(( FX - 10 )) 60 $(( FW + 60 )) 200 "bar-wide"; B1="$SNAP_RESULT"
assert_regions_differ "$B0" "$B1" "dragging the corner widened the bar (more icon columns)"
F2=$(grep -m1 '^DOCK_FLOAT_EDITBAR=' "$QA_CFG" | cut -d= -f2 | tr -d '\r')
IFS=, read -r _ FY2 FW2 _ <<< "$F2"
if [[ -n "$FW2" && "$FW2" -gt "$FW" ]]; then pass "new width saved ($FW -> $FW2)"; else fail "width not saved ('$F2')"; fi

# --- dock back: double-click the grip strip ------------------------------------------
double_click $(( FX + FW2 / 2 )) $(( FY2 + 2 ))
wait_for 0.6 "dock back"
park_mouse
wait_for 0.3 "settle"
if [[ -z "$(grep -m1 '^DOCK_FLOAT_EDITBAR=' "$QA_CFG")" ]]; then
    pass "double-clicking the grip docked it back"
else
    fail "still floating ($(grep -m1 '^DOCK_FLOAT_EDITBAR=' "$QA_CFG" | tr -d '\r'))"
fi

assert_no_crash
assert_window_exists
info "=== Dock: floating thin bar Test PASSED ==="
