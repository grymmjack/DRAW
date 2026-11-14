#!/bin/bash
# =============================================================================
# panel-scale-bars.sh — QA test: Scale for the docked Edit bar and Advanced
# bar in real screen pixels, like the floating windows (Rick, 2026-11-14:
# "for scale - real 1x like floating panels").
#
# At Auto a bar draws into the viewport (one icon px = the display scale, 2
# here). Right-click its handle > Scale 1x: it draws into its own surface at
# one screen px an icon px (GUI/PANEL-SURFACE) - its column half as wide, its
# buttons half the size - and clicks still land on its buttons. 3x makes it
# bigger than Auto; Auto puts it back.
#
# (the scale keys are not pinned in QA-OPTIONS: --option keys are never saved)
# Dump: PSURF id on k vx vy vw vh uw uh ready; BTN editbar i kind id name x y
# w h (viewport px); P editbar ... (dock-lib.sh); DMENU / DMENUR (the menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: Scale for the Edit bar and the Advanced bar ==="

# NAME DPID VALUE: right-click NAME's handle, pick the menu row VALUE (20 Auto, 20+k = kx)
pick_scale() {
    local ry rh
    dk_settle
    if ! dk_grab_point "$1"; then fail "$1 has no handle"; return 1; fi
    right_click "$GX" "$GY"; wait_for 0.6 "the handle menu"; dk_settle
    read -r _ MO MP _ MX _ <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
    if [[ "$MO" != -1 || "$MP" != "$2" ]]; then fail "$1: no handle menu (open '$MO' panel '$MP')"; key Escape; return 1; fi
    read -r ry rh _ <<< "$(awk -v v="$3" '$1=="DMENUR" && $3==v {print $4" "$5; exit}' "$DK_DUMP")"
    if [[ -z "$ry" ]]; then fail "$1: no Scale row $3 in its menu"; key Escape; return 1; fi
    click $(( MX + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "scale row $3"; dk_park; dk_settle
}
surf() { read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
btn() { # PANEL I -> B_X B_Y B_W B_H B_NAME of the I-th drawn button
    read -r _ _ _ _ _ B_NAME B_X B_Y B_W B_H <<< "$(awk -v p="$1" '$1=="BTN" && $2==p && $9>0' "$DK_DUMP" | sed -n "${2}p")"
}

dk_begin
for spec in "editbar 5 EDIT_BAR_SCALE" "advbar 6 ADV_BAR_SCALE"; do
    read -r NM ID KEY <<< "$spec"
    dk_p "$NM"; W0=$P_W
    btn "$NM" 1; BW0=$B_W; BH0=$B_H; BN=$B_NAME
    info "$NM at Auto: ${W0}px wide, first button $BN ${BW0}x$BH0"
    if [[ -z "$BW0" || "$BW0" == 0 ]]; then fail "$NM: no drawn button in the dump"; continue; fi

    # 1x: its own surface, half the size at display scale 2
    pick_scale "$NM" "$ID" 21 || continue
    surf "$ID"
    [[ "$S_ON" == -1 && "$S_K" == 1 && "$S_RDY" == -1 ]] && pass "$NM 1x: drawn into its own surface (k $S_K, ${S_UW}x$S_UH units in ${S_VW}x$S_VH px)" || fail "$NM 1x: PSURF line '$(grep "^PSURF $ID " "$DK_DUMP")'"
    grep -q "^$KEY=1\b" "$QA_CFG" && pass "$NM: $KEY=1 saved" || fail "$NM: saved '$(grep "^$KEY" "$QA_CFG")'"
    dk_p "$NM"
    (( P_W * 2 <= W0 + 2 )) && pass "$NM 1x: half as wide ($W0 -> $P_W)" || fail "$NM 1x: width $W0 -> $P_W (want about half)"
    btn "$NM" 1
    (( B_W * 2 <= BW0 + 1 && B_W > 0 )) && pass "$NM 1x: buttons half the size (${BW0}x$BH0 -> ${B_W}x$B_H)" || fail "$NM 1x: first button ${BW0}x$BH0 -> ${B_W}x$B_H"
    (( B_X >= P_X && B_X + B_W <= P_X + P_W + 1 )) && pass "$NM 1x: its buttons inside its column" || fail "$NM 1x: button at $B_X..$(( B_X + B_W )) outside $P_X..$(( P_X + P_W ))"
    dk_check "$NM at 1x"
    screenshot "panel-scale-$NM-1x"

    # a click on a 1x button lands on it: the hover outline follows the pointer
    # (hover the button, the region under the pointer is the bar, the button lit)
    hover $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); wait_for 0.3 "hover"
    hover $(( B_X + B_W / 2 + 1 )) $(( B_Y + B_H / 2 )); wait_for 0.4 "hover"; dk_settle
    HV=$(awk -v p="$NM" '$1=="BARHOVER" && $2==p {print $3}' "$DK_DUMP")
    [[ "$HV" == "$(awk -v p="$NM" '$1=="BTN" && $2==p && $9>0 {print $3; exit}' "$DK_DUMP")" ]] && pass "$NM 1x: the pointer is on its first button (hover $HV)" || fail "$NM 1x: hover '$HV' over the first button"

    # 3x: bigger than Auto (1.5x at display scale 2)
    pick_scale "$NM" "$ID" 23 || continue
    surf "$ID"; dk_p "$NM"; btn "$NM" 1
    [[ "$S_K" == 3 ]] && pass "$NM 3x: k 3" || fail "$NM 3x: PSURF '$(grep "^PSURF $ID " "$DK_DUMP")'"
    (( B_W * 2 >= BW0 * 3 - 2 )) && pass "$NM 3x: buttons 1.5x Auto (${BW0} -> $B_W)" || fail "$NM 3x: first button ${BW0} -> $B_W"
    dk_check "$NM at 3x"
    screenshot "panel-scale-$NM-3x"

    # Auto: back into the viewport, the old size
    pick_scale "$NM" "$ID" 20 || continue
    grep -q "^PSURF $ID " "$DK_DUMP" && fail "$NM Auto: still a surface" || pass "$NM Auto: drawn into the viewport again"
    dk_p "$NM"; btn "$NM" 1
    (( P_W == W0 && B_W == BW0 )) && pass "$NM Auto: the old size (${P_W}px, ${B_W}px buttons)" || fail "$NM Auto: ${P_W}px / ${B_W}px, was ${W0}px / ${BW0}px"
    grep -q "^$KEY=0\b" "$QA_CFG" && pass "$NM: $KEY=0 saved" || fail "$NM: saved '$(grep "^$KEY" "$QA_CFG")'"
done
assert_no_crash
info "=== Panels: Scale for the Edit bar and the Advanced bar: done ==="
