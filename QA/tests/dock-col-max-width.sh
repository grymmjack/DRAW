#!/bin/bash
# =============================================================================
# dock-col-max-width.sh — QA test: a column holding only the organizer (or only
# the drawer) widens by its edge up to what the panel can fill - all organizer
# stacks side by side / the drawer's widest bin grid - and stops there. It used
# to follow the mouse up to 600 px (the layers' cap), leaving black bars right
# of the panel.
# Rick, 2026-11-06: "when i just dock the organizer, i can resize the panel
# super wide ... it shouldn't if it's the only thing docked".
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: a lone organizer / drawer column stops at its widest Test ==="
dk_begin

colw() { dk_p "$1"; dk_slot "$P_SLOT"; dk_col "$S_COL"; CX=$C_X; CW=$C_W; CSIDE=$C_SIDE; CY=$C_Y; }
inner_x() { if (( $1 == 1 )); then echo $(( $2 + $3 )); else echo "$2"; fi; } # side x w
out_dx()  { if (( $1 == 1 )); then echo "$2"; else echo $(( - $2 )); fi; }

try_alone() { # $1 = panel, $2 = a panel to put it next to
    dk_move "$1" newcol "$2"
    dk_check "$1 alone in its own column"
    colw "$1"; local W0=$CW EX EY W1 W2
    EX=$(inner_x "$CSIDE" "$CX" "$CW"); EY=$(( CY + 40 ))
    dk_drag "$EX" "$EY" $(( EX + $(out_dx "$CSIDE" 300) )) "$EY"
    dk_park; dk_settle; colw "$1"; W1=$CW
    info "$1: column $W0 -> $W1 after a 300 px drag"
    if (( W1 > W0 )); then pass "$1: the column widens ($W0 -> $W1)"; else fail "$1: the column did not widen ($W0 -> $W1)"; fi
    if (( W1 < W0 + 280 )); then pass "$1: it stops at the panel's widest ($W1), not at the mouse"; else fail "$1: the column followed the mouse to $W1 px (black bars right of the panel)"; fi
    EX=$(inner_x "$CSIDE" "$CX" "$CW")
    dk_drag "$EX" "$EY" $(( EX + $(out_dx "$CSIDE" 100) )) "$EY"
    dk_park; dk_settle; colw "$1"; W2=$CW
    if (( W2 == W1 )); then pass "$1: further out it stays at $W1"; else fail "$1: further out it went $W1 -> $W2"; fi
    screenshot "dock-col-max-$1"
}

try_alone organizer layers
try_alone drawer layers
assert_window_exists
info "=== Dock: a lone organizer / drawer column stops at its widest Test PASSED ==="
