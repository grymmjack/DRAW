#!/bin/bash
# =============================================================================
# swatches-ramp-sort.sh — QA test: ramps and sorting from the ☰ menu:
#   - SORT chips: REV / LIGHT / LUMA on the selection (2+ selected), HUE on the
#     whole set; locked swatches, empty cells and row breaks keep their places;
#     an order that is already right is no edit
#   - RAMP FIRST > LAST blends the colors between the first and last selected;
#     the ends, a locked swatch and an empty cell stay; a second ramp is no edit
#   - STEPS chips (saved as RAMP_STEPS); INSERT RAMP FG > BG after the
#     selection; INSERT OKLCH RAMP FROM FG at the end; the new ones selected
#   - undo all = the file again
# Fixture swatches-edit.gpl: 1-8 reds 3C 55 6E 87 A0 B9 D2 EB, 9-12 greens (12
# locked), 13 break, 14-19 blues, 20 empty, 21 Gold FFC800.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
hexes_of() { local k out=""; for k in "$@"; do sw_cell "$k"; out+="${out:+ }$C_HEX"; done; echo "$out"; }
sort_by() { sw_menu_edit; sw_chip_click 31 "$1"; sw_read; sw_edit_state; }
REDS="3C0000 550000 6E0000 870000 A00000 B90000 D20000 EB0000"
REDS_REV="EB0000 D20000 B90000 A00000 870000 6E0000 550000 3C0000"

info "=== Swatches: ramps and sorting ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
H0=$(sw_hexes)

# A. sorting the selection
sw_click 1; sw_click 8 shift
sort_by REV
sw_expect "REV on 1-8" "$(hexes_of 1 2 3 4 5 6 7 8)" "$REDS_REV"
sw_expect "... one undo step" "$SE_UNDO" 1
sort_by LIGHT
sw_expect "LIGHT on 1-8: dark to light" "$(hexes_of 1 2 3 4 5 6 7 8)" "$REDS"
sw_expect "... another step" "$SE_UNDO" 2
sort_by LIGHT
sw_expect "LIGHT again: already in order, no step" "$SE_UNDO" 2
sw_click 1; sw_click 19 ctrl; sw_click 21 ctrl
sort_by REV
sw_expect "REV on 1, 19, 21" "$(hexes_of 1 19 21)" "FFC800 0000EB 3C0000"
sort_by LUMA
sw_expect "LUMA on them: dark red, blue, gold" "$(hexes_of 1 19 21)" "3C0000 0000EB FFC800"
sw_expect "... the others in between unchanged" "$(hexes_of 2 18)" "550000 0000C8"

# B. HUE on the whole set (nothing selected): locked / empty / break stay
key Escape; dk_settle; sw_hover_panel; key Escape; dk_settle
sort_by HUE
sw_expect "HUE on the set: entries" "$SW_N" 21
sw_cell 12; sw_expect "the locked green stays 12" "$C_HEX" "00D200"
sw_cell 20; sw_expect "the empty cell stays 20" "$C_KIND" 1
if [[ "$(sw_hexes)" == *" | "* ]]; then pass "the row break is still there"; else fail "the row break moved or went: $(sw_hexes)"; fi
if [[ "$(sw_hexes)" != "$H0" ]]; then pass "HUE changed the order"; else fail "HUE changed nothing"; fi
screenshot "swatches-sorted-hue"
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z after HUE: the order before it" "$(hexes_of 1 19 21)" "3C0000 0000EB FFC800"

# C. RAMP Red 1 -> Gold: everything between blends; locked 12, empty 20 stay
sw_hover_panel; for k in 1 2 3 4 5 6; do key ctrl+z; dk_settle; done
sw_read; sw_expect "back to the file" "$(sw_hexes)" "$H0"
sw_click 1; sw_click 21 ctrl
sw_edit_state; U0=$SE_UNDO
sw_menu_edit; sw_menu_click 220; sw_read; sw_edit_state
sw_expect "RAMP: one undo step" "$SE_UNDO" $(( U0 + 1 ))
sw_expect "RAMP: the ends stay" "$(hexes_of 1 21)" "3C0000 FFC800"
sw_cell 12; sw_expect "RAMP: the locked green stays" "$C_HEX" "00D200"
sw_cell 20; sw_expect "RAMP: the empty cell stays" "$C_KIND" 1
CH=0; for k in 2 3 4 5 6 7 8 9 10 11 14 15 16 17 18 19; do
    sw_cell $k; o=$(echo "$H0" | tr ' ' '\n' | grep -v '^[-|]$' | sed -n "$(( k <= 12 ? k : k - 1 ))p")
    [[ "$C_HEX" != "$o" ]] && CH=$(( CH + 1 ))
done
sw_expect "RAMP: the 16 swatches between changed" "$CH" 16
R1=$(sw_hexes)
# the red channel climbs from 3C to FF along the ramp
RS=$(for k in 1 2 3 4 5 6 7 8 9 10 11 14 15 16 17 18 19 21; do sw_cell $k; echo $(( 16#${C_HEX:0:2} )); done | awk 'NR > 1 && $1 < p {bad = 1} {p = $1} END {print bad ? "no" : "yes"}')
sw_expect "RAMP: red rises along it" "$RS" "yes"
screenshot "swatches-ramp"
sw_menu_edit; sw_menu_click 220; sw_read; sw_edit_state
sw_expect "RAMP again: no step" "$SE_UNDO" $(( U0 + 1 ))
sw_expect "RAMP again: unchanged" "$(sw_hexes)" "$R1"
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z: the file again" "$(sw_hexes)" "$H0"

# D. STEPS 5; INSERT RAMP FG > BG (FG Gold, BG Red 1) after Gold
sw_click 21; sw_click 1 right
sw_menu_edit; screenshot "swatches-edit-menu-ramps"; sw_chip_click 30 5; key Escape; dk_settle
if grep -q '^RAMP_STEPS=5' "$QA_CFG"; then pass "STEPS 5 saved"; else fail "RAMP_STEPS not 5 ($(grep '^RAMP_STEPS' "$QA_CFG"))"; fi
sw_click 21
sw_menu_edit; sw_menu_click 221; sw_read; sw_sel
sw_expect "INSERT RAMP: entries" "$SW_N" 26
sw_expect "INSERT RAMP: FG first, BG last" "$(hexes_of 22 26)" "FFC800 3C0000"
sw_expect "INSERT RAMP: the new ones selected" "$SS_LIST" "22 23 24 25 26"

# E. INSERT OKLCH RAMP from FG (Gold), nothing selected: at the end
sw_hover_panel; key Escape; dk_settle
sw_menu_edit; sw_menu_click 222; sw_read; sw_sel
sw_expect "OKLCH RAMP: entries" "$SW_N" 31
sw_expect "OKLCH RAMP: the new ones selected" "$SS_LIST" "27 28 29 30 31"
LS=$(for k in 27 28 29 30 31; do sw_cell $k; echo $(( 16#${C_HEX:0:2} + 16#${C_HEX:2:2} + 16#${C_HEX:4:2} )); done | awk 'NR > 1 && $1 <= p {bad = 1} {p = $1} END {print bad ? "no" : "yes"}')
sw_expect "OKLCH RAMP: dark to light" "$LS" "yes"
screenshot "swatches-inserted-ramps"

# F. undo all
sw_edit_state; N=$SE_UNDO
sw_hover_panel; for (( k = 0; k < N; k++ )); do key ctrl+z; dk_settle; done
sw_read; sw_expect "undo all: the file" "$(sw_hexes)" "$H0"
assert_window_exists
info "=== Swatches: ramps and sorting PASSED ==="
