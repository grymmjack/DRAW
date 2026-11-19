#!/bin/bash
# =============================================================================
# panel-scale-half.sh — QA test: half-step panel Scales, on the MyPaint Brushes
# palette first (Rick 2026-11-18: "is it possible to get scale in .5 amounts?
# 1.5x 2.5x 3.5x ... let's try it with the my paint brushes panel").
#
#   1. its handle menu offers 1.5x .. 5.5x between the whole steps (rows 31 ..,
#      DOCK_ACT_SCALE_HALF + k = k.5x); so does the Layers' (every panel takes them)
#   2. 1.5x: its own surface at k 1.5, MYPAINT_PANEL_SCALE=1.5 saved, its column
#      3/4 of Auto's (Auto = 2 here), and the pointer finds the cell drawn under it
#      (hover + click pick that brush) - first, middle and last cells of a row
#   3. 2.5x: k 2.5, 5/4 of Auto, the pointer still lands
#   4. a relaunch reads 1.5 back from the cfg
#   5. Auto puts it back into the viewport
#   6. a docked panel, the Layers, at 1.5x: rows 3/4 of Auto's, hover + click land
# Panel units -> viewport px: v = vx + (u - vx) * k / ds (PSURF line: vx vy, ds 2).
# Dump: PSURF id on k vx vy vw vh uw uh ready; MYPP vis x y w h group nGroups n
# cell cols rowsFit rowsAll scroll gridX gridY hover cur name (its units).
# (the scale key is not pinned in QA-OPTIONS: --option keys are never saved)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE MYPAINT_PANEL=TRUE MYPAINT_BRUSH= MYPAINT_SET=Classic MYPAINT_CELL=48
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: half-step Scale (MyPaint Brushes) ==="

