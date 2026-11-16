#!/bin/bash
# =============================================================================
# layer-bar.sh — QA test: the layer bar in the Layers panel (Rick, 2026-11-14:
# "Layer panel bar at top or bottom (user's choice): [blend mode v] [eye]
# [lock] [opacity slider]; blend = dropdown; opacity wheel / drag / click /
# hotkeys; eye = show/hide all (toggle the visible ones); lock = lock all but
# current / unlock all").
#
# LAYER_PANEL_BAR = TOP (the default; DRAW.qa.cfg pins OFF so the other tests
# keep their geometry) / BOTTOM / OFF. Off, the layer menu has SHOW LAYER BAR;
# on, right-click the bar: BAR AT TOP / BAR AT BOTTOM / HIDE BAR. The rows
# move down under it (or stop above it) and still take clicks.
#   blend    click: the blend popup, pick a mode; wheel: the next mode
#   opacity  click / drag / wheel; 1-0 with the pointer on it (elsewhere 1-0 is
#            still the paint opacity)
#   eye      hides the visible layers; again: shows those (a layer hidden before
#            stays hidden)
#   lock     opacity-locks every layer but the current one; again: unlocks all
#
# Dump: LPBAR where y h bx bw ex lx sx sw mode opacity anyVisible othersLocked
# hot; LPBPOP / LPBPOPR (the blend popup); LPGEO listTop row listBottom;
# LPMENU / LPMENUR; LPANEL; LAYER i z parent type collapsed visible ...; PAINT.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Layers: the layer bar ==="

geo() { read -r _ G_TOP G_ROW G_BOT <<< "$(grep -m1 '^LPGEO ' "$DK_DUMP")"; }
bar() { read -r _ B_WHERE B_Y B_H B_BX B_BW B_EX B_LX B_SX B_SW B_MODE B_OP B_VIS B_LOCK B_HOT <<< "$(grep -m1 '^LPBAR ' "$DK_DUMP")"; }
menu() { read -r _ M_OPEN M_THUMB M_X M_Y M_W M_N <<< "$(grep -m1 '^LPMENU ' "$DK_DUMP")"; }
mrow() { awk -v v="$1" '$1=="LPMENUR" && $3==v {print $4" "$5; exit}' "$DK_DUMP"; }
cur() { awk '$1=="LPANEL" {print $3; exit}' "$DK_DUMP"; }
paint_op() { awk '$1=="PAINT" {print $2; exit}' "$DK_DUMP"; }
vis() { awk -v l="$1" '$1=="LAYER" && $2==l {print $7; exit}' "$DK_DUMP"; }
saved() { grep -q "^$1=$2\b" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1=" "$QA_CFG")', want $2"; }
settle() { wait_for "${2:-0.5}" "$1"; dk_park; dk_settle; }
pick() { # VALUE in the open layer menu
    local ry rh; read -r ry rh <<< "$(mrow "$1")"
    if [[ -z "$ry" ]]; then fail "no menu row $1"; key Escape; return 1; fi
    click $(( M_X + M_W / 2 )) $(( ry + rh / 2 )); settle "menu row $1" 0.6
}
row_y() { echo $(( P_Y + G_TOP + G_ROW * $1 + G_ROW / 2 )); }
BY() { echo $(( B_Y + B_H / 2 )); }
near() { (( $1 >= $2 - $3 && $1 <= $2 + $3 )); }

dk_begin
park_mouse; key ctrl+shift+n; wait_for 0.6 "layer 2"; key ctrl+shift+n; wait_for 0.6 "layer 3"; dk_settle
dk_p layers || fail "no layers panel in the dump"
geo; bar; TOP0=$G_TOP; L3=$(cur)
[[ "$B_WHERE" == 0 ]] && pass "QA config: the bar off" || fail "the bar is $B_WHERE at the start (DRAW.qa.cfg pins OFF)"

