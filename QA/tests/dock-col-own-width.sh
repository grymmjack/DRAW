#!/bin/bash
# =============================================================================
# dock-col-own-width.sh — QA test: a dock column without the toolbox / layers /
# a bar (here the organizer + drawer, docked in a column next to the toolbox)
# has its OWN width edge, and is not ganged to the toolbox's width:
#   - it starts as narrow as its panels go (one organizer stack), not the
#     toolbox's 2-column width
#   - dragging its inner edge widens it; the toolbox keeps its width
#   - dragging the toolbox's edge resizes the toolbox only (3 -> 2 columns:
#     the QA window is too short for 28 buttons in one)
# Rick, 2026-11-06: "each dock is stuck with the left most one deciding all the
# columns for all the panels".
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLBOX_COLUMNS=3
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: a column's own width Test ==="
dk_begin

dk_move organizer newcol toolbox
dk_move drawer below organizer && dk_expect_stacked organizer drawer
dk_check "organizer + drawer in their own column"

colw() { # name -> CX CW CSIDE
    dk_p "$1"; dk_slot "$P_SLOT"; dk_col "$S_COL"; CX=$C_X; CW=$C_W; CSIDE=$C_SIDE; CY=$C_Y; CH=$C_H
}
colw toolbox; TB_X=$CX; TB_W=$CW
colw organizer; OR_X=$CX; OR_W=$CW; OR_SIDE=$CSIDE; OR_Y=$CY
info "toolbox column x=$TB_X w=$TB_W; organizer column x=$OR_X w=$OR_W (side $OR_SIDE)"
(( OR_X != TB_X )) || fail "the organizer is not in a column of its own"
if (( OR_W < TB_W )); then pass "the organizer's column is narrower than the toolbox's ($OR_W < $TB_W)"; else fail "the organizer's column has the toolbox's width ($OR_W vs $TB_W)"; fi

# its inner edge: the side facing the canvas
inner_x() { if (( $1 == 1 )); then echo $(( $2 + $3 )); else echo "$2"; fi; } # side x w
grow_dx() { if (( $1 == 1 )); then echo 40; else echo -40; fi; }
EX=$(inner_x "$OR_SIDE" "$OR_X" "$OR_W"); EY=$(( OR_Y + 60 ))
info "drag the organizer column's edge at $EX,$EY"
dk_drag "$EX" "$EY" $(( EX + $(grow_dx "$OR_SIDE") )) "$EY"
dk_park; dk_settle
colw organizer; OR_W2=$CW
colw toolbox; TB_W2=$CW
if (( OR_W2 > OR_W + 20 )); then pass "the organizer's column widened by its own edge ($OR_W -> $OR_W2)"; else fail "the organizer's column did not widen ($OR_W -> $OR_W2)"; fi
if (( TB_W2 == TB_W )); then pass "the toolbox kept its width ($TB_W)"; else fail "the toolbox changed width with it ($TB_W -> $TB_W2)"; fi
screenshot "dock-col-own-width-wide"

# the toolbox's edge: one column narrower; the organizer column stays
colw toolbox; TB_SIDE=$CSIDE; TB_X=$CX
EX=$(inner_x "$TB_SIDE" "$TB_X" "$TB_W2"); EY=$(( CY + 20 ))
info "drag the toolbox column's edge at $EX,$EY"
dk_drag "$EX" "$EY" $(( EX - $(grow_dx "$TB_SIDE") )) "$EY"
dk_park; dk_settle
colw toolbox; TB_W3=$CW
colw organizer; OR_W3=$CW
if (( TB_W3 < TB_W2 )); then pass "the toolbox narrowed by its edge ($TB_W2 -> $TB_W3)"; else fail "the toolbox did not narrow ($TB_W2 -> $TB_W3)"; fi
if (( OR_W3 == OR_W2 )); then pass "the organizer's column kept its width ($OR_W2)"; else fail "the organizer's column changed with the toolbox ($OR_W2 -> $OR_W3)"; fi

# narrow the organizer column back as far as it goes: one stack
colw organizer
EX=$(inner_x "$OR_SIDE" "$CX" "$CW"); EY=$(( OR_Y + 60 ))
dk_drag "$EX" "$EY" $(( EX - 3 * $(grow_dx "$OR_SIDE") )) "$EY"
dk_park; dk_settle
colw organizer; OR_W4=$CW
if (( OR_W4 == OR_W )); then pass "the organizer's column narrows back to one stack ($OR_W4)"; else fail "the organizer's column narrowest is $OR_W4 (was $OR_W)"; fi

assert_window_exists
info "=== Dock: a column's own width Test PASSED ==="
