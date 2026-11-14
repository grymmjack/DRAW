#!/bin/bash
# =============================================================================
# panel-scale-charmap.sh — QA test: Scale for the docked Character Map in real
# screen pixels, like the floating windows (Rick, 2026-11-14: "for scale -
# real 1x like floating panels").
#
# At Auto it draws into the viewport (one panel px = the display scale, 2
# here). Right-click its handle > Scale 1x: it draws into its own surface at
# one screen px a panel px (GUI/PANEL-SURFACE) - its column half as wide, its
# cells half the size - and the pointer still finds the cell drawn under it.
# 3x is three times 1x; Auto puts it back.
#
# (the scale key is not pinned in QA-OPTIONS: --option keys are never saved)
# Dump: PSURF id on k vx vy vw vh uw uh ready; CMAPV x y w h (cell 65, "A",
# viewport px); CMAP ... hoverIdx (field 10); P charmap ...; DMENU / DMENUR.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt CHARMAP_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: Scale for the Character Map ==="

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
cell() { read -r _ C_X C_Y C_W C_H <<< "$(grep -m1 '^CMAPV ' "$DK_DUMP")"; }
hov() { awk '$1=="CMAP" {print $10; exit}' "$DK_DUMP"; }
saved() { grep -q "^$1=$2\b" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1" "$QA_CFG")', want $2"; }

dk_begin
dk_p charmap || fail "no charmap in the dump"
W0=$P_W; cell; CW0=$C_W; CH0=$C_H
# the panels right of it (they stay put when it narrows): nothing of it may spill
# onto them at 1x (it once drew its grid into the viewport at unit coords)
RX=$(( P_X + P_W )); RY=$(( P_Y + 20 ))
snap_region "$RX" "$RY" 40 80 cm-right-auto; SNAP_AUTO=$SNAP_RESULT
info "charmap at Auto: ${W0}px wide, cell A ${CW0}x$CH0 at $C_X,$C_Y"
if [[ -z "$CW0" || "$CW0" == 0 ]]; then fail "charmap: no cell in the dump"
elif pick_scale charmap 7 21; then
    surf 7
    [[ "$S_ON" == -1 && "$S_K" == 1 && "$S_RDY" == -1 ]] && pass "charmap 1x: its own surface (${S_UW}x$S_UH units in ${S_VW}x$S_VH px)" || fail "charmap 1x: PSURF '$(grep '^PSURF 7 ' "$DK_DUMP")'"
    saved CHARMAP_PANEL_SCALE 1
    dk_p charmap; cell
    (( P_W * 2 <= W0 + 2 )) && pass "charmap 1x: half as wide ($W0 -> $P_W)" || fail "charmap 1x: width $W0 -> $P_W (want about half)"
    (( C_W * 2 <= CW0 + 1 && C_W > 0 )) && pass "charmap 1x: cells half the size (${CW0}x$CH0 -> ${C_W}x$C_H)" || fail "charmap 1x: cell ${CW0}x$CH0 -> ${C_W}x$C_H"
    (( C_X >= P_X && C_X + C_W <= P_X + P_W + 1 )) && pass "charmap 1x: its cells inside its column" || fail "charmap 1x: cell at $C_X..$(( C_X + C_W )) outside $P_X..$(( P_X + P_W ))"
    CW1=$C_W
    hover $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); wait_for 0.3 "hover"
    hover $(( C_X + C_W / 2 + 1 )) $(( C_Y + C_H / 2 )); wait_for 0.4 "hover"; dk_settle
    HV=$(hov)
    [[ "$HV" == 65 ]] && pass "charmap 1x: the pointer on A hovers A (65)" || fail "charmap 1x: hover '$HV' over cell A"
    # one cell step right (CMAP field 6 = the step in units; 1x at display scale 2 = half that in px)
    ST=$(awk '$1=="CMAP" {print $6; exit}' "$DK_DUMP")
    hover $(( C_X + C_W / 2 + ST / 2 )) $(( C_Y + C_H / 2 )); wait_for 0.3 "hover B"
    hover $(( C_X + C_W / 2 + ST / 2 )) $(( C_Y + C_H / 2 + 1 )); wait_for 0.4 "hover B"; dk_settle
    HV=$(hov)
    [[ "$HV" == 66 ]] && pass "charmap 1x: one cell right hovers B (66)" || fail "charmap 1x: hover '$HV' one cell right of A"
    dk_park; dk_settle
    snap_region "$RX" "$RY" 40 80 cm-right-1x
    assert_regions_same "$SNAP_AUTO" "$SNAP_RESULT" "charmap 1x: nothing drawn onto the panels right of it" 200
    dk_check "charmap at 1x"
    screenshot "panel-scale-charmap-1x"
    if pick_scale charmap 7 23; then
        surf 7; cell
        [[ "$S_K" == 3 ]] && pass "charmap 3x: k 3" || fail "charmap 3x: PSURF '$(grep '^PSURF 7 ' "$DK_DUMP")'"
        (( C_W >= CW1 * 3 - 2 && C_W <= CW1 * 3 + 2 )) && pass "charmap 3x: cells 3x the 1x size ($CW1 -> $C_W)" || fail "charmap 3x: cell $CW1 -> $C_W"
        dk_check "charmap at 3x"
    fi
    if pick_scale charmap 7 20; then
        grep -q '^PSURF 7 ' "$DK_DUMP" && fail "charmap Auto: still a surface" || pass "charmap Auto: drawn into the viewport again"
        dk_p charmap; cell
        (( P_W == W0 && C_W == CW0 )) && pass "charmap Auto: the old size (${P_W}px, ${C_W}px cells)" || fail "charmap Auto: ${P_W}px / ${C_W}px, was ${W0}px / ${CW0}px"
        saved CHARMAP_PANEL_SCALE 0
    fi
fi
assert_no_crash
info "=== Panels: Scale for the Character Map: done ==="
