#!/bin/bash
# =============================================================================
# swatches-save-as.sh — QA test: ☰ → SAVE AS... writes the set in every
# format (.gpl .aco .ase .act .pal .hex .txt .png; no extension = .gpl), and
# ☰ → LOAD... reads them back: .ase .png .act .pal .txt .hex each come back as
# the same colors in the same order (as a new set in My Swatches). The panel
# keeps its set after a Save As. Dialogs are driven by typing the file name
# (they open in My Swatches - a scratch folder here, sw_isolate).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
colors_only() { tr ' ' '\n' | grep -v '^[-|]$' | tr '\n' ' ' | sed 's/ $//'; }
save_as() { # NAME
    sw_menu_edit; sw_menu_click 215; wait_for 1.2 "the Save As dialog"
    local i; for (( i = 0; i < 24; i++ )); do key BackSpace; done   # the set's name is pre-filled
    type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 1.5 "saved"
    dk_settle
}
load_file() { # NAME
    sw_menu_edit; sw_menu_click 214; wait_for 1.2 "the Load dialog"
    type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 1.5 "loaded"
    dk_settle; sw_read
}
magic() { head -c "$2" "$1" 2>/dev/null; }

info "=== Swatches: Save As / Load in every format ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
C0=$(sw_hexes | colors_only)
info "colors: $C0"

for ext in gpl aco ase act pal hex txt png; do
    save_as "qa-out.$ext"
    if [[ -s "$SW_MINE/qa-out.$ext" ]]; then pass "saved qa-out.$ext"; else fail "no qa-out.$ext in My Swatches ($(command ls "$SW_MINE" | tr '\n' ' '))"; fi
done
[[ "$(magic "$SW_MINE/qa-out.gpl" 12)" == "GIMP Palette" ]] && pass ".gpl is a GIMP palette" || fail ".gpl header"
[[ "$(magic "$SW_MINE/qa-out.ase" 4)" == "ASEF" ]] && pass ".ase starts ASEF" || fail ".ase header"
[[ "$(magic "$SW_MINE/qa-out.pal" 8)" == "JASC-PAL" ]] && pass ".pal is JASC" || fail ".pal header"
[[ "$(stat -c %s "$SW_MINE/qa-out.act" 2>/dev/null)" == 772 ]] && pass ".act is 772 bytes" || fail ".act size"
[[ "$(magic "$SW_MINE/qa-out.png" 8 | tail -c 3)" == "PNG" || "$(head -c 4 "$SW_MINE/qa-out.png" | tail -c 3)" == "PNG" ]] && pass ".png is a PNG" || fail ".png header"
if grep -q "#SWS:LOCK" "$SW_MINE/qa-out.gpl" && grep -q "#SWS:BREAK" "$SW_MINE/qa-out.gpl"; then pass ".gpl keeps the lock and the row break"; else fail ".gpl lacks #SWS: extras"; fi
sw_read; sw_edit_state
sw_expect "after the saves: still the fixture set" "$SW_KEY" "QA/fixtures/swatches-edit.gpl"
sw_expect "... unedited (no My Swatches copy)" "$SE_MINE" 0

save_as "qa-noext"
if [[ -s "$SW_MINE/qa-noext.gpl" ]]; then pass "no extension: saved as .gpl"; else fail "no qa-noext.gpl ($(command ls "$SW_MINE" | tr '\n' ' '))"; fi

for ext in ase png act pal txt hex; do
    load_file "qa-out.$ext"
    if [[ "$SW_KEY" == *"/SWATCHES/qa-out"*".gpl" ]]; then pass "Load $ext: a set in My Swatches ($(basename "$SW_KEY"))"; else fail "Load $ext: the set is $SW_KEY"; fi
    sw_expect "Load $ext: the same colors in order" "$(sw_hexes | colors_only)" "$C0"
done
load_file qa-out.png
sw_expect "the PNG came back 8 columns wide" "$SW_COLS" 8
screenshot "swatches-loaded-png"
assert_window_exists
info "=== Swatches: Save As / Load in every format PASSED ==="
