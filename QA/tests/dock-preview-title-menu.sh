#!/bin/bash
# =============================================================================
# dock-preview-title-menu.sh — QA test: right-click anywhere on the floating
# Preview's title bar opens its panel menu (Rick, 2026-11-14: "i cannot right
# click on the preview panel except on it's text section to get the menu to
# show up" - the empty stretch between FP and the minimize box did nothing).
#
#  - on the PREVIEW label: the menu (as before)
#  - on the empty stretch just left of the minimize box: the menu too
#  - inside the picture: no panel menu
#
# Dump: WIN preview x y w h; P preview ... hx hy hw hh (dock-lib.sh); DMENU open panel ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE PREVIEW_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Preview: right-click its whole title bar ==="
dk_begin
DP_PREVIEW=9
menu() { read -r _ M_OPEN M_PANEL _ <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"; }
rclick() { right_click "$1" "$2"; wait_for 0.6 "$3"; dk_settle; menu; }
close_menu() { key Escape; wait_for 0.4 "close"; dk_park; dk_settle; }

dk_floating preview || fail "the Preview is not floating at the start"
dk_p preview
read -r _ _ P_X P_Y P_W P_H _ <<< "$(grep -m1 '^WIN preview ' "$DK_DUMP")" # (a floating window: its rect)
info "preview at $P_X,$P_Y ${P_W}x$P_H, label handle $P_HX,$P_HY ${P_HW}x$P_HH"
TY=$(( P_HY + P_HH / 2 ))

# the label (it always worked)
rclick $(( P_HX + P_HW / 2 )) "$TY" "right-click the PREVIEW label"
[[ "$M_OPEN" == -1 && "$M_PANEL" == "$DP_PREVIEW" ]] && pass "the label: the Preview's menu" || fail "the label: DMENU open '$M_OPEN' panel '$M_PANEL'"
close_menu

# the empty stretch: just left of the minimize box (two title heights from the right edge)
EX=$(( P_X + P_W - 2 * P_HH - 4 ))
(( EX > P_HX + P_HW + 12 )) || fail "the Preview is too narrow for an empty title stretch (x $EX, label ends $(( P_HX + P_HW )))"
rclick "$EX" "$TY" "right-click the empty title bar"
[[ "$M_OPEN" == -1 && "$M_PANEL" == "$DP_PREVIEW" ]] && pass "the empty title bar (x $EX): the Preview's menu" || fail "the empty title bar (x $EX): DMENU open '$M_OPEN' panel '$M_PANEL'"
screenshot "preview-title-menu"
close_menu

# inside the picture: not the panel menu
rclick $(( P_X + P_W / 2 )) $(( P_Y + P_H / 2 )) "right-click the picture"
[[ "$M_OPEN" != -1 ]] && pass "the picture: no panel menu" || fail "the picture opened the panel menu (panel $M_PANEL)"
close_menu
assert_no_crash
info "=== Preview: right-click its whole title bar: done ==="
