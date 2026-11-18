#!/bin/bash
# =============================================================================
# palette-strip-size-menu.sh — QA test: right-click a blank part of the color
# strip for its size menu (Rick, 2026-11-14: "max-rows ... max-columns ...
# chip height ... chip width are all submenu popups ... so you can do it
# immediately without having to use settings dialog").
#
#  - a right-click left of the chips (no color): the menu, four rows
#  - hovering a row opens its submenu (8 / 6 / 29 / 29 values)
#  - a pick applies at once: the strip's height follows, DRAW.cfg keeps it
#  - a right-click ON a chip is still the background color (no menu)
#  - Esc / a click elsewhere closes it
#
# Dump: PSTRIP y h allFit maxRows maxPerRow chipH chipW | PSM rx ry rw subRow sbX sbY
# sbW sbN. Rows are 12 px from the box top + 2 (GUI/POPUP-MENU).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# (the strip's keys are NOT --option pins: those are never saved, and this checks the save)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Color strip: the size menu ==="
dk_begin

strip() { read -r _ ST_Y ST_H ST_FIT <<< "$(grep -m1 '^PSTRIP ' "$DK_DUMP")"; }
psm() { PM_RX=""; read -r _ PM_RX PM_RY PM_RW PM_SUB PM_SX PM_SY PM_SW PM_SN <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"; }
wspn() { read -r _ _ _ _ W_ROWS W_PER W_CH W_CW _ <<< "$(grep -m1 '^PSTRIP ' "$DK_DUMP")"; }
open_menu() { strip; right_click 1 $(( ST_Y + 2 )); wait_for 0.6 "the size menu"; dk_settle; psm; }
row_y() { echo $(( $1 + 2 + $2 * 12 + 6 )); } # BOX_Y ROW
pick() { # ROOT_ROW SUB_ROW LABEL
    open_menu
    [[ -n "$PM_RX" ]] || { fail "$3: no menu"; return 1; }
    hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" "$1")"; wait_for 0.5 "row $1"; dk_settle; psm
    (( PM_SUB == $1 )) || { fail "$3: hovering row $1 opened submenu '$PM_SUB'"; key Escape; return 1; }
    hover $(( PM_SX + PM_SW / 2 )) "$(row_y "$PM_SY" "$2")"; wait_for 0.3 "over the value"
    click $(( PM_SX + PM_SW / 2 )) "$(row_y "$PM_SY" "$2")"; wait_for 0.8 "$3"; dk_park; dk_settle
}

strip; H0=$ST_H; info "strip at y $ST_Y, $ST_H px tall"
open_menu
[[ -n "$PM_RX" ]] && pass "a right-click left of the chips opens the size menu ($PM_RX,$PM_RY ${PM_RW}w)" || fail "no size menu after a right-click at x 1"
screenshot "palette-strip-size-menu"
for spec in "0 8 max rows" "1 6 max columns" "2 29 chip height" "3 29 chip width"; do
    read -r R N NM <<< "$spec"
    hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" "$R")"; wait_for 0.5 "row $R"; dk_settle; psm
    (( PM_SUB == R && PM_SN == N )) && pass "$NM: its submenu, $N values" || fail "$NM: submenu row '$PM_SUB' with '$PM_SN' values (want $R / $N)"
done
screenshot "palette-strip-size-submenu"
key Escape; wait_for 0.5 "esc"; dk_settle; psm
[[ -z "$PM_RX" ]] && pass "Esc closes it" || fail "the menu stayed after Esc"

# Max Columns = 16 (row 0): more rows for a palette of more than 16 colors
pick 1 0 "max columns 16"; wspn; strip; HC=$ST_H
(( W_PER == 16 )) && pass "Max Columns 16: PALETTE_MAX_CHIPS_PER_ROW=16 (strip $H0 -> $HC px)" || fail "max columns: $W_PER"
# Max Rows = 1 (row 0 of its submenu): one row of chips, whatever the palette
pick 0 0 "max rows 1"; wspn; strip
(( W_ROWS == 1 )) && pass "Max Rows 1: PALETTE_MAX_ROWS=1" || fail "max rows: $W_ROWS"
(( ST_H == W_CH + 1 + 3 )) && pass "the strip is one row of chips tall ($HC -> $ST_H)" || fail "the strip is $ST_H px, one row is $(( W_CH + 4 ))"
H1=$ST_H
# Chip Height = 14 (4 .. 32: row 10)
pick 2 10 "chip height 14"; wspn; strip
(( W_CH == 14 )) && pass "Chip Height 14: PALETTE_CHIP_HEIGHT=14" || fail "chip height: $W_CH"
(( ST_H > H1 )) && pass "the strip got taller with the chips ($H1 -> $ST_H)" || fail "the strip did not grow ($H1 -> $ST_H)"
# Chip Width = 8 (row 4), Max Columns = 64 (16 32 48 64: row 3)
pick 3 4 "chip width 8"; wspn
(( W_CW == 8 )) && pass "Chip Width 8: PALETTE_CHIP_WIDTH=8" || fail "chip width: $W_CW"
pick 1 3 "max columns 64"; wspn
(( W_PER == 64 )) && pass "Max Columns 64: PALETTE_MAX_CHIPS_PER_ROW=64" || fail "max columns: $W_PER"
grep -q '^PALETTE_CHIP_HEIGHT=14' "$QA_CFG" && grep -q '^PALETTE_MAX_ROWS=1' "$QA_CFG" \
    && pass "DRAW.cfg keeps them" || fail "not saved: $(grep -E '^PALETTE_(MAX_ROWS|CHIP_HEIGHT)=' "$QA_CFG" | tr '\n' ' ')"

# a right-click on a chip: the background color, no menu
strip; right_click $(( 2 + 12 + 2 + 3 )) $(( ST_Y + 4 )); wait_for 0.6 "a chip"; dk_settle; psm
[[ -z "$PM_RX" ]] && pass "a right-click on a chip opens no menu" || { fail "a chip right-click opened the size menu"; key Escape; }
# a click elsewhere closes an open menu (and does nothing else)
open_menu; dk_park; click $(( PM_RX + PM_RW + 80 )) $(( PM_RY - 60 )); wait_for 0.6 "outside"; dk_settle; psm
[[ -z "$PM_RX" ]] && pass "a click outside closes it" || fail "still open after a click outside"
# a right-click on a scroll button opens the menu too, and does not scroll
# (Rick 2026-11-16: "the color strip context menu needs to popup when right
# clicking the scroll left/right buttons (or ... vertical ...) up/down")
pick 1 0 "max columns 16 (so the strip scrolls)"
pgrid() { read -r _ _ _ _ _ _ _ G_OFF _ A1X A1Y A1W A1H A2X A2Y A2W A2H G_FIT <<< "$(grep -m1 '^PSTRIPG' "$DK_DUMP")"; }
dk_settle; pgrid
if [[ "$G_FIT" != 0 ]] || (( A1W <= 0 )); then
    fail "the strip has no scroll buttons with 16 columns in 1 row (allFit $G_FIT, a1w $A1W)"
else
    for ab in 1 2; do
        if (( ab == 1 )); then AX=$(( A1X + A1W / 2 )); AY=$(( A1Y + A1H / 2 )); else AX=$(( A2X + A2W / 2 )); AY=$(( A2Y + A2H / 2 )); fi
        O0=$G_OFF
        right_click "$AX" "$AY"; wait_for 0.6 "scroll button $ab"; dk_settle; psm; pgrid
        [[ -n "$PM_RX" ]] && pass "a right-click on scroll button $ab opens the menu" || fail "no menu after a right-click on scroll button $ab ($AX,$AY)"
        (( G_OFF == O0 )) && pass "... and does not scroll (offset $G_OFF)" || fail "the right-click scrolled $O0 -> $G_OFF"
        key Escape; wait_for 0.4 "esc"; dk_settle
    done
    click $(( A2X + A2W / 2 )) $(( A2Y + A2H / 2 )); wait_for 0.4 "left click"; dk_settle; pgrid
    (( G_OFF != O0 )) && pass "a left click on it still scrolls ($O0 -> $G_OFF)" || fail "a left click on the scroll button did not scroll"
fi
assert_no_crash
info "=== Color strip: the size menu: done ==="