# --- off: SHOW LAYER BAR in the layer menu -> at the top ---------------------
right_click $(( P_X + P_W / 2 )) "$(row_y 0)"; settle "the layer menu" 0.6; menu
if [[ -n "$(mrow 221)" ]]; then pass "off: the layer menu has SHOW LAYER BAR"; pick 221; else fail "off: no SHOW LAYER BAR"; key Escape; fi
saved LAYER_PANEL_BAR TOP
geo; bar
[[ "$B_WHERE" == 1 && "$G_TOP" == $(( TOP0 + B_H )) && "$B_Y" == $(( P_Y + TOP0 )) ]] && pass "top: under the header (y $B_Y, ${B_H}px), the rows ${B_H}px lower" || fail "top: LPBAR '$(grep '^LPBAR ' "$DK_DUMP")', list top $TOP0 -> $G_TOP"
screenshot "layer-bar-top"

# the rows still take clicks, under the bar
click $(( P_X + P_W - 24 )) "$(row_y 1)"; settle "click row 1"
L2=$(cur)
[[ "$L2" != "$L3" ]] && pass "a click on the second row selects it ($L2)" || fail "row 1 click: current still $L3"
click $(( P_X + P_W - 24 )) "$(row_y 0)"; settle "click row 0"
[[ "$(cur)" == "$L3" ]] && pass "a click on the top row selects it again" || fail "row 0 click: current $(cur), want $L3"

# --- opacity: click, drag, wheel, digits -------------------------------------
bar
click $(( B_SX + B_SW / 4 )) "$(BY)"; settle "click a quarter along the slider"; bar
near "$B_OP" 64 8 && pass "slider click a quarter along: opacity $B_OP (of 255)" || fail "slider click: opacity $B_OP, want about 64"
drag $(( B_SX + B_SW / 4 )) "$(BY)" $(( B_SX + B_SW + 20 )) "$(BY)"; settle "drag past its end"; bar
[[ "$B_OP" == 255 ]] && pass "slider drag past its end: 255" || fail "slider drag: opacity $B_OP"
scroll_down $(( B_SX + B_SW / 2 )) "$(BY)"; scroll_down $(( B_SX + B_SW / 2 )) "$(BY)"; settle "wheel down twice"; bar
[[ "$B_OP" == 225 ]] && pass "wheel down twice on the slider: 225" || fail "slider wheel: opacity $B_OP, want 225"
P0=$(paint_op)
hover $(( B_SX + B_SW / 2 )) "$(BY)"; wait_for 0.3 "hover"; hover $(( B_SX + B_SW / 2 + 1 )) "$(BY)"; wait_for 0.3 "hover"; dk_settle; bar
[[ "$B_HOT" == -1 ]] && pass "the pointer on the slider: hot" || fail "hot '$B_HOT' over the slider"
key 5; wait_for 0.4 "5"; dk_settle; bar
[[ "$B_OP" == 127 && "$(paint_op)" == "$P0" ]] && pass "5 on the slider: the layer 50% (127), the paint opacity kept ($P0)" || fail "5 on the slider: layer $B_OP, paint $(paint_op) (was $P0)"
park_mouse; key 3; wait_for 0.4 "3"; dk_settle; bar
[[ "$(paint_op)" == 30 && "$B_OP" == 127 ]] && pass "3 elsewhere: the paint opacity 30, the layer kept" || fail "3 elsewhere: paint $(paint_op), layer $B_OP"
key 0; wait_for 0.3 "paint 100"

# --- blend: the popup, then the wheel ------------------------------------------
click $(( B_BX + B_BW / 2 )) "$(BY)"; settle "the blend dropdown" 0.6
read -r _ BP_OPEN BP_X BP_Y <<< "$(grep -m1 '^LPBPOP ' "$DK_DUMP")"
read -r BRY BRH <<< "$(awk '$1=="LPBPOPR" && $3==1 {print $4" "$5; exit}' "$DK_DUMP")"
if [[ "$BP_OPEN" == -1 && -n "$BRY" ]]; then
    pass "the dropdown opens the blend popup"
    click $(( BP_X + 30 )) $(( BRY + BRH / 2 )); settle "MULTIPLY"; bar
    [[ "$B_MODE" == 1 ]] && pass "picked MULTIPLY: blend mode 1" || fail "blend popup pick: mode $B_MODE"
else
    fail "no blend popup (LPBPOP '$(grep '^LPBPOP ' "$DK_DUMP")')"; key Escape
