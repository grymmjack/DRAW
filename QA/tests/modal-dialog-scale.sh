#!/bin/bash
# =============================================================================
# modal-dialog-scale.sh — QA test: the modal colour picker comes up at the
# Color Mixer's Scale, and the file dialogs at the Browser's (Rick 2026-11-16,
# screenshots: the Color Ops picker tiny beside a 2x mixer; Export Palette's
# text tiny in a huge dialog; 2026-11-17: Save As still 1x beside a 2x
# Browser). A panel Scale is window px per panel px, and both modals draw on
# page 0 in window px too, so they take the Scale as it is - here 3 (not 3
# over the display scale, which is what shipped the 1x Save As).
#   - right-click the status bar's FG swatch: the GJ picker at scale 3
#   - Save As (Ctrl+Shift+S): the file dialog's font and icons at 3
# Dump: SBSW <FG swatch x y> | QA/.dock-dump.txt.modal: "MODAL picker <scale>
# <mixer screen px>" / "MODAL fd <font> <icons> <Browser Scale>" (written as a
# modal opens - frames stop while it is up).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE COLOR_MIXER_SCALE=3 BROWSER_SCALE=3
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Modal picker / file dialog at the panels' Scale ==="
dk_begin
MD="$DK_DUMP.modal"

rm -f "$MD"
read -r _ SX SY _ <<< "$(grep -m1 '^SBSW ' "$DK_DUMP")"
[[ -n "$SY" ]] || { fail "no SBSW line"; assert_no_crash; exit 0; }
right_click $(( SX + 5 )) $(( SY + 6 )); wait_for 1.5 "the GJ colour picker"
read -r _ KIND SC MIX _ <<< "$(tr -d '\r' < "$MD" 2>/dev/null)"
info "picker: '$(cat "$MD" 2>/dev/null)'"
[[ "$KIND" == picker ]] && (( SC == 3 && MIX == 3 )) && pass "the picker at the mixer's Scale (3)" || fail "picker scale '$KIND $SC $MIX' (want picker 3 3)"
screenshot "modal-picker-scale"
key Escape; wait_for 1.0 "picker cancelled"; dk_settle

rm -f "$MD"
key ctrl+shift+s; wait_for 1.5 "Save As"
read -r _ KIND FS IS BSC _ <<< "$(tr -d '\r' < "$MD" 2>/dev/null)"
info "file dialog: '$(cat "$MD" 2>/dev/null)'"
[[ "$KIND" == fd ]] && (( FS == 3 && IS == 3 && BSC == 3 )) && pass "the file dialog at the Browser's Scale (font + icons 3)" || fail "file dialog scale '$KIND $FS $IS $BSC' (want fd 3 3 3)"
screenshot "modal-fd-scale"
key Escape; wait_for 1.0 "Save As cancelled"
rm -f "$MD"
assert_no_crash
info "=== Modal dialog scale done ==="
