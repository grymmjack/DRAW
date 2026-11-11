#!/bin/bash
# =============================================================================
# swatches-list-recent.sh — QA test: the gear's VIEW: LIST, the recent colors
# row, and Find FG.
#   LIST: one full-width row per swatch (a row break = a divider row), clicks
#     and Shift ranges as in the grid, a drag drops above / below a row; the
#     view is saved (SWATCHES_VIEW); GRID puts it back
#   RECENT COLORS ROW: the FG colors used last, newest first, each once;
#     click = FG, right-click = BG; kept across a restart
#   F over the panel / ☰ FIND FG COLOR: selects the FG's swatch (scrolled to),
#     else the nearest in OKLab; the FG itself is not changed
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
sw_view() { read -r _ SV_VIEW SV_RSHOWN SV_RN <<< "$(grep '^SWATV ' "$DK_DUMP")"; }
sw_rec_hexes() { awk '$1=="SWATR" && $7!="-" {printf "%s%s", (n++ ? " " : ""), $7} END {print ""}' "$DK_DUMP"; }
sw_rec_xy() { read -r _ _ RX RY RW RH _ <<< "$(awk -v k="$1" '$1=="SWATR" && $2==k' "$DK_DUMP")"; TX=$(( RX + RW / 2 )); TY=$(( RY + RH / 2 )); }
sw_gear() { sw_geo; click $(( E_X + E_W / 2 )) $(( E_Y + E_H / 2 )); dk_settle; }
gear_check() { # ID: click the gear's check row id
    local r mx my mw mh
    sw_menu_find "$1"; read -r _ _ _ _ _ mx my mw mh _ <<< "$SM_ROW"
    [[ -z "$mx" ]] && { fail "no gear row $1"; return 1; }
    click $(( mx + mw / 2 )) $(( my + mh / 2 )); dk_settle
}

info "=== Swatches: list view, recent colors, Find FG ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; sw_view
sw_expect "starts as a grid" "$SV_VIEW" 0
sw_expect "no recent row by default" "$SV_RSHOWN" 0
HEX0=$(sw_hexes)

# --- LIST ---
sw_gear; sw_chip_click 32 LIST; key Escape; dk_settle; sw_read; sw_view
sw_expect "VIEW LIST" "$SV_VIEW" 1
sw_expect "one column" "$SW_COLS" 1
sw_cell 1; Y1=$C_Y; W1=$C_W; sw_cell 2; Y2=$C_Y; X2=$C_X
sw_geo
if (( Y2 > Y1 && X2 == $(sw_cell 1; echo $C_X) )); then pass "rows stack (y $Y1, $Y2)"; else fail "entry 2 at $X2,$Y2 (entry 1 y $Y1)"; fi
if (( W1 * 10 >= G_W * 8 )); then pass "a row is the grid's width ($W1 of $G_W)"; else fail "row width $W1 of $G_W"; fi
sw_cell 12; Y12=$C_Y; RH=$(( Y2 - Y1 )); sw_cell 14; Y14=$C_Y
sw_expect "a row break is a divider row (entry 14 two rows below 12)" "$(( (Y14 - Y12) / RH ))" 2
sw_expect "the order is the set's" "$(sw_hexes)" "$HEX0"
grep -q '^SWATCHES_VIEW=1' "$QA_CFG" && pass "SWATCHES_VIEW=1 saved" || fail "SWATCHES_VIEW not saved ($(grep '^SWATCHES_VIEW' "$QA_CFG"))"
sw_click 3; sw_read; sw_expect "a click: FG = entry 3" "$SW_FG" 3
sw_click 5 shift; sw_sel; sw_expect "Shift+click: 3 selected" "$SS_N" 3
screenshot "swatches-list"
# drag entry 1 below entry 2 (the lower half of row 2)
sw_click 1; sw_cell 2; TX=$(( C_X + C_W / 2 )); TY=$(( C_Y + C_H - 2 ))
sw_drag_entry 1
sw_expect "drag in the list: drop after entry 2" "$SD_DROP" 3
sw_expect "... the first two swapped" "$(sw_hexes | cut -d' ' -f1-3)" "550000 3C0000 6E0000"
sw_hover_panel; key ctrl+z; dk_settle
sw_expect "Ctrl+Z puts it back" "$(sw_hexes)" "$HEX0"
sw_gear; sw_chip_click 32 GRID; key Escape; dk_settle; sw_read; sw_view
sw_expect "VIEW GRID again" "$SV_VIEW" 0
sw_expect "the set's 8 columns again" "$SW_COLS" 8

# --- RECENT ---
sw_gear; gear_check 18; key Escape; dk_settle; sw_view
if (( SV_RSHOWN > 0 )); then pass "RECENT COLORS ROW: $SV_RSHOWN slots"; else fail "no recent row ($SV_RSHOWN)"; fi
sw_click 1; sw_click 9; sw_click 14; sw_click 9; dk_park; dk_settle
sw_expect "newest first, each once" "$(sw_rec_hexes | cut -d' ' -f1-3)" "003C00 00003C 3C0000"
sw_rec_xy 3; click "$TX" "$TY"; dk_settle; sw_read
sw_expect "a recent chip click: FG" "$SW_FG" 1
sw_expect "... and moves to the front" "$(sw_rec_hexes | cut -d' ' -f1-3)" "3C0000 003C00 00003C"
sw_rec_xy 3; right_click "$TX" "$TY"; dk_settle; sw_read
sw_expect "a right-click: BG" "$SW_BG" 14
sw_expect "... (the BG is not a recent FG)" "$(sw_rec_hexes | cut -d' ' -f1)" "3C0000"
screenshot "swatches-recent"
REC=$(sw_rec_hexes | cut -d' ' -f1-3)
wait_for 2.0 "the recent colors saved"
grep -q "^SWATCHES_RECENT_COLORS=${REC// /,}" "$QA_CFG" && pass "SWATCHES_RECENT_COLORS saved" || fail "SWATCHES_RECENT_COLORS = $(grep '^SWATCHES_RECENT_COLORS' "$QA_CFG")"
grep -q '^SWATCHES_RECENT=TRUE' "$QA_CFG" && pass "SWATCHES_RECENT=TRUE saved" || fail "SWATCHES_RECENT not saved"
sw_relaunch_saved
sw_view; sw_expect "after a restart: the row" "$(( SV_RSHOWN > 0 ))" 1
sw_expect "after a restart: the colors" "$(sw_rec_hexes | cut -d' ' -f1-3)" "$REC"

# --- FIND FG ---
sw_click 5; sw_hover_panel; key Escape; dk_settle; sw_sel
sw_expect "nothing selected" "$SS_N" 0
sw_hover_panel; key f; dk_settle; sw_sel; sw_read
sw_expect "F: the FG's swatch selected" "$SS_LIST" "5"
sw_expect "F: the FG unchanged" "$SW_FG" 5
sw_strip_xy 0; click "$TX" "$TY"; dk_settle    # the strip's black
sw_menu_edit; sw_menu_click 224; sw_sel
sw_expect "FIND FG COLOR, black: the nearest (00003C, entry 14)" "$SS_LIST" "14"
sw_strip; sw_expect "the FG is still black" "$(cut -d' ' -f$(( SP_FG + 1 )) <<< "$SP_HEX")" "000000"
assert_window_exists
info "=== Swatches: list view, recent colors, Find FG PASSED ==="
