#!/bin/bash
# =============================================================================
# swatches-panel.sh — QA test: the Swatches panel (View > Swatches, GUI/SWATCHES).
# A .gpl fixture (8 columns, 160 colors, one empty cell) shows in the set's own
# columns; left-click a swatch = FG, right-click = BG; the wheel scrolls the
# grid; the gear's COLUMNS chips change the layout (16, then back to the set's
# own); the set list opens and closes; it docks above the layers and floats again.
# State comes from the SWAT* lines GUI/SWATCHES.BM adds to the dock dump.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-ramps.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

sw_read() { read -r _ SW_N SW_COLORS SW_COLS SW_CW SW_CH SW_GAP SW_ROWS SW_SCROLL SW_MAXS SW_FG SW_BG SW_MENU SW_MROWS SW_KEY <<< "$(grep '^SWAT ' "$DK_DUMP")"; }
sw_geo()  { read -r _ G_X G_Y G_W G_H B_X B_Y B_W B_H E_X E_Y E_W E_H <<< "$(grep '^SWATG ' "$DK_DUMP")"; }
sw_cell() { read -r _ _ C_X C_Y C_W C_H C_KIND C_HEX <<< "$(grep "^SWATC $1 " "$DK_DUMP")"; }
# the chip labelled $2 in the chips row with id $1
sw_chip() { read -r _ _ _ K_X K_Y K_W K_H _ <<< "$(awk -v id="$1" -v lb="$2" '$1=="SWATMC" && $2==id && $8==lb' "$DK_DUMP" | head -1)"; }
sw_expect() { # LABEL VALUE WANT
    if [[ "$2" == "$3" ]]; then pass "$1 = $3"; else fail "$1 = '$2', want '$3'"; fi
}

info "=== Swatches panel ==="
dk_begin
if ! grep -q '^SWAT ' "$DK_DUMP"; then fail "no Swatches panel in the dump (SWAT line missing)"; fi
sw_read
sw_expect "entries" "$SW_N" 161
sw_expect "colors" "$SW_COLORS" 160
sw_expect "columns (the set's own)" "$SW_COLS" 8
sw_expect "set" "$SW_KEY" "QA/fixtures/swatches-ramps.gpl"
sw_cell 6; sw_expect "entry 6 kind (empty cell)" "$C_KIND" 1
dk_check "start"

# left-click = FG, right-click = BG
sw_cell 3
click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); dk_park; dk_settle; sw_read
sw_expect "FG after clicking swatch 3" "$SW_FG" 3
sw_cell 10
right_click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); dk_park; dk_settle; sw_read
sw_expect "BG after right-clicking swatch 10" "$SW_BG" 10
sw_expect "FG unchanged by the right-click" "$SW_FG" 3

# the wheel scrolls the grid
sw_geo
if (( SW_MAXS > 0 )); then pass "grid scrolls (max $SW_MAXS)"; else fail "grid does not scroll (max $SW_MAXS)"; fi
scroll_down $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 )); scroll_down $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 ))
dk_park; dk_settle; sw_read
if (( SW_SCROLL > 0 )); then pass "wheel scrolled the grid ($SW_SCROLL px)"; else fail "wheel did not scroll the grid"; fi
scroll_up $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 )); scroll_up $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 ))
scroll_up $(( G_X + G_W / 2 )) $(( G_Y + G_H / 2 ))
dk_park; dk_settle; sw_read
sw_expect "scrolled back to the top" "$SW_SCROLL" 0

# the gear: COLUMNS 16, then SET (the set's own 8)
sw_geo
click $(( E_X + E_W / 2 )) $(( E_Y + E_H / 2 )); dk_settle; sw_read
sw_expect "gear menu open" "$SW_MENU" 2
sw_chip 10 16
if [[ -z "$K_X" ]]; then fail "no COLUMNS 16 chip in the gear menu"; else
    click $(( K_X + K_W / 2 )) $(( K_Y + K_H / 2 )); dk_settle; sw_read
    sw_expect "columns after the 16 chip" "$SW_COLS" 16
    sw_expect "gear menu stays open after a chip" "$SW_MENU" 2
fi
sw_chip 10 SET
if [[ -z "$K_X" ]]; then fail "no COLUMNS SET chip in the gear menu"; else
    click $(( K_X + K_W / 2 )) $(( K_Y + K_H / 2 )); dk_settle; sw_read
    sw_expect "columns after the SET chip" "$SW_COLS" 8
fi
screenshot "swatches-gear"
key Escape; dk_park; dk_settle; sw_read
sw_expect "Escape closes the menu" "$SW_MENU" 0

# the set list opens (the document palette + the shipped sets) and closes
sw_geo
click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); dk_settle; sw_read
sw_expect "set list open" "$SW_MENU" 1
if (( SW_MROWS >= 5 )); then pass "set list has $SW_MROWS rows"; else fail "set list has only $SW_MROWS rows"; fi
screenshot "swatches-sets"
click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); dk_park; dk_settle; sw_read
sw_expect "set list closed by its button" "$SW_MENU" 0
sw_expect "set unchanged" "$SW_KEY" "QA/fixtures/swatches-ramps.gpl"

# dock it above the layers, then float it again
dk_move_expect swatches above layers; dk_check "swatches above the layers"
sw_read
sw_expect "entries while docked" "$SW_N" 161
# docked, the set list reaches past the column: drawn over the dock seam
sw_geo
click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); dk_settle; sw_read
sw_expect "docked: set list open" "$SW_MENU" 1
screenshot "swatches-docked-sets"
key Escape; dk_park; dk_settle; sw_read
sw_expect "docked: Escape closes the set list" "$SW_MENU" 0
dk_move_expect swatches float; dk_check "swatches floating again"
sw_read
sw_expect "entries floating again" "$SW_N" 161
screenshot "swatches-panel-end"
assert_window_exists
info "=== Swatches panel PASSED ==="
