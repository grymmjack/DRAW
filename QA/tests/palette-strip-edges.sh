#!/bin/bash
# =============================================================================
# palette-strip-edges.sh — QA test: the colour strip docks on any edge (Rick
# 2026-11-16: "color strip could be docked to top, left, or right, in addition
# to bottom ... it should honor the configuration of the palette strip ... the
# dropdown picker should be above the color chips").
# For LEFT, TOP, RIGHT, then BOTTOM again - picked from the strip's own
# right-click menu (EDGE = flyout, PSM row 4):
#   - PSTRIP says the edge, and the strip lies on it (a side strip from the
#     menu bar / window top down to the status bar, a top one under the menu)
#   - the docks lay out beside / under it (SCR LX / RX, ROWS y1)
#   - its rows setting turns sideways: a side strip is MAX_ROWS-ish columns of
#     chips, the dropdown above them
#   - clicking chip 3 makes it the FG (PCYC fgIdx), the dropdown opens the
#     palette menu beside / under the strip, Escape closes it
#   - saved: PALETTE_STRIP_EDGE in DRAW.cfg; dk_check (dock invariants + seams)
# Then LEFT again + a restart: still on the left.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Colour strip on every edge Test ==="
dk_begin
dk_check "start"

strip() { read -r _ ST_Y ST_H ST_FIT _ _ _ _ ST_EDGE ST_X ST_W ST_ON <<< "$(grep -m1 '^PSTRIP ' "$DK_DUMP")"; }
geo()   { read -r _ G_CX G_CY G_CW G_CH G_PER G_LINES G_SCR G_VERT _ <<< "$(grep -m1 '^PSTRIPG ' "$DK_DUMP")"; }
psm()   { PM_RX=""; read -r _ PM_RX PM_RY PM_RW PM_SUB PM_SX PM_SY PM_SW PM_SN <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"; }
fgidx() { read -r _ _ _ FG_IDX _ <<< "$(grep -m1 '^PCYC ' "$DK_DUMP")"; }
row_y() { echo $(( $1 + 2 + $2 * 12 + 6 )); }
# the viewport point of shown chip K (before the scroll)
chip_xy() {
    geo
    if (( G_VERT )); then
        TX=$(( G_CX + ($1 / G_PER) * G_CW + G_CW / 2 )); TY=$(( G_CY + ($1 % G_PER) * G_CH + G_CH / 2 ))
    else
        TX=$(( G_CX + ($1 % G_PER) * G_CW + G_CW / 2 )); TY=$(( G_CY + ($1 / G_PER) * G_CH + G_CH / 2 ))
    fi
}
# a blank point on the strip (no chip, no button, no dropdown): past the last chip
blank_xy() {
    strip; geo
    if (( G_VERT )); then TX=$(( ST_X + ST_W / 2 )); TY=$(( ST_Y + ST_H - 4 ))
    else TX=$(( ST_X + 1 )); TY=$(( ST_Y + ST_H / 2 )); fi
}
NAMES=(BOTTOM TOP LEFT RIGHT)

# EDGE (0 bottom, 1 top, 2 left, 3 right) from the strip's size menu
set_edge() {
    local e=$1
    blank_xy
    right_click "$TX" "$TY"; wait_for 0.6 "strip menu"; dk_settle; psm
    if [[ -z "$PM_RX" ]]; then fail "${NAMES[e]}: no strip menu at ($TX,$TY)"; key Escape; return 1; fi
    hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" 4)"; wait_for 0.5 "EDGE flyout"; dk_settle; psm
    if [[ "$PM_SUB" != 4 || "$PM_SN" != 4 ]]; then fail "${NAMES[e]}: the EDGE flyout did not open (sub '$PM_SUB', rows '$PM_SN')"; key Escape; return 1; fi
    click $(( PM_SX + PM_SW / 2 )) "$(row_y "$PM_SY" "$e")"; wait_for 0.8 "${NAMES[e]}"; dk_park; dk_settle
}

check_edge() {
    local e=$1 n=${NAMES[$1]} lx rx
    strip; geo; dk_scr; dk_rows
    read -r _ _ _ lx rx _ <<< "$(grep -m1 '^SCR ' "$DK_DUMP")"
    [[ "$ST_EDGE" == "$e" && "$ST_ON" == 1 ]] && pass "$n: the strip is on its edge" || fail "$n: PSTRIP edge '$ST_EDGE' shown '$ST_ON'"
    case $e in
        0) (( ST_X == 0 && ST_W == SCR_W && G_VERT == 0 )) && pass "$n: across the window above the status bar (y $ST_Y)" || fail "$n: x $ST_X w $ST_W vert $G_VERT" ;;
        1) (( ST_Y <= 12 && G_VERT == 0 )) && pass "$n: under the menu bar (y $ST_Y h $ST_H)" || fail "$n: y $ST_Y vert $G_VERT"
           (( DOCK_TOP >= ST_Y + ST_H )) && pass "$n: the docks / canvas start under it (y $DOCK_TOP)" || fail "$n: the dock area starts at $DOCK_TOP, inside the strip (ends $(( ST_Y + ST_H )))" ;;
        2) (( ST_X == 0 && G_VERT == 1 && ST_H > ST_W )) && pass "$n: a column down the left (w $ST_W h $ST_H)" || fail "$n: x $ST_X w $ST_W h $ST_H vert $G_VERT"
           (( lx >= ST_W )) && pass "$n: the docks lay out right of it (LX $lx)" || fail "$n: dock LX $lx under the strip (w $ST_W)" ;;
        3) (( ST_X + ST_W == SCR_W && G_VERT == 1 && ST_H > ST_W )) && pass "$n: a column down the right (x $ST_X w $ST_W)" || fail "$n: x $ST_X w $ST_W vert $G_VERT"
           (( rx < ST_X )) && pass "$n: the docks lay out left of it (RX $rx)" || fail "$n: dock RX $rx under the strip (x $ST_X)" ;;
    esac
    if (( G_VERT )); then
        # the rows setting turned sideways: as many columns as the width holds, the dropdown above the chips
        local pn; read -r _ _ pn _ <<< "$(grep -m1 '^PALNAME ' "$DK_DUMP")"
        (( G_LINES >= 1 && G_CW * G_LINES <= ST_W )) && pass "$n: $G_LINES column(s) of $G_PER chips" || fail "$n: lines $G_LINES cell $G_CW in w $ST_W"
        (( pn < G_CY )) && pass "$n: the dropdown is above the chips (y $pn < $G_CY)" || fail "$n: dropdown y $pn, chips from $G_CY"
    fi
    # chip 3 -> FG
    chip_xy 3; click "$TX" "$TY"; wait_for 0.5 "chip 3"; dk_park; dk_settle; fgidx
    [[ "$FG_IDX" == $(( (3 + G_SCR) % 32 )) || "$FG_IDX" == 3 ]] && pass "$n: clicking chip 3 sets the FG (idx $FG_IDX)" || fail "$n: chip 3 at ($TX,$TY) gave FG idx '$FG_IDX'"
    # the dropdown opens the palette menu beside / under the strip
    local nx ny nw nh px py pw ph
    read -r _ nx ny nw nh <<< "$(grep -m1 '^PALNAME ' "$DK_DUMP")"
    click $(( nx + nw / 2 )) $(( ny + nh / 2 )); wait_for 0.7 "palette menu"; dk_settle
    read -r _ _ px py pw ph <<< "$(grep -m1 '^POPUP palettemenu ' "$DK_DUMP")"
    if [[ -z "$px" ]]; then fail "$n: the dropdown opened no palette menu"
    else
        case $e in
            0) (( py + ph <= ST_Y + 1 )) && pass "$n: palette menu above the strip" || fail "$n: menu $py+$ph over the strip ($ST_Y)" ;;
            1) (( py >= ST_Y + ST_H - 1 )) && pass "$n: palette menu under the strip" || fail "$n: menu y $py inside the strip" ;;
            2) (( px >= ST_X + ST_W - 1 )) && pass "$n: palette menu beside the strip" || fail "$n: menu x $px over the strip" ;;
            3) (( px + pw <= ST_X + 1 )) && pass "$n: palette menu beside the strip" || fail "$n: menu $px+$pw over the strip ($ST_X)" ;;
        esac
    fi
    key Escape; wait_for 0.4 "menu closed"; dk_park; dk_settle
    grep -q "^PALETTE_STRIP_EDGE=$n" "$QA_CFG" && pass "$n: saved (PALETTE_STRIP_EDGE=$n)" || fail "$n: not saved ($(grep '^PALETTE_STRIP_EDGE' "$QA_CFG"))"
    dk_check "strip $n"
    screenshot "palette-strip-$n"
}

for e in 2 1 3 0; do
    set_edge "$e" && check_edge "$e"
done

# --- persists ----------------------------------------------------------------------
set_edge 2
draw_quit
rm -f "$DK_DUMP"
draw_launch 15
dk_begin
strip
[[ "$ST_EDGE" == 2 ]] && pass "still on the left after a restart" || fail "after a restart: edge '$ST_EDGE'"
dk_check "after restart"
set_edge 0

assert_window_exists
info "=== Colour strip on every edge Test PASSED ==="
