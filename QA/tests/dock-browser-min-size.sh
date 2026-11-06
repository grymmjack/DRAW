#!/bin/bash
# =============================================================================
# dock-browser-min-size.sh — QA test: a docked Browser never draws bigger than
# its band (or slot). Its minimum is 180x120 FILE-DIALOG px; at a render scale
# of 2 that is 360x240 viewport px, but the dock once reserved only 180x120 /
# an 80px band, so a short band drew the Browser 240 tall - over the status bar
# and palette strip (bottom band) or into the canvas (top band).
# SCALE_RATIO_BROWSER=2 at the QA display scale 2 -> render scale 2.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 SCALE_RATIO_BROWSER=2
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: docked Browser stays inside its band Test ==="
dk_begin
dk_move_expect browser band-bottom; dk_check "browser along the bottom"

win_browser() { read -r _ _ W_X W_Y W_W W_H _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"; }
check_inside() {
    dk_band; win_browser
    info "$1: band y=$B_Y h=$B_H, browser drawn y=$W_Y h=$W_H"
    [[ -n "$W_H" ]] || { fail "$1: no WIN browser line"; return; }
    if (( W_Y >= B_Y && W_Y + W_H <= B_Y + B_H )); then
        pass "$1: the Browser is drawn inside its band"
    else
        fail "$1: the Browser spills out of its band (drawn $W_Y..$(( W_Y + W_H - 1 )), band $B_Y..$(( B_Y + B_H - 1 )))"
    fi
}

# shrink the band as far as it goes: drag its top edge down to the bottom
dk_band; dk_scr
EX=$(( B_X + B_W / 2 ))
drag "$EX" "$B_Y" "$EX" $(( SCR_H - 4 ))
wait_for 0.5 "band resized"
dk_park; dk_settle
check_inside "shortest bottom band"
screenshot "dock-browser-min-band"

# a top band at its shortest too
dk_move_expect browser band-top; dk_check "browser along the top"
dk_band
drag "$EX" $(( B_Y + B_H - 1 )) "$EX" $(( B_Y + 2 ))
wait_for 0.5 "band resized"
dk_park; dk_settle
check_inside "shortest top band"

assert_window_exists
info "=== Dock: docked Browser stays inside its band Test PASSED ==="
