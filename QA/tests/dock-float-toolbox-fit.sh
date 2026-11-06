#!/bin/bash
# =============================================================================
# dock-float-toolbox-fit.sh — QA test: a floating toolbox's window is exactly
# its buttons. Resizing it snaps to the nearest button grid: no empty area
# beside or under the buttons, and a wide window holds every button in ONE
# row (more than the docked 8-column limit). One column works too.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: floating toolbox fits its buttons Test ==="
dk_begin
dk_scr
dk_move toolbox float $(( CAN_LX + 60 )) $(( DOCK_TOP + 60 ))
dk_expect_floating toolbox

# window vs the button grid: the BTN rects' extents must fill the window
fit_check() {
    local what=$1 bx1 by1 bx2 by2 rows cols
    dk_p toolbox
    read -r bx1 by1 bx2 by2 rows cols <<< "$(awk '$1=="BTN" && $2=="toolbox" {
        if (n==0 || $7<x1) x1=$7; if (n==0 || $8<y1) y1=$8
        if ($7+$9>x2) x2=$7+$9; if ($8+$10>y2) y2=$8+$10
        ys[$8]=1; xs[$7]=1; n++ }
        END { r=0; for (k in ys) r++; c=0; for (k in xs) c++; print x1, y1, x2, y2, r, c }' "$DK_DUMP")"
    info "$what: window $P_FX,$P_FY ${P_FW}x$P_FH, buttons $bx1,$by1-$bx2,$by2 ($cols cols x $rows rows)"
    local gapR=$(( P_FX + P_FW - bx2 )) gapB=$(( P_FY + P_FH - by2 ))
    if (( gapR >= 0 && gapR <= 4 )); then pass "$what: no gap right of the buttons ($gapR px)"; else fail "$what: ${gapR}px gap right of the buttons"; fi
    if (( gapB >= 0 && gapB <= 4 )); then pass "$what: no gap under the buttons ($gapB px)"; else fail "$what: ${gapB}px gap under the buttons"; fi
    FIT_ROWS=$rows; FIT_COLS=$cols
}

corner_drag() { # dx dy from the bottom-right corner
    dk_p toolbox
    local cx=$(( P_FX + P_FW - 2 )) cy=$(( P_FY + P_FH - 2 ))
    dk_drag "$cx" "$cy" $(( cx + $1 )) $(( cy + $2 ))
    dk_park; dk_settle
}

fit_check "floated"
# wide: as wide as the screen allows -> one row
corner_drag $(( SCR_W )) 0
fit_check "wide"
screenshot "dock-float-toolbox-wide"
if (( FIT_ROWS == 1 )); then pass "a wide floating toolbox shows every button in one row ($FIT_COLS)"; else fail "wide floating toolbox still has $FIT_ROWS rows"; fi
# narrow: as narrow as it goes -> one column (more if it would not fit the height)
corner_drag $(( -SCR_W )) 0
fit_check "narrow"
screenshot "dock-float-toolbox-narrow"
# one column, unless every button in one column would be taller than the work area
dk_scr
NBTN=$(awk '$1=="BTN" && $2=="toolbox"' "$DK_DUMP" | wc -l)
ROWH=$(( P_FH / FIT_ROWS ))
if (( FIT_COLS == 1 )); then
    pass "a narrow floating toolbox goes to one column"
elif (( (FIT_COLS - 1) > 0 && ROWH * ( (NBTN + FIT_COLS - 2) / (FIT_COLS - 1) ) > DOCK_BOT - DOCK_TOP + 1 )); then
    pass "a narrow floating toolbox has the fewest columns that fit the height ($FIT_COLS)"
else
    fail "narrow floating toolbox stuck at $FIT_COLS columns ($NBTN buttons, work area $(( DOCK_BOT - DOCK_TOP + 1 ))px)"
fi
# a height-only drag can't open a gap under the buttons
corner_drag 0 120
fit_check "taller"

assert_window_exists
info "=== Dock: floating toolbox fits its buttons Test PASSED ==="
