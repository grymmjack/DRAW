#!/bin/bash
# =============================================================================
# dock-after-combine.sh — QA test: once panels are combined, take them apart and
# rearrange them again:
#   - three tabs in one slot; drag the middle one out by its tab, then the active
#   - drag a whole tabbed slot by its title strip (the active tab moves)
#   - collapse a slot, then move it; expand it where it landed
#   - drag a divider, then move the lower panel away and back
#   - a three-panel stack: pull out the middle, the top, the bottom
# dk_check (QA/dock-lib.sh) after every step.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: rearrange after combining Test ==="
dk_begin

# three tabs: editbar and advbar join the layers
dk_move editbar tab layers;  dk_expect_tabs layers editbar; dk_check "editbar tab of layers"
dk_move advbar tab layers;   dk_expect_tabs layers advbar;  dk_check "advbar tab of layers"
dk_expect_tree 'layers\+editbar\+advbar' "three tabs in one slot"
# the middle tab out by its tab
dk_move editbar edge-right;  dk_expect_side editbar 2; dk_check "middle tab out to the right edge"
dk_expect_tabs layers advbar
# the active one out by its tab
dk_move advbar newcol editbar; dk_expect_docked advbar; dk_check "active tab out to a new column"
dk_expect_tree '^[^+]*$' "no tabs left"

# a tabbed slot moved by its strip: make drawer+organizer tabs, then grab the strip
dk_move organizer tab drawer; dk_expect_tabs drawer organizer; dk_check "organizer tab of drawer"
dk_p drawer; dk_slot "$P_SLOT"
GX=$(( S_X + S_W - 6 )); GY=$(( S_Y + 5 ))         # the strip, right of the tabs
dk_point edge-left
info "move the tabbed slot by its strip: ($GX,$GY) -> ($TX,$TY)"
dk_drag "$GX" "$GY" "$TX" "$TY"; dk_park; dk_settle
dk_check "tabbed slot dragged by its strip"
dk_expect_tabs drawer organizer
dk_expect_side drawer 1
dk_expect_side organizer 1
screenshot "dock-after-combine-strip"

# collapse a slot (chevron), then move it, then expand it where it is
dk_move layers tab editbar; dk_expect_tabs editbar layers; dk_check "layers tab of editbar"
dk_p layers; dk_slot "$P_SLOT"
click $(( S_X + 3 )) $(( S_Y + 5 )); dk_park; dk_settle
dk_slot "$P_SLOT"
if (( S_COLL != 0 )); then pass "slot collapsed by its chevron"; else fail "chevron did not collapse the slot"; fi
dk_check "collapsed"
dk_move layers edge-left; dk_expect_side layers 1; dk_check "collapsed tab dragged out"
dk_p editbar; dk_slot "$P_SLOT"
if (( S_COLL != 0 )) && dk_grab_point editbar; then click "$GX" "$GY"; dk_park; dk_settle; fi  # its tab (any click opens a collapsed slot)
dk_p editbar; dk_slot "$P_SLOT"
if (( S_COLL == 0 )); then pass "the slot left behind opens with a click"; else fail "slot left behind still collapsed"; fi
dk_check "expanded"

# a divider, then move the lower panel out and back
dk_move editbar below layers; dk_expect_stacked layers editbar; dk_check "editbar under layers"
dk_p editbar; dk_slot "$P_SLOT"
dk_drag $(( S_X + S_W / 2 )) $(( S_Y - 2 )) $(( S_X + S_W / 2 )) $(( S_Y - 120 )) 5; dk_park; dk_settle
dk_p editbar; dk_slot "$P_SLOT"; NEWY=$S_Y
dk_check "divider dragged"
dk_move editbar edge-right; dk_expect_side editbar 2; dk_check "lower panel out after a divider drag"
dk_move editbar below layers; dk_expect_stacked layers editbar; dk_check "and back under the layers"
dk_p layers; LH=$P_H; dk_p editbar
if (( P_H >= 40 && LH >= 40 )); then pass "both keep a usable height (layers $LH, editbar $P_H)"; else fail "a sliver: layers $LH, editbar $P_H"; fi

# a three-panel stack: middle out, top out, bottom out
dk_move advbar below editbar; dk_expect_stacked editbar advbar; dk_check "three stacked"
dk_move editbar float;        dk_expect_floating editbar; dk_check "middle out (float)"
dk_expect_stacked layers advbar
dk_move layers edge-right;    dk_expect_side layers 2; dk_check "top out"
dk_move advbar newcol layers; dk_expect_docked advbar; dk_check "bottom out"
dk_grab_point editbar && double_click "$GX" "$GY"; dk_park; dk_settle
dk_expect_docked editbar; dk_check "floating one docked back"
screenshot "dock-after-combine-end"

assert_window_exists
info "=== Dock: rearrange after combining Test PASSED ==="
