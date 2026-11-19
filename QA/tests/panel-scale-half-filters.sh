#!/bin/bash
# =============================================================================
# panel-scale-half-filters.sh — QA test: how a half-step Scale is scaled up
# (CFG.PANEL_HALF_FILTER; Rick 2026-11-18: the Tiny5 text "crunchy looking" at
# nearest 1.5x - "can we use bicubic scale on .5 sizes?").
#
# The MyPaint Brushes palette at 1.5x, launched once per filter: BICUBIC (the
# default), NEAREST, SHARP. Its header (the group name, the buttons: Tiny5 text) is
# snapped in screen px each time:
#   - the three differ
#   - BICUBIC has more colour levels than NEAREST (smoothed edges), SHARP in between
#     or more than NEAREST
#   - the pointer still lands on a cell with each (the picture moves, the hit test
#     does not)
# Crops: screenshots/half-filter-{BICUBIC,NEAREST,SHARP}.png
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE MYPAINT_PANEL=TRUE MYPAINT_PANEL_SCALE=1.5 MYPAINT_BRUSH= MYPAINT_SET=Classic MYPAINT_CELL=48
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Panels: half-step Scale filters ==="

DS=2
mp_read() { read -r _ M_VIS M_X M_Y M_W M_H M_G M_NG M_N M_CELL M_COLS M_RF M_RA M_SC M_GX M_GY M_HOV M_CUR M_GNAME <<< "$(grep -m1 '^MYPP ' "$DK_DUMP")"; }
surf() { S_ON=; S_K=; read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
u2v() { awk -v u="$1" -v o="$2" -v k="$3" -v ds="$DS" 'BEGIN { printf "%d", o + (u - o) * k / ds }'; }
ncol() { magick "$1" -format '%k' info:; }

declare -A SNAP NC
for F in BICUBIC NEAREST SHARP; do
    if [[ "$F" != BICUBIC ]]; then
        DRAW_EXTRA_ARGS="--option PANEL_HALF_FILTER=$F"
        info "Relaunching DRAW with PANEL_HALF_FILTER=$F"
        draw_quit; rm -f "$DK_DUMP"; draw_launch 15
    fi
    dk_begin
    surf 11
    if [[ "$S_K" != 1.5 ]]; then fail "$F: the palette is not at 1.5x (PSURF '$(grep '^PSURF 11 ' "$DK_DUMP")')"; continue; fi
    dk_park; dk_settle
    # the header: its first 30 viewport px (group name + buttons)
    snap_region "$S_VX" "$S_VY" "$S_VW" 30 "half-$F"
    SNAP[$F]=$SNAP_RESULT; NC[$F]=$(ncol "$SNAP_RESULT")
    cp "$SNAP_RESULT" "$SCREENSHOTS_DIR/half-filter-$F.png"
    info "$F: ${NC[$F]} colours in the header"
    screenshot "panel-scale-half-$F"
    # the pointer on cell 1 still hovers it
    mp_read
    cx=$(( M_GX + (M_CELL + 2) + M_CELL / 2 )); cy=$(( M_GY + M_CELL / 2 ))
    vx=$(u2v "$cx" "$S_VX" 1.5); vy=$(u2v "$cy" "$S_VY" 1.5)
    hover "$vx" "$vy"; wait_for 0.3 "hover"; hover $(( vx + 1 )) "$vy"; wait_for 0.4 "hover"; dk_settle; mp_read
    (( M_HOV == 101 )) && pass "$F: the pointer on cell 1 hovers it" || fail "$F: the pointer on cell 1 ($vx,$vy) hovers '$M_HOV'"
    dk_park
done
if [[ -n "${SNAP[BICUBIC]}" && -n "${SNAP[NEAREST]}" && -n "${SNAP[SHARP]}" ]]; then
    assert_regions_differ "${SNAP[BICUBIC]}" "${SNAP[NEAREST]}" "BICUBIC is not the NEAREST picture"
    assert_regions_differ "${SNAP[SHARP]}" "${SNAP[NEAREST]}" "SHARP is not the NEAREST picture"
    assert_regions_differ "${SNAP[SHARP]}" "${SNAP[BICUBIC]}" "SHARP is not the BICUBIC picture"
    (( NC[BICUBIC] > NC[NEAREST] )) && pass "BICUBIC smooths: ${NC[BICUBIC]} colours vs NEAREST ${NC[NEAREST]}" || fail "BICUBIC ${NC[BICUBIC]} colours, NEAREST ${NC[NEAREST]}"
    (( NC[SHARP] > NC[NEAREST] )) && pass "SHARP smooths a little: ${NC[SHARP]} colours" || fail "SHARP ${NC[SHARP]} colours, NEAREST ${NC[NEAREST]}"
fi
assert_no_crash
info "=== Panels: half-step Scale filters: done ==="