DS=2
mp_read() { read -r _ M_VIS M_X M_Y M_W M_H M_G M_NG M_N M_CELL M_COLS M_RF M_RA M_SC M_GX M_GY M_HOV M_CUR M_GNAME <<< "$(grep -m1 '^MYPP ' "$DK_DUMP")"; }
surf() { S_ON=; S_K=; read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
saved() { grep -q "^$1=$2[[:space:]]*\$" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1=" "$QA_CFG")', want $2"; }
# units -> viewport px at Scale K (awk: K may be 1.5)
u2v() { awk -v u="$1" -v o="$2" -v k="$3" -v ds="$DS" 'BEGIN { printf "%d", o + (u - o) * k / ds }'; }
# NAME VALUE LABEL: right-click NAME's handle, pick menu row VALUE
pick_scale() { dk_rmenu "$1" || return 1; dk_pick "$2" "$3"; }
# K LABEL: the pointer on cells 0, the row's middle and its last: each hovers its
# cell; a click on the last picks that brush
cells_land() {
    local k=$1 c i cx cy vx vy ok=1
    mp_read; surf 11
    for c in 0 $(( M_COLS / 2 )) $(( M_COLS - 1 )); do
        cx=$(( M_GX + c * (M_CELL + 2) + M_CELL / 2 )); cy=$(( M_GY + M_CELL / 2 ))
        vx=$(u2v "$cx" "$S_VX" "$k"); vy=$(u2v "$cy" "$S_VY" "$k")
        hover "$vx" "$vy"; wait_for 0.3 "hover"; hover $(( vx + 1 )) "$vy"; wait_for 0.4 "hover"; dk_settle
        mp_read
        if (( M_HOV == 100 + c )); then info "$2: cell $c at $vx,$vy hovers it"; else ok=0; fail "$2: the pointer on cell $c ($vx,$vy) hovers '$M_HOV' (want $(( 100 + c )))"; fi
    done
    (( ok )) && pass "$2: the pointer finds cells 0, $(( M_COLS / 2 )), $(( M_COLS - 1 )) of the row"
    click "$vx" "$vy"; wait_for 0.8 "pick the last cell"; dk_park; dk_settle; mp_read
    (( M_CUR == M_COLS - 1 )) && pass "$2: a click picks the brush drawn under it (cell $M_CUR)" || fail "$2: click on cell $(( M_COLS - 1 )): brush in use is cell '$M_CUR'"
}

dk_begin
dk_p mypaint || fail "no mypaint panel in the dump"
W0=$P_W; mp_read; C0=$M_CELL
info "Auto: ${W0}px wide, $M_COLS columns of $M_CELL"
grep -q '^PSURF 11 ' "$DK_DUMP" && fail "Auto: already a surface" || pass "Auto: drawn into the viewport"

# --- 1. the menu ---------------------------------------------------------------
if dk_rmenu mypaint; then
    n=0; for v in 31 32 33 34 35; do dk_menu_has "$v" && n=$(( n + 1 )); done
    (( n == 5 )) && pass "the Scale menu has 1.5x .. 5.5x" || fail "half-step rows: $n of 5 (31-35)"
    dk_menu_has 21 && dk_menu_has 22 && pass "... and the whole steps" || fail "whole-step rows missing"
    key Escape; wait_for 0.4 "close"; dk_settle
fi
if dk_rmenu layers; then
    dk_menu_has 31 && dk_menu_has 33 && pass "the Layers menu offers half steps too (every panel does)" || fail "the Layers menu: no 1.5x / 3.5x rows"
    key Escape; wait_for 0.4 "close"; dk_settle
fi

# --- 2. 1.5x -------------------------------------------------------------------
if pick_scale mypaint 31 "1.5x"; then
    surf 11
    [[ "$S_ON" == -1 && "$S_K" == 1.5 && "$S_RDY" == -1 ]] && pass "1.5x: its own surface at k 1.5 (${S_UW}x$S_UH units in ${S_VW}x$S_VH px)" || fail "1.5x: PSURF '$(grep '^PSURF 11 ' "$DK_DUMP")'"
    saved MYPAINT_PANEL_SCALE 1.5
    dk_p mypaint; W15=$P_W
    (( W15 * 4 >= W0 * 3 - 8 && W15 * 4 <= W0 * 3 + 8 )) && pass "1.5x: its column 3/4 of Auto's ($W0 -> $W15)" || fail "1.5x: width $W0 -> $W15 (want about $(( W0 * 3 / 4 )))"
    mp_read
    (( M_CELL == C0 )) && pass "1.5x: the same $M_CELL-unit cells" || info "1.5x: cell $C0 -> $M_CELL units"
    cells_land 1.5 "1.5x"
    dk_check "mypaint at 1.5x"
    screenshot "panel-scale-half-1.5x"
fi

# --- 3. 2.5x -------------------------------------------------------------------
if pick_scale mypaint 32 "2.5x"; then
    surf 11
    [[ "$S_K" == 2.5 ]] && pass "2.5x: k 2.5" || fail "2.5x: PSURF '$(grep '^PSURF 11 ' "$DK_DUMP")'"
    saved MYPAINT_PANEL_SCALE 2.5
    dk_p mypaint; W25=$P_W
    (( W25 * 4 >= W0 * 5 - 8 && W25 * 4 <= W0 * 5 + 8 )) && pass "2.5x: its column 5/4 of Auto's ($W0 -> $W25)" || fail "2.5x: width $W0 -> $W25 (want about $(( W0 * 5 / 4 )))"
    cells_land 2.5 "2.5x"
    dk_check "mypaint at 2.5x"
    screenshot "panel-scale-half-2.5x"
fi

# --- 4. a relaunch keeps 1.5 -----------------------------------------------------
if pick_scale mypaint 31 "1.5x again"; then
    info "Relaunching DRAW"
    draw_quit
    rm -f "$DK_DUMP"
    draw_launch 15
    dk_begin
    surf 11
    [[ "$S_K" == 1.5 ]] && pass "after a relaunch: still 1.5x" || fail "after a relaunch: PSURF '$(grep '^PSURF 11 ' "$DK_DUMP")' (cfg '$(grep '^MYPAINT_PANEL_SCALE=' "$QA_CFG")')"
fi

# --- 5. Auto -------------------------------------------------------------------------
if pick_scale mypaint 20 "Auto"; then
    grep -q '^PSURF 11 ' "$DK_DUMP" && fail "Auto: still a surface" || pass "Auto: drawn into the viewport again"
    dk_p mypaint
    (( P_W == W0 )) && pass "Auto: the old width ($P_W)" || fail "Auto: ${P_W}px, was ${W0}px"
    saved MYPAINT_PANEL_SCALE 0
fi
# --- 6. a docked panel (the Layers) at 1.5x: rows 3/4 of Auto's, the pointer finds them --
geo() { read -r _ G_HDR G_ROW G_BAR <<< "$(grep -m1 '^LPGEO ' "$DK_DUMP")"; }
lphit() { awk '$1=="LPHIT" {print $2; exit}' "$DK_DUMP"; }
lcur() { awk '$1=="LPANEL" {print $3; exit}' "$DK_DUMP"; }
hover_row() { # N: hover row N's middle -> RY, H = the layer under it
    RY=$(( P_Y + G_HDR + G_ROW * $1 + G_ROW / 2 ))
    hover $(( P_X + P_W / 2 )) "$RY"; wait_for 0.3 "hover"
    hover $(( P_X + P_W / 2 + 1 )) "$RY"; wait_for 0.4 "hover"; dk_settle
    H=$(lphit)
}
park_mouse; key ctrl+shift+n; wait_for 0.6 "layer 2"; key ctrl+shift+n; wait_for 0.6 "layer 3"; dk_settle
dk_p layers; geo; R0=$G_ROW
if pick_scale layers 31 "layers 1.5x"; then
    surf 4
    [[ "$S_ON" == -1 && "$S_K" == 1.5 ]] && pass "layers 1.5x: its own surface at k 1.5" || fail "layers 1.5x: PSURF '$(grep '^PSURF 4 ' "$DK_DUMP")'"
    saved LAYER_PANEL_SCALE 1.5
    dk_p layers; geo
    (( G_ROW * 4 >= R0 * 3 - 4 && G_ROW * 4 <= R0 * 3 + 4 )) && pass "layers 1.5x: rows 3/4 of Auto's ($R0 -> $G_ROW)" || fail "layers 1.5x: row $R0 -> $G_ROW (want about $(( R0 * 3 / 4 )))"
    hover_row 0; TOP=$H
    (( TOP > 0 )) && [[ "$TOP" == "$(lcur)" ]] && pass "layers 1.5x: the top row is the current layer ($TOP)" || fail "layers 1.5x: top row hit '$TOP', current '$(lcur)'"
    hover_row 2; BOT=$H
    (( BOT > 0 && BOT != TOP )) && pass "layers 1.5x: the third row is another layer ($BOT)" || fail "layers 1.5x: third row hit '$BOT' (top $TOP)"
    click $(( P_X + P_W / 2 )) "$RY"; wait_for 0.5 "select the third row"; dk_park; dk_settle
    [[ "$(lcur)" == "$BOT" ]] && pass "layers 1.5x: a click on the third row selects it" || fail "layers 1.5x: clicked layer $BOT, current is $(lcur)"
    dk_check "layers at 1.5x"
    screenshot "panel-scale-half-layers-1.5x"
    pick_scale layers 20 "layers Auto" && saved LAYER_PANEL_SCALE 0
fi
assert_no_crash
info "=== Panels: half-step Scale: done ==="
