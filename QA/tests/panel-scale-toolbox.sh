#!/bin/bash
# =============================================================================
# panel-scale-toolbox.sh — QA test: Scale for the docked Toolbox, Organizer
# and Drawer in real screen pixels, like the floating windows (Rick,
# 2026-11-14: "for scale - real 1x like floating panels").
#
# At Auto the toolbox family draws into the viewport at its widget scale (QA:
# display scale 2 x toolbar scale 2 = 4 screen px an icon px). Right-click its
# handle > Scale 1x: it draws into its own surface at one screen px an icon px
# (GUI/PANEL-SURFACE) - a quarter of the size here - and the pointer still
# lands on what is drawn: a toolbox button picks its tool, the organizer's
# opacity slider sets the opacity from where it is clicked, the drawer bin
# under the pointer is the one drawn there. 3x is three times 1x; Auto puts
# it back.
#
# (the scale keys are not pinned in QA-OPTIONS: --option keys are never saved)
# Dump: PSURF id on k vx vy vw vh uw uh ready; BTN toolbox i kind id name x y
# w h; ORGW i x y w h; DRWB x y w h; DRWAT slot (viewport px); VIEW zoom ox oy
# tool (VIEW's is the tool id, BTN's the button id); PAINT opacity tool; DMENU / DMENUR (the handle menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: Scale for the Toolbox, the Organizer and the Drawer ==="

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
surf() { S_ON=; S_K=; read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
# a plain drawn tool button (the marquee; else the first tool) -> B_*
# (not the hand or the zoom: those are momentary tools)
tbtn() {
    local l; l=$(awk '$1=="BTN" && $2=="toolbox" && $4==1 && $6=="marquee" && $9>0' "$DK_DUMP" | head -1)
    [[ -z "$l" ]] && l=$(awk '$1=="BTN" && $2=="toolbox" && $4==1 && $6!="hand" && $6!="zoom" && $9>0' "$DK_DUMP" | head -1)
    read -r _ _ B_I B_KIND B_ID B_NAME B_X B_Y B_W B_H <<< "$l"
}
orgw() { read -r _ _ O_X O_Y O_W O_H <<< "$(grep "^ORGW $1 " "$DK_DUMP")"; } # widget 1 = the opacity slider
drwb() { read -r _ D_X D_Y D_W D_H <<< "$(grep -m1 '^DRWB ' "$DK_DUMP")"; }
saved() { grep -q "^$1=$2\b" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1" "$QA_CFG")', want $2"; }

dk_begin
for p in toolbox organizer drawer; do dk_p "$p" || fail "no $p in the dump"; done

# ---- Toolbox -------------------------------------------------------------
tbtn; BW0=$B_W; BH0=$B_H
dk_p toolbox; TW0=$P_W
# the tool that button gives (BTN has the button id, VIEW the tool id): click it at Auto
if [[ -n "$BW0" && "$BW0" != 0 ]]; then
    click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); wait_for 0.5 "pick $B_NAME"; dk_park; dk_settle
    TWANT=$(awk '$1=="VIEW" {print $5; exit}' "$DK_DUMP")
