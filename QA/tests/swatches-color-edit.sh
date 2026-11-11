#!/bin/bash
# =============================================================================
# swatches-color-edit.sh — QA test: changing a swatch's color and name:
#   - a double-click opens the color dialog; OK changes the swatch (one undo
#     step, saved to the My Swatches copy, the FG follows); Cancel changes nothing
#   - ☰ → RENAME... names it (saved in the copy)
#   - one swatch selected: the Color Mixer changes it live; an FG change made
#     anywhere else (X over the canvas) leaves it; the gear's COLOR PANELS EDIT
#     THE SELECTED turns that off
# The dialogs are driven by keyboard (palette-ops-color-edit.sh does the same).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE COLOR_MIXER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
sw_name() { read -r _ SN_I SN_LIVE SN_FG SN_NAME <<< "$(grep '^SWATN ' "$DK_DUMP")"; }
dbl_entry() { sw_cell "$1"; double_click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); wait_for 0.8 "the color dialog"; }
# click the Color Mixer at a fraction (percent) of its width / height
mixer_click() {
    local r wx wy ww wh
    r=$(grep '^WIN colormixer ' "$DK_DUMP"); read -r _ _ wx wy ww wh _ <<< "$r"
    if [[ -z "$wx" ]]; then fail "no Color Mixer window in the dump"; return 1; fi
    click $(( wx + ww * $1 / 100 )) $(( wy + wh * $2 / 100 )); dk_settle
}

info "=== Swatches: edit color / rename / live edit ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
if grep -q '^WIN colormixer ' "$DK_DUMP"; then pass "the Color Mixer is open"; else fail "the Color Mixer is not open"; fi

# A. double-click Red 1: the dialog, hex 12AB34, OK
dbl_entry 1
key Tab; wait_for 0.15 "hex field"
key BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace
type_text "12AB34"; wait_for 0.15 "typed"
key Return; wait_for 0.15 "hex committed"
key Return; wait_for 0.6 "OK"
dk_settle; sw_read; sw_edit_state; sw_name
sw_cell 1; sw_expect "double-click + OK: swatch 1" "$C_HEX" "12AB34"
sw_expect "... one undo step" "$SE_UNDO" 1
sw_expect "... in the My Swatches copy" "$SE_MINE" 1
sw_expect "... the FG follows" "$SN_FG" "12AB34"
COPY="$SW_MINE/QA Edit.gpl"
if grep -qE "^ *18 +171 +52" "$COPY"; then pass "the copy was saved with 12AB34 (18 171 52)"; else fail "the copy lacks 18 171 52: $(head -8 "$COPY" | tr '\n' '|')"; fi

# B. Cancel
dbl_entry 2; key Escape; wait_for 0.6 "cancelled"; dk_settle; sw_edit_state
sw_cell 2; sw_expect "double-click + Cancel: swatch 2 unchanged" "$C_HEX" "550000"
sw_expect "... no undo step" "$SE_UNDO" 1

# C. rename Red 3
sw_click 3; sw_menu_edit; sw_menu_click 213; wait_for 0.8 "the rename box"
type_text "Crimson"; wait_for 0.2 "typed"; key Return; wait_for 0.6 "renamed"
dk_settle; sw_name; sw_edit_state
sw_expect "RENAME: the name" "$SN_NAME" "Crimson"
sw_expect "... one more undo step" "$SE_UNDO" 2
if grep -q "Crimson" "$COPY"; then pass "the name was saved in the copy"; else fail "the copy has no 'Crimson'"; fi
sw_cell 3; sw_expect "... the color unchanged" "$C_HEX" "6E0000"

# D. live: Red 4 selected, the mixer changes it
sw_click 4; sw_read; sw_name
sw_expect "Red 4 is the FG" "$SN_FG" "870000"
mixer_click 30 30; sw_name; sw_edit_state
sw_cell 4
if [[ "$SN_FG" != "870000" ]]; then pass "the mixer changed the FG ($SN_FG)"; else fail "the mixer click did not change the FG"; fi
sw_expect "live: swatch 4 is the new FG" "$C_HEX" "$SN_FG"
sw_expect "live: one more undo step" "$SE_UNDO" 3
sw_expect "live: the step is closed after the mouse-up" "$SN_LIVE" 0
screenshot "swatches-live-edit"
L4=$C_HEX

# E. an FG change elsewhere (X over the canvas swaps FG / BG) leaves it
dk_park; key x; dk_settle; sw_name
sw_cell 4; sw_expect "X over the canvas: swatch 4 unchanged" "$C_HEX" "$L4"
if [[ "$SN_FG" != "$L4" ]]; then pass "... though the FG changed ($SN_FG)"; else fail "X did not change the FG"; fi
key x; dk_settle

# F. the gear option off: the mixer no longer edits it
sw_geo; click $(( E_X + E_W / 2 )) $(( E_Y + E_H / 2 )); dk_settle
sw_menu_click 17; key Escape; dk_settle
if grep -q '^SWATCHES_LIVE_EDIT=FALSE' "$QA_CFG"; then pass "the option was saved off"; else fail "SWATCHES_LIVE_EDIT not saved FALSE ($(grep '^SWATCHES_LIVE_EDIT' "$QA_CFG"))"; fi
sw_click 5; sw_edit_state; U0=$SE_UNDO
mixer_click 60 40; sw_name; sw_edit_state
sw_cell 5; sw_expect "option off: swatch 5 unchanged" "$C_HEX" "A00000"
sw_expect "... no undo step" "$SE_UNDO" "$U0"

# G. undo it all
sw_hover_panel
for (( k = 0; k < U0; k++ )); do key ctrl+z; dk_settle; done
sw_read; sw_name
sw_cell 1; sw_expect "undo all: swatch 1" "$C_HEX" "3C0000"
sw_cell 4; sw_expect "undo all: swatch 4" "$C_HEX" "870000"
sw_click 3; sw_name; sw_expect "undo all: swatch 3's name" "$SN_NAME" "Red 3"
assert_window_exists
info "=== Swatches: edit color / rename / live edit PASSED ==="
