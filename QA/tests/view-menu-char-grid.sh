#!/bin/bash
# =============================================================================
# view-menu-char-grid.sh — QA test: View > Char Grid sits with the grids.
#
# Rick 2026-11-14: "move view | char grid under the other grid options but
# before the grid adjustments". It was in the panel list (after Browser); now
# Grid, Make Grid Brush Size, Pixel Grid, Frame Grid, CHAR GRID, then Increase /
# Decrease Grid Size.
#
# Dump: MROOT view x w; MENUI <action id>... = the open menu's rows in order
# (0 = a divider). Grid 901, Pixel 902, Frame 2500, Char 2053, Increase 904,
# Browser 2022.
#
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== View menu: Char Grid with the grids ==="

VM_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
vm_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
vm_line() { vm_settle; grep -m1 "^$1" "$VM_DUMP" 2>/dev/null; }

read -r _ _ VX VW <<< "$(vm_line 'MROOT view ')"
if [[ -z "$VX" ]]; then
    fail "no VIEW menu in the dump"
else
    click $(( VX + VW / 2 )) 6; wait_for 0.6 "VIEW menu open"
    VI=$(vm_line 'MENUI' | cut -d' ' -f2-)
    [[ -n "$VI" ]] || fail "no MENUI line with the VIEW menu open"
    # the ids in order, padded so whole numbers match
    VS=" $VI "
    [[ "$VS" == *" 2500 2053 904 "* ]] && pass "Frame Grid, Char Grid, Increase Grid Size in a row" || fail "order around Char Grid: [$VI]"
    [[ "$VS" == *" 901 907 902 2500 2053 "* ]] && pass "the grid toggles, then Char Grid" || fail "grid rows: [$VI]"
    [[ "$VS" != *" 2022 2053 "* ]] && pass "no longer right after Browser" || fail "still after Browser: [$VI]"
    (( $(grep -o ' 2053 ' <<< "$VS" | wc -l) == 1 )) && pass "Char Grid listed once" || fail "Char Grid count: [$VI]"
    screenshot "view-menu-char-grid"
    key Escape; wait_for 0.4 "closed"
fi
assert_no_crash
info "=== View menu: Char Grid with the grids: done ==="