fi
info "toolbox at Auto: ${TW0}px wide, button $B_NAME ${BW0}x$BH0"
if [[ -z "$BW0" || "$BW0" == 0 ]]; then fail "toolbox: no drawn tool button in the dump"
elif pick_scale toolbox 1 21; then
    surf 1
    [[ "$S_ON" == -1 && "$S_K" == 1 && "$S_RDY" == -1 ]] && pass "toolbox 1x: its own surface (${S_UW}x$S_UH units in ${S_VW}x$S_VH px)" || fail "toolbox 1x: PSURF '$(grep '^PSURF 1 ' "$DK_DUMP")'"
    saved TOOLBOX_PANEL_SCALE 1
    tbtn
    (( B_W * 4 <= BW0 + 3 && B_W > 0 )) && pass "toolbox 1x: buttons a quarter the size (${BW0}x$BH0 -> ${B_W}x$B_H)" || fail "toolbox 1x: button ${BW0}x$BH0 -> ${B_W}x$B_H"
    dk_p toolbox
    (( B_X >= P_X && B_X + B_W <= P_X + P_W + 1 && B_Y >= P_Y && B_Y + B_H <= P_Y + P_H + 1 )) && pass "toolbox 1x: its buttons inside its rect" || fail "toolbox 1x: button $B_X,$B_Y ${B_W}x$B_H outside $P_X,$P_Y ${P_W}x$P_H"
    BW1=$B_W
    key b; wait_for 0.3 "the brush first" # (so the click has something to change)
    click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); wait_for 0.5 "pick $B_NAME"; dk_park; dk_settle
    T=$(awk '$1=="VIEW" {print $5; exit}' "$DK_DUMP")
    [[ "$T" == "$TWANT" ]] && pass "toolbox 1x: a click on $B_NAME picks it (tool $T, as at Auto)" || fail "toolbox 1x: clicked $B_NAME, tool is $T (at Auto it gave $TWANT)"
    dk_check "toolbox at 1x"
    screenshot "panel-scale-toolbox-1x"
    if pick_scale toolbox 1 23; then
        surf 1; tbtn
        [[ "$S_K" == 3 ]] && pass "toolbox 3x: k 3" || fail "toolbox 3x: PSURF '$(grep '^PSURF 1 ' "$DK_DUMP")'"
        (( B_W >= BW1 * 3 - 2 && B_W <= BW1 * 3 + 2 )) && pass "toolbox 3x: buttons 3x the 1x size ($BW1 -> $B_W)" || fail "toolbox 3x: button $BW1 -> $B_W"
        dk_check "toolbox at 3x"
    fi
    if pick_scale toolbox 1 20; then
        grep -q '^PSURF 1 ' "$DK_DUMP" && fail "toolbox Auto: still a surface" || pass "toolbox Auto: drawn into the viewport again"
        tbtn; dk_p toolbox
        (( B_W == BW0 && P_W == TW0 )) && pass "toolbox Auto: the old size (${P_W}px, ${B_W}px buttons)" || fail "toolbox Auto: ${P_W}px / ${B_W}px, was ${TW0}px / ${BW0}px"
        saved TOOLBOX_PANEL_SCALE 0
    fi
fi

# ---- Organizer -----------------------------------------------------------
orgw 1; OW0=$O_W; OH0=$O_H
info "organizer at Auto: opacity slider ${OW0}x$OH0"
if [[ -z "$OW0" || "$OW0" == 0 ]]; then fail "organizer: no opacity slider (ORGW 1) in the dump"
elif pick_scale organizer 2 21; then
    surf 2
    [[ "$S_ON" == -1 && "$S_K" == 1 && "$S_RDY" == -1 ]] && pass "organizer 1x: its own surface (${S_UW}x$S_UH units)" || fail "organizer 1x: PSURF '$(grep '^PSURF 2 ' "$DK_DUMP")'"
    saved ORGANIZER_PANEL_SCALE 1
    orgw 1
    (( O_W * 4 <= OW0 + 3 && O_W > 0 )) && pass "organizer 1x: widgets a quarter the size (${OW0}x$OH0 -> ${O_W}x$O_H)" || fail "organizer 1x: slider ${OW0}x$OH0 -> ${O_W}x$O_H"
    # the slider: its top is 100%, its bottom 1%
    click $(( O_X + O_W / 2 )) $(( O_Y + 1 )); wait_for 0.4 "opacity top"; dk_park; dk_settle
    OPT=$(awk '$1=="PAINT" {print $2; exit}' "$DK_DUMP")
    click $(( O_X + O_W / 2 )) $(( O_Y + O_H - 2 )); wait_for 0.4 "opacity bottom"; dk_park; dk_settle
    OPB=$(awk '$1=="PAINT" {print $2; exit}' "$DK_DUMP")
    (( OPT >= 90 && OPB <= 20 )) && pass "organizer 1x: the opacity slider takes the click where it is drawn (top $OPT%, bottom $OPB%)" || fail "organizer 1x: opacity top $OPT% bottom $OPB% (want >= 90 / <= 20)"
    click $(( O_X + O_W / 2 )) $(( O_Y + 1 )); wait_for 0.4 "opacity back"; dk_park
    dk_check "organizer at 1x"
    screenshot "panel-scale-organizer-1x"
    if pick_scale organizer 2 20; then
        grep -q '^PSURF 2 ' "$DK_DUMP" && fail "organizer Auto: still a surface" || pass "organizer Auto: drawn into the viewport again"
        orgw 1
        (( O_W == OW0 )) && pass "organizer Auto: the old size (${O_W}px)" || fail "organizer Auto: slider ${O_W}px, was ${OW0}px"
        saved ORGANIZER_PANEL_SCALE 0
    fi
