#!/bin/bash
# =============================================================================
# zoom-fit-center.sh — QA test: Hand double-click fit and Zoom-tool region zoom
# centre in the canvas view (BUGS.md 2026-11-15)
#
#  - DEFAULT 2 workspace (side docks of different widths): a double-click on the
#    Hand button fits the canvas with equal margins left / right and top /
#    bottom - the fit added the docks' offset twice (no left margin)
#  - a Zoom-tool drag: the middle of the dragged region lands in the middle of
#    the canvas view - it landed off to one side
#
# Dump: SCR w h dockLX dockRX barY1 dockY2 | VIEW zoom% offX offY tool |
#       CVORG x y (the canvas's top-left on screen) | BTN toolbox i kind id name x y w h
# QA-OPTIONS: WORKSPACE=default-2 DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Zoom: fit + region centre in the view ==="
ZF_DIR="$(mktemp -d /tmp/draw-qa-zoomfit-XXXXXX)"
CW=320; CH=200
magick -size ${CW}x${CH} xc:'#c00000' "PNG32:$ZF_DIR/red.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$ZF_DIR/red.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
geo() {
    dk_scr
    # the view is between the top / bottom dock rows (the Selection Bar's row
    # included): ROWS full y1 y2 topH botH - DRAW fits the canvas there
    read -r _ _ RY1 RY2 RTH RBH <<< "$(grep -m1 '^ROWS ' "$DK_DUMP")"
    (( ${RTH:-0} > 0 && RY1 > DOCK_TOP )) && DOCK_TOP=$RY1
    (( ${RBH:-0} > 0 && RY2 < DOCK_BOT )) && DOCK_BOT=$RY2
    read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
    read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
    ZW=$(( CW * Z / 100 )); ZH=$(( CH * Z / 100 ))
}
geo
info "view: x $CAN_LX..$CAN_RX  y $DOCK_TOP..$DOCK_BOT  (window $SCR_W x $SCR_H)"

# -- Hand double-click: fit, centred --
read -r HX HY HW <<< "$(awk '$1=="BTN" && $2=="toolbox" && $6=="hand" {print $7+int($9/2)" "$8+int($10/2)" "$9; exit}' "$DK_DUMP")"
if [[ -z "$HW" ]]; then
    fail "no Hand button in the toolbox dump"
else
    double_click "$HX" "$HY"; wait_for 0.6 "fit"
    dk_park; dk_settle; geo
    L=$(( OX - CAN_LX )); R=$(( CAN_RX + 1 - (OX + ZW) ))
    T=$(( OY - DOCK_TOP )); B=$(( DOCK_BOT + 1 - (OY + ZH) ))
    info "fit at $Z%: margins left $L right $R top $T bottom $B"
    (( L >= 0 && R >= 0 && (L - R) * (L - R) <= 4 )) && pass "fit: left and right margins match ($L / $R)" || fail "fit off-centre: left $L right $R"
    (( T >= 0 && B >= 0 && (T - B) * (T - B) <= 4 )) && pass "fit: top and bottom margins match ($T / $B)" || fail "fit off-centre: top $T bottom $B"
    screenshot "zoom-fit-center"
fi

# -- Zoom-tool region: its middle lands in the middle of the view --
key z; wait_for 0.3 "zoom tool"
geo
PX=60; PY=50 # canvas point the region is centred on (upper left, away from the middle)
SX=$(( OX + PX * Z / 100 )); SY=$(( OY + PY * Z / 100 ))
drag $(( SX - 30 )) $(( SY - 20 )) $(( SX + 30 )) $(( SY + 20 )); wait_for 0.6 "region zoom"
dk_park; dk_settle; geo
NX=$(( OX + PX * Z / 100 )); NY=$(( OY + PY * Z / 100 ))
VX=$(( (CAN_LX + CAN_RX + 1) / 2 )); VY=$(( (DOCK_TOP + DOCK_BOT + 1) / 2 ))
info "region zoom to $Z%: canvas ($PX,$PY) at $NX,$NY - view centre $VX,$VY"
TOL=$(( Z / 100 + 2 ))
DX=$(( NX - VX )); DY=$(( NY - VY ))
(( DX * DX <= TOL * TOL && DY * DY <= TOL * TOL )) && pass "the region's middle is in the middle of the view (off by $DX,$DY)" || fail "region zoom off-centre by $DX,$DY (tolerance $TOL)"
(( Z > 200 )) && pass "the region zoom zoomed in ($Z%)" || fail "no zoom in ($Z%)"
screenshot "zoom-region-center"
key b
assert_no_crash
rm -rf "$ZF_DIR"
