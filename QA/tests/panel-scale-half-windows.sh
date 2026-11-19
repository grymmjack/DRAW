#!/bin/bash
# =============================================================================
# panel-scale-half-windows.sh — QA test: a floating native window (the Color
# Mixer) at a half-step Scale (Rick 2026-11-18: "let's do this for all of the
# panels :)" after the MyPaint palette's 1.5x "LOOKS STUNNING").
#
#   1. its title-bar menu offers 1.5x .. (DOCK_ACT_SCALE_HALF 30 + k)
#   2. 1.5x: the window 3/4 of its Auto size (Auto = the display scale, 2 here),
#      COLOR_MIXER_SCALE=1.5 saved, the picture smoothed (bicubic: many more
#      colours than the whole-step picture), dk_check clean
#   3. 2.5x: 5/4 of Auto
#   4. Auto: the old size, COLOR_MIXER_SCALE=0
# Native windows resample through HSC_put (GUI/PANEL-SURFACE) - only when their
# picture changed (gj_region_changed).
# Dump: WIN name x y w h slot (viewport px); DMENU / DMENUR (the open menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE COLOR_MIXER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: half-step Scale on a native window (Color Mixer) ==="

win() { W_X=; read -r _ _ W_X W_Y W_W W_H _ <<< "$(grep -m1 '^WIN colormixer ' "$DK_DUMP")"; }
saved() { grep -q "^$1=$2[[:space:]]*\$" "$QA_CFG" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1=" "$QA_CFG")', want $2"; }
pick_scale() { dk_rmenu colormixer || return 1; dk_pick "$1" "$2"; }
about() { (( $1 * $3 >= $2 * $4 - 8 && $1 * $3 <= $2 * $4 + 8 )); } # A ~= B * NUM / DEN: about A B DEN NUM
# LABEL: the number of distinct colours along its title bar (flat chrome + text: a few at a
# whole step, many once bicubic - the body is a colour field, too many either way)
colours() {
    snap_region $(( W_X + 2 )) $(( W_Y + 1 )) $(( W_W - 4 )) 7 "hsw-$1" >/dev/null 2>&1
    [[ -f "$SNAP_RESULT" ]] && magick "$SNAP_RESULT" -format '%k' info: 2>/dev/null || echo 0
}

dk_begin
win
[[ -n "$W_X" ]] || fail "no colormixer window in the dump"
AW=$W_W; AH=$W_H
info "Auto: ${AW}x$AH at $W_X,$W_Y"
pick_scale 22 "2x (whole)" && { win; C2=$(colours whole2); info "2x: ${W_W}x$W_H, $C2 colours"; }

# --- 1. the menu -----------------------------------------------------------------
if dk_rmenu colormixer; then
    dk_menu_has 31 && dk_menu_has 32 && pass "the Mixer's Scale menu has 1.5x, 2.5x" || fail "no half-step rows in the Mixer's menu"
    key Escape; wait_for 0.4 "close"; dk_settle
fi

# --- 2. 1.5x ---------------------------------------------------------------------------
if pick_scale 31 "1.5x"; then
    win
    about "$W_W" "$AW" 4 3 && about "$W_H" "$AH" 4 3 && pass "1.5x: the window 3/4 of Auto (${AW}x$AH -> ${W_W}x$W_H)" || fail "1.5x: ${AW}x$AH -> ${W_W}x$W_H (want about $(( AW * 3 / 4 ))x$(( AH * 3 / 4 )))"
    saved COLOR_MIXER_SCALE 1.5
    C15=$(colours half15)
    (( C15 > C2 )) && pass "1.5x: smoothed ($C15 colours, $C2 at 2x)" || fail "1.5x: $C15 colours, $C2 at 2x - not smoothed?"
    dk_check "colormixer at 1.5x"
    screenshot "panel-scale-half-windows-1.5x"
fi

# --- 3. 2.5x ---------------------------------------------------------------------------
if pick_scale 32 "2.5x"; then
    win
    about "$W_W" "$AW" 4 5 && pass "2.5x: the window 5/4 of Auto ($AW -> $W_W)" || fail "2.5x: width $AW -> $W_W (want about $(( AW * 5 / 4 )))"
    saved COLOR_MIXER_SCALE 2.5
    dk_check "colormixer at 2.5x"
fi

# --- 4. Auto ---------------------------------------------------------------------------
if pick_scale 20 "Auto"; then
    win
    (( W_W == AW && W_H == AH )) && pass "Auto: the old size (${W_W}x$W_H)" || fail "Auto: ${W_W}x$W_H, was ${AW}x$AH"
    saved COLOR_MIXER_SCALE 0
fi
assert_no_crash
info "=== Panels: half-step Scale on a native window: done ==="