fi

# ---- Drawer --------------------------------------------------------------
drwb; DW0=$D_W
info "drawer at Auto: first bin $D_X,$D_Y ${D_W}x$D_H"
if [[ -z "$DW0" || "$DW0" == 0 ]]; then fail "drawer: no bin (DRWB) in the dump"
elif pick_scale drawer 3 21; then
    surf 3
    [[ "$S_ON" == -1 && "$S_K" == 1 && "$S_RDY" == -1 ]] && pass "drawer 1x: its own surface (${S_UW}x$S_UH units)" || fail "drawer 1x: PSURF '$(grep '^PSURF 3 ' "$DK_DUMP")'"
    saved DRAWER_PANEL_SCALE 1
    drwb
    (( D_W < DW0 && D_W > 0 )) && pass "drawer 1x: smaller bins ($DW0 -> $D_W px)" || fail "drawer 1x: bin $DW0 -> $D_W px"
    hover $(( D_X + D_W / 2 )) $(( D_Y + D_H / 2 )); wait_for 0.3 "hover"
    hover $(( D_X + D_W / 2 + 1 )) $(( D_Y + D_H / 2 )); wait_for 0.4 "hover"; dk_settle
    AT=$(awk '$1=="DRWAT" {print $2; exit}' "$DK_DUMP")
    (( AT >= 1 )) && pass "drawer 1x: the pointer on the first bin finds a bin (slot $AT)" || fail "drawer 1x: DRWAT '$AT' over the first bin"
    hover $(( D_X + D_W / 2 )) $(( D_Y + D_H * 4 )); wait_for 0.4 "hover lower"; dk_settle
    AT2=$(awk '$1=="DRWAT" {print $2; exit}' "$DK_DUMP")
    [[ "$AT2" != "$AT" ]] && pass "drawer 1x: a bin lower down is another one (slot $AT2)" || fail "drawer 1x: still slot $AT2 four bins lower"
    dk_park
    dk_check "drawer at 1x"
    screenshot "panel-scale-drawer-1x"
    if pick_scale drawer 3 20; then
        grep -q '^PSURF 3 ' "$DK_DUMP" && fail "drawer Auto: still a surface" || pass "drawer Auto: drawn into the viewport again"
        drwb
        (( D_W == DW0 )) && pass "drawer Auto: the old size (${D_W}px)" || fail "drawer Auto: bin ${D_W}px, was ${DW0}px"
        saved DRAWER_PANEL_SCALE 0
    fi
fi

# ---- all three at 1x: the column narrows ---------------------------------
dk_p toolbox; CW0=$P_W
pick_scale toolbox 1 21 && pick_scale organizer 2 21 && pick_scale drawer 3 21
dk_p toolbox
(( P_W < CW0 )) && pass "all three at 1x: the toolbox column narrows ($CW0 -> $P_W px)" || fail "all three at 1x: toolbox ${CW0} -> ${P_W}px"
dk_check "the toolbox family at 1x"
screenshot "panel-scale-toolbox-family-1x"
pick_scale toolbox 1 20; pick_scale organizer 2 20; pick_scale drawer 3 20
assert_no_crash
info "=== Panels: Scale for the Toolbox, the Organizer and the Drawer: done ==="
