#!/bin/bash
# =============================================================================
# dock-toolbox-under-layers.sh — QA test: the toolbox docked under the layers
# follows the layers' width. Widening the layers' column past 8 toolbox columns
# lays the buttons out in more columns (and fewer rows: the toolbox gets
# shorter, the layers get the height back). It used to stop the whole column at
# the toolbox's 8-column maximum.
# Rick, 2026-11-06: "the layer panel can only resize to the max of the toolbox
# in 8 columns - it should ... go as far as the layer panel can to make the
# buttons just stack in as many rows/columns as needed".
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: toolbox under the layers follows their width Test ==="
dk_begin

colw() { dk_p "$1"; dk_slot "$P_SLOT"; dk_col "$S_COL"; CX=$C_X; CW=$C_W; CSIDE=$C_SIDE; CY=$C_Y; }
inner_x() { if (( $1 == 1 )); then echo $(( $2 + $3 )); else echo "$2"; fi; }
out_dx()  { if (( $1 == 1 )); then echo "$2"; else echo $(( - $2 )); fi; }
tb_grid() { # TBC columns, TBR rows, TBRX rightmost button edge
    TBC=$(awk '$1 == "BTN" && $2 == "toolbox" {print $(NF-3)}' "$DK_DUMP" | sort -un | wc -l)
    TBR=$(awk '$1 == "BTN" && $2 == "toolbox" {print $(NF-2)}' "$DK_DUMP" | sort -un | wc -l)
    TBRX=$(awk '$1 == "BTN" && $2 == "toolbox" {r = $(NF-3) + $(NF-1); if (r > m) m = r} END {print m + 0}' "$DK_DUMP")
    # button pitch: the step between the first two column x's (scale-aware)
    PITCH=$(awk '$1 == "BTN" && $2 == "toolbox" {print $(NF-3)}' "$DK_DUMP" | sort -un | head -2 | awk 'NR==1 {a=$1} NR==2 {print $1 - a}')
}

dk_move_expect toolbox below layers; dk_check "toolbox under the layers"
colw layers; W0=$CW; dk_p toolbox; TH0=$P_H; tb_grid; C0=$TBC
info "column $W0 wide, toolbox $C0 columns x $TBR rows, ${TH0}px tall"

EX=$(inner_x "$CSIDE" "$CX" "$CW"); EY=$(( CY + 40 ))
dk_drag "$EX" "$EY" $(( EX + $(out_dx "$CSIDE" 300) )) "$EY"
dk_park; dk_settle
colw layers; W1=$CW; dk_p toolbox; TH1=$P_H; TBX=$P_X; TBW=$P_W; tb_grid
info "after +300: column $W1 wide, toolbox $TBC columns x $TBR rows, ${TH1}px tall"
if (( W1 > W0 + 150 )); then pass "the layers' column widens ($W0 -> $W1)"; else fail "the column stopped at $W1 (was $W0, dragged +300)"; fi
if (( W1 >= 9 * PITCH + 4 )); then
    if (( TBC > 8 )); then pass "room for 9+ columns: the toolbox lays out in $TBC"; else fail "room for 9+ columns ($W1 px, ${PITCH}px buttons) but the toolbox stays at $TBC"; fi
else
    info "only $(( W1 / PITCH )) columns fit $W1 px at ${PITCH}px buttons"
fi
if (( TH1 < TH0 )); then pass "the toolbox gets shorter ($TH0 -> $TH1)"; else fail "the toolbox did not get shorter ($TH0 -> $TH1)"; fi
C1=$TBC
GAP=$(( TBX + TBW - TBRX ))
if (( GAP < PITCH )); then pass "the buttons fill the width (${GAP}px right, under one ${PITCH}px button)"; else fail "${GAP}px gap right of the toolbox buttons (room for another ${PITCH}px column)"; fi
screenshot "dock-toolbox-under-layers-wide"

# narrower again: fewer columns, taller
EX=$(inner_x "$CSIDE" "$CX" "$CW")
dk_drag "$EX" "$EY" $(( EX - $(out_dx "$CSIDE" 200) )) "$EY"
dk_park; dk_settle
colw layers; W2=$CW; dk_p toolbox; TH2=$P_H; tb_grid
if (( W2 < W1 && TBC < C1 && TH2 > TH1 )); then pass "narrowed back: $W2 wide, $TBC columns, ${TH2}px tall"; else fail "narrowed back: $W2 wide, $TBC columns, ${TH2}px tall (was $W1 / $C1 columns / ${TH1}px)"; fi
assert_window_exists
info "=== Dock: toolbox under the layers follows their width Test PASSED ==="
