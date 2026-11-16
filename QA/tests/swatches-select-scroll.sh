#!/bin/bash
# =============================================================================
# swatches-select-scroll.sh — QA test: selection in a set taller than the
# panel (swatches-ramps.gpl: 161 entries, scrolls) and docked:
#   Shift+click across a scroll, Ctrl+A = every entry, a box dragged below
#   the grid scrolls it, switching sets clears the selection, docked the
#   same clicks work.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-ramps.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"

info "=== Swatches: selection while scrolled / docked ==="
dk_begin
sw_read; sw_expect "entries" "$SW_N" 161
if (( SW_MAXS > 0 )); then pass "the grid scrolls (max $SW_MAXS)"; else fail "the grid does not scroll"; fi

sw_click 2; sw_sel; sw_expect "click 2" "$SS_LIST" "2"
sw_geo
for _ in 1 2 3 4 5 6; do scroll_down $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 )); done
dk_settle; sw_read
if (( SW_SCROLL > 0 )); then pass "scrolled ($SW_SCROLL px)"; else fail "did not scroll"; fi
# the last entry's cell is dumped; pick the first entry whose cell is inside the grid now
T=$(awk -v gy="$G_Y" -v gh="$G_H" '$1=="SWATC" && $2>48 && $2<160 && $4>=gy && $4+$6<=gy+gh && $7==0 {print $2; exit}' "$DK_DUMP")
if [[ -z "$T" ]]; then fail "no entry past 48 inside the scrolled grid"; else
    sw_click "$T" shift; sw_sel
    if (( SS_N == T - 1 )); then pass "Shift+click $T after scrolling: 2..$T ($SS_N selected)"; else fail "Shift+click $T: $SS_N selected, want $(( T - 1 ))"; fi
fi

# Ctrl+A: all 161 (no breaks in this set)
sw_cell "$T"; hover $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); sleep 0.2
key ctrl+a; dk_settle; sw_sel; sw_expect "Ctrl+A" "$SS_N" 161
key Escape; dk_settle

# back to the top, then a box from the strip right of the 8 columns (if the
# panel is wider than them) dragged below the grid: it scrolls
sw_geo
for _ in 1 2 3 4 5 6 7 8 9 10; do scroll_up $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 )); done
dk_settle; sw_read; sw_expect "back at the top" "$SW_SCROLL" 0
S0=$SW_SCROLL
sw_pitch
RX=$(( G_X + 8 * SW_PITCH + 2 ))
if (( RX < G_X + G_W - 1 )); then
    dk_drag "$RX" $(( G_Y + 4 )) $(( G_X + 2 )) $(( G_Y + G_H + 30 )) 10; dk_settle; sw_read; sw_sel
    if (( SW_SCROLL > S0 )); then pass "a box dragged below the grid scrolls it ($S0 -> $SW_SCROLL)"; else fail "box below the grid: no scroll ($S0 -> $SW_SCROLL)"; fi
    if (( SS_N >= 16 )); then pass "the box selected $SS_N"; else fail "the box selected only $SS_N"; fi
else
    info "no empty strip right of the columns at this width: box-scroll check skipped"
fi

# switching sets clears the selection: the set list's first row (the document palette)
for _ in 1 2 3 4 5 6 7 8 9 10; do scroll_up $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 )); done
dk_settle
sw_click 5; sw_sel; sw_expect "click 5" "$SS_LIST" "5"
sw_geo; click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); dk_settle
R=$(awk '$1=="SWATMI" && $4==100 {print; exit}' "$DK_DUMP")
read -r _ _ _ _ _ MX MY MW MH _ <<< "$R"
if [[ -n "$MX" ]]; then
    click $(( MX + MW / 2 )) $(( MY + MH / 2 )); dk_settle; sw_sel; sw_read
    if [[ "$SW_KEY" != "QA/fixtures/swatches-ramps.gpl" ]]; then pass "switched set ($SW_KEY)"; else fail "set did not switch"; fi
    sw_expect "switching sets clears the selection" "$SS_N" 0
else
    fail "no set list row to click"
fi
key Escape; dk_settle

# docked: the same clicks
dk_move_expect swatches above layers; dk_check "swatches docked"
sw_click 1; sw_click 3 shift; sw_sel
sw_expect "docked: click 1, Shift+click 3" "$SS_LIST" "1 2 3"
sw_click 2 ctrl; sw_sel
sw_expect "docked: Ctrl+click 2" "$SS_LIST" "1 3"
screenshot "swatches-select-docked"
assert_window_exists
info "=== Swatches: selection while scrolled / docked PASSED ==="
