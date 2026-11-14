#!/bin/bash
# =============================================================================
# panel-scale-layers.sh — QA test: Scale for the docked Layers panel in real
# screen pixels, like the floating windows (Rick, 2026-11-14: "for scale -
# real 1x like floating panels").
#
# At Auto it draws into the viewport (one panel px = the display scale, 2
# here). Right-click its handle (its header) > Scale 1x: it draws into its own
# surface at one screen px a panel px (GUI/PANEL-SURFACE) - its column half as
# wide, its rows half as tall - and the pointer still finds the row drawn
# under it: hovering a row, nothing under the last one, a click selects it.
# 3x is three times 1x; Auto puts it back.
#
# (the scale key is not pinned in QA-OPTIONS: --option keys are never saved)
# Dump: PSURF id on k ...; LPHIT slot (the row under the pointer); LPGEO header
# row buttonbar (viewport px); LPANEL scroll current multi; P layers ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: Scale for the Layers panel ==="

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
geo() { read -r _ G_HDR G_ROW G_BAR <<< "$(grep -m1 '^LPGEO ' "$DK_DUMP")"; }
lphit() { awk '$1=="LPHIT" {print $2; exit}' "$DK_DUMP"; }
cur() { awk '$1=="LPANEL" {print $3; exit}' "$DK_DUMP"; }
saved() { grep -q "^$1=$2\b" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1" "$QA_CFG")', want $2"; }
# row N (0 = top) of the list: hover its middle -> RY, LPHIT in H
hover_row() {
    RY=$(( P_Y + G_HDR + G_ROW * $1 + G_ROW / 2 ))
    hover $(( P_X + P_W / 2 )) "$RY"; wait_for 0.3 "hover"
    hover $(( P_X + P_W / 2 + 1 )) "$RY"; wait_for 0.4 "hover"; dk_settle
    H=$(lphit)
}

dk_begin
park_mouse; key ctrl+shift+n; wait_for 0.6 "layer 2"; key ctrl+shift+n; wait_for 0.6 "layer 3"; dk_settle
dk_p layers || fail "no layers panel in the dump"
W0=$P_W; geo; R0=$G_ROW
info "layers at Auto: ${W0}px wide, rows ${R0}px, header ${G_HDR}px, $(grep -c '^LAYER ' "$DK_DUMP") layers"
if pick_scale layers 4 21; then
    surf 4
    [[ "$S_ON" == -1 && "$S_K" == 1 && "$S_RDY" == -1 ]] && pass "layers 1x: its own surface (${S_UW}x$S_UH units in ${S_VW}x$S_VH px)" || fail "layers 1x: PSURF '$(grep '^PSURF 4 ' "$DK_DUMP")'"
    saved LAYER_PANEL_SCALE 1
    dk_p layers; geo
    (( P_W * 2 <= W0 + 2 )) && pass "layers 1x: half as wide ($W0 -> $P_W)" || fail "layers 1x: width $W0 -> $P_W (want about half)"
    (( G_ROW * 2 <= R0 + 1 && G_ROW > 0 )) && pass "layers 1x: rows half as tall ($R0 -> $G_ROW)" || fail "layers 1x: row $R0 -> $G_ROW"
    R1=$G_ROW
    hover_row 0; TOP=$H
    (( TOP > 0 )) && [[ "$TOP" == "$(cur)" ]] && pass "layers 1x: the top row is the current layer ($TOP)" || fail "layers 1x: top row hit '$TOP', current '$(cur)'"
    hover_row 2; BOT=$H
    (( BOT > 0 && BOT != TOP )) && pass "layers 1x: the third row is another layer ($BOT)" || fail "layers 1x: third row hit '$BOT' (top $TOP)"
    hover_row 3
    [[ "$H" == 0 ]] && pass "layers 1x: nothing under the last row" || fail "layers 1x: a row ($H) under the last one"
    hover_row 2
    click $(( P_X + P_W / 2 )) "$RY"; wait_for 0.5 "select the third row"; dk_park; dk_settle
    [[ "$(cur)" == "$BOT" ]] && pass "layers 1x: a click on the third row selects it ($BOT)" || fail "layers 1x: clicked row 3 (layer $BOT), current is $(cur)"
    dk_check "layers at 1x"
    screenshot "panel-scale-layers-1x"
    if pick_scale layers 4 23; then
        surf 4; geo
        [[ "$S_K" == 3 ]] && pass "layers 3x: k 3" || fail "layers 3x: PSURF '$(grep '^PSURF 4 ' "$DK_DUMP")'"
        (( G_ROW >= R1 * 3 - 2 && G_ROW <= R1 * 3 + 2 )) && pass "layers 3x: rows 3x the 1x height ($R1 -> $G_ROW)" || fail "layers 3x: row $R1 -> $G_ROW"
        dk_check "layers at 3x"
    fi
    if pick_scale layers 4 20; then
        grep -q '^PSURF 4 ' "$DK_DUMP" && fail "layers Auto: still a surface" || pass "layers Auto: drawn into the viewport again"
        dk_p layers; geo
        (( P_W == W0 && G_ROW == R0 )) && pass "layers Auto: the old size (${P_W}px, ${G_ROW}px rows)" || fail "layers Auto: ${P_W}px / ${G_ROW}px, was ${W0}px / ${R0}px"
        saved LAYER_PANEL_SCALE 0
    fi
fi
assert_no_crash
info "=== Panels: Scale for the Layers panel: done ==="
