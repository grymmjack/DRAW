#!/bin/bash
# =============================================================================
# gui-colormixer-more.sh — QA test: the Color Mixer's MORE disclosure (Rick,
# 2026-11-14: "the same disclosure for color mixer ... |> MORE ...").
#   - open by default; a click on the MORE row folds the panel down to the
#     SV field, the hue bar and OLD / NEW (it gets shorter)
#   - folded, the hue bar and the field still pick colors
#   - a second click brings the panel back to its old height
# Dump: CMXM x y w h open panelH (viewport px); CMIX <sv> <hue> <hex> ... FG.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 COLOR_MIXER_X=560 COLOR_MIXER_Y=60 COLOR_MIXER_MORE=TRUE TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Color Mixer: MORE disclosure ==="
dk_begin
cmxm() { read -r _ MX MY MW MH MOPEN MPH <<< "$(grep '^CMXM ' "$DK_DUMP")"; }
cmix() { read -r _ SVX SVY SVW SVH HX HY HW HH _ _ _ _ _ FG _ <<< "$(grep '^CMIX' "$DK_DUMP")"; }
cmxm
if [[ -z "$MW" ]]; then fail "no CMXM line in the dump"; assert_no_crash; exit 0; fi
info "MORE row at $MX,$MY ${MW}x$MH open=$MOPEN; panel height $MPH"
[[ "$MOPEN" == 1 ]] && pass "MORE open by default" || fail "MORE open=$MOPEN at start"
H0=$MPH

click $(( MX + 20 )) $(( MY + MH / 2 )); dk_park; dk_settle; cmxm
[[ "$MOPEN" == 0 ]] && pass "a click folds MORE" || fail "after a click open=$MOPEN"
(( MPH < H0 - 20 )) && pass "the panel got shorter ($H0 -> $MPH)" || fail "the panel height $H0 -> $MPH"
screenshot "colormixer-more-folded"

# folded: the hue bar's top (red) + the field's top-right corner still pick
cmix
click $(( HX + HW / 2 )) $(( HY + 1 )); sleep 0.4
click $(( SVX + SVW - 2 )) $(( SVY + 1 )); dk_park; dk_settle; cmix
(( 16#${FG:0:2} > 220 && 16#${FG:2:2} < 40 && 16#${FG:4:2} < 40 )) && pass "folded, the field still picks (FG $FG)" || fail "folded pick gave FG $FG, want red"

cmxm
click $(( MX + 20 )) $(( MY + MH / 2 )); dk_park; dk_settle; cmxm
[[ "$MOPEN" == 1 ]] && pass "a second click opens MORE" || fail "after the second click open=$MOPEN"
(( MPH >= H0 - 1 && MPH <= H0 + 1 )) && pass "the panel is back to its height ($MPH)" || fail "height $MPH, was $H0"
screenshot "colormixer-more-open"
assert_no_crash
info "=== Color Mixer: MORE disclosure: done ==="
