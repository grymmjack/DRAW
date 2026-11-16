#!/bin/bash
# =============================================================================
# swatches-edit-edges.sh — QA test: Swatches edits at their edges, and that
# they survive a restart:
#   - nothing selected: L / DUPLICATE / DELETE / LOCK change nothing, make no
#     undo step and no My Swatches copy; L over the panel is never the Line tool
#   - REMOVE DUPLICATES keeps a locked duplicate; the unlocked one goes
#   - an inserted empty cell, a row break and a lock are saved: after a
#     restart the set reads back the same (order, cells, breaks, locks)
# Fixture swatches-edit.gpl: 1-8 reds, 9-12 greens (12 locked), 13 break,
# 14-19 blues, 20 empty, 21 Gold FFC800.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
tool_now() { awk '$1=="PAINT" {print $3; exit}' "$DK_DUMP"; }
locks() { awk '$1=="SWATC" && $9==1 {printf "%s%s", (n++ ? " " : ""), $8} END {print ""}' "$DK_DUMP"; }

info "=== Swatches: edits at their edges + a restart ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
key b; dk_settle
sw_read; sw_expect "entries" "$SW_N" 21
H0=$(sw_hexes)
sw_expect "locked at the start" "$(locks)" "00D200"

# A. nothing selected
sw_hover_panel; key l; dk_settle; sw_read; sw_edit_state
sw_expect "L with nothing selected: no lock" "$(locks)" "00D200"
sw_expect "L over the panel: still the brush (tool 1)" "$(tool_now)" 1
for id in 206 202 203; do sw_menu_edit; sw_menu_click $id; done
sw_read; sw_edit_state
sw_expect "DUPLICATE / DELETE / LOCK with nothing selected: entries" "$SW_N" 21
sw_expect "... every swatch as it was" "$(sw_hexes)" "$H0"
sw_expect "... no undo step" "$SE_UNDO" 0
sw_expect "... no copy in My Swatches" "$SE_MINE" 0
dk_park; key l; dk_settle
sw_expect "L over the canvas: the Line tool (4)" "$(tool_now)" 4
key b; dk_settle

# B. a locked duplicate stays
sw_click 21; sw_hover_panel; key Insert; dk_settle            # 22 = Gold, selected
sw_hover_panel; key l; dk_settle                               # lock 22
sw_edit_state; U0=$SE_UNDO
sw_menu_edit; sw_menu_click 207; sw_read; sw_edit_state
sw_expect "only the later Gold is a copy, and it is locked: entries" "$SW_N" 22
sw_expect "... no undo step" "$SE_UNDO" "$U0"
sw_click 22; sw_hover_panel; key l; dk_settle                  # unlock 22
sw_click 21; sw_hover_panel; key l; dk_settle                  # lock 21
sw_menu_edit; sw_menu_click 207; sw_read
sw_expect "the unlocked later Gold goes: entries" "$SW_N" 21
sw_cell 21; sw_expect "the locked Gold stays" "$C_HEX" "FFC800"
sw_expect "... locked" "$C_FLAGS" 1

# C. an empty cell, a row break and a lock; then a restart
sw_click 14; sw_menu_edit; sw_menu_click 205                   # a break before blue 1
sw_click 1; sw_menu_edit; sw_menu_click 204                    # an empty cell first
sw_click 2; sw_hover_panel; key l; dk_settle                   # lock Red 1 (now 2)
sw_read; sw_expect "after the edits: entries" "$SW_N" 23
H1=$(sw_hexes); L1=$(locks)
sw_expect "locked now" "$L1" "3C0000 00D200 FFC800"
sw_cell 1; sw_expect "entry 1 is an empty cell" "$C_KIND" 1
info "before the restart: $H1"
sw_relaunch_saved
dk_begin
sw_read; sw_edit_state
sw_expect "after a restart: entries" "$SW_N" 23
sw_expect "after a restart: the same swatches, cells and breaks" "$(sw_hexes)" "$H1"
sw_expect "after a restart: the same locks" "$(locks)" "$L1"
sw_expect "after a restart: in My Swatches" "$SE_MINE" 1
screenshot "swatches-edit-edges"
assert_window_exists
info "=== Swatches: edits at their edges PASSED ==="
