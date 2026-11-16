#!/bin/bash
# =============================================================================
# palette-strip-menu-zorder.sh — QA test: the color strip's size menu draws on
# top of everything (Rick, 2026-11-14: "the color strip menu isn't working
# properly ... it goes behind the color strip itself too and sometimes just
# shows black rectangles"; the root rows' labels were missing next to a
# docked panel at its own Scale).
#
# The menu was drawn before the GUI layer was put back over the canvas, so
# the strip covered it; the cursor-only redraw paths copied cached pixels
# over it (the black boxes); a panel at a set Scale is put on the window
# after the canvas and covered it too.
#
#  - the drawer at 1x (its own surface); Max Columns 16 so the strip's right
#    end is blank
#  - right-click the strip's right end: the menu box over the strip differs
#    from the strip without it, and so does the part over the drawer column
#  - moving the pointer around inside the menu leaves its rows unchanged
#    (no stale boxes copied over them)
#  - no tooltip while it is open
#
# Dump: PSTRIP y h ... | PSM rx ry rw subRow sbX sbY sbW sbN | SCR w h ... |
# P drawer ... (dock-lib.sh) | PSURF id on k. Rows 12 px from the box top + 2.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt HELP_CARD_ENABLED=FALSE
# (tooltips stay on: the menu must hold them off)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Color strip menu: on top ==="
dk_begin

strip() { read -r _ ST_Y ST_H ST_FIT <<< "$(grep -m1 '^PSTRIP ' "$DK_DUMP")"; }
psm() { PM_RX=""; read -r _ PM_RX PM_RY PM_RW PM_SUB PM_SX PM_SY PM_SW PM_SN <<< "$(grep -m1 '^PSM ' "$DK_DUMP")"; }
row_y() { echo $(( $1 + 2 + $2 * 12 + 6 )); }
# NAME DPID VALUE: right-click NAME's handle, pick its menu row VALUE (20 Auto, 20+k = kx)
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

# --- setup: the drawer on its own surface, a short strip --------------------------
DRAWER_1X=0
if dk_visible drawer; then
    pick_scale drawer 3 21
    read -r _ _ S_ON S_K _ <<< "$(grep -m1 '^PSURF 3 ' "$DK_DUMP")"
    [[ "$S_ON" == -1 && "$S_K" == 1 ]] && DRAWER_1X=1 && info "drawer at 1x (own surface)" || info "drawer not on a surface ($(grep '^PSURF 3 ' "$DK_DUMP"))"
fi
strip; right_click 1 $(( ST_Y + 2 )); wait_for 0.6 "menu"; dk_settle; psm
if [[ -n "$PM_RX" ]]; then
    hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" 1)"; wait_for 0.5 "max columns"; dk_settle; psm
    click $(( PM_SX + PM_SW / 2 )) "$(row_y "$PM_SY" 0)"; wait_for 0.8 "16"; dk_park; dk_settle
else
    fail "setup: no size menu at the strip's left end"
fi

# --- the menu from the strip's right end ------------------------------------------------
dk_scr; strip
RX=$(( SCR_W - 4 )); RY=$(( ST_Y + ST_H / 2 ))
dk_park; wait_for 0.6 "pointer away"
snap_region $(( SCR_W - 160 )) $(( ST_Y - 60 )) 156 $(( ST_H + 58 )) "strip-closed"; CLOSED=$SNAP_RESULT
right_click "$RX" "$RY"; wait_for 0.8 "the size menu"; dk_settle; psm
[[ -n "$PM_RX" ]] && pass "a right-click at the strip's blank right end opens the menu ($PM_RX,$PM_RY ${PM_RW}w; strip y $ST_Y)" || fail "no menu at x $RX (strip y $ST_Y h $ST_H)"
BOX_H=$(( 4 * 12 + 4 ))
BOX_B=$(( PM_RY + BOX_H ))
# the part of the box over the strip
if (( BOX_B > ST_Y + 3 )); then
    OY=$(( PM_RY > ST_Y ? PM_RY : ST_Y )); OH=$(( BOX_B - OY - 2 ))
    hover "$RX" $(( ST_Y + ST_H - 2 )); wait_for 0.4 "pointer below"
    snap_region $(( PM_RX + 2 )) "$OY" $(( PM_RW - 4 )) "$OH" "menu-over-strip"; A=$SNAP_RESULT
    dk_park; key Escape; wait_for 0.6 "closed"; dk_settle
    snap_region $(( PM_RX + 2 )) "$OY" $(( PM_RW - 4 )) "$OH" "strip-under-menu"; B=$SNAP_RESULT
    assert_regions_differ "$A" "$B" "the menu shows over the strip (y $OY, ${OH}px)"
    right_click "$RX" "$RY"; wait_for 0.8 "the menu again"; dk_settle; psm
else
    info "the box sits wholly above the strip (bottom $BOX_B, strip $ST_Y)"
fi
# the part above the strip: over the drawer column when it is at 1x
if (( PM_RY < ST_Y - 4 )); then
    UH=$(( ST_Y - PM_RY - 3 )); (( UH > BOX_H - 4 )) && UH=$(( BOX_H - 4 ))
    hover "$RX" "$RY"; wait_for 0.4 "pointer on the strip"
    snap_region $(( PM_RX + 2 )) $(( PM_RY + 2 )) $(( PM_RW - 4 )) "$UH" "menu-above-strip"; A=$SNAP_RESULT
    dk_park; key Escape; wait_for 0.6 "closed"; dk_settle
    snap_region $(( PM_RX + 2 )) $(( PM_RY + 2 )) $(( PM_RW - 4 )) "$UH" "under-menu-above-strip"; B=$SNAP_RESULT
    assert_regions_differ "$A" "$B" "the menu shows above the strip$( (( DRAWER_1X )) && echo ', over the drawer at 1x')"
    right_click "$RX" "$RY"; wait_for 0.8 "the menu again"; dk_settle; psm
fi
screenshot "palette-strip-menu-zorder"

# --- moving around inside it: its rows stay put --------------------------------------
hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" 0)"; wait_for 0.5 "row 0"; dk_settle; psm
snap_region $(( PM_RX + 2 )) $(( PM_RY + 2 + 2 * 12 )) $(( PM_RW - 4 )) 22 "rows-2-3-a"; A=$SNAP_RESULT
for dx in 6 14 22 30; do hover $(( PM_RX + dx )) "$(row_y "$PM_RY" 0)"; wait_for 0.15 "wiggle"; done
hover $(( PM_RX + PM_RW / 2 )) "$(row_y "$PM_RY" 0)"; wait_for 0.6 "back on row 0"
snap_region $(( PM_RX + 2 )) $(( PM_RY + 2 + 2 * 12 )) $(( PM_RW - 4 )) 22 "rows-2-3-b"; B=$SNAP_RESULT
assert_regions_same "$A" "$B" "rows 2-3 unchanged while the pointer moves on row 0 (no stale boxes over them)"

key Escape; wait_for 0.5 "closed"; dk_settle; psm
[[ -z "$PM_RX" ]] && pass "Esc closes it" || fail "the menu stayed after Esc"
(( DRAWER_1X )) && pick_scale drawer 3 20
assert_no_crash
info "=== Color strip menu: on top: done ==="
