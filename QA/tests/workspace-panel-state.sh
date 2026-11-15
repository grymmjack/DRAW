#!/bin/bash
# =============================================================================
# workspace-panel-state.sh — QA test: a workspace keeps its panels' state -
# scales, zooms, the color strip's sizes (Rick, 2026-11-14: "workspaces need
# to remember their scales for the panels, the zooms of the panel states ...
# the size, height, width" / "when someone saves a workspace it should be
# 100% recallable, even the panel configurations themselves").
#
#  1. Default: the user's values (DRAW.cfg)
#  2. in workspace PANEL A: the edit bar at 1x and the color strip at 1 row
#     -> saved into panel-a.workspace ([PANELS]), not into DRAW.cfg
#  3. Default again: the user's own values come back
#  4. PANEL A again: 1x and 1 row come back
#  5. Save Current Layout As "panel b": every panel key is in its [PANELS]
#  6. a restart straight into PANEL B: its values, from the file
#
# Dump: WSA <id> | WSPN on saves drawerCols N editbarScale N palRows N ... |
# PSTRIP / PSM (the strip's size menu) | DMENU / DMENUR (the handle menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-panel-state STOCK_DEFAULT_LAYOUT=0 WORKSPACE_SAVE_PROMPT=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# (the strip rows / edit bar scale are not --option pins: those are never saved, and this checks DRAW.cfg)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
WSD="/tmp/draw-qa-ws-panel-state"
mkdir -p "$WSD"; rm -f "$WSD"/*.workspace
printf '; QA fixture\n[WORKSPACE]\nNAME=Panel A\n' > "$WSD/panel-a.workspace"

pal() { # QUERY - run a command palette entry
    local try
    for try in 1 2 3; do
        dk_park; key question; wait_for 1.0 "palette"
        grep -q '^POPUP cmdpalette' "$DK_DUMP" && break
    done
    type_text "$1"; wait_for 1.2 "filtered"; key Return; wait_for 1.5 "$1"; dk_settle
}
wsa() { awk '$1=="WSA" {print $2}' "$DK_DUMP"; }
wspn() { read -r _ W_ON W_SAVES _ W_DC _ W_EBS _ W_ROWS _ <<< "$(grep -m1 '^WSPN ' "$DK_DUMP")"; }
psm() { PM_RX=""; read -r _ PM_RX PM_RY PM_RW PM_SUB PM_SX PM_SY PM_SW PM_SN <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"; }
row_y() { echo $(( $1 + 2 + $2 * 12 + 6 )); }
strip_rows() { # SUBROW - the color strip's Max Rows submenu, row SUBROW (= SUBROW + 1 rows)
    local sy; sy=$(awk '$1=="PSTRIP" {print $2}' "$DK_DUMP")
    right_click 1 $(( sy + 2 )); wait_for 0.6 "strip menu"; dk_settle; psm
    [[ -n "$PM_RX" ]] || { fail "no strip menu"; return 1; }
    hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" 0)"; wait_for 0.5 "max rows"; dk_settle; psm
    click $(( PM_SX + PM_SW / 2 )) "$(row_y "$PM_SY" "$1")"; wait_for 0.8 "picked"; dk_park; dk_settle
}
pick_scale() { # NAME DPID VALUE (20 Auto, 20+k = kx) - as panel-scale-grip.sh
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

info "=== Workspaces keep their panels' state ==="
dk_begin
pal "reload workspaces" # (the fixture was written after DRAW scanned the folder)
wspn
(( W_ROWS == 3 && W_EBS == 0 && W_ON == 0 )) && pass "Default: 3 strip rows, edit bar at Auto" || fail "Default at the start: rows $W_ROWS editbar $W_EBS on $W_ON"

pal "workspace: panel a"
[[ "$(wsa)" == panel-a ]] && pass "PANEL A is active" || fail "active '$(wsa)'"
wspn; S0=$W_SAVES
(( W_ON == 1 )) && pass "its panel keys are in the overlay" || fail "WSPN on $W_ON"
pick_scale editbar 5 21
strip_rows 0
wait_for 1.0 "the change is looked at"; dk_settle; wspn
(( W_EBS == 1 && W_ROWS == 1 )) && pass "in PANEL A: the edit bar at 1x, the strip at 1 row" || fail "in PANEL A: editbar $W_EBS rows $W_ROWS"
(( W_SAVES > S0 )) && pass "saved into the workspace ($(( W_SAVES - S0 )) save(s))" || fail "no workspace save (saves $W_SAVES)"
F="$WSD/panel-a.workspace"
grep -q '^\[PANELS\]' "$F" && grep -q '^EDIT_BAR_SCALE=1' "$F" && grep -q '^PALETTE_MAX_ROWS=1' "$F" \
    && pass "panel-a.workspace has them in [PANELS]" || fail "panel-a.workspace: $(grep -A8 '^\[PANELS\]' "$F" | tr '\n' ' ')"
grep -q '^EDIT_BAR_SCALE=0' "$QA_CFG" && grep -q '^PALETTE_MAX_ROWS=3' "$QA_CFG" \
    && pass "DRAW.cfg keeps the user's own (Auto, 3 rows)" || fail "DRAW.cfg: $(grep -E '^(EDIT_BAR_SCALE|PALETTE_MAX_ROWS)=' "$QA_CFG" | tr '\n' ' ')"

pal "workspace: default"
wspn
[[ "$(wsa)" == default ]] && (( W_EBS == 0 && W_ROWS == 3 )) && pass "Default again: the user's own back (Auto, 3 rows)" || fail "Default: '$(wsa)' editbar $W_EBS rows $W_ROWS"
read -r _ _ PS_ON PS_K _ <<< "$(grep -m1 '^PSURF 5 ' "$DK_DUMP")"
[[ "$PS_ON" != -1 ]] && pass "the edit bar is off its own surface again" || fail "PSURF 5: on $PS_ON k $PS_K"

pal "workspace: panel a"
wspn
(( W_EBS == 1 && W_ROWS == 1 )) && pass "PANEL A again: 1x and 1 row come back" || fail "PANEL A again: editbar $W_EBS rows $W_ROWS"
read -r _ _ PS_ON PS_K _ <<< "$(grep -m1 '^PSURF 5 ' "$DK_DUMP")"
[[ "$PS_ON" == -1 && "$PS_K" == 1 ]] && pass "the edit bar is drawn at 1x (its own surface)" || fail "PSURF 5: on $PS_ON k $PS_K"
screenshot "workspace-panel-state"

pal "save current layout"; type_text "panel b"; wait_for 0.5 "typed"; key Return; wait_for 2.0 "saved"; dk_settle
FB="$WSD/panel-b.workspace"
N=$(awk '/^\[PANELS\]/{p=1;next} /^\[/{p=0} p&&/=/' "$FB" 2>/dev/null | wc -l)
(( N >= 70 )) && pass "Save Current Layout As: [PANELS] holds every panel key ($N)" || fail "panel-b.workspace [PANELS]: $N keys"
grep -q '^EDIT_BAR_SCALE=1' "$FB" && grep -q '^PALETTE_MAX_ROWS=1' "$FB" && pass "with this layout's values" || fail "panel-b values: $(grep -E '^(EDIT_BAR_SCALE|PALETTE_MAX_ROWS)=' "$FB" | tr '\n' ' ')"
pal "workspace: default"

# a restart straight into PANEL B (as a remembered workspace starts): read from disk
draw_quit
draw_settle
DRAW_TEST_OPTIONS+=" --option WORKSPACE=panel-b"
draw_launch 15
wait_for 1.5 "launched in panel b"
dk_begin
wspn
[[ "$(wsa)" == panel-b ]] && (( W_EBS == 1 && W_ROWS == 1 )) && pass "a restart in PANEL B: 1x and 1 row from its file" || fail "restart: '$(wsa)' editbar $W_EBS rows $W_ROWS"
assert_no_crash
rm -rf "$WSD"
info "=== Workspaces keep their panels' state: done ==="