fi
scroll_down $(( B_BX + B_BW / 2 )) "$(BY)"; settle "wheel on the dropdown"; bar
[[ "$B_MODE" == 2 ]] && pass "wheel down on the dropdown: the next mode (2)" || fail "dropdown wheel: mode $B_MODE"

# --- eye: hide the visible ones, show them again ------------------------------
L1=$(awk -v a="$L2" -v b="$L3" '$1=="LAYER" && $2!=a && $2!=b {print $2; exit}' "$DK_DUMP")
click $(( P_X + 6 )) "$(row_y 1)"; settle "hide layer $L2 with its own eye"
[[ "$(vis "$L2")" == 0 ]] || fail "layer $L2 not hidden by its row's eye"
click $(( B_EX + 5 )) "$(BY)"; settle "the bar's eye"; bar
[[ "$B_VIS" == 0 && "$(vis "$L1")" == 0 && "$(vis "$L3")" == 0 ]] && pass "eye: every layer hidden" || fail "eye: any visible $B_VIS, layers $L1 $(vis "$L1") $L3 $(vis "$L3")"
click $(( B_EX + 5 )) "$(BY)"; settle "the bar's eye again"; bar
[[ "$(vis "$L1")" == -1 && "$(vis "$L3")" == -1 && "$(vis "$L2")" == 0 ]] && pass "eye again: the layers it hid shown, the one hidden before still hidden" || fail "eye again: $L1 $(vis "$L1") $L2 $(vis "$L2") $L3 $(vis "$L3")"

# --- lock: all but the current one, then unlock all ----------------------------
click $(( B_LX + 5 )) "$(BY)"; settle "the bar's lock"; bar
[[ "$B_LOCK" == -1 ]] && pass "lock: every layer but the current one locked" || fail "lock: others locked '$B_LOCK'"
click $(( B_LX + 5 )) "$(BY)"; settle "the bar's lock again"; bar
[[ "$B_LOCK" == 0 ]] && pass "lock again: unlocked" || fail "lock again: others locked '$B_LOCK'"

# --- right-click: at the bottom, then hidden ------------------------------------
right_click $(( B_EX + 5 )) "$(BY)"; settle "the bar's menu" 0.6; menu
[[ "$M_OPEN" == -1 && -n "$(mrow 222)" && -z "$(mrow 707)" ]] && pass "right-click the bar: its menu (top / bottom / hide)" || fail "bar menu: open '$M_OPEN', rows $(grep -c '^LPMENUR' "$DK_DUMP")"
pick 222
saved LAYER_PANEL_BAR BOTTOM
dk_p layers; geo; bar
[[ "$B_WHERE" == 2 && "$G_TOP" == "$TOP0" && $(( B_Y + B_H )) == $(( P_Y + P_H - G_BOT + B_H )) ]] && pass "bottom: over the buttons (y $B_Y), the rows from the header again" || fail "bottom: LPBAR '$(grep '^LPBAR ' "$DK_DUMP")' panel $P_Y+$P_H, LPGEO $G_TOP $G_BOT"
click $(( P_X + P_W - 24 )) "$(row_y 1)"; settle "click row 1"
[[ "$(cur)" == "$L2" ]] && pass "bottom: a click on the second row selects it" || fail "bottom: row 1 click -> $(cur), want $L2"
click $(( B_SX + B_SW - 1 )) "$(BY)"; settle "the slider's end"; bar
(( B_OP >= 250 )) && pass "bottom: the slider works there ($B_OP)" || fail "bottom: slider end -> $B_OP"
screenshot "layer-bar-bottom"
right_click $(( B_EX + 5 )) "$(BY)"; settle "the bar's menu" 0.6; menu
pick 220
saved LAYER_PANEL_BAR OFF
geo; bar
[[ "$B_WHERE" == 0 && "$G_TOP" == "$TOP0" ]] && pass "hidden: gone, the list as before" || fail "hidden: LPBAR '$(grep '^LPBAR ' "$DK_DUMP")', list top $G_TOP"
assert_no_crash
info "=== Layers: the layer bar: done ==="
