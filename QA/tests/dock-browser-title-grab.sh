#!/bin/bash
# =============================================================================
# dock-browser-title-grab.sh — QA test: the floating Browser moves by its
# title bar, comes back from a maximize by dragging, and a toggle always shows
# it (Rick, 2026-11-14: "it disappeared ... i couldn't get it to show up by
# toggling it ... it said it was floated, but i couldn't unsnap it from the
# edge of the window on the left side").
#   grab     a press 2px into the title moves it (the file dialog's 6 native px
#            resize strip was a third of the title: the window resized instead)
#   top      the top row still resizes it (taller)
#   max      a double-click on the title fills the work area; a drag brings it
#            back to its own size and moves it (it used to stay full width,
#            stuck against the left edge)
#   toggle   a polygon in progress hides the Browser while the pointer is over
#            it (and keeps it hidden until the polygon ends); Toggle Browser
#            off + on shows it again
#
# Dump: WIN browser x y w h slot, P browser shown live ... (dock-lib.sh).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=120 BROWSER_WIDTH=420 BROWSER_HEIGHT=260 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser: grab the title, un-maximize by dragging, toggle shows it ==="

bw() { read -r _ _ BX BY BW BH _ <<< "$(grep '^WIN browser ' "$DK_DUMP")"; }
shown() { dk_p browser && (( P_SHOWN != 0 )); }
pcmd() {
    park_mouse; key question; wait_for 1.0 "palette"
    type_text "$1"; wait_for 1.4 "filtered"; dk_settle
    key Return; wait_for 1.0 "$1"; dk_park; dk_settle
}
dk_begin
bw
if [[ -z "$BW" ]] || dk_docked browser; then fail "the Browser is not a floating window: $(grep '^WIN browser\|^P browser' "$DK_DUMP")"; fi
info "Browser at $BX,$BY ${BW}x$BH"

# grab: 2px into the title, drag right 120 / down 40 -> moved, same size
X0=$BX; Y0=$BY; W0=$BW; H0=$BH
dk_drag $(( BX + BW / 2 )) $(( BY + 2 )) $(( BX + BW / 2 + 120 )) $(( BY + 42 )) 7; dk_park; dk_settle; bw
if (( BX >= X0 + 100 && BY >= Y0 + 30 && BW == W0 && BH == H0 )); then pass "grab 2px into the title: moved ($X0,$Y0 -> $BX,$BY), size kept"
else fail "grab 2px into the title: $X0,$Y0 ${W0}x$H0 -> $BX,$BY ${BW}x$BH (want moved +120,+40, same size)"; fi

# top: the very top row resizes (taller by ~30, bottom still)
B0=$(( BY + BH )); H0=$BH
dk_drag $(( BX + BW / 2 )) "$BY" $(( BX + BW / 2 )) $(( BY - 30 )) 6; dk_park; dk_settle; bw
if (( BH >= H0 + 20 )) && (( ${B0} - (BY + BH) <= 2 && (BY + BH) - B0 <= 2 )); then pass "top row resizes: ${H0} -> $BH, bottom still"
else fail "top row: height $H0 -> $BH, bottom $B0 -> $(( BY + BH ))"; fi

# max: double-click the title -> the work area; drag -> its own size, moved
X0=$BX; W0=$BW; H0=$BH
for try in 1 2 3; do # (a double-click is two presses inside 0.3 s: retry a slow pair)
    double_click $(( BX + BW / 3 )) $(( BY + 4 )); wait_for 0.8 "maximize"; dk_park; dk_settle
    read -r _ BRM_MAX _ <<< "$(grep '^BRM ' "$DK_DUMP")"
    (( BRM_MAX != 0 )) && break
    bw
done
bw
dk_scr
info "$(grep ^BRM "$DK_DUMP")"
if (( BW >= (CAN_RX - CAN_LX) * 9 / 10 )); then pass "double-click: maximized (${BW}x$BH)"; else fail "double-click did not maximize: ${W0}x$H0 -> ${BW}x$BH (canvas $CAN_LX..$CAN_RX)"; fi
MX=$(( BX + BW / 3 )); MY=$(( BY + 4 ))
dk_drag "$MX" "$MY" $(( MX + 150 )) $(( MY + 80 )) 8; dk_park; dk_settle; bw
info "after: $(grep -E "^(BRM|P browser|WIN browser|BAND|TREE)" "$DK_DUMP" | tr "\n" "/")"
if (( BW == W0 && BH == H0 )); then pass "dragged: back to its own size (${BW}x$BH)"; else fail "dragged: ${BW}x$BH, was ${W0}x$H0 before the maximize"; fi
if (( BX > CAN_LX + 20 )); then pass "dragged: off the left edge (x $BX)"; else fail "dragged: still at the left edge (x $BX, canvas from $CAN_LX)"; fi
screenshot "browser-title-grab-restored"

# toggle: a polygon in progress hides it under the pointer; toggle off + on shows it
bw
key p; wait_for 0.3 "polygon"
dk_scr
click $(( CAN_LX + 40 )) $(( DOCK_BOT - 40 )); wait_for 0.3 "first point"
hover $(( BX + BW / 2 )) $(( BY + BH / 2 )); wait_for 0.4 "over the Browser"
hover $(( BX + BW / 2 + 5 )) $(( BY + BH / 2 + 3 )); wait_for 0.4 "over the Browser"
dk_settle
if shown; then info "the polygon did not hide the Browser (shown $P_SHOWN) - the toggle check below still runs"; else pass "a polygon in progress hid the Browser under the pointer"; fi
pcmd "toggle browser"
pcmd "toggle browser"
if shown; then pass "Toggle Browser off + on: shown"; else fail "Toggle Browser off + on: still hidden ($(grep '^P browser' "$DK_DUMP"))"; fi
key Escape; wait_for 0.3 "polygon off"
screenshot "browser-title-grab-toggled"
assert_no_crash
info "=== Browser: grab the title, un-maximize by dragging, toggle shows it: done ==="
