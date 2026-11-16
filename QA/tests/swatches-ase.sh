#!/bin/bash
# =============================================================================
# swatches-ase.sh — QA test: an Adobe Swatch Exchange (.ase) file written by
# another program (QA/fixtures/make-swatch-fixtures.py) opens as a set: each
# group starts a row, CMYK and Gray colors come in as RGB, names are kept.
#   swatches-groups.ase: Ink | group Skin: Skin1 Skin2 Skin3 | group Sky: Cyan (CMYK) Gray (50%)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-groups.ase SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
sw_name() { read -r _ SN_I SN_LIVE SN_FG SN_NAME <<< "$(grep '^SWATN ' "$DK_DUMP")"; }

info "=== Swatches: an .ase file ==="
dk_begin
sw_read
sw_expect "the set" "$SW_KEY" "QA/fixtures/swatches-groups.ase"
sw_expect "entries (6 colors + 2 row breaks)" "$SW_N" 8
sw_expect "colors" "$SW_COLORS" 6
sw_expect "every color, a group per row" "$(sw_hexes)" "102030 | FFE0BD EAC086 8D5524 | 00FFFF 808080"
sw_cell 3; Y3=$C_Y; sw_cell 1; Y1=$C_Y; sw_cell 7; Y7=$C_Y
if (( Y3 > Y1 && Y7 > Y3 )); then pass "three rows (y $Y1, $Y3, $Y7)"; else fail "rows at y $Y1 $Y3 $Y7"; fi
sw_click 3; sw_name; sw_expect "names kept (entry 3)" "$SN_NAME" "Skin1"
sw_click 7; sw_name; sw_expect "the CMYK cyan's name" "$SN_NAME" "Cyan"
screenshot "swatches-ase"
assert_window_exists
info "=== Swatches: an .ase file PASSED ==="
