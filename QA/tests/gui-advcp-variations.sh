#!/bin/bash
# =============================================================================
# gui-advcp-variations.sh — QA test: the Advanced Color Picker's VARIATIONS
# disclosure (Rick, 2026-11-14: "hide the sliders under it but keep the
# quantize slider with a disclosure |> arrow saying VARIATIONS ... that when
# clicked shows the panel like i have now").
#   - open by default: the shade rows show, the panel is full height
#   - a click on the VARIATIONS row folds them away: the panel gets shorter,
#     the Quantize slider stays and still works
#   - a second click brings the panel back to its old height
# Dump: ACPV x y w h open (the row, viewport px); ACPQ <track x y w h> steps
# <gear>; WIN advcolorpicker x y w h slot.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ADV_COLOR_PICKER_VISIBLE=1 ADV_COLOR_PICKER_VARIATIONS=TRUE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Advanced Color Picker: VARIATIONS disclosure ==="
dk_begin
acpv() { read -r _ VX VY VW VH VOPEN <<< "$(grep '^ACPV ' "$DK_DUMP")"; }
acpq() { read -r _ TX TY TW TH STEPS _ <<< "$(grep '^ACPQ ' "$DK_DUMP")"; }
win()  { read -r _ _ W_X W_Y W_W W_H _ <<< "$(grep '^WIN advcolorpicker ' "$DK_DUMP")"; }
acpv; win
if [[ -z "$VW" ]]; then fail "no ACPV line in the dump"; assert_no_crash; exit 0; fi
info "VARIATIONS row at $VX,$VY ${VW}x$VH open=$VOPEN; panel ${W_W}x$W_H"
[[ "$VOPEN" == 1 ]] && pass "VARIATIONS open by default" || fail "VARIATIONS open=$VOPEN at start"
H0=$W_H

click $(( VX + 20 )) $(( VY + VH / 2 )); dk_park; dk_settle; acpv; win
[[ "$VOPEN" == 0 ]] && pass "a click folds VARIATIONS" || fail "after a click open=$VOPEN"
(( W_H < H0 - 20 )) && pass "the panel got shorter ($H0 -> $W_H)" || fail "the panel height $H0 -> $W_H"
screenshot "advcp-variations-folded"
# folded, the row keeps a margin under its text (BUGS.md 2026-11-15: "too close to
# the bottom"): the 3 px above the panel's frame (the slot's last px) are plain
snap_region $(( VX + 2 )) $(( VY + VH - 4 )) $(( VW - 4 )) 3 "advcp-variations-under"
NUC=$(magick "$SNAP_RESULT" -unique-colors -format '%w' info: 2>/dev/null)
[[ "$NUC" == 1 ]] && pass "folded: a margin under VARIATIONS" || fail "folded: $NUC colors in the last 3 px of the VARIATIONS row"

# the Quantize slider stays and still works
acpq
(( TW > 40 )) && pass "Quantize slider still shown (${TW}px)" || fail "Quantize slider width '$TW' when folded"
click $(( TX + TW - 2 )) $(( TY + TH / 2 )); dk_park; dk_settle; acpq
[[ "$STEPS" == 32 ]] && pass "Quantize still works folded (32)" || fail "Quantize gave '$STEPS' folded"
click $(( TX + 1 )) $(( TY + TH / 2 )); dk_park; dk_settle

# open again
acpv
click $(( VX + 20 )) $(( VY + VH / 2 )); dk_park; dk_settle; acpv; win
[[ "$VOPEN" == 1 ]] && pass "a second click opens VARIATIONS" || fail "after the second click open=$VOPEN"
(( W_H >= H0 - 1 && W_H <= H0 + 1 )) && pass "the panel is back to its height ($W_H)" || fail "height $W_H, was $H0"
screenshot "advcp-variations-open"
assert_no_crash
info "=== Advanced Color Picker: VARIATIONS disclosure: done ==="
